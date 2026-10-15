import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/common/widgets/title_widget.dart';
import 'package:sixam_mart/features/rental_module/vendor/controllers/verified_provider_controller.dart';
import 'package:sixam_mart/features/rental_module/home/domain/models/last_trip_model.dart';
import 'package:sixam_mart/helper/date_converter.dart';
import 'package:sixam_mart/helper/image_cache_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

class RentalLastTripsSectionWidget extends StatelessWidget {
  const RentalLastTripsSectionWidget({super.key});

  /// Whether this section will draw anything — true while the trips are still
  /// loading (the shimmer occupies the same slot), false once they came back empty.
  ///
  /// The screen checks this so the gap above the section collapses with it, instead of
  /// leaving a band of empty space where a hidden section used to be. Kept next to
  /// [build] so the two conditions cannot drift apart.
  static bool hasContent(VerifiedProviderController controller) {
    return controller.lastTrips == null || controller.lastTrips!.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<VerifiedProviderController>(
      builder: (controller) {
        final List<LastTripModel> lastTrips = controller.lastTrips ?? [];

        if(lastTrips.isEmpty) {
          return controller.lastTrips == null ? const _RentalLastTripsShimmer() : const SizedBox();
        }

        const double cardWidth = 280;
        return Column(
          children: [
            const SizedBox(height: Dimensions.paddingSizeLarge),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
              child: TitleWidget(title: 'your_last_trips'.tr),
            ),
            const SizedBox(height: Dimensions.paddingSizeSmall),

            SizedBox(
              height: 150,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: lastTrips.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: EdgeInsets.only(
                      left: index == 0 ? Dimensions.paddingSizeDefault : Dimensions.paddingSizeSmall,
                      right: (lastTrips.length == index + 1) ? Dimensions.paddingSizeDefault : 0,
                    ),
                    child: _RentalTripCard(
                      width: cardWidth,
                      trip: lastTrips[index],
                      reorderingTripId: controller.reorderingTripId,
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _RentalTripCard extends StatelessWidget {
  final double width;
  final LastTripModel trip;
  final int? reorderingTripId;

  const _RentalTripCard({
    required this.width, required this.trip, this.reorderingTripId,
  });

  @override
  Widget build(BuildContext context) {
    // Get all vehicle images from trip_details (max 4)
    final List<String> vehicleImages = [];
    for (var detail in trip.tripDetails.take(4)) {
      if (detail.vehicle != null) {
        final thumbUrl = detail.vehicle!.thumbnailFullUrl ?? detail.vehicle!.thumbnail ?? '';
        if (thumbUrl.isNotEmpty) {
          vehicleImages.add(thumbUrl);
        }
      }
    }

    return Container(
      width: width,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        border: Border.all(color: Theme.of(context).disabledColor.withValues(alpha: 0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Company logo and name
            Row(
              children: [
                Container(
                  height: 44,
                  width: 44,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                    color: Theme.of(context).disabledColor.withValues(alpha: 0.1),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                    child: CustomImage(
                      image: trip.provider?.logoFullUrl ?? '',
                      fit: BoxFit.cover,
                      cacheWidth: ImageCacheHelper.pixels(context, 44),
                    ),
                  ),
                ),
                const SizedBox(width: Dimensions.paddingSizeSmall),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        trip.provider?.name ?? 'Company Name',
                        style: robotoMedium.copyWith(
                          fontSize: Dimensions.fontSizeDefault,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Row(
                        children: [
                          Text(
                           DateConverter.formatUtcTime(trip.createdAt!),
                            style: robotoRegular.copyWith(
                              fontSize: Dimensions.fontSizeSmall,
                              color: Theme.of(context).disabledColor,
                            ),
                          ),
                          const SizedBox(width: Dimensions.paddingSizeExtraSmall),
                          Container(width: 1, height: 8, color: Theme.of(context).disabledColor),
                          const SizedBox(width: Dimensions.paddingSizeExtraSmall),
                          Text(
                            '${trip.estimatedHours}hr',
                            style: robotoRegular.copyWith(
                              fontSize: Dimensions.fontSizeSmall,
                              color: Theme.of(context).disabledColor,
                            ),
                          ),
                          
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: Dimensions.paddingSizeDefault),

            // Vehicle images with overlapping circles + Price and Rebook button
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall, vertical: Dimensions.paddingSizeExtraSmall),
                    decoration: BoxDecoration(
                      color: Theme.of(context).disabledColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(Dimensions.radiusDefault)
                    ),
                    child: Row(children: [
                        Expanded(
                          child: SizedBox(
                            height: 36,
                            width: 36 + (vehicleImages.length - 1) * 20,
                            child: Stack(
                              children: List.generate(vehicleImages.length, (index) {
                                return Positioned(
                                  left: index * 20.0,
                                  child: Container(
                                    height: 36,
                                    width: 36,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Theme.of(context).cardColor,
                                        width: 2,
                                      ),
                                    ),
                                    child:  ClipOval(
                                      child: CustomImage(
                                        image: vehicleImages.isNotEmpty ? vehicleImages[index] : '',
                                        fit: BoxFit.cover,
                                        cacheWidth: ImageCacheHelper.pixels(context, 36),
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ),
                          ),
                        ),
                      

                      // Price
                      Text(
                        '\$${trip.tripAmount}',
                        style: robotoBold.copyWith(
                          fontSize: Dimensions.fontSizeLarge,
                        ),
                      ),
                    ]),
                  ),
                ),
                const SizedBox(width: Dimensions.paddingSizeSmall),

                // Refresh button
                InkWell(
                  onTap: reorderingTripId == trip.id ? null : () {
                    Get.find<VerifiedProviderController>().reorderTrip(trip.id);
                  },
                  child: Container(
                    height: 40,
                    width: 40,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                      color: reorderingTripId == trip.id
                        ? Theme.of(context).disabledColor.withValues(alpha: 0.5)
                        : Theme.of(context).primaryColor,
                    ),
                    child: Icon(
                      Icons.refresh,
                      color: Theme.of(context).cardColor,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RentalLastTripsShimmer extends StatelessWidget {
  const _RentalLastTripsShimmer();

  @override
  Widget build(BuildContext context) {
    return Column( crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: Dimensions.paddingSizeLarge),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
          child: Container(
            width: 120,
            height: Dimensions.paddingSizeLarge,
            color: Theme.of(context).disabledColor.withValues(alpha: 0.1),
          ),
        ),
        const SizedBox(height: Dimensions.paddingSizeSmall),
        SizedBox(
          height: 150,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: 3,
            itemBuilder: (context, index) {
              return Padding(
                padding: EdgeInsets.only(
                  left: index == 0 ? Dimensions.paddingSizeDefault : Dimensions.paddingSizeSmall,
                  right: index == 2 ? Dimensions.paddingSizeDefault : 0,
                ),
                child: Container(
                  width: 280,
                  decoration: BoxDecoration(
                    color: Theme.of(context).disabledColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
