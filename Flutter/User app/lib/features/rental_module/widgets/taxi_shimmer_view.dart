import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer_animation/shimmer_animation.dart';
import 'package:sixam_mart/features/rental_module/common/widgets/headers_title_widget.dart';
import 'package:sixam_mart/util/dimensions.dart';

/// Loading state for the "Discover local favourites" rail on the rental home.
///
/// Stands in for the whole section, header included — the real one draws a
/// two-line heading above the rail, and a shimmer that covers only the cards
/// makes that heading appear out of nowhere. The rail is [railHeight], the same
/// figure the loaded section uses, and each tile traces [VechicleCardWidget]:
/// 70% of the screen wide, a 160px image under `radiusLarge` corners, then the
/// provider row, name, "start from", price and feature chips.
///
/// It used to be a 210px rail of bordered 240px cards with a 105px image — a
/// card the app does not have — so the section grew 120px and re-flowed the
/// moment the vehicles arrived.
class TopRatedVehicleShimmerView extends StatelessWidget {

  const TopRatedVehicleShimmerView({super.key});

  /// Kept in step with the `SizedBox(height: 330)` the loaded rail sits in.
  static const double railHeight = 330;

  @override
  Widget build(BuildContext context) {
    final Color bar = Theme.of(context).disabledColor.withValues(alpha: 0.15);

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

      // The heading block, at the padding and rhythm the real one uses.
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
        child: Shimmer(
          duration: const Duration(seconds: 2),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _ShimmerBlock(height: 18, width: 200, color: bar),
            const SizedBox(height: Dimensions.paddingSizeExtraSmall),
            _ShimmerBlock(height: 12, width: 260, color: bar),
          ]),
        ),
      ),
      const SizedBox(height: Dimensions.paddingSizeDefault),

      SizedBox(
        height: railHeight,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: 4,
          padding: const EdgeInsets.only(left: Dimensions.paddingSizeDefault),
          physics: const NeverScrollableScrollPhysics(),
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.only(right: Dimensions.paddingSizeDefault),
              child: _VehicleCardShimmer(bar: bar),
            );
          },
        ),
      ),
    ]);
  }
}

/// One tile of the top-rated rail, tracing [VechicleCardWidget]'s layout.
class _VehicleCardShimmer extends StatelessWidget {
  final Color bar;

  const _VehicleCardShimmer({required this.bar});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      // The real card is `MediaQuery.size.width * 0.70`.
      width: MediaQuery.of(context).size.width * 0.70,
      child: Shimmer(
        duration: const Duration(seconds: 2),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // The thumbnail: full width, 160 high, radiusLarge — no border, since
          // the real card has none.
          Container(
            width: double.infinity, height: 160,
            decoration: BoxDecoration(color: bar, borderRadius: BorderRadius.circular(Dimensions.radiusLarge)),
          ),
          const SizedBox(height: Dimensions.paddingSizeSmall),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeExtraSmall),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

              // Provider row: an 18px avatar beside the provider name.
              Row(children: [
                Container(
                  height: 18, width: 18,
                  decoration: BoxDecoration(color: bar, shape: BoxShape.circle),
                ),
                const SizedBox(width: 4),
                _ShimmerBlock(height: 10, width: 110, color: bar),
              ]),
              const SizedBox(height: 6),

              // Vehicle name.
              _ShimmerBlock(height: 14, width: 170, color: bar),
              const SizedBox(height: Dimensions.paddingSizeExtraSmall),

              // "Start from".
              _ShimmerBlock(height: 9, width: 60, color: bar),
              const SizedBox(height: 2),

              // Price.
              _ShimmerBlock(height: 14, width: 90, color: bar),
              const SizedBox(height: Dimensions.paddingSizeSmall),

              // The three feature chips (seats / AC / transmission).
              Row(children: <Widget>[
                _ShimmerBlock(height: 20, width: 62, color: bar),
                const SizedBox(width: Dimensions.paddingSizeSmall),
                _ShimmerBlock(height: 20, width: 52, color: bar),
                const SizedBox(width: Dimensions.paddingSizeSmall),
                _ShimmerBlock(height: 20, width: 70, color: bar),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }
}

/// A rounded placeholder block.
class _ShimmerBlock extends StatelessWidget {
  final double height;
  final double width;
  final Color color;

