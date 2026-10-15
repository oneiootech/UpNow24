import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer_animation/shimmer_animation.dart';
import 'package:sixam_mart/features/rental_module/vendor/controllers/verified_provider_controller.dart';
import 'package:sixam_mart/features/rental_module/vendor/domain/models/verified_provider_model.dart';
import 'package:sixam_mart/features/rental_module/vendor/screens/verified_providers_list_screen.dart';
import 'package:sixam_mart/features/rental_module/vendor/widgets/verified_provider_card_widget.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

class VerifiedProvidersSectionWidget extends StatelessWidget {
  const VerifiedProvidersSectionWidget({super.key});

  static const double _railHeight = 250;

  static bool hasContent(VerifiedProviderController controller) {
    final VerifiedProviderResponse? response = controller.verifiedProviderResponse;
    return response == null || (response.stores ?? const <VerifiedProvider>[]).isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<VerifiedProviderController>(builder: (controller) {
      final VerifiedProviderResponse? response = controller.verifiedProviderResponse;

      if (response == null) {
        return const _VerifiedProvidersShimmer();
      }
      final List<VerifiedProvider> providers = response.stores ?? [];
      if (providers.isEmpty) {
        return const SizedBox();
      }

      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
          child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('verified_providers'.tr, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge)),
                const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                Text(
                  'trust_secure_buying_experience'.tr,
                  style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).hintColor),
                ),
              ]),
            ),

            InkWell(
              onTap: () => Get.to(() => const VerifiedProvidersListScreen()),
              child: Row(children: [
                Text(
                  'see_more'.tr,
                  style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall, color: Colors.blueAccent),
                ),
                Icon(Icons.chevron_right_rounded, size: 18, color: Theme.of(context).textTheme.bodyLarge!.color),
              ]),
            ),
          ]),
        ),
        const SizedBox(height: Dimensions.paddingSizeDefault),

        SizedBox(
          height: VerifiedProvidersSectionWidget._railHeight,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: providers.length,
            padding: const EdgeInsets.only(left: Dimensions.paddingSizeDefault),
            physics: const BouncingScrollPhysics(),
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(right: Dimensions.paddingSizeDefault),
                child: VerifiedProviderCardWidget(provider: providers[index]),
              );
            },
          ),
        ),
      ]);
    });
  }
}

class _VerifiedProvidersShimmer extends StatelessWidget {
  const _VerifiedProvidersShimmer();

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

      Padding(
        padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
        child: Shimmer(
          duration: const Duration(seconds: 2),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              height: 16, width: 160,
              decoration: BoxDecoration(color: Theme.of(context).shadowColor, borderRadius: BorderRadius.circular(Dimensions.radiusSmall)),
            ),
            const SizedBox(height: Dimensions.paddingSizeExtraSmall),
            Container(
              height: 12, width: 220,
              decoration: BoxDecoration(color: Theme.of(context).shadowColor, borderRadius: BorderRadius.circular(Dimensions.radiusSmall)),
            ),
          ]),
        ),
      ),
      const SizedBox(height: Dimensions.paddingSizeDefault),

      SizedBox(
        height: VerifiedProvidersSectionWidget._railHeight,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: 4,
          padding: const EdgeInsets.only(left: Dimensions.paddingSizeDefault),
          physics: const BouncingScrollPhysics(),
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.only(right: Dimensions.paddingSizeDefault),
              child: Shimmer(
                duration: const Duration(seconds: 2),
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.78,
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(Dimensions.radiusLarge)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Container(
                      width: double.infinity, height: 160,
                      decoration: BoxDecoration(color: Theme.of(context).shadowColor, borderRadius: BorderRadius.circular(Dimensions.radiusLarge)),
                    ),
                    const SizedBox(height: Dimensions.paddingSizeSmall),
                    Container(
                      width: 180, height: 14,
                      decoration: BoxDecoration(color: Theme.of(context).shadowColor, borderRadius: BorderRadius.circular(Dimensions.radiusSmall)),
                    ),
                    const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                    Container(
                      width: 120, height: 12,
                      decoration: BoxDecoration(color: Theme.of(context).shadowColor, borderRadius: BorderRadius.circular(Dimensions.radiusSmall)),
                    ),
                    const SizedBox(height: Dimensions.paddingSizeSmall),
                    Container(
                      width: 200, height: 22,
                      decoration: BoxDecoration(color: Theme.of(context).shadowColor, borderRadius: BorderRadius.circular(Dimensions.radiusSmall)),
                    ),
                  ]),
                ),
              ),
            );
          },
        ),
      ),
    ]);
  }
}
