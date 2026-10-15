part of '../rental_vehicle_details_screen.dart';

class _BottomCartSection extends StatelessWidget {
  const _BottomCartSection({
    required this.vehicle, required this.discount, required this.discountType, required this.totalVehicles, required this.cartQuantity,
    required this.tripTypeChosen, required this.onRequestTripType,
  });
  final VehicleModel vehicle;
  final double discount;
  final String discountType;
  final int totalVehicles;
  final int cartQuantity;
  final bool tripTypeChosen;
  final VoidCallback onRequestTripType;

  @override
  Widget build(BuildContext context) {
    return GetBuilder<TaxiCartController>(builder: (taxiCartController) {
      return GetBuilder<TaxiLocationController>(builder: (locationController) {
        int isExistInCartPosition = taxiCartController.isExistInCart(vehicle.id);
        int quantity = 1;
        int cartId = 0;
        double price = 0;
        double priceWithoutDiscount = 0;
        double discountPrice = 0;
        String? rentalType = taxiCartController.carCartModel?.userData?.rentalType;

        double estimatedDay = 0;
        estimatedDay = (taxiCartController.carCartModel?.userData?.estimatedHours ?? 0) / 24;

        if(isExistInCartPosition != -1) {
          quantity = taxiCartController.getCartQuantity(isExistInCartPosition);
          cartId = taxiCartController.getCartId(isExistInCartPosition)??0;

          double a = rentalType == AppConstants.hourly ? (vehicle.hourlyPrice ?? 0) : rentalType == AppConstants.dayWise ? (vehicle.dayWisePrice ?? 0) : (vehicle.distancePrice ?? 0);
          double b = rentalType == AppConstants.hourly ? taxiCartController.carCartModel!.userData!.estimatedHours! : rentalType == AppConstants.dayWise ? estimatedDay : taxiCartController.carCartModel!.userData!.distance!;
          priceWithoutDiscount = (a * b) * quantity;

          discountPrice = _calculateDiscount(priceWithoutDiscount, discount, discountType, vehicle, quantity);
          price = priceWithoutDiscount - discountPrice;
        }

        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            boxShadow: [BoxShadow(color: Theme.of(context).disabledColor.withValues(alpha: 0.2), blurRadius: 10)],
          ),
          padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeLarge, vertical: Dimensions.paddingSizeSmall),
          child: SafeArea(
            top: false,
            child: Column(children: [

              if(isExistInCartPosition != -1) ...[
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [

                  Text('${rentalType == AppConstants.dayWise ? 'duration'.tr : 'estimated'.tr} (${rentalType == AppConstants.hourly ? '${taxiCartController.carCartModel?.userData?.estimatedHours}${'hr'.tr}' :
                    rentalType == AppConstants.dayWise ? '${estimatedDay.toStringAsFixed(0)} ${'day'.tr}' : '${taxiCartController.carCartModel?.userData?.distance?.toStringAsFixed(3)??0}${'km'.tr}' })',
                    style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeDefault),
                  ),

                  Text(PriceConverter.convertPrice(price, forTaxi: true), style: robotoBold.copyWith(fontSize: Dimensions.fontSizeExtraLarge)),
                ]),
                const SizedBox(height: Dimensions.paddingSizeSmall),
              ],

              Row(children: [

                isExistInCartPosition != -1 ? Expanded(flex: 2, child: Row(children: [
                  QuantityButton(
                    onTap: taxiCartController.isLoading ? null : () {
                      if (quantity > 1) {
                        taxiCartController.setQuantity(true, isExistInCartPosition, count: quantity - 1);
                      } else {
                        taxiCartController.removeFromCart(cartId);
                      }
                    },
                    isIncrement: false,
                    showRemoveIcon: quantity <= 1,
                  ),

                  Text(
                    quantity.toString(),
                    style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeExtraLarge),
                  ),

                  QuantityButton(
                    onTap: taxiCartController.isLoading ? null : () {
                      if(totalVehicles > quantity) {
                        taxiCartController.setQuantity(true, isExistInCartPosition, count: quantity + 1);
                      } else {
                        showCustomSnackBar('${'you_cant_add_more_than'.tr} $totalVehicles ${'quantities_of_this_vehicle'.tr}');
                      }
                    },
                    isIncrement: true,
                    color: taxiCartController.isLoading || quantity >= totalVehicles ? Theme.of(context).disabledColor : null,
                  ),
                ])) : const SizedBox(),
                SizedBox(width: isExistInCartPosition != -1 ? Dimensions.paddingSizeSmall : 0),

                Expanded(flex: 5, child: _buildActionButton(taxiCartController, locationController, isExistInCartPosition, quantity)),

              ]),

            ]),
          ),
        );
      });
    });
  }

  Widget _buildActionButton(TaxiCartController cartController, TaxiLocationController locationController, int isExistInCartPosition, int quantity) {
    final String tripType = locationController.tripType;
    final TextEditingController? estimateCtrl = tripType == AppConstants.hourly
        ? locationController.estimateTimeController
        : tripType == AppConstants.dayWise
            ? locationController.estimateDayController
            : null;

    Widget render() {
      final bool needsTripType = isExistInCartPosition == -1 && !tripTypeChosen;
      final bool estimateMissing = estimateCtrl != null && estimateCtrl.text.trim().isEmpty;
      final bool disabled = isExistInCartPosition == -1 && !needsTripType && estimateMissing;
      return CustomButton(
        buttonText: needsTripType
            ? 'select_trip_type'.tr
            : estimateMissing ? 'choose_required_option'.tr : (isExistInCartPosition != -1 ? 'update_in_cart'.tr : 'rent_this_vehicle'.tr),
        isLoading: cartController.isLoading,
        color: needsTripType ? const Color(0xff93A2AE) : null,
        onPressed: disabled ? null : () {
          if(needsTripType) {
            onRequestTripType();
            return;
          }
          if(isExistInCartPosition != -1) {
            cartController.setQuantity(true, isExistInCartPosition, count: quantity).then((_) {
              Get.toNamed(RouteHelper.getRentalCartRoute());
            });
          } else {
            _addToCart(cartController, vehicle);
          }
        },
      );
    }

    return estimateCtrl != null
        ? ValueListenableBuilder<TextEditingValue>(
            valueListenable: estimateCtrl,
            builder: (_, _, _) => render(),
          )
        : render();
  }

  void _addToCart(TaxiCartController taxiCartController, VehicleModel vehicle) {

    if((taxiCartController.cartList.isEmpty && Get.find<TaxiLocationController>().toAddress == null)) {
      Get.to(()=> RentalLocationSuggestionScreen(vehicle: vehicle));
    }
    else if (taxiCartController.cartList.isNotEmpty) {

      CartLocation pick = CartLocation(lat: taxiCartController.carCartModel!.userData!.pickupLocation!.lat, lng: taxiCartController.carCartModel!.userData!.pickupLocation!.lng, locationName: taxiCartController.carCartModel!.userData!.pickupLocation!.locationName);
      CartLocation destination = CartLocation(lat: taxiCartController.carCartModel!.userData!.destinationLocation!.lat, lng: taxiCartController.carCartModel!.userData!.destinationLocation!.lng, locationName: taxiCartController.carCartModel!.userData!.destinationLocation!.locationName);
      double? estimatedDay = (taxiCartController.carCartModel!.userData!.estimatedHours ?? 0) * 24;

      CarCart cart = CarCart(
        vehicleId: vehicle.id, quantity: 1, pickupLocation: pick, destinationLocation: destination,
        pickupTime: taxiCartController.carCartModel!.userData!.pickupTime,
        rentalType: taxiCartController.carCartModel!.userData!.rentalType, estimatedHour: taxiCartController.carCartModel!.userData!.rentalType == 'day_wise' ? estimatedDay.toStringAsFixed(0) : taxiCartController.carCartModel!.userData!.estimatedHours.toString(),
        destinationTime: taxiCartController.carCartModel!.userData!.destinationTime, distance: taxiCartController.carCartModel!.userData!.distance,
      );

      taxiCartController.decideAddToCart(taxiCartController, cart, vehicle);

    }
    else {

      CartLocation pick = CartLocation(
        lat: Get.find<TaxiLocationController>().fromAddress!.latitude,
        lng: Get.find<TaxiLocationController>().fromAddress!.longitude,
        locationName: Get.find<TaxiLocationController>().fromAddress!.address,
      );
      CartLocation destination = CartLocation(
        lat: Get.find<TaxiLocationController>().toAddress!.latitude,
        lng: Get.find<TaxiLocationController>().toAddress!.longitude,
        locationName: Get.find<TaxiLocationController>().toAddress!.address,
      );

      double? estimatedDay = (double.tryParse(Get.find<TaxiLocationController>().estimateDayController.text) ?? 0) * 24;

      CarCart cart = CarCart(
        vehicleId: vehicle.id, quantity: 1, pickupLocation: pick, destinationLocation: destination,
        pickupTime: DateConverter.formatDate(Get.find<TaxiLocationController>().finalTripDateTime!),
        rentalType: Get.find<TaxiLocationController>().tripType, estimatedHour: Get.find<TaxiLocationController>().tripType == 'day_wise' ? estimatedDay.toStringAsFixed(0) : Get.find<TaxiLocationController>().estimateTimeController.text,
        destinationTime: Get.find<TaxiLocationController>().duration, distance: Get.find<TaxiLocationController>().distance,
      );

      taxiCartController.addToCart(cart);
    }
  }

  double _calculateDiscount(double priceWithoutDiscount, double discount, String discountType, VehicleModel vehicle, int quantity) {
    double discountPrice = 0;
    if(discountType == 'amount') {
      discountPrice = PriceConverter.calculation(priceWithoutDiscount, discount, discountType, quantity);

    } else {
      double pPrice = PriceConverter.convertWithDiscount(priceWithoutDiscount, discount, discountType)!;
      discountPrice = priceWithoutDiscount - pPrice;
    }

    return discountPrice > priceWithoutDiscount ? priceWithoutDiscount : discountPrice;
  }
}
