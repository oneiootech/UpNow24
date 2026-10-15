import 'package:sixam_mart/features/rental_module/home/domain/models/taxi_banner_model.dart';
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/common/widgets/custom_ink_well.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';
import 'package:sixam_mart/features/rental_module/home/controllers/taxi_home_controller.dart';
import 'package:sixam_mart/features/rental_module/vendor/screens/provider_detail_screen.dart';
import 'package:sixam_mart/helper/image_cache_helper.dart';
import 'package:sixam_mart/common/widgets/carousel_banner_shimmer.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:url_launcher/url_launcher_string.dart';

class BannerWidget extends StatefulWidget {
  const BannerWidget({super.key});

  /// Whether this section will draw anything — true while the banners are loading
  /// (the shimmer fills the same slot), false once they came back empty. Mirrors
  /// [build] so the screen can drop the gap above the section along with it.
  static bool hasContent(TaxiHomeController controller) {
    return controller.taxiBannerModel == null
        || (controller.taxiBannerModel!.banners ?? const <Banners>[]).isNotEmpty;
  }

  @override
  State<BannerWidget> createState() => _BannerWidgetState();
}

class _BannerWidgetState extends State<BannerWidget> {
  int _currentCarouselIndex = 0;

  @override
  Widget build(BuildContext context) {

    return GetBuilder<TaxiHomeController>(
      builder: (taxiHomeController) {
        return taxiHomeController.taxiBannerModel != null ? taxiHomeController.taxiBannerModel!.banners!.isNotEmpty ? Padding(
          padding: const EdgeInsets.only(top: Dimensions.paddingSizeLarge),
          child: Column(children: [
            CarouselSlider.builder(
              options: CarouselOptions(
                height: MediaQuery.of(context).size.width * 0.8 * 0.45,
                viewportFraction: 0.8,
                autoPlay: true,
                enlargeCenterPage: false,
                disableCenter: true,
                padEnds: false,
                aspectRatio: 16/6,
                autoPlayInterval: const Duration(seconds: 7),
                onPageChanged: (index, reason) {
                  setState(() {
                    _currentCarouselIndex = index;
                  });
                },
              ),
              itemCount: taxiHomeController.taxiBannerModel!.banners!.length,
              itemBuilder: (context, index, _) {
                return Container(
                  margin: const EdgeInsets.only(left: Dimensions.paddingSizeDefault, bottom: 3),
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(Dimensions.radiusLarge)),
                  child: CustomInkWell(
                    onTap: () async {
                      if(taxiHomeController.taxiBannerModel!.banners![index].type == 'default') {
                        String url = taxiHomeController.taxiBannerModel!.banners![index].link ?? '';
                        if (await canLaunchUrlString(url)) {
                          await launchUrlString(url, mode: LaunchMode.externalApplication);
                        } else {
                          showCustomSnackBar('unable_to_found_url'.tr);
                        }
                      } else {
                        Get.to(()=> ProviderDetailScreen(vendorId: taxiHomeController.taxiBannerModel!.banners![index].providerId));
                      }
                    },
                    radius: Dimensions.radiusLarge,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
                      child: LayoutBuilder(builder: (BuildContext context, BoxConstraints constraints) {
                        return CustomImage(image: taxiHomeController.taxiBannerModel!.banners![index].imageFullUrl??'', fit: BoxFit.cover, width: double.infinity,
                          cacheWidth: ImageCacheHelper.pixels(context, constraints.maxWidth),
                          cacheHeight: ImageCacheHelper.pixels(context, constraints.maxHeight),
                        );
                      }),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: Dimensions.paddingSizeSmall),

            Center(
              child: AnimatedSmoothIndicator(
                activeIndex: _currentCarouselIndex,
                count: taxiHomeController.taxiBannerModel!.banners!.length,
                effect: ExpandingDotsEffect(
                  dotHeight: 6, dotWidth: 6, activeDotColor: Theme.of(context).primaryColor,
                  dotColor: Theme.of(context).disabledColor, spacing: 5,
                ),
              ),
            ),

          ]),
        ) : const SizedBox() : const CarouselBannerShimmer(padding: EdgeInsets.only(top: Dimensions.paddingSizeLarge));
      }
    );
  }
}
