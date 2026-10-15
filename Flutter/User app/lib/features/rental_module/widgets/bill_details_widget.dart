import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/rental_module/rental_cart_screen/controllers/taxi_cart_controller.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/helper/price_converter.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

class BillDetailsWidget extends StatelessWidget {
  final double tripCost;
  final double tripDiscountCost;
  final double couponDiscountCost;
  final double subtotal;
  final double vat;
  final double serviceFee;
  final bool isCompleted;
  final bool? taxInclude;
  final double? taxPercent;
  final double proDiscount;
  final String? couponType;
  const BillDetailsWidget({
    super.key, required this.tripCost, required this.tripDiscountCost, required this.couponDiscountCost,
    required this.subtotal, required this.vat, required this.serviceFee, this.isCompleted = false,
    this.taxInclude = false, this.taxPercent = 0, this.proDiscount = 0, this.couponType,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: Dimensions.paddingSizeSmall, crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          !isCompleted ? Text('billing_summary'.tr, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeDefault)) : Padding(
            padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeExtraSmall),
            child: Text('trip_cost_info'.tr, style: robotoBold),
          ),

          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('trip_cost'.tr, style: robotoRegular),
            Text(PriceConverter.convertPrice(tripCost, forTaxi: true), style: robotoRegular, textDirection: TextDirection.ltr),
          ]),

          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('trip_discount'.tr, style: robotoRegular),
            Text('- ${PriceConverter.convertPrice(tripDiscountCost, forTaxi: true)}', style: robotoRegular, textDirection: TextDirection.ltr),
          ]),

          if(couponDiscountCost > 0)
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(couponType == 'pro_customer' ? 'coupon_discount_pro'.tr : 'coupon_discount'.tr, style: robotoRegular),
            Text('- ${PriceConverter.convertPrice(couponDiscountCost, forTaxi: true)}', style: robotoRegular, textDirection: TextDirection.ltr),
          ]),

          const Divider(),

          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('subtotal'.tr, style: robotoBold),
            Text(PriceConverter.convertPrice(subtotal, forTaxi: true), style: robotoRegular, textDirection: TextDirection.ltr),
          ]),

          if(proDiscount > 0)
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('discount_pro'.tr, style: robotoRegular),
            Text('- ${PriceConverter.convertPrice(proDiscount, forTaxi: true)}', style: robotoRegular, textDirection: TextDirection.ltr),
          ]),

          ((Get.find<TaxiCartController>().taxIncluded == null) || taxInclude! || (Get.find<TaxiCartController>().tripTax == 0)) ? const SizedBox() : Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Row(mainAxisSize: MainAxisSize.min, children: [
              Text('vat_tax'.tr, style: robotoRegular),
            ]),

            Text('+ ${PriceConverter.convertPrice(vat, forTaxi: true)}', style: robotoRegular, textDirection: TextDirection.ltr),
          ]),

          if(Get.find<SplashController>().configModel!.additionalChargeStatus!)
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Flexible(child: Text(
              Get.find<SplashController>().configModel!.additionalChargeName!, style: robotoRegular,
              maxLines: 1, overflow: TextOverflow.ellipsis,
            )),
            Text(
              '+ ${PriceConverter.convertPrice(serviceFee, forTaxi: true)}',
              style: robotoRegular, textDirection: TextDirection.ltr,
            ),
          ]),


    ]);
  }
}
