import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/common/widgets/custom_ink_well.dart';
import 'package:sixam_mart/common/widgets/store_verified_avatar.dart';
import 'package:sixam_mart/features/rental_module/vehicle_details_screen/rental_vehicle_details_screen.dart';
import 'package:sixam_mart/features/rental_module/common/widgets/new_tag.dart';
import 'package:sixam_mart/features/rental_module/common/widgets/taxi_add_favourite_view.dart';
import 'package:sixam_mart/features/rental_module/home/domain/models/vehicle_details_model.dart';
import 'package:sixam_mart/features/rental_module/vendor/screens/provider_detail_screen.dart';
import 'package:sixam_mart/features/rental_module/widgets/featured_item.dart';
import 'package:sixam_mart/helper/image_cache_helper.dart';
import 'package:sixam_mart/helper/price_converter.dart';
import 'package:sixam_mart/helper/string_extension.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';

class VechicleCardWidget extends StatefulWidget {
  final VehicleModel vehicleModel;

  const VechicleCardWidget({super.key, required this.vehicleModel});

  @override
  State<VechicleCardWidget> createState() => _VechicleCardWidgetState();
}

class _VechicleCardWidgetState extends State<VechicleCardWidget> {
  bool isInfoExpanded = false;

  @override
  Widget build(BuildContext context) {

    double discount = widget.vehicleModel.discountPrice ?? 0;
    String discountType = widget.vehicleModel.discountType ?? 'percent';
    double startPrice = _startPrice();
    double discountAmount = PriceConverter.calculation(startPrice, discount, discountType, 1);
    double finalPrice = (startPrice - discountAmount).clamp(0, startPrice);

    return Container(
        width: MediaQuery.of(context).size.width * 0.70,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
        ),
        child: CustomInkWell(
          onTap: () => Get.to(() => RentalVehicleDetailsScreen(vehicleId: widget.vehicleModel.id), preventDuplicates: false),
          highlightColor: Colors.transparent,
          radius: Dimensions.radiusLarge,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

            Stack(children: [
              SizedBox(
                width: double.infinity, height: 160,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
                  child: CustomImage(
                    image: widget.vehicleModel.thumbnailFullUrl??'', fit: BoxFit.cover,
                    cacheWidth: ImageCacheHelper.pixels(context, MediaQuery.of(context).size.width * 0.70),
                    cacheHeight: ImageCacheHelper.pixels(context, 160),
                  ),
                ),
              ),

              Positioned(
                left: Dimensions.paddingSizeSmall, bottom: Dimensions.paddingSizeSmall,
                child: NewTag(isNew: widget.vehicleModel.newTag, fromRental: true),
              ),

              if(discount > 0)
                Positioned(
                  left: Dimensions.paddingSizeSmall, top: Dimensions.paddingSizeSmall,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall, vertical: Dimensions.paddingSizeExtraSmall),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.error,
                      borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge),
                    ),
                    child: Text(
                      discountType == 'percent' ? '-${discount.toStringAsFixed(discount % 1 == 0 ? 0 : 1)}%' : '-${PriceConverter.convertPrice(discount, forTaxi: true)}',
                      textDirection: TextDirection.ltr,
                      style: robotoMedium.copyWith(color: Colors.white, fontSize: Dimensions.fontSizeOverSmall),
                    ),
                  ),
                ),

              Positioned(
                right: Dimensions.paddingSizeSmall, top: Dimensions.paddingSizeSmall,
                child: Container(
                  height: 26, width: 26,
                  decoration: BoxDecoration(color: Theme.of(context).cardColor, shape: BoxShape.circle),
                  child: TaxiAddFavouriteView(
                    favIconSize: 18,
                    vehicle: widget.vehicleModel,
                  ),
                ),
              ),

              Positioned(
                bottom: Dimensions.paddingSizeSmall, right: Dimensions.paddingSizeSmall,
                child: (widget.vehicleModel.vehicleIdentitiesCount ?? 0) > 1 ? AnimatedContainer(
                  width: isInfoExpanded ? 125 : 25,
                  padding: const EdgeInsets.all(1),
                  decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(Dimensions.radiusLarge)),
                  duration: const Duration(milliseconds: 600),
                  child: Row(
                    children: [

                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 5),
                          child: Text(
                            '${widget.vehicleModel.vehicleIdentitiesCount!} ${'vehicles_available'.tr}',
                            maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeExtraSmall),
                          ),
                        ),
                      ),

                      InkWell(
                        highlightColor: Colors.transparent,
                        onTap: () {
                          setState(() {
                            isInfoExpanded = !isInfoExpanded;
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(Dimensions.radiusLarge)),
                          child: const Icon(Icons.info, size: 22, color: Color(0xFF8891F5)),
                        ),
                      ),
                    ],
                  ),
                ) : const SizedBox(),
              ),

            ]),
            const SizedBox(height: Dimensions.paddingSizeSmall),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeExtraSmall),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                  Expanded(
                    child: CustomInkWell(
                      onTap: (){
                        Get.to(()=> ProviderDetailScreen(vendorId: widget.vehicleModel.providerId));
                      },
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(children: [
                        StoreVerifiedAvatar(
                          imageUrl: widget.vehicleModel.provider?.logoFullUrl,
                          isVerified: widget.vehicleModel.verifiedSeller == 1,
                          size: 18,
                        ),
                        const SizedBox(width: 4),

                        Flexible(
                          child: Text(
                            '${widget.vehicleModel.provider?.name}',
                            style: robotoRegular.copyWith(color: Theme.of(context).textTheme.bodyLarge!.color!.withValues(alpha: 0.5), fontSize: Dimensions.fontSizeExtraSmall),
                            textAlign: TextAlign.left, maxLines: 1, overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ]),
                    ),
                  ),
                  if((widget.vehicleModel.avgRating ?? 0) > 0)
                    Row(children: [
                      const Icon(Icons.star, color: Colors.amber, size: 18),
                      const SizedBox(width: 2),
                      Text('${widget.vehicleModel.avgRating?.toStringAsFixed(1)}', style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeExtraSmall, color: Theme.of(context).textTheme.bodyLarge!.color!.withValues(alpha: 0.65))),
                    ]),
                ]),

                Text(
                  '${widget.vehicleModel.name}',
                  style: robotoBold.copyWith(fontSize: Dimensions.fontSizeDefault),
                  textAlign: TextAlign.left, maxLines: 1, overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: Dimensions.paddingSizeExtraSmall),

                Text('start_from'.tr, style: robotoRegular.copyWith(color: Theme.of(context).textTheme.bodyLarge!.color!.withValues(alpha: 0.5), fontSize: Dimensions.fontSizeExtraSmall)),
                const SizedBox(height: 2),
                Row(children: [
                  Text(PriceConverter.convertPrice(finalPrice, forTaxi: true), style: robotoBold.copyWith(fontSize: Dimensions.fontSizeDefault)),
                  if(discount > 0) ...[
                    const SizedBox(width: Dimensions.paddingSizeExtraSmall),
                    Text(
                      PriceConverter.convertPrice(startPrice, forTaxi: true),
                      style: robotoRegular.copyWith(color: Theme.of(context).disabledColor, fontSize: Dimensions.fontSizeExtraSmall, decoration: TextDecoration.lineThrough),
                    ),
                  ],
                ]),
                const SizedBox(height: Dimensions.paddingSizeSmall),

                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(mainAxisAlignment: MainAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                    FeatureItem(image: Images.taxiSeatIcon, text: '${widget.vehicleModel.seatingCapacity} ${"seats".tr}'),
                    const SizedBox(width: Dimensions.paddingSizeSmall),

                    FeatureItem(image: Images.taxiACIcon, text: widget.vehicleModel.airCondition! ? 'ac'.tr : 'non_ac'.tr),
                    const SizedBox(width: Dimensions.paddingSizeSmall),

                    FeatureItem(image: Images.taxiAutomaticIcon, text: '${widget.vehicleModel.transmissionType?.toTitleCase() ?? widget.vehicleModel.type?.toTitleCase()}'),
                    if((widget.vehicleModel.vehicleIdentitiesCount ?? 0) > 1) ...[
                      const SizedBox(width: Dimensions.paddingSizeSmall),
                      FeatureItem(icon: Icons.add, text: '${widget.vehicleModel.vehicleIdentitiesCount}'),
                    ],
                  ]),
                ),
              ]),
            ),
          ]),
        )
    );
  }

  double _startPrice() {
    final List<double> prices = [
      widget.vehicleModel.hourlyPrice ?? 0,
      widget.vehicleModel.distancePrice ?? 0,
      widget.vehicleModel.dayWisePrice ?? 0,
    ].where((price) => price > 0).toList();

    if(prices.isEmpty) {
      return 0;
    }
    prices.sort();
    return prices.first;
  }
}
