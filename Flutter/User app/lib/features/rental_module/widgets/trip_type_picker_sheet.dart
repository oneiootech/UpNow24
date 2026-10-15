
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/custom_button.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';
import 'package:sixam_mart/common/widgets/custom_text_field.dart';
import 'package:sixam_mart/features/rental_module/custom/custom_icon.dart';
import 'package:sixam_mart/features/rental_module/home/domain/models/vehicle_details_model.dart';
import 'package:sixam_mart/features/rental_module/rental_location_screen/controller/taxi_location_controller.dart';
import 'package:sixam_mart/features/rental_module/rental_cart_screen/controllers/taxi_cart_controller.dart';
import 'package:sixam_mart/features/rental_module/rental_cart_screen/domain/models/car_cart.dart';
import 'package:sixam_mart/features/rental_module/rental_cart_screen/domain/models/car_cart_model.dart';
import 'package:sixam_mart/features/rental_module/rental_cart_screen/widgets/trip_vehicle_list_dialog.dart';
import 'package:sixam_mart/features/rental_module/helper/cart_helper.dart';
import 'package:sixam_mart/common/models/config_model.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/helper/price_converter.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

class TripTypePickerSheet extends StatefulWidget {
  final VehicleModel? vehicle;
  final bool showTripTypeHourly;
  final bool showTripTypeDistance;
  final bool showTripTypeDay;
  final double hourlyDiscount;
  final double distanceWiseDiscount;
  final double dayWiseDiscount;
  final String discountType;
  final bool fromCart;

  const TripTypePickerSheet({super.key,
    this.vehicle,
    required this.showTripTypeHourly, required this.showTripTypeDistance, required this.showTripTypeDay,
    required this.hourlyDiscount, required this.distanceWiseDiscount, required this.dayWiseDiscount,
    required this.discountType, this.fromCart = false,
  });

  @override
  State<TripTypePickerSheet> createState() => _TripTypePickerSheetState();
}

class _TripTypePickerSheetState extends State<TripTypePickerSheet> {
  late String _selectedType;

  /// True while the cart round-trip behind "confirm trip type" is in flight.
  /// Local rather than `TaxiCartController.isLoading` so only this sheet's
  /// button reacts — the same controller flag drives the add-to-cart button on
  /// RentalLocationConfirmScreen.
  bool _isConfirming = false;

  @override
  void initState() {
    super.initState();
    _selectedType = Get.find<TaxiLocationController>().tripType;

    if (widget.fromCart) {
      final UserData? userData = Get.find<TaxiCartController>().carCartModel?.userData;
      if (userData != null) {
        _selectedType = userData.rentalType ?? _selectedType;
        final TaxiLocationController locationController = Get.find<TaxiLocationController>();
        final double hours = userData.estimatedHours ?? 0;
        if (hours > 0) {
          locationController.estimateTimeController.text = '$hours';
          locationController.estimateDayController.text = (hours / 24).toStringAsFixed(1);
        }
      }
    }
  }

  /// Closes this sheet — and only this sheet.
  ///
  /// A bare `Get.back()` pops whatever route is topmost *at the moment it runs*,
  /// which is not the same thing once two awaited cart calls sit in front of it.
  /// The sheet gave no feedback while those requests ran, so the customer would
  /// either tap "confirm" again or dismiss the sheet by hand; the delayed
  /// `Get.back()` then popped RentalCartScreen instead, dropping them back on
  /// the rental location screen. Popping by route identity makes that
  /// impossible: if the sheet is already gone, nothing happens.
  void _closeSheet() {
    if (!mounted) return;
    final ModalRoute<dynamic>? sheetRoute = ModalRoute.of(context);
    if (sheetRoute == null || !sheetRoute.isCurrent) return;
    Navigator.of(context).pop();
  }

