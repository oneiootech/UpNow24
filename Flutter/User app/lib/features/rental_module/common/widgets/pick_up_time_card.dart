
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/custom_ink_well.dart';
import 'package:sixam_mart/features/rental_module/rental_cart_screen/domain/models/car_cart_model.dart';
import 'package:sixam_mart/features/rental_module/rental_location_screen/controller/taxi_location_controller.dart';
import 'package:sixam_mart/helper/date_converter.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

class PickUpTimeCard extends StatelessWidget {
  final TaxiLocationController taxiLocationController;
  final UserData? userData;
  final bool fromCart;
  final Function? onTap;
  final Widget? icon;
  // Default true keeps callers that have no provider in hand on the original behavior.
  final bool scheduleAllowed;
  const PickUpTimeCard({super.key,
    required this.taxiLocationController, this.userData, this.fromCart = false, this.onTap, this.icon,
    this.scheduleAllowed = true,
  });

  @override
  Widget build(BuildContext context) {
    return GetBuilder<TaxiLocationController>(
      builder: (controller) {
        final bool hasPickedTime = controller.finalTripDateTime != null;

        final String titleLabel = hasPickedTime
            ? (DateConverter.isSameDate(controller.finalTripDateTime!) || controller.pickCurrentTime
                ? 'pickup_now'.tr
                : 'custom'.tr)
            : 'pick_time'.tr;

        final String dateLabel = fromCart
            ? (hasPickedTime
                ? DateConverter.taxiDateTimeToString(controller.finalTripDateTime!)
                : userData?.pickupTime != null
                    ? DateConverter.dateTimeStringToDateTime(userData!.pickupTime!)
                    : 'not_set_yet'.tr)
            : (userData != null
                ? DateConverter.dateTimeStringToDateTime(userData!.pickupTime!)
                : hasPickedTime
                    ? DateConverter.taxiDateTimeToString(controller.finalTripDateTime!)
                    : 'not_set_yet'.tr);

        return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (!fromCart) ...[
            icon ?? const SizedBox.shrink(),
            const SizedBox(width: Dimensions.paddingSizeDefault),
          ],

          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(titleLabel, style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeDefault)),
              const SizedBox(height: Dimensions.paddingSizeExtraSmall),
              Text(dateLabel, style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall)),
            ]),
          ),

          if (scheduleAllowed) CustomInkWell(
            onTap: onTap,
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

// SUMMARY
// Pickup time row for the rental flows. Shows whether the trip starts now or at a
// custom time along with that date and time, and opens the caller's date-time picker
// unless the provider does not take scheduled trips.
