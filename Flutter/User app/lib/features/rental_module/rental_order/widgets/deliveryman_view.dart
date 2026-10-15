import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/common/widgets/custom_ink_well.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';
import 'package:sixam_mart/features/chat/domain/models/conversation_model.dart';
import 'package:sixam_mart/features/notification/domain/models/notification_body_model.dart';
import 'package:sixam_mart/features/rental_module/common/models/trip_details_model.dart';
import 'package:sixam_mart/helper/auth_helper.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/helper/image_cache_helper.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:url_launcher/url_launcher_string.dart';
class DeliverymanView extends StatelessWidget {
  final List<VehicleIdentity>? vehicleIdentity;
  final int tripId;
  final String? paymentStatus;
  const DeliverymanView({super.key, required this.vehicleIdentity, required this.tripId, this.paymentStatus});

  @override
  Widget build(BuildContext context) {
    List<DriverData> dm = [];
    if(vehicleIdentity != null) {
      for (var d in vehicleIdentity!) {
        if(d.driverData != null) {
          dm.add(d.driverData!);
        }
      }
    }
    return dm.isNotEmpty ? Padding(
      padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall, horizontal: Dimensions.paddingSizeLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            itemCount: dm.length,
              itemBuilder: (context, index) {
            return deliverymanCard(context, dm[index]);
          }),
        ],
      ),
    ) : const SizedBox();
  }

  Widget deliverymanCard(BuildContext context, DriverData data) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall, vertical: Dimensions.paddingSizeSmall),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        color: Theme.of(context).disabledColor.withValues(alpha: 0.08),
      ),
      child: Row(spacing: Dimensions.paddingSizeSmall, children: [
        SizedBox(
          height: 40, width: 40,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(50),
            child: CustomImage(
              image: data.imageFullUrl??'',
              cacheWidth: ImageCacheHelper.pixels(context, 40),
              cacheHeight: ImageCacheHelper.pixels(context, 40),
            ),
          ),
        ),
      
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, spacing: Dimensions.paddingSizeExtraSmall, children: [
      
            Text('${data.firstName} ${data.lastName}', style: robotoBold.copyWith(fontSize: Dimensions.fontSizeDefault), maxLines: 1, overflow: TextOverflow.ellipsis,),
      
            Text(data.phone??'', style: robotoMedium.copyWith(color: Theme.of(context).disabledColor, fontSize: Dimensions.fontSizeSmall)),
      
          ]),
        ),
      
        paymentStatus == 'paid' ? const SizedBox.shrink() : CustomInkWell(
          onTap: () async {
            if(await canLaunchUrlString('tel:${data.phone}')) {
              launchUrlString('tel:${data.phone}', mode: LaunchMode.externalApplication);
            }else {
              showCustomSnackBar('${'can_not_launch'.tr} ${data.phone}');
            }
          },
          child: Image.asset(Images.newCallIcon, height: 20, width: 20),
        ),
        paymentStatus == 'paid' ? const SizedBox.shrink() : const SizedBox(width: Dimensions.paddingSizeExtraSmall),

        paymentStatus == 'paid' ? const SizedBox.shrink() :AuthHelper.isLoggedIn() ? CustomInkWell(
          onTap: () async {
            await Get.toNamed(RouteHelper.getChatRoute(
              notificationBody: NotificationBodyModel(orderId: tripId, deliverymanId: data.id),
              user: User(id: data.id, fName: data.firstName, lName: data.lastName??'', imageFullUrl: data.imageFullUrl),
            ));
          },
          child: Image.asset(Images.chattingIcon, height: 20, width: 20),
        ) : const SizedBox(),
      ]),
    );
  }
}
