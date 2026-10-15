import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/rental_module/home/controllers/taxi_home_controller.dart';
import 'package:sixam_mart/features/rental_module/home/screens/taxi_coupon_screen.dart';
import 'package:sixam_mart/features/rental_module/widgets/taxi_shimmer_view.dart';
import 'coupon_card.dart';
import '../common/widgets/headers_title_widget.dart';

class CouponWidget extends StatelessWidget {
  const CouponWidget({super.key});

  /// Whether this section will draw anything — true while the coupons are loading
  /// (shimmer), false once the list came back empty. Mirrors [build] so the screen can
  /// collapse the gap above the section with it.
  static bool hasContent(TaxiHomeController controller) {
    return controller.taxiCouponList == null || controller.taxiCouponList!.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {

    return GetBuilder<TaxiHomeController>(
        builder: (taxiHomeController) {
        return taxiHomeController.taxiCouponList != null ? taxiHomeController.taxiCouponList!.isNotEmpty ? Container(
          color: Theme.of(context).scaffoldBackgroundColor,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: HeadersTitleWidget(
                title: 'coupons'.tr,
                onSeeAllPressed: (){
                  Get.to(()=> const TaxiCouponScreen());
                  },
              ),
            ),

            SizedBox(
              height: 110,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: taxiHomeController.taxiCouponList!.length,
                padding: const EdgeInsets.only(left: 16),
                physics: const BouncingScrollPhysics(),
                itemBuilder: (context, index) {
                  return CouponCard(couponModel: taxiHomeController.taxiCouponList![index]);
                },
              ),
            ),

          ]),
        ) : const SizedBox() : const CouponsWidgetShimmerView();
      }
    );
  }
}
