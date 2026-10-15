part of '../rental_checkout_screen.dart';

class _RentalCouponCard extends StatelessWidget {
  final TaxiCartController taxiCartController;
  final TextEditingController couponTextController;
  final double subtotal;
  final int providerId;
  final String rentalType;
  final String scheduleTime;
  final bool isScheduled;

  const _RentalCouponCard({
    required this.taxiCartController, required this.couponTextController, required this.subtotal, required this.providerId, required this.rentalType,
    required this.scheduleTime, required this.isScheduled,
  });

  void _openSheet(BuildContext context) {
    Get.bottomSheet(
      _CouponBottomSheet(providerId: providerId),
      backgroundColor: Colors.transparent, isScrollControlled: true,
    ).then((val) {
      if (val != null) {
        couponTextController.text = val;
        taxiCartController.applyTaxiCoupon(val, subtotal, providerId).then((discount) {
          if ((discount ?? 0) > 0) {
            taxiCartController.getTripTax(
              tripAmount: subtotal, tripType: rentalType, providerId: providerId,
              couponCode: val, scheduleTime: scheduleTime, isSchedule: isScheduled,
            );
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool applied = taxiCartController.couponDiscount > 0;

    return Column(children: [
      Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
          border: Border.all(color: Theme.of(context).disabledColor.withValues(alpha: 0.2)),
        ),
        padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          InkWell(
            onTap: taxiCartController.isCouponLoading ? null : () => _openSheet(context),
            borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeExtraSmall),
              child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('add_voucher'.tr, style: robotoBold),
                    const SizedBox(height: 2),
                    Text(
                      'to_save_more_use_available_coupons'.tr,
                      style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).disabledColor),
                    ),
                  ]),
                ),
                if (taxiCartController.isCouponLoading)
                  const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                else
                  Icon(
                    applied ? Icons.edit_outlined : Icons.add,
                    size: applied ? 18 : 22,
                    color: applied ? Theme.of(context).primaryColor : Theme.of(context).textTheme.bodyLarge?.color,
                  ),
              ]),
            ),
          ),

          if (applied && !taxiCartController.isCouponLoading) ...[
            const SizedBox(height: Dimensions.paddingSizeDefault),
            _RentalAppliedVoucherBox(
              code: taxiCartController.couponCode,
              discount: taxiCartController.couponDiscount,
              onCancel: () {
                couponTextController.text = '';
                taxiCartController.removeCoupon(willUpdate: false);
                // Re-fetch the trip tax without the coupon so VAT updates on removal
                // (the checkout's isFirstTime block recomputes it on the next rebuild).
                taxiCartController.updateFirstTime();
              },
            ),
          ],

        ]),
      ),
      const SizedBox(height: Dimensions.paddingSizeLarge),
    ]);
  }
}

class _RentalAppliedVoucherBox extends StatelessWidget {
  final String code;
  final double discount;
  final VoidCallback onCancel;

  const _RentalAppliedVoucherBox({required this.code, required this.discount, required this.onCancel});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _TicketShapePainter(
        backgroundColor: Theme.of(context).disabledColor.withValues(alpha: 0.08),
        dashColor: Theme.of(context).disabledColor.withValues(alpha: 0.5),
        cornerRadius: Dimensions.radiusDefault,
        notchRadius: 8,
        notchYRatio: 0.5,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault, vertical: Dimensions.paddingSizeSmall),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, mainAxisSize: MainAxisSize.min, children: [

          Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            Expanded(
              child: Text(
                code,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: robotoBold.copyWith(fontSize: Dimensions.fontSizeDefault),
              ),
            ),
            const SizedBox(width: Dimensions.paddingSizeSmall),
            Text(
              '${PriceConverter.convertPrice(discount)} ${'off'.tr}',
              style: robotoBold.copyWith(fontSize: Dimensions.fontSizeDefault),
            ),
          ]),

          const SizedBox(height: Dimensions.paddingSizeDefault + 5),

          Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            Expanded(
              child: Text(
                'voucher_applied'.tr,
                style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).disabledColor),
              ),
            ),
            const SizedBox(width: Dimensions.paddingSizeSmall),
            InkWell(
              onTap: onCancel,
              borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
              child: Container(
                margin: const EdgeInsets.only(top: 6),
                padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault, vertical: Dimensions.paddingSizeExtraSmall+2),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.error,
                  borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                ),
                child: Text('cancel'.tr, style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall, color: Colors.white)),
              ),
            ),
          ]),

        ]),
      ),
    );
  }
}

class _TicketShapePainter extends CustomPainter {
  final Color backgroundColor;
  final Color dashColor;
  final double cornerRadius;
  final double notchRadius;
  final double notchYRatio;

  _TicketShapePainter({
    required this.backgroundColor, required this.dashColor, required this.cornerRadius,
    required this.notchRadius, required this.notchYRatio,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double r = cornerRadius;
    final double n = notchRadius;
    final double ny = size.height * notchYRatio;

    final Path path = Path()
      ..moveTo(r, 0)
      ..lineTo(size.width - r, 0)
      ..arcToPoint(Offset(size.width, r), radius: Radius.circular(r))
      ..lineTo(size.width, ny - n)
      ..arcToPoint(Offset(size.width, ny + n), radius: Radius.circular(n), clockwise: false)
      ..lineTo(size.width, size.height - r)
      ..arcToPoint(Offset(size.width - r, size.height), radius: Radius.circular(r))
      ..lineTo(r, size.height)
      ..arcToPoint(Offset(0, size.height - r), radius: Radius.circular(r))
      ..lineTo(0, ny + n)
      ..arcToPoint(Offset(0, ny - n), radius: Radius.circular(n), clockwise: false)
      ..lineTo(0, r)
      ..arcToPoint(Offset(r, 0), radius: Radius.circular(r))
      ..close();

    canvas.drawPath(path, Paint()..color = backgroundColor..style = PaintingStyle.fill);

    const double dashWidth = 6;
    const double dashGap = 8;
    final Paint dashPaint = Paint()
      ..color = dashColor
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round;
    double x = n + 4;
    final double end = size.width - n - 4;
    while (x < end) {
      canvas.drawLine(Offset(x, ny), Offset(x + dashWidth, ny), dashPaint);
      x += dashWidth + dashGap;
    }
  }

  @override
  bool shouldRepaint(covariant _TicketShapePainter old) {
    return old.backgroundColor != backgroundColor
        || old.dashColor != dashColor
        || old.cornerRadius != cornerRadius
        || old.notchRadius != notchRadius
        || old.notchYRatio != notchYRatio;
  }
}
