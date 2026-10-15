import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/models/config_model.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/features/rental_module/rental_cart_screen/domain/models/car_cart_model.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/helper/image_cache_helper.dart';
import 'package:sixam_mart/helper/price_converter.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

class RentalCheckoutVehicleCard extends StatelessWidget {
  final Carts cart;
  final String rentalType;
  const RentalCheckoutVehicleCard({super.key, required this.cart, required this.rentalType});

  @override
  Widget build(BuildContext context) {
    final vehicle = cart.vehicle;
    final double discount = vehicle?.discountPrice ?? 0;
    final String discountType = vehicle?.discountType ?? 'percent';

    final double priceBase = rentalType == 'hourly'
        ? vehicle?.hourlyPrice ?? 0
        : rentalType == 'day_wise'
            ? vehicle?.dayWisePrice ?? 0
            : vehicle?.distancePrice ?? 0;

    final double totalDiscountAmount = PriceConverter.calculation(priceBase, discount, discountType, 1);
    final double finalPrice = discountType == 'amount' ? priceBase : priceBase - totalDiscountAmount;
    final ConfigModel? config = Get.find<SplashController>().configModel;
    final String fareUnit = rentalType == 'hourly' ? 'hr'.tr : rentalType == 'day_wise' ? 'day'.tr : (config?.distanceUnitSuffix ?? 'km');

    return Padding(
      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
      child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [

        ClipRRect(
          borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
          child: CustomImage(
            image: vehicle?.thumbnailFullUrl ?? '',
            width: 70, height: 50, fit: BoxFit.cover,
            cacheHeight: ImageCacheHelper.pixels(context, 50),
            cacheWidth: ImageCacheHelper.pixels(context, 70),
          ),
        ),
        const SizedBox(width: Dimensions.paddingSizeSmall),

        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              vehicle?.name ?? '',
              maxLines: 1, overflow: TextOverflow.ellipsis,
              style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall),
            ),
            const SizedBox(height: 4),
            Row(children: [
              Text(
                PriceConverter.convertPrice(finalPrice, forTaxi: true),
                style: robotoBold.copyWith(fontSize: Dimensions.fontSizeDefault),
              ),
              Text(
                ' /$fareUnit',
                style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall),
              ),
              if (discount > 0 && discountType != 'amount') ...[
                const SizedBox(width: 6),
                Text(
                  PriceConverter.convertPrice(priceBase, forTaxi: true),
                  style: robotoRegular.copyWith(
                    fontSize: Dimensions.fontSizeSmall,
                    color: Theme.of(context).disabledColor,
                    decoration: TextDecoration.lineThrough,
                    decorationColor: Theme.of(context).disabledColor,
                  ),
                ),
              ],
            ]),
          ]),
        ),
        const SizedBox(width: Dimensions.paddingSizeSmall),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall, vertical: 4),
          decoration: BoxDecoration(
            color: Theme.of(context).disabledColor.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
          ),
          child: Text(
            '${'qty'.tr}: ${cart.quantity}',
            style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall),
          ),
        ),
      ]),
    );
  }
}