  Future<void> _confirmFromCart() async {
    final TaxiCartController cartController = Get.find<TaxiCartController>();
    final TaxiLocationController locationController = Get.find<TaxiLocationController>();
    final UserData? userData = cartController.carCartModel?.userData;
    if (userData == null) {
      locationController.selectTripType(_selectedType);
      _closeSheet();
      return;
    }

    final double estimatedDay = (double.tryParse(locationController.estimateDayController.text) ?? 0) * 24;
    final CarCart cart = CarCart(
      applyMethod: true, distance: userData.distance, destinationTime: userData.destinationTime,
      rentalType: _selectedType,
      estimatedHour: _selectedType == 'hourly'
          ? locationController.estimateTimeController.text
          : _selectedType == 'day_wise'
              ? estimatedDay.toStringAsFixed(1)
              : '${userData.estimatedHours ?? 0}',
    );

    setState(() => _isConfirming = true);
    try {
      final bool isCartExistType = await CartHelper.checkTypeInCart(cartController.cartList, _selectedType);

      if (!isCartExistType) {
        _closeSheet();
        Get.dialog(TripVehicleListDialog(rentalType: _selectedType, cart: cart, userId: userData.id!));
        return;
      }

      // `updateUserData` reports its own failure through ApiChecker; falling
      // through here just leaves the sheet open so the customer can retry.
      final bool success = await cartController.updateUserData(cart: cart, userId: userData.id!);
      if (!success) return;

      await cartController.getCarCartList();
      locationController.selectTripType(_selectedType);
      _closeSheet();
    } finally {
      if (mounted) {
        setState(() => _isConfirming = false);
      }
    }
  }

  /// `km` or `mi`, whichever the platform is configured for. The rate itself is
  /// never converted — it is entered against the configured unit, so only the
  /// suffix changes.
  String get _distanceUnitLabel {
    if (!Get.isRegistered<SplashController>()) {
      return 'km'.tr;
    }
    final ConfigModel? config = Get.find<SplashController>().configModel;
    final String? label = config?.distanceUnitLabel ?? config?.distanceUnit?.label;
    return (label != null && label.trim().isNotEmpty) ? label.trim() : 'km'.tr;
  }

  /// `distance_unit_label` decides, so the word can never disagree with the
  /// suffix shown beside the price. `units.distance.name` is only a fallback for
  /// a unit this app has no word for.
  String get _distanceUnitName {
    final String label = _distanceUnitLabel.toLowerCase();
    if (label == 'mi') {
      return 'mile'.tr;
    }
    if (label == 'km') {
      return 'kilometre'.tr;
    }
    final String? name = Get.isRegistered<SplashController>()
        ? Get.find<SplashController>().configModel?.distanceUnit?.name : null;
    return (name != null && name.trim().isNotEmpty) ? name.trim() : 'kilometre'.tr;
  }

  String _subtitle(String tripType) {
    switch (tripType) {
      case 'hourly': return 'fair_per_hour'.tr;
      case 'day_wise': return 'fair_per_day'.tr;
      default: return '${'fare_per'.tr} $_distanceUnitName';
    }
  }

  String _fareType(String tripType) {
    switch (tripType) {
      case 'hourly': return 'hr'.tr;
      case 'day_wise': return 'day'.tr;
      default: return _distanceUnitLabel;
    }
  }

  String _price(String tripType) {
    if (widget.vehicle == null) {
      final config = Get.find<SplashController>().configModel!;
      switch (tripType) {
        case 'hourly': return PriceConverter.convertPrice(config.vehicleHourlyMinPrice ?? 0);
        case 'day_wise': return PriceConverter.convertPrice(config.vehicleDayWiseMinPrice ?? 0);
        default: return PriceConverter.convertPrice(config.vehicleDistanceMinPrice ?? 0);
      }
    }
    switch (tripType) {
      case 'hourly':
        return widget.discountType == 'amount'
            ? PriceConverter.convertPrice(widget.vehicle!.hourlyPrice!)
            : PriceConverter.convertPrice(widget.vehicle!.hourlyPrice! - widget.hourlyDiscount);
      case 'day_wise':
        return widget.discountType == 'amount'
            ? PriceConverter.convertPrice(widget.vehicle!.dayWisePrice!)
            : PriceConverter.convertPrice(widget.vehicle!.dayWisePrice! - widget.dayWiseDiscount);
      default:
        return widget.discountType == 'amount'
            ? PriceConverter.convertPrice(widget.vehicle!.distancePrice!)
            : PriceConverter.convertPrice(widget.vehicle!.distancePrice! - widget.distanceWiseDiscount);
    }
  }

  @override
  Widget build(BuildContext context) {
    final taxiLocationController = Get.find<TaxiLocationController>();

    final types = [
      if (widget.showTripTypeHourly) 'hourly',
      if (widget.showTripTypeDay) 'day_wise',
      if (widget.showTripTypeDistance) 'distance_wise',
    ];

    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(Dimensions.radiusLarge),
          topRight: Radius.circular(Dimensions.radiusLarge),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeLarge),
      child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SizedBox(height: 8),

          Align(
            alignment: Alignment.topRight,
            child: GestureDetector(
              onTap: () => Get.back(),
              child: CustomIcon(icon: Icons.close, height: 24, width: 24, color: Colors.grey[500]),
            ),
          ),

