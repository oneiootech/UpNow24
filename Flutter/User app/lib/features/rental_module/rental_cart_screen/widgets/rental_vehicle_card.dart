import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/models/config_model.dart';
import 'package:sixam_mart/common/widgets/confirmation_dialog.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';
import 'package:sixam_mart/features/rental_module/helper/cart_helper.dart';
import 'package:sixam_mart/features/rental_module/home/domain/models/vehicle_details_model.dart';
import 'package:sixam_mart/features/rental_module/rental_cart_screen/controllers/taxi_cart_controller.dart';
import 'package:sixam_mart/features/rental_module/rental_cart_screen/domain/models/car_cart.dart';
import 'package:sixam_mart/features/rental_module/rental_cart_screen/domain/models/car_cart_model.dart';
import 'package:sixam_mart/features/rental_module/rental_location_screen/controller/taxi_location_controller.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/helper/date_converter.dart';
import 'package:sixam_mart/helper/image_cache_helper.dart';
import 'package:sixam_mart/helper/price_converter.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';

class RentalCartVehicleCard extends StatefulWidget {
  final VehicleModel vehicle;
  final Carts? carts;
  final int index;
  final bool? isCartHourly;
  final bool? fromSelectVehicleScreen;
  final String? licenseNumber;

  const RentalCartVehicleCard({super.key,
    required this.vehicle, this.carts, required this.index, this.isCartHourly, this.fromSelectVehicleScreen = false, this.licenseNumber,
  });

  @override
  State<RentalCartVehicleCard> createState() => _RentalCartVehicleCardState();
}

