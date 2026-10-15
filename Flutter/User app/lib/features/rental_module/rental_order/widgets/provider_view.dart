import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/common/widgets/custom_ink_well.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';
import 'package:sixam_mart/features/chat/domain/models/conversation_model.dart';
import 'package:sixam_mart/features/notification/domain/models/notification_body_model.dart';
import 'package:sixam_mart/features/rental_module/common/models/trip_details_model.dart';
import 'package:sixam_mart/features/rental_module/vendor/screens/provider_detail_screen.dart';
import 'package:sixam_mart/helper/auth_helper.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/helper/image_cache_helper.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:url_launcher/url_launcher_string.dart';
class ProviderView extends StatelessWidget {
  final Provider provider;
  final int tripId;
  const ProviderView({super.key, required this.provider, required this.tripId});

  @override
  Widget build(BuildContext context) {
    return CustomInkWell(
      onTap: ()=> Get.to(()=> ProviderDetailScreen(vendorId: provider.id)),
      child: Container(
         padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall, vertical: Dimensions.paddingSizeSmall),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: Theme.of(context).disabledColor.withValues(alpha: 0.08),
          ),
        child: Row(spacing: Dimensions.paddingSizeSmall, children: [
            
          SizedBox(
            height: 42, width: 42,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(50),
              // 42x42 logo — see deliveryman_view: bound the decode, one axis only.
              child: CustomImage(image: provider.logoFullUrl??'', cacheWidth: ImageCacheHelper.pixels(context, 42)),
            ),
          ),
            
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, spacing: Dimensions.paddingSizeExtraSmall, children: [
              Row(
                children: [
                  Flexible(child: Text('${provider.name}', style: robotoBold.copyWith(fontSize: Dimensions.fontSizeDefault), maxLines: 1, overflow: TextOverflow.ellipsis,)),
                  const SizedBox(width: Dimensions.paddingSizeExtraSmall),
                  provider.verifiedSeller == 1 ? Image.asset(Images.verifiedBadge, width: 16, height: 16) : const SizedBox.shrink(),
                ],
              ),
              Row(children: [
                const Icon(Icons.star, color: Colors.orange, size: 18,),
                Text('${provider.avgRating?.toStringAsFixed(1)}', style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall)),
                Text('(${provider.ratingCount}+)', style: robotoRegular.copyWith(color: Theme.of(context).disabledColor, fontSize: Dimensions.fontSizeSmall)),
              ]),
            ]),
          ),

          CustomInkWell(
            onTap: () async {
              if(await canLaunchUrlString('tel:${provider.phone}')) {
                launchUrlString('tel:${provider.phone}', mode: LaunchMode.externalApplication);
              }else {
                showCustomSnackBar('${'can_not_launch'.tr} ${provider.phone}');
              }
              },
            child: Image.asset(Images.newCallIcon, height: 20, width: 20),
          ),
          const SizedBox(width: Dimensions.paddingSizeExtraSmall),
            
          provider.chat! && AuthHelper.isLoggedIn() ? CustomInkWell(
            onTap: () async {
              await Get.toNamed(RouteHelper.getChatRoute(
                notificationBody: NotificationBodyModel(orderId: tripId, restaurantId: provider.id),
                user: User(id: provider.id, fName: provider.name, lName: '', imageFullUrl: provider.logoFullUrl),
              ));
            },
            child: Image.asset(Images.chattingIcon, height: 20, width: 20),
          ) : const SizedBox(),
        ]),
      ),
    );
  }
}
