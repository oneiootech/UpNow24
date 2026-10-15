
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/models/config_model.dart';
import 'package:sixam_mart/common/widgets/custom_ink_well.dart';
import 'package:sixam_mart/features/rental_module/custom/custom_icon.dart';
import 'package:sixam_mart/features/rental_module/widgets/trip_type_picker_sheet.dart';
import 'package:sixam_mart/features/rental_module/home/domain/models/vehicle_details_model.dart';
import 'package:sixam_mart/features/rental_module/rental_location_screen/controller/taxi_location_controller.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/helper/price_converter.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

class TripTypeSummaryCard extends StatelessWidget {
  final VehicleModel? vehicle;
  final bool showTripTypeHourly;
  final bool showTripTypeDistance;
  final bool showTripTypeDay;
  final double hourlyDiscount;
  final double distanceWiseDiscount;
  final double dayWiseDiscount;
  final String discountType;
  final bool fromCart;

  const TripTypeSummaryCard({super.key,
    this.vehicle, this.showTripTypeHourly = true, this.showTripTypeDistance = true, this.showTripTypeDay = true,
    this.hourlyDiscount = 0, this.distanceWiseDiscount = 0, this.dayWiseDiscount = 0,
    this.discountType = 'percent', this.fromCart = false,
  });

  String _tripTitle(String tripType) {
    switch (tripType) {
      case 'hourly': return 'hourly_trip'.tr;
      case 'day_wise': return 'day_wise'.tr;
      default: return 'distance_wise'.tr;
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

  String _fareType(String tripType) {
    switch (tripType) {
      case 'hourly': return 'hr'.tr;
      case 'day_wise': return 'day'.tr;
      default: return _distanceUnitLabel;
    }
  }

  String _displayPrice(String tripType) {
    if (vehicle == null) return '';
    switch (tripType) {
      case 'hourly':
        return discountType == 'amount'
            ? PriceConverter.convertPrice(vehicle!.hourlyPrice!)
            : PriceConverter.convertPrice(vehicle!.hourlyPrice! - hourlyDiscount);
      case 'day_wise':
        return discountType == 'amount'
            ? PriceConverter.convertPrice(vehicle!.dayWisePrice!)
            : PriceConverter.convertPrice(vehicle!.dayWisePrice! - dayWiseDiscount);
      default:
        return discountType == 'amount'
            ? PriceConverter.convertPrice(vehicle!.distancePrice!)
            : PriceConverter.convertPrice(vehicle!.distancePrice! - distanceWiseDiscount);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<TaxiLocationController>(
      builder: (taxiLocationController) {
        return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (!fromCart) ...[
            const CustomIcon(height: 32, width: 32, icon: Icons.directions_car_outlined),
            const SizedBox(width: Dimensions.paddingSizeDefault),
          ],

          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_tripTitle(taxiLocationController.tripType),
                  style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeDefault)),
              const SizedBox(height: Dimensions.paddingSizeExtraSmall),
              if (fromCart)
                Text('rent_type'.tr,
                    style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).disabledColor))
              else ...[
                Text('click_edit_to_change_your_trip_type'.tr,
                    style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).disabledColor)),
                if (vehicle != null) ...[
                  const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                  RichText(text: TextSpan(children: [
                    TextSpan(text: '${'start_from'.tr}  ',
                        style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).textTheme.bodyLarge!.color)),
                    TextSpan(text: _displayPrice(taxiLocationController.tripType),
                        style: robotoBold.copyWith(fontSize: Dimensions.fontSizeDefault, color: Theme.of(context).textTheme.bodyLarge!.color)),
                    TextSpan(text: ' / ${_fareType(taxiLocationController.tripType)}',
                        style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).textTheme.bodyLarge!.color)),
                  ])),
                ],
              ],
            ]),
          ),

          CustomInkWell(
            onTap: () {
              Get.bottomSheet(
                TripTypePickerSheet(
                  vehicle: vehicle,
                  showTripTypeHourly: showTripTypeHourly,
                  showTripTypeDistance: showTripTypeDistance,
                  showTripTypeDay: showTripTypeDay,
                  hourlyDiscount: hourlyDiscount,
                  distanceWiseDiscount: distanceWiseDiscount,
                  dayWiseDiscount: dayWiseDiscount,
                  discountType: discountType,
                  fromCart: fromCart,
                ),
                backgroundColor: Colors.transparent,
                isScrollControlled: true,
              );
            },
            radius: Dimensions.radiusSmall,
            child: Padding(
              padding: const EdgeInsets.all(3),
              child: Icon(
                fromCart ? Icons.mode_edit_outline_outlined : Icons.keyboard_arrow_down,
                size: 24,
                color: fromCart ? Colors.blue : Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
          ),
        ]);
      },
    );
  }
}