class _RentalCartVehicleCardState extends State<RentalCartVehicleCard> {
  @override
  Widget build(BuildContext context) {
    double discount = widget.vehicle.discountPrice ?? 0;
    String discountType = widget.vehicle.discountType ?? 'percent';

    bool tripHourly = widget.vehicle.tripHourly ?? false;
    bool tripDayWise = widget.vehicle.tripDayWise ?? false;
    if (widget.fromSelectVehicleScreen == true) {
      tripHourly = Get.find<TaxiLocationController>().tripType == 'hourly';
      tripDayWise = Get.find<TaxiLocationController>().tripType == 'day_wise';
    }
    if (widget.isCartHourly != null) {
      tripHourly = widget.isCartHourly!;
      tripDayWise = widget.isCartHourly!;
    }

    double hourlyDiscount = PriceConverter.calculation(widget.vehicle.hourlyPrice!, discount, discountType, 1);
    double distanceWiseDiscount = PriceConverter.calculation(widget.vehicle.distancePrice!, discount, discountType, 1);
    double dayWiseDiscount = PriceConverter.calculation(widget.vehicle.dayWisePrice!, discount, discountType, 1);

    return GetBuilder<TaxiCartController>(builder: (taxiCartController) {
      int isExistInCartPosition = taxiCartController.isExistInCart(widget.vehicle.id);
      int quantity = 1;
      int cartId = 0;

      if (isExistInCartPosition != -1) {
        quantity = taxiCartController.getCartQuantity(isExistInCartPosition);
        cartId = taxiCartController.getCartId(isExistInCartPosition) ?? 0;
        tripHourly = taxiCartController.carCartModel?.userData?.rentalType == 'hourly';
        tripDayWise = taxiCartController.carCartModel?.userData?.rentalType == 'day_wise';
      }

      final double priceBase = tripHourly
          ? widget.vehicle.hourlyPrice ?? 0
          : tripDayWise
              ? widget.vehicle.dayWisePrice ?? 0
              : widget.vehicle.distancePrice ?? 0;
      final double totalDiscountPrice = tripHourly ? hourlyDiscount : tripDayWise ? dayWiseDiscount : distanceWiseDiscount;
      final double finalPrice = discountType == 'amount' ? priceBase : priceBase - totalDiscountPrice;
      final ConfigModel? config = Get.find<SplashController>().configModel;
      final String fareUnit = tripHourly ? 'hr'.tr : tripDayWise ? 'day'.tr : (config?.distanceUnitSuffix ?? 'km');

      return Padding(
        padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.center, children: [

            ClipRRect(
              borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
              child: CustomImage(
                image: widget.vehicle.thumbnailFullUrl ?? '',
                width: 60, height: 50, fit: BoxFit.cover,
                cacheWidth: ImageCacheHelper.pixels(context, 50),
              ),
            ),
            const SizedBox(width: Dimensions.paddingSizeSmall),

            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(
                  widget.vehicle.name ?? '',
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall),
                ),
                const SizedBox(height: 4),
                Row(children: [
                  Text(
                    PriceConverter.convertPrice(finalPrice, forTaxi: true),
                    style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeDefault),
                  ),
                  Text(
                    ' /$fareUnit',
                    style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).disabledColor),
                  ),
                  if (discountType != 'amount') ...[
                    const SizedBox(width: 2),
                    Text(
                      PriceConverter.convertPrice(priceBase, forTaxi: true),
                      style: robotoRegular.copyWith(
                        fontSize: Dimensions.fontSizeSmall,
                        color: Theme.of(context).disabledColor,
                        decoration: TextDecoration.lineThrough,
                        decorationColor: Theme.of(context).disabledColor,
                      ),
                    ),
                  ],
                ]),
              ]),
            ),
            const SizedBox(width: Dimensions.paddingSizeSmall),

            _QuantityControls(
              quantity: quantity,
              isLoading: taxiCartController.isLoading,
              maxStock: widget.vehicle.vehicleIdentitiesCount,
              onDecrement: () {
                if (quantity > 1) {
                  _manageCartQuantity(false, isExistInCartPosition, taxiCartController);
                } else {
                  taxiCartController.removeFromCart(cartId);
                }
              },
              onIncrement: () => _manageCartQuantity(true, isExistInCartPosition, taxiCartController),
            ),
          ]),

          if (widget.licenseNumber != null && widget.licenseNumber!.isNotEmpty) ...[
            const SizedBox(height: Dimensions.paddingSizeSmall),
            Text(
              '${'license_no'.tr} : ${widget.licenseNumber}',
              style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).disabledColor),
            ),
          ],
        ]),
      );
    });
  }

  void _manageCartQuantity(bool isIncrement, int cartIndex, TaxiCartController cartController) {
    TaxiLocationController locationController = Get.find<TaxiLocationController>();
    UserData userData = cartController.carCartModel!.userData!;

    if (widget.carts == null &&
        locationController.tripType == 'hourly' &&
        locationController.tripType == userData.rentalType &&
        userData.estimatedHours != double.parse(locationController.estimateTimeController.text)) {
      Get.dialog(ConfirmationDialog(
        icon: Images.warning,
        title: 'do_you_want_to_change_trip_duration'.tr,
        description: '${'are_you_sure_you_want_to_update_trip_duration_to'.tr} '
            '${CartHelper.calculateHour(tripType: locationController.tripType, time: locationController.estimateTimeController.text, day: locationController.estimateDayController.text)} ${'hours'.tr}',
        onYesPressed: () async {
          Get.back();
          CarCart userInfo = CarCart(
            applyMethod: true, distance: userData.distance, destinationTime: userData.destinationTime,
            rentalType: locationController.tripType,
            estimatedHour: CartHelper.calculateHour(tripType: locationController.tripType, time: locationController.estimateTimeController.text, day: locationController.estimateDayController.text),
          );
          cartController.updateUserData(cart: userInfo, userId: userData.id!).then((success) {
            if (success) cartController.setQuantity(isIncrement, cartIndex, stock: widget.vehicle.vehicleIdentitiesCount);
          });
        },
      ));
    } else if (widget.carts == null && locationController.tripType != userData.rentalType) {
      CartLocation pick = CartLocation(
        lat: locationController.fromAddress!.latitude, lng: locationController.fromAddress!.longitude,
        locationName: locationController.fromAddress!.address, locationType: locationController.fromAddress!.addressType,
      );
      CartLocation destination = CartLocation(
        lat: locationController.toAddress!.latitude, lng: locationController.toAddress!.longitude,
        locationName: locationController.toAddress!.address, locationType: locationController.toAddress!.addressType,
      );
      CarCart cart = CarCart(
        vehicleId: widget.vehicle.id, quantity: 1, pickupLocation: pick, destinationLocation: destination,
        pickupTime: DateConverter.formatDate(locationController.finalTripDateTime!),
        rentalType: locationController.tripType,
        estimatedHour: CartHelper.calculateHour(tripType: locationController.tripType, time: locationController.estimateTimeController.text, day: locationController.estimateDayController.text),
        destinationTime: locationController.duration, distance: locationController.distance,
      );
      cartController.decideAddToCart(cartController, cart, widget.vehicle, selectedLocationRentalType: locationController.tripType, isIncrement: isIncrement, cartIndex: cartIndex);
    } else {
      cartController.setQuantity(isIncrement, cartIndex, stock: widget.vehicle.vehicleIdentitiesCount);
    }
  }
}

class _QuantityControls extends StatelessWidget {
  final int quantity;
  final bool isLoading;
  final int? maxStock;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  const _QuantityControls({
    required this.quantity, required this.isLoading, this.maxStock, required this.onDecrement, required this.onIncrement,
  });

  @override
  Widget build(BuildContext context) {
    final bool atStockLimit = maxStock != null && quantity >= maxStock!;
    final bool incrementDisabled = isLoading || atStockLimit;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).disabledColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        InkWell(
          borderRadius: const BorderRadius.horizontal(left: Radius.circular(Dimensions.radiusDefault)),
          onTap: isLoading ? null : onDecrement,
          child: Icon(
            quantity == 1 ? Icons.delete_outline_rounded : Icons.remove,
            size: 18,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(quantity.toString(), style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeDefault)),
        ),

        InkWell(
          borderRadius: const BorderRadius.horizontal(right: Radius.circular(Dimensions.radiusDefault)),
          onTap: isLoading ? null : () {
            if (atStockLimit) {
              showCustomSnackBar('${'you_cant_add_more_than'.tr} $maxStock ${'quantities_of_this_vehicle'.tr}');
            } else {
              onIncrement();
            }
          },
          child: Icon(
            Icons.add, size: 18,
            color: incrementDisabled ? Theme.of(context).disabledColor : Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
      ]),
    );
  }
}
