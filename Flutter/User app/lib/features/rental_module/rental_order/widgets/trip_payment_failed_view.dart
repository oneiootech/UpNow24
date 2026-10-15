import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/custom_button.dart';
import 'package:sixam_mart/features/rental_module/common/models/trip_details_model.dart';
import 'package:sixam_mart/features/rental_module/rental_order/controllers/taxi_order_controller.dart';
import 'package:sixam_mart/features/rental_module/rental_order/widgets/taxi_payment_bottom_sheet.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/helper/price_converter.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';

class TripPaymentFailedView extends StatelessWidget {
  final TripDetailsModel tripDetailsModel;
  const TripPaymentFailedView({super.key, required this.tripDetailsModel});

  @override
  Widget build(BuildContext context) {
    final Color errorColor = Theme.of(context).colorScheme.error;
    final double dueAmount = (tripDetailsModel.tripAmount ?? 0) - (tripDetailsModel.partiallyPaidAmount ?? 0);
    final bool isCashPaymentActive = Get.find<SplashController>().configModel?.cashOnDelivery ?? false;

    return GetBuilder<TaxiOrderController>(builder: (taxiOrderController) {
      return SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeLarge),
        child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
          SizedBox(height: context.height * 0.08),

          Image.asset(Images.warning, width: 70, height: 70),
          const SizedBox(height: Dimensions.paddingSizeLarge),

          SelectableText(
            '${'trip'.tr} #${tripDetailsModel.id}',
            style: robotoBold.copyWith(color: Theme.of(context).primaryColor),
          ),
          const SizedBox(height: Dimensions.paddingSizeSmall),

          Text('your_trip_is'.tr, style: robotoMedium),
          const SizedBox(height: Dimensions.paddingSizeSmall),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeLarge, vertical: Dimensions.paddingSizeExtraSmall),
            decoration: BoxDecoration(
              color: errorColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
            ),
            child: Text('${'payment_failed'.tr} !!', style: robotoBold.copyWith(color: errorColor)),
          ),
          const SizedBox(height: Dimensions.paddingSizeExtraLarge),

          Text('due_amount'.tr, style: robotoRegular),
          const SizedBox(height: Dimensions.paddingSizeSmall),

          Text(
            PriceConverter.convertPrice(dueAmount, forTaxi: true),
            style: robotoBold.copyWith(fontSize: Dimensions.fontSizeExtraLarge), textDirection: TextDirection.ltr,
          ),
          const SizedBox(height: Dimensions.paddingSizeExtraLarge),

          Text(
            'please_choose_an_option_from_below_to_continue_with_this_booking'.tr,
            textAlign: TextAlign.center, style: robotoRegular,
          ),
          const SizedBox(height: Dimensions.paddingSizeExtraLarge),

          taxiOrderController.isLoading ? const Center(child: CircularProgressIndicator()) : Column(children: [
            CustomButton(
              width: context.width * 0.7,
              buttonText: 'pay_now'.tr,
              onPressed: () => _openPaymentSheet(context, dueAmount),
            ),

            if(isCashPaymentActive) ...[
              const SizedBox(height: Dimensions.paddingSizeDefault),
              SizedBox(
                width: context.width * 0.7, height: 50,
                child: OutlinedButton(
                  onPressed: () => _switchToCashPayment(taxiOrderController),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Theme.of(context).primaryColor, width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Dimensions.radiusDefault)),
                  ),
                  child: Text('switch_to_cash_on_delivery'.tr, style: robotoBold.copyWith(
                    fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).textTheme.bodyLarge!.color,
                  )),
                ),
              ),
            ],
          ]),

          const SizedBox(height: Dimensions.paddingSizeExtraLarge),
        ]),
      );
    });
  }

  void _openPaymentSheet(BuildContext context, double dueAmount) {
    showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      builder: (BuildContext context) => TaxiPaymentBottomSheet(id: tripDetailsModel.id!, totalPrice: dueAmount),
    ).then((success) {
      // The sheet re-reads the trip itself, so only the dashboard feed is stale.
      if(success != null && success) {
        final TaxiOrderController taxiOrderController = Get.find<TaxiOrderController>();
        taxiOrderController.setFailedPaymentTrip(null);
        taxiOrderController.refreshRunningOrders();
      }
    });
  }

  void _switchToCashPayment(TaxiOrderController taxiOrderController) {
    // `cash_payment` is what `rental/user/trip/payment` expects for cash, and the
    // gateway name stays null so the retry settles without opening a webview.
    taxiOrderController.retryTripPayment(tripId: tripDetailsModel.id!, paymentMethod: 'cash_payment').then((success) {
      if(success) {
        taxiOrderController.setFailedPaymentTrip(null, willUpdate: false);
        taxiOrderController.getTripDetails(tripDetailsModel.id!, willUpdate: false);
        taxiOrderController.refreshRunningOrders();
      }
    });
  }
}

// SUMMARY
// Full-screen view shown on the trip details screen right after a rental trip's
// digital payment comes back failed. Shows the trip id, the due amount and two
// ways to settle it:
// Pay Now, which opens the rental payment sheet (wallet, cash or a gateway), and
// Switch to Cash On Delivery, which pays the trip in cash through the rental
// payment endpoint. Refreshes the trip and the running-orders feed once paid.