          Text('select_trip_type'.tr, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge)),
          Text('choose_your_preferable_trip_type_at_best_price'.tr,
              style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).disabledColor)),
          const SizedBox(height: Dimensions.paddingSizeDefault),

          ...types.map((type) => _TripTypeOptionCard(
            tripType: type,
            subtitle: _subtitle(type),
            price: _price(type),
            fareType: _fareType(type),
            isSelected: _selectedType == type,
            taxiLocationController: taxiLocationController,
            // Ignored while confirming so the selection cannot drift away from
            // the type the in-flight request is already saving.
            onTap: () {
              if (_isConfirming) return;
              setState(() => _selectedType = type);
            },
          )),

          const SizedBox(height: Dimensions.paddingSizeDefault),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeLarge),
              child: CustomButton(
                buttonText: 'confirm_trip_type'.tr,
                // `CustomButton` drops its own `onPressed` while loading, so this
                // also makes the double-tap that used to queue a second pop
                // impossible.
                isLoading: _isConfirming,
                onPressed: () {
                  if (_selectedType == 'hourly' && taxiLocationController.estimateTimeController.text.isEmpty) {
                    showCustomSnackBar('please_enter_estimate_time'.tr);
                    return;
                  }
                  if (_selectedType == 'hourly' && (double.tryParse(taxiLocationController.estimateTimeController.text) ?? 0) <= 0) {
                    showCustomSnackBar('please_enter_valid_estimate_time'.tr);
                    return;
                  }
                  if (_selectedType == 'day_wise' && taxiLocationController.estimateDayController.text.isEmpty) {
                    showCustomSnackBar('please_enter_estimate_days'.tr);
                    return;
                  }
                  if (_selectedType == 'day_wise' && (double.tryParse(taxiLocationController.estimateDayController.text) ?? 0) <= 0) {
                    showCustomSnackBar('please_enter_valid_estimate_days'.tr);
                    return;
                  }
                  if (widget.fromCart) {
                    _confirmFromCart();
                  } else {
                    taxiLocationController.selectTripType(_selectedType);
                    Get.back();
                  }
                },
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

class _TripTypeOptionCard extends StatelessWidget {
  final String tripType;
  final String subtitle;
  final String price;
  final String fareType;
  final bool isSelected;
  final TaxiLocationController taxiLocationController;
  final VoidCallback onTap;

  const _TripTypeOptionCard({
    required this.tripType, required this.subtitle, required this.price, required this.fareType, required this.isSelected,
    required this.taxiLocationController, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
          border: Border.all(
            color: isSelected ? Theme.of(context).primaryColor : Theme.of(context).disabledColor.withValues(alpha: 0.3),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(tripType.tr, style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeDefault)),
                const SizedBox(height: 2),
                Text(subtitle, style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).disabledColor)),
              ]),
            ),

            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('start_from'.tr, style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeExtraSmall, color: Theme.of(context).disabledColor)),
              Text(price, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeDefault, color: Theme.of(context).textTheme.bodyLarge!.color)),
            ]),

            const SizedBox(width: Dimensions.paddingSizeSmall),

            Icon(
              isSelected ? Icons.radio_button_on : Icons.radio_button_off_outlined,
              color: isSelected ? Theme.of(context).primaryColor : Theme.of(context).disabledColor,
              size: 22,
            ),
          ]),

          if (isSelected && tripType == 'hourly') ...[
            const SizedBox(height: Dimensions.paddingSizeSmall),
            RichText(text: TextSpan(children: [
              TextSpan(text: 'estimate_time'.tr, style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).textTheme.bodyLarge!.color)),
              const TextSpan(text: ' *', style: TextStyle(color: Colors.red)),
            ])),
            const SizedBox(height: Dimensions.paddingSizeExtraSmall),
            CustomTextField(
              controller: taxiLocationController.estimateTimeController,
              titleText: 'Ex: 2 hours',
              isNumber: true,
              inputType: TextInputType.number,
            ),
          ],

          if (isSelected && tripType == 'day_wise') ...[
            const SizedBox(height: Dimensions.paddingSizeSmall),
            RichText(text: TextSpan(children: [
              TextSpan(text: 'estimate_days'.tr, style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).textTheme.bodyLarge!.color)),
              const TextSpan(text: ' *', style: TextStyle(color: Colors.red)),
            ])),
            const SizedBox(height: Dimensions.paddingSizeExtraSmall),

            CustomTextField(
              controller: taxiLocationController.estimateDayController,
              titleText: 'Ex: 2 days',
              isNumber: true,
              inputType: TextInputType.number,
            ),
          ],

        ]),
      ),
    );
  }
}