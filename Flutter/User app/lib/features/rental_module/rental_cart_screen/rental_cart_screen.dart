import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/models/config_model.dart';
import 'package:sixam_mart/common/widgets/custom_app_bar.dart';
import 'package:sixam_mart/common/widgets/custom_asset_image_widget.dart';
import 'package:sixam_mart/common/widgets/custom_button.dart';
import 'package:sixam_mart/common/widgets/custom_text_field.dart';
import 'package:sixam_mart/features/address/domain/models/address_model.dart';
import 'package:sixam_mart/features/pro/widgets/pro_cart_banner_widget.dart';
import 'package:sixam_mart/features/rental_module/common/widgets/extra_discount_view_widget.dart';
import 'package:sixam_mart/features/rental_module/common/widgets/pick_up_time_card.dart';
import 'package:sixam_mart/features/rental_module/helper/taxi_price_helper.dart';
import 'package:sixam_mart/features/rental_module/rental_cart_screen/controllers/taxi_cart_controller.dart';
import 'package:sixam_mart/features/rental_module/rental_cart_screen/widgets/rental_vehicle_card.dart';
import 'package:sixam_mart/features/rental_module/rental_checkout_screen/rental_checkout_screen.dart';
import 'package:sixam_mart/features/rental_module/rental_location_screen/controller/taxi_location_controller.dart';
import 'package:sixam_mart/features/rental_module/rental_location_screen/taxi_location_screen.dart';
import 'package:sixam_mart/features/rental_module/rental_location_screen/widgets/location_card.dart';
import 'package:sixam_mart/features/rental_module/vendor/controllers/taxi_vendor_controller.dart';
import 'package:sixam_mart/features/rental_module/vendor/screens/provider_detail_screen.dart';
import 'package:sixam_mart/features/rental_module/widgets/rental_date_time_picker_sheet.dart';
import 'package:sixam_mart/features/rental_module/widgets/trip_type_summary_card.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/helper/price_converter.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';

class RentalCartScreen extends StatefulWidget {
  final bool? fromSelectVehicleScreen;
  const RentalCartScreen({super.key, this.fromSelectVehicleScreen = false});

  @override
  State<RentalCartScreen> createState() => _RentalCartScreenState();
}

