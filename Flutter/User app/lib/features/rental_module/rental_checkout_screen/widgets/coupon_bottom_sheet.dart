part of '../rental_checkout_screen.dart';

class _CouponBottomSheet extends StatefulWidget {
  final int? providerId;
  const _CouponBottomSheet({this.providerId});

  @override
  State<_CouponBottomSheet> createState() => _CouponBottomSheetState();
}

class _CouponBottomSheetState extends State<_CouponBottomSheet> {
  @override
  void initState() {
    super.initState();

    Get.find<TaxiHomeController>().getTaxiCouponList(false, customerId: Get.find<ProfileController>().userInfoModel?.id, providerId: widget.providerId, source: DataSourceEnum.client);

  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.5),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(Dimensions.radiusLarge), topRight: Radius.circular(Dimensions.radiusLarge)),
      ),
      padding: const EdgeInsets.only(top: Dimensions.paddingSizeSmall),
      child: Column(children: [
        Container(width: 33, height: 4.0, decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(23.0))),
        const SizedBox(height: Dimensions.paddingSizeDefault),

        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Padding(
            padding: const EdgeInsets.only(left: Dimensions.paddingSizeExtremeLarge),
            child: Text('available_promo'.tr, style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeLarge)),
          ),

          Container(
            padding: const EdgeInsets.only(right: Dimensions.paddingSizeSmall),
            alignment: Alignment.centerRight,
            child: InkWell(
              onTap: () => Get.back(),
              child: Icon(Icons.close, size: Dimensions.fontSizeOverLarge, color: Colors.grey[300]),
            ),
          ),
        ]),
        const SizedBox(height: Dimensions.paddingSizeSmall),

        Expanded(
          child: GetBuilder<TaxiHomeController>(
            builder: (taxiHomeController) {
              return taxiHomeController.taxiCouponList != null ? taxiHomeController.taxiCouponList!.isNotEmpty
                  ? Container(
                color: Theme.of(context).cardColor,
                child: ListView.builder(
                  itemCount: taxiHomeController.taxiCouponList!.length,
                  padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault, vertical: Dimensions.paddingSizeSmall),
                  itemBuilder: (context, index) {
                    final taxiCoupon = taxiHomeController.taxiCouponList![index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
                      child: SizedBox(
                        height: 160,
                        child: InkWell(
                        onTap: () => Get.back(result: taxiCoupon.code ?? ''),
                        child: CouponCardWidget(
                          color: Theme.of(context).disabledColor.withAlpha(100),
                          coupon: coupon_lib.CouponModel(
                            code: taxiCoupon.code,
                            discount: taxiCoupon.discount ?? 0,
                            discountType: taxiCoupon.discountType ?? 'amount',
                            couponType: taxiCoupon.couponType ?? 'default',
                            minPurchase: taxiCoupon.minPurchase ?? 0,
                            maxDiscount: taxiCoupon.maxDiscount ?? 0,
                            startDate: taxiCoupon.startDate ?? DateTime.now().toIso8601String(),
                            expireDate: taxiCoupon.expireDate ?? DateTime.now().toIso8601String(),
                            data: taxiCoupon.data,
                            store: taxiCoupon.store != null
                                ? coupon_lib.Store(id: taxiCoupon.store!.id, name: taxiCoupon.store!.name, verifiedSeller: 0)
                                : null,
                          ),
                          index: index,
                        ),
                      ),
                      ),
                    );
                  }),
              ) : Column(children: [
                Image.asset(Images.noCoupon, height: 70),
                const SizedBox(height: Dimensions.paddingSizeSmall),

                Text('no_promo_available'.tr, style: robotoMedium),
                const SizedBox(height: Dimensions.paddingSizeExtraSmall),
              ]) : const Center(child: CircularProgressIndicator());
            },
          ),
        )
      ]),
    );
  }
}
