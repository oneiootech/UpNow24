import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/helper/price_converter.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

class TripCalculationView extends StatefulWidget {
  final double tripCost;
  final double discount;
  final double couponDiscount;
  final double proDiscount;
  final bool isProCoupon;
  final double subTotal;
  final double tax;
  final double total;
  final double serviceFee;
  final bool isCompleted;
  final bool? taxInclude;
  final double? taxPercent;
  final double? walletPay;
  final double? duePay;

  const TripCalculationView({
    super.key, required this.tripCost, required this.discount, required this.couponDiscount, required this.subTotal,
    required this.tax, required this.total, this.isCompleted = false, required this.serviceFee, this.taxInclude,
    this.taxPercent, this.walletPay, this.duePay, this.proDiscount = 0, this.isProCoupon = false,
  });

  @override
  State<TripCalculationView> createState() => _TripCalculationViewState();
}

class _TripCalculationViewState extends State<TripCalculationView> {
  bool _isBillingSummaryExpanded = true;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeLarge, vertical: Dimensions.paddingSizeSmall),
      child: Column(children: [
        // Billing Summary Header
        InkWell(
          onTap: () => setState(() => _isBillingSummaryExpanded = !_isBillingSummaryExpanded),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Row(children: [
              Text('billing_summary'.tr, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge)),
              const SizedBox(width: Dimensions.paddingSizeSmall),
              const Icon(Icons.info, size: 24, color: Colors.indigo),
            ]),
            Container(padding: const EdgeInsets.all(Dimensions.paddingSizeExtraSmall-4),
            decoration: BoxDecoration(color: Theme.of(context).disabledColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(Dimensions.radiusLarge)),
             child: Icon(_isBillingSummaryExpanded ? Icons.expand_less : Icons.expand_more, color: Theme.of(context).disabledColor)),
          ]),
        ),

        // Billing Details (expandable)
        if(_isBillingSummaryExpanded) ...[
          const SizedBox(height: Dimensions.paddingSizeDefault),

          // Trip Cost
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('trip_cost'.tr, style: robotoRegular.copyWith(color: Theme.of(context).disabledColor)),
            Text(PriceConverter.convertPrice(widget.tripCost, forTaxi: true), style: robotoRegular, textDirection: TextDirection.ltr),
          ]),
          const SizedBox(height: Dimensions.paddingSizeSmall),

          // Trip Discount
          if(widget.discount > 0)
            Padding(
              padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('trip_discount'.tr, style: robotoRegular.copyWith(color: Theme.of(context).disabledColor)),
                Text('(-) ${PriceConverter.convertPrice(widget.discount, forTaxi: true)}', style: robotoRegular, textDirection: TextDirection.ltr),
              ]),
            ),

          // Coupon Discount (labelled "Pro Coupon" when it is a pro-customer coupon)
          if(widget.couponDiscount > 0)
            Padding(
              padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text(widget.isProCoupon ? 'coupon_discount_pro'.tr : 'coupon_discount'.tr, style: robotoRegular.copyWith(color: Theme.of(context).disabledColor)),
                Text('(-) ${PriceConverter.convertPrice(widget.couponDiscount, forTaxi: true)}', style: robotoRegular, textDirection: TextDirection.ltr),
              ]),
            ),

          // Pro Discount
          if(widget.proDiscount > 0)
            Padding(
              padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('discount_pro'.tr, style: robotoRegular.copyWith(color: Theme.of(context).disabledColor)),
                Text('(-) ${PriceConverter.convertPrice(widget.proDiscount, forTaxi: true)}', style: robotoRegular, textDirection: TextDirection.ltr),
              ]),
            ),

          // VAT/TAX
          if(widget.tax > 0)
            Padding(
              padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('vat_tax'.tr, style: robotoRegular.copyWith(color: Theme.of(context).disabledColor)),
                Text('(+) ${PriceConverter.convertPrice(widget.tax, forTaxi: true)}', style: robotoRegular, textDirection: TextDirection.ltr),
              ]),
            ),

          // Additional Charges
          if(widget.serviceFee > 0)
            Padding(
              padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Flexible(
                  child: Text(
                    Get.find<SplashController>().configModel!.additionalChargeName ?? 'additional_charges'.tr,
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: robotoRegular.copyWith(color: Theme.of(context).disabledColor),
                  ),
                ),
                Text('(+) ${PriceConverter.convertPrice(widget.serviceFee, forTaxi: true)}', style: robotoRegular, textDirection: TextDirection.ltr),
              ]),
            ),

          Divider(height: 30, thickness: 1, color: Theme.of(context).disabledColor.withAlpha(50)),

          // Total
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('total'.tr, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeDefault)),
            Text(PriceConverter.convertPrice(widget.total, forTaxi: true), style: robotoBold.copyWith(fontSize: Dimensions.fontSizeDefault), textDirection: TextDirection.ltr),
          ]),

          const SizedBox(height: Dimensions.paddingSizeLarge),
        ],
      ]),
    );
  }

  String taxInclude() {
    if(widget.taxInclude == true) {
      return 'inc_vat_tax'.tr;
    } else {
      return 'exc_vat_tax'.tr;
    }
  }
}