class _RentalCartScreenState extends State<RentalCartScreen> {
  final TextEditingController _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Get.find<TaxiCartController>().getCarCartList().then((_) => _loadCartProvider());
  }

  void _loadCartProvider() {
    final TaxiCartController cartController = Get.find<TaxiCartController>();
    if(cartController.cartList.isEmpty) return;

    final int? providerId = cartController.cartList.first.vehicle?.providerId;
    final TaxiVendorController vendorController = Get.find<TaxiVendorController>();
    if(providerId != null && vendorController.taxiVendor?.id != providerId) {
      vendorController.getTaxiVendorDetails(providerId);
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<TaxiCartController>(builder: (taxiCartController) {

      double totalPrice = 0;
      double discountPrice = 0;
      double extraDiscount = 0;

      String? rentalType = taxiCartController.carCartModel?.userData?.rentalType;

      final double estimatedHours = taxiCartController.carCartModel?.userData?.estimatedHours ?? 0;
      double estimatedDay = 0;
      estimatedDay = estimatedHours / 24;

      final ConfigModel? config = Get.find<SplashController>().configModel;
      final double estimatedDistance = taxiCartController.carCartModel?.userData?.distance ?? 0;

      if(taxiCartController.cartList.isNotEmpty && taxiCartController.carCartModel != null && taxiCartController.carCartModel!.userData != null) {
        totalPrice = TaxiPriceHelper.calculateTripCost(taxiCartController.cartList, taxiCartController.carCartModel!.userData!);
        double productDiscountPrice = TaxiPriceHelper.calculateDiscountCost(taxiCartController.cartList, taxiCartController.carCartModel!.userData!, calculateProviderDiscount: false);
        double providerDiscountPrice = TaxiPriceHelper.calculateDiscountCost(taxiCartController.cartList, taxiCartController.carCartModel!.userData!, calculateProviderDiscount: true);

        extraDiscount = TaxiPriceHelper.getExtraDiscountPrice(providerDiscountPrice, productDiscountPrice);
        discountPrice = TaxiPriceHelper.getDiscountPrice(providerDiscountPrice, productDiscountPrice, totalPrice);
      }
      totalPrice = totalPrice - discountPrice;

      final int vehicleCount = taxiCartController.cartList.length;
      final String providerName = vehicleCount > 0 ? (taxiCartController.cartList[0].provider?.name ?? '') : '';
      final cartVehicle = vehicleCount > 0 ? taxiCartController.cartList[0].vehicle : null;

      return Scaffold(
        appBar: CustomAppBar(
          isCart: true, 
          title: vehicleCount > 0 ? '${'cart'.tr} - $providerName' : 'cart'.tr,
          cartSubtitle: vehicleCount > 0 ? '$vehicleCount ${'vehicle_added'.tr}' : null,
          menuWidget: vehicleCount > 0 ? IconButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (con) => AlertDialog(
                  title: Text('are_you_sure'.tr),
                  content: Text('do_you_want_to_clear_cart'.tr),
                  actions: [
                    TextButton(child: Text('no'.tr), onPressed: () => Get.back()),
                    TextButton(child: Text('yes'.tr), onPressed: () {
                      taxiCartController.clearTaxiCart();
                      Get.back();
                    }),
                  ],
                ),
              );
            },
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
          ) : const SizedBox(),
        ),
        body: taxiCartController.cartList.isNotEmpty ? Column(children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                const SizedBox(height: Dimensions.paddingSizeDefault),

                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(Dimensions.radiusLarge)
                  ),
                  padding: EdgeInsets.all(Dimensions.fontSizeSmall),
                  child: Column(children: [
                    GetBuilder<TaxiVendorController>(builder: (vendorController) {
                      return PickUpTimeCard(
                        taxiLocationController: Get.find<TaxiLocationController>(),
                        userData: taxiCartController.carCartModel?.userData,
                        fromCart: true,
                        scheduleAllowed: vendorController.isScheduleAllowed(cartVehicle?.providerId),
                        onTap: () {
                          Get.bottomSheet(
                            const RentalDateTimePickerSheet(fromCart: false),
                            backgroundColor: Colors.transparent, isScrollControlled: true,
                          ).then((date) {
                            if (kDebugMode) {
                              print('======Deleted date is: $date');
                            }
                          });
                        },
                      );
                    }),
                    const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                    const Divider(),
                    const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                    TripTypeSummaryCard(
                      fromCart: true,
                      vehicle: cartVehicle,
                      showTripTypeHourly: cartVehicle?.tripHourly ?? true,
                      showTripTypeDistance: cartVehicle?.tripDistance ?? true,
                      showTripTypeDay: cartVehicle?.tripDayWise ?? true,
                    ),
                  ]),
                ),
                const SizedBox(height: Dimensions.paddingSizeDefault),

                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(Dimensions.radiusLarge)
                  ),
                  padding: EdgeInsets.all(Dimensions.fontSizeSmall),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('address_information'.tr, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeDefault)),
                    const SizedBox(height: Dimensions.paddingSizeSmall),

                    LocationCard(
                      fromAddress: AddressModel(address: taxiCartController.carCartModel?.userData?.pickupLocation?.locationName??'', addressType: taxiCartController.carCartModel?.userData?.pickupLocation?.locationType),
                      toAddress: AddressModel(address: taxiCartController.carCartModel?.userData?.destinationLocation?.locationName??'', addressType:  taxiCartController.carCartModel?.userData?.destinationLocation?.locationType),
                      fromCartOnClick: () {
                        Get.to(()=> TaxiLocationScreen(
                          fromAddress: AddressModel(
                            addressType: taxiCartController.carCartModel!.userData!.pickupLocation!.locationType,
                            address: taxiCartController.carCartModel!.userData!.pickupLocation!.locationName,
                            latitude: taxiCartController.carCartModel!.userData!.pickupLocation!.lat,
                            longitude: taxiCartController.carCartModel!.userData!.pickupLocation!.lng,
                          ),
                          toAddress: AddressModel(
                            addressType: taxiCartController.carCartModel!.userData!.destinationLocation!.locationType,
                            address: taxiCartController.carCartModel!.userData!.destinationLocation!.locationName,
                            latitude: taxiCartController.carCartModel!.userData!.destinationLocation!.lat,
                            longitude: taxiCartController.carCartModel!.userData!.destinationLocation!.lng,
                          ),
                          userData: taxiCartController.carCartModel!.userData,
                        ));
                      },
                    ),
                    const SizedBox(height: Dimensions.paddingSizeLarge),

                    RichText(text: TextSpan(children: [
                      TextSpan(text: 'additional_note'.tr, style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeDefault, color: Theme.of(context).textTheme.bodyLarge!.color)),
                      TextSpan(text: ' (${'optional'.tr})', style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).disabledColor)),
                    ])),
                    const SizedBox(height: Dimensions.paddingSizeSmall),

                    CustomTextField(
                      controller: _noteController,
                      titleText: 'write_your_note'.tr,
                      showTitle: false,
                      showLabelText: false,
                      maxLines: 1,
                      inputType: TextInputType.multiline,
                      inputAction: TextInputAction.done,
                      capitalization: TextCapitalization.sentences,
                    ),
                  ]),
                ),
                
                const SizedBox(height: Dimensions.paddingSizeDefault),

                taxiCartController.cartList.isNotEmpty
                  ? Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: taxiCartController.cartList.length,
                        separatorBuilder: (context, index) => Divider(height: 1, color: Theme.of(context).disabledColor.withValues(alpha: 0.2)),
                        itemBuilder: (context, index) {
                          return RentalCartVehicleCard(
                            vehicle: taxiCartController.cartList[index].vehicle!,
                            index: index, carts: taxiCartController.cartList[index],
                            isCartHourly: taxiCartController.carCartModel?.userData?.rentalType == 'hourly',
                            fromSelectVehicleScreen: widget.fromSelectVehicleScreen,
                          );
                        },
                      ),
                    )
                  : Center(child: Text('cart_is_empty'.tr)),


                const SizedBox(height: Dimensions.paddingSizeDefault),

                Center(
                  child: InkWell(
                    onTap: (){
                      if(taxiCartController.cartList.isNotEmpty) {
                        Get.to(() => ProviderDetailScreen(vendorId: taxiCartController.cartList[0].vehicle!.providerId));
                      } else {
                        Get.back();
                      }
                    },
                    child: Text('add_more_vehicle'.tr, style: robotoBold.copyWith(fontSize: 14, color: Theme.of(context).primaryColor)),
                  ),
                ),
                const SizedBox(height: Dimensions.paddingSizeLarge),
              ]),
            ),
          ),

          ExtraDiscountViewWidget(extraDiscount: extraDiscount),

          Container(
            decoration: BoxDecoration(
              boxShadow: [BoxShadow(color: Theme.of(context).disabledColor.withValues(alpha: 0.2), blurRadius: 10)],
              color: Theme.of(context).cardColor,
            ),
            padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeLarge, vertical: Dimensions.paddingSizeSmall),
            child: Column(children: [

              ProCartBannerWidget(subtotal: totalPrice, redirectRoute: RouteHelper.getRentalCartRoute()),
              const SizedBox(height: Dimensions.paddingSizeSmall),

              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text(
                  '${rentalType == AppConstants.dayWise ? 'duration'.tr : 'estimated'.tr} ${rentalType == AppConstants.distanceWise
                      ? estimatedDistance.toStringAsFixed(3)
                      : rentalType == AppConstants.dayWise ? estimatedDay.toStringAsFixed(0)
                      : estimatedHours.toStringAsFixed(estimatedHours % 1 == 0 ? 0 : 2)}'
                      ' ${rentalType == AppConstants.distanceWise ? (config?.distanceUnitSuffix ?? 'km') : rentalType == AppConstants.dayWise ? 'day'.tr : 'hrs'.tr}',
                    style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeDefault),
                ),
                Text(PriceConverter.convertPrice(totalPrice, forTaxi: true), style: robotoBold.copyWith(fontSize: Dimensions.fontSizeExtraLarge)),
              ]),
              const SizedBox(height: Dimensions.paddingSizeSmall),

              SafeArea(
                child: CustomButton(
                  buttonText: 'proceed_to_checkout'.tr,
                  onPressed: () {
                    taxiCartController.updateFirstTime();
                    Get.to(() => RentalCheckoutScreen(note: _noteController.text));
                  },
                ),
              ),
            ]),
          ),

        ]) : Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const CustomAssetImageWidget(Images.taxiEmptyCart, height: 80),
            const SizedBox(height: Dimensions.paddingSizeSmall),
            Text('your_cart_is_empty'.tr, style: robotoMedium.copyWith(color: Theme.of(context).textTheme.bodyLarge!.color!.withValues(alpha: 0.5))),
            const SizedBox(height: Dimensions.paddingSizeLarge),

            CustomButton(
              buttonText: 'explore_more'.tr,
              width: 200, height: 40,
              onPressed: () {
                Get.toNamed(RouteHelper.getInitialRoute());
              },
            ),

          ]),
        ),
      );
    });
  }

}

// SUMMARY
// Rental cart. Holds the pickup time (editable only when the cart's provider takes
// scheduled trips) and trip type summary, the pickup and destination addresses, an
// optional note, the vehicles in the cart and their discounts, and the estimated
// duration or distance beside the total, leading to rental checkout.
