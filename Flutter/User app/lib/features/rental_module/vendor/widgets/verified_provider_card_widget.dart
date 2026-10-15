import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/models/config_model.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/common/widgets/custom_ink_well.dart';
import 'package:sixam_mart/common/widgets/store_verified_avatar.dart';
import 'package:sixam_mart/features/rental_module/common/widgets/new_tag.dart';
import 'package:sixam_mart/features/rental_module/vendor/controllers/verified_provider_controller.dart';
import 'package:sixam_mart/features/rental_module/vendor/domain/models/verified_provider_model.dart';
import 'package:sixam_mart/features/rental_module/vendor/screens/provider_detail_screen.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/helper/image_cache_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

class VerifiedProviderCardWidget extends StatelessWidget {
  final VerifiedProvider provider;
  final double? width;

  const VerifiedProviderCardWidget({super.key, required this.provider, this.width});

  @override
  Widget build(BuildContext context) {
    final double cardWidth = width ?? MediaQuery.of(context).size.width * 0.78;
    final double avg = provider.avgRating();
    final int ratingCount = provider.totalRatingCount();
    final bool hasRating = ratingCount > 0;
    final String? distanceText = _distanceAway(provider);

    final bool hasDiscount = (provider.discount?.discount ?? 0) > 0;
    final String discountLabel = hasDiscount
        ? (provider.discount!.discountType == 'percent'
            ? '-${provider.discount!.discount!.toStringAsFixed(provider.discount!.discount! % 1 == 0 ? 0 : 1)}%'
            : '-${provider.discount!.discount!.toStringAsFixed(0)}')
        : '';

    return Container(
      width: cardWidth,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(Dimensions.radiusLarge)),
      child: CustomInkWell(
        onTap: () => Get.to(() => ProviderDetailScreen(vendorId: provider.id), preventDuplicates: false),
        radius: Dimensions.radiusLarge,
        highlightColor: Colors.transparent,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          Stack(children: [
            SizedBox(
              width: double.infinity, height: 160,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
                child: LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints constraints) {
                    return CustomImage(
                      image: provider.coverPhotoFullUrl ?? '', fit: BoxFit.cover,
                      cacheWidth: ImageCacheHelper.pixels(context, constraints.maxWidth),
                      cacheHeight: ImageCacheHelper.pixels(context, 160),
                    );
                  }
                ),
              ),
            ),

            Positioned(
              right: Dimensions.paddingSizeSmall, top: Dimensions.paddingSizeSmall,
              child: GetBuilder<VerifiedProviderController>(builder: (controller) {
                final bool isFav = controller.isFavourite(provider.id);
                return InkWell(
                  onTap: () => controller.toggleFavourite(provider.id),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    height: 30, width: 30,
                    decoration: BoxDecoration(color: Theme.of(context).cardColor, shape: BoxShape.circle),
                    child: Icon(
                      isFav ? Icons.favorite : Icons.favorite_border,
                      size: 18,
                      color: isFav ? Theme.of(context).colorScheme.error : Theme.of(context).disabledColor,
                    ),
                  ),
                );
              }),
            ),

