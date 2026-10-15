import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/rental_module/common/enums/trip_status_enum.dart';
import 'package:sixam_mart/features/rental_module/common/models/trip_details_model.dart';
import 'package:sixam_mart/helper/date_converter.dart';
import 'package:sixam_mart/helper/image_cache_helper.dart';
import 'package:sixam_mart/helper/price_converter.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';
class TripStatusView extends StatelessWidget {
  final TripDetailsModel tripDetailsModel;
  const TripStatusView({super.key, required this.tripDetailsModel});

  @override
  Widget build(BuildContext context) {
    // For pending, confirmed, and ongoing status - show in container with row layout
    if(tripDetailsModel.tripStatus == TripStatusEnum.pending.name ||
       tripDetailsModel.tripStatus == TripStatusEnum.confirmed.name ||
       tripDetailsModel.tripStatus == TripStatusEnum.ongoing.name) {
      return Container(
        padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          Image.asset(
            Images.taxiPending, height: 80, width: 80,
            cacheWidth: ImageCacheHelper.pixels(context, 80),
            cacheHeight: ImageCacheHelper.pixels(context, 80),
          ),
          const SizedBox(width: Dimensions.paddingSizeDefault),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Status Label
              Text(
                tripDetailsModel.tripStatus == TripStatusEnum.pending.name ? 'pending'.tr :
                tripDetailsModel.tripStatus == TripStatusEnum.confirmed.name ? 'confirmed'.tr :
                'on_the_way'.tr,
                style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge),
              ),
              const SizedBox(height: Dimensions.paddingSizeSmall),
              // Status Message
              tripDetailsModel.tripStatus == TripStatusEnum.pending.name ?
                Text('please_wait_for_vendor_confirmation'.tr, style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).disabledColor)) :
              tripDetailsModel.tripStatus == TripStatusEnum.confirmed.name ?
                Text('driver_will_arrive_soon_to_the_pickup_location'.tr, style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).disabledColor)) :
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('you_will_be_reached_your_destination_approximately'.tr, style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).disabledColor)),
                const SizedBox(height: Dimensions.paddingSizeSmall),
                Text(
                  tripDetailsModel.tripType == 'hourly' ?
                  DateConverter.durationFromNow(tripDetailsModel.estimatedTripEndTime!) < 20
                      ? DateConverter.durationFromNow(tripDetailsModel.estimatedTripEndTime!) > 0
                      ? '${DateConverter.durationFromNow(tripDetailsModel.estimatedTripEndTime!) - 5} - ${DateConverter.durationFromNow(tripDetailsModel.estimatedTripEndTime!)}'
                      : '1 - 5 ${'min'.tr}'
                      : DateConverter.dateTimeStringToDateTime(tripDetailsModel.estimatedTripEndTime!)
                  : DateConverter.dateTimeStringToDateTime(tripDetailsModel.estimatedTripEndTime!),
                  style: robotoBold.copyWith(fontSize: Dimensions.fontSizeDefault),
                ),
              ]),
            ]),
          ),
        ]),
      );
    }

    // For completed (unpaid), paid, and payment failed - show original layout
    final bool isCanceled = tripDetailsModel.tripStatus == TripStatusEnum.canceled.apiValue;
    // `apiValue`, not `.name`: the wire format is `payment_failed`, so comparing
    // against the enum identifier never matched and this whole branch fell
    // through to an empty SizedBox.
    final bool isPaymentFailed = tripDetailsModel.tripStatus == TripStatusEnum.paymentFailed.apiValue;
    final bool isCompleted = tripDetailsModel.tripStatus == TripStatusEnum.completed.apiValue;
    final bool isPaid = tripDetailsModel.paymentStatus == 'paid';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeLarge, vertical: Dimensions.paddingSizeDefault),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge),
      ),
      child: Row(children: [
        Container(
          height: 48, width: 48,
          decoration: BoxDecoration(
            // A failed payment is an error state, so it gets the error treatment
            // rather than the neutral disc a completed trip uses — a white tick
            // on light grey read as success, and was barely legible besides.
            color: isCanceled
              ? Colors.red.withValues(alpha: 0.2)
              : isPaymentFailed
                ? Theme.of(context).colorScheme.error.withValues(alpha: 0.2)
                : Theme.of(context).disabledColor.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isCanceled ? Icons.close : isPaymentFailed ? Icons.priority_high_rounded : Icons.check,
            color: isCanceled
              ? Colors.red
              : isPaymentFailed ? Theme.of(context).colorScheme.error : Colors.white,
            size: 32,
            weight: 9,
          ),
        ),
        const SizedBox(width: Dimensions.paddingSizeDefault),
        Expanded(
          child: (isCompleted && !isPaid)
          ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(PriceConverter.convertPrice(tripDetailsModel.tripAmount), style: robotoBold.copyWith(fontSize: Dimensions.fontSizeExtraLarge, color: Theme.of(context).textTheme.bodyLarge!.color)),
              Text(
                'arrived_complete_payment_finish_trip'.tr,
                style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).disabledColor),
                maxLines: 3, overflow: TextOverflow.ellipsis,
              ),
            ])
            : isCompleted && isPaid
              ?  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${tripDetailsModel.tripStatus}'.tr, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeExtraLarge, color: Theme.of(context).textTheme.bodyLarge!.color), textAlign: TextAlign.center,),
                Text(
                  'arrived_destination_pay_message'.tr,
                  style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).disabledColor),
                  maxLines: 3, overflow: TextOverflow.ellipsis,
                ),
              ])
              // Was additionally gated on `paymentStatus == 'unpaid'`; relaxed to
              // "not paid" so the header still renders when the API leaves the
              // field null or sends another unsettled value — the same test
              // `showPayNow` uses on the screen itself.
              : isPaymentFailed && !isPaid ?  Column( crossAxisAlignment: CrossAxisAlignment.start, children: [
                 Text('payment_failed'.tr, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeExtraLarge, color: Theme.of(context).colorScheme.error), textAlign: TextAlign.center,),
                Text(
                  '${'your_payment'.tr} ${'is_failed'.tr}',
                  style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).disabledColor),
                  maxLines: 3, overflow: TextOverflow.ellipsis,
                ),
              ]) : const SizedBox(),
        ),
      ]),
    );
  }
}