  const _ShimmerBlock({required this.height, required this.width, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height, width: width,
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(Dimensions.radiusSmall)),
    );
  }
}

class TopHistoryWidgetShimmerView extends StatelessWidget {

  const TopHistoryWidgetShimmerView({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

      Padding(
        padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
        child: HeadersTitleWidget(title: 'trip_history'.tr,),
      ),
      const SizedBox(height: 10),

      ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 3,
        itemBuilder: (context, index) {
          return Shimmer(
            duration: const Duration(seconds: 2),
            enabled: true,
            child: Container(
              height: 85,
              margin: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall, right: 18, left: 18),
              decoration: BoxDecoration(
                color: Theme.of(context).disabledColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
              ),
              child: Row(children: [
                const SizedBox(width: Dimensions.paddingSizeSmall),

                Container(
                  height: 70, width: 70,
                  decoration: BoxDecoration(
                    color: Theme.of(context).shadowColor,
                    borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                  ),
                ),
                const SizedBox(width: Dimensions.paddingSizeSmall),

                Expanded(
                  flex: 7,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeDefault),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                      Container(
                        width: double.infinity, height: Dimensions.paddingSizeDefault,
                        decoration: BoxDecoration(color: Theme.of(context).shadowColor, borderRadius: BorderRadius.circular(Dimensions.radiusSmall)),
                      ),

                      Container(
                        margin: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeExtraSmall),
                        width: double.infinity, height: 13,
                        decoration: BoxDecoration(color: Theme.of(context).shadowColor, borderRadius: BorderRadius.circular(Dimensions.radiusSmall)),
                      ),

                      Container(
                        width: double.infinity, height: 15,
                        decoration: BoxDecoration(color: Theme.of(context).shadowColor, borderRadius: BorderRadius.circular(Dimensions.radiusSmall)),
                      ),

                    ]),
                  ),
                ),
                const SizedBox(width: Dimensions.paddingSizeSmall),

                Expanded(flex: 1,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 7),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      shape: BoxShape.circle,
                      boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
                    ),
                  ),
                ),
                const SizedBox(width: Dimensions.paddingSizeSmall),],
              ),
            ),
          );
        },
      )]
    ) ;
  }
}

class CouponsWidgetShimmerView extends StatelessWidget {

  const CouponsWidgetShimmerView({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).disabledColor.withValues(alpha: 0.2),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        Padding(padding: const EdgeInsets.symmetric(horizontal: 16),
          child: HeadersTitleWidget(title: 'coupons'.tr, onSeeAllPressed: (){}),
        ),

        SizedBox(
          // Matches the loaded rail's 110; at 90 the section grew 20px on load.
          height: 110,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 3,
            padding: const EdgeInsets.only(bottom: 15, left: 16),
            physics: const NeverScrollableScrollPhysics(),
            itemBuilder: (context, index) {
              return Shimmer(
                duration: const Duration(seconds: 2),
                enabled: true,
                child: Container(
                  margin: const EdgeInsets.only(right: Dimensions.paddingSizeDefault),
                  width: 250,
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                  ),
                  child: Row(children: [

                    Expanded(flex: 12, child: Container(
                      padding: const EdgeInsets.only(left: Dimensions.paddingSizeLarge),
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [

                        Container(
                            margin: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeExtraSmall),
                            width: double.infinity, height: 13,
                            decoration: BoxDecoration(color: Theme.of(context).shadowColor, borderRadius: BorderRadius.circular(Dimensions.radiusSmall)),
                          ),
                          const SizedBox(height: Dimensions.paddingSizeExtraSmall),

                          Container(
                            margin: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeExtraSmall),
                            width: double.infinity, height: 13,
                            decoration: BoxDecoration(color: Theme.of(context).shadowColor, borderRadius: BorderRadius.circular(Dimensions.radiusSmall)),
                          ),
                        ]),
                      )),

                      Expanded(flex: 4,
                        child: Container(
                          height: 25,
                          margin: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeLarge),
                          decoration: BoxDecoration(color: Theme.of(context).shadowColor, borderRadius: BorderRadius.circular(Dimensions.radiusSmall)),
                          ),
                      ),
                  ]),
                ),
              );
            },
          ),
        ),

        ]),
      );
  }
}