            if(provider.ad == 1)
              Positioned(
                right: Dimensions.paddingSizeSmall, bottom: Dimensions.paddingSizeSmall,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                  ),
                  child: Text('ad'.tr, style: robotoBold.copyWith(color: Colors.white, fontSize: Dimensions.fontSizeOverSmall)),
                ),
              ),

            if(provider.isNew())
              const Positioned(
                left: Dimensions.paddingSizeSmall, bottom: Dimensions.paddingSizeSmall,
                child: NewTag(isNew: 1, fromRental: true),
              ),
          ]),
          const SizedBox(height: Dimensions.paddingSizeSmall),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeExtraSmall),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

              Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                Expanded(
                  child: Row(children: [
                    StoreVerifiedAvatar(
                      imageUrl: provider.logoFullUrl,
                      isVerified: provider.verifiedSeller == 1,
                      size: 20,
                    ),
                    const SizedBox(width: Dimensions.paddingSizeExtraSmall),

                    Flexible(
                      child: Text(
                        provider.name ?? '',
                        style: robotoBold.copyWith(fontSize: Dimensions.fontSizeDefault),
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ]),
                ),
                if(hasRating) ...[
                  const Icon(Icons.star, color: Colors.amber, size: 16),
                  const SizedBox(width: 2),
                  Text(
                    avg.toStringAsFixed(1),
                    style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeExtraSmall),
                  ),
                  const SizedBox(width: 2),
                  Text(
                    '($ratingCount)',
                    style: robotoRegular.copyWith(
                      fontSize: Dimensions.fontSizeExtraSmall,
                      color: Theme.of(context).disabledColor,
                    ),
                  ),
                ],
              ]),
              const SizedBox(height: 2),

              Text(
                provider.address ?? '',
                style: robotoRegular.copyWith(
                  fontSize: Dimensions.fontSizeSmall,
                  color: Theme.of(context).textTheme.bodyLarge!.color!.withValues(alpha: 0.6),
                ),
                maxLines: 1, overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: Dimensions.paddingSizeSmall),

              Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                if(provider.deliveryTime != null && provider.deliveryTime!.trim().isNotEmpty) ...[
                  Row(children: [
                    Icon(Icons.access_time_filled_outlined, size: 16, color: Theme.of(context).disabledColor),
                    const SizedBox(width: 2),
                    Text(
                      distanceText != null
                          ? '${provider.deliveryTime} ($distanceText)'
                          : '${provider.deliveryTime}',
                      style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeExtraSmall, color: Theme.of(context).disabledColor),
                    ),
                  ]),
                  // const SizedBox(width: Dimensions.paddingSizeSmall),
                ],

                Container(
                  height: 10, width: 1, color: Theme.of(context).disabledColor,
                  margin: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall),
                ),

                if((provider.vehiclesCount ?? 0) > 0)
                  Row(children: [
                    Icon(Icons.directions_car_rounded, size: 16, color: Theme.of(context).disabledColor),
                    const SizedBox(width: 2),
                    Text(
                      '${provider.vehiclesCount} ${'cars'.tr}',
                      style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeExtraSmall, color: Theme.of(context).disabledColor),
                    ),
                  ]),
                  // FeatureItem(
                  //   icon: Icons.directions_car_rounded,
                  //   iconColor: Theme.of(context).primaryColor,
                  //   text: '${provider.vehiclesCount} ${'cars'.tr}',
                  // ),

                if(hasDiscount) ...[
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall, vertical: 3),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.error,
                      borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge),
                    ),
                    child: Text(discountLabel, textDirection: TextDirection.ltr, style: robotoBold.copyWith(color: Colors.white, fontSize: Dimensions.fontSizeOverSmall)),
                  ),
                ],
              ]),
            ]),
          ),
        ]),
      ),
    );
  }

  String get _distanceUnitLabel {
    if (!Get.isRegistered<SplashController>()) {
      return 'km'.tr;
    }
    final ConfigModel? config = Get.find<SplashController>().configModel;
    final String? label = config?.distanceUnitLabel ?? config?.distanceUnit?.label;
    return (label != null && label.isNotEmpty) ? label : 'km'.tr;
  }

  String? _distanceAway(VerifiedProvider provider) {
    final String? label = provider.distanceLabel;
    if (label != null && label.trim().isNotEmpty) {
      return '${label.trim()} ${'away'.tr}';
    }

    final double? distance = provider.distanceKm
        ?? (provider.distance != null ? provider.distance! / 1000 : null);
    if (distance == null || distance <= 0) {
      return null;
    }

    final String text = distance < 10 ? distance.toStringAsFixed(1) : distance.toStringAsFixed(0);
    return '$text $_distanceUnitLabel ${'away'.tr}';
  }
}
