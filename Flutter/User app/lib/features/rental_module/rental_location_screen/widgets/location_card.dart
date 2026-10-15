import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/custom_ink_well.dart';
import 'package:sixam_mart/features/address/domain/models/address_model.dart';
import 'package:sixam_mart/features/language/controllers/language_controller.dart';
import 'package:sixam_mart/features/rental_module/custom/custom_icon.dart';
import 'package:sixam_mart/features/rental_module/custom/custom_vertical_dotted_line.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';

class LocationCard extends StatelessWidget {
  final AddressModel fromAddress;
  final AddressModel toAddress;
  final bool showTitle;
  final String? searchName;
  final Function()? fromCartOnClick;
  const LocationCard({super.key, required this.fromAddress, required this.toAddress, this.showTitle = false, this.searchName, this.fromCartOnClick});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    
      Row(children: [
        Padding(
          padding: EdgeInsets.only(right: Get.find<LocalizationController>().isLtr ? Dimensions.paddingSizeSmall : 0 , left: Get.find<LocalizationController>().isLtr ? 0 : Dimensions.paddingSizeSmall),
          child: const CustomIcon(height: 20, width: 20, icon: CupertinoIcons.placemark),
        ),
    
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('pickup_from'.tr, style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeDefault)),
              
            Text(
              "${fromAddress.addressType != null ? fromAddress.addressType?.tr : ''}${fromAddress.addressType != null ? ': ' : ''}${fromAddress.address}", maxLines: 2, overflow: TextOverflow.ellipsis,
              style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall,/* color: Theme.of(context).disabledColor*/),
            ),
          ]),
        ),

        const SizedBox(width: Dimensions.paddingSizeDefault),
        CustomInkWell(
          onTap: fromCartOnClick ?? () {
            Get.back();
          },
          radius: Dimensions.radiusSmall,
          child: const Padding(
            padding: EdgeInsets.all(3),
            child: Icon(Icons.mode_edit_outlined, size: 24, color: Colors.blue),
          ),
        ),        
      ]),
    
      Padding(
        padding: EdgeInsets.only(left: Get.find<LocalizationController>().isLtr ? Dimensions.paddingSizeDefault : 0, right: Get.find<LocalizationController>().isLtr ? 0 : Dimensions.paddingSizeDefault),
        child: const CustomVerticalDottedLine(dotCount: 6),
      ),
    
      Row(children: [
    
        Padding(
          padding: EdgeInsets.only(right: Get.find<LocalizationController>().isLtr ? Dimensions.paddingSizeSmall : 0 , left: Get.find<LocalizationController>().isLtr ? 0 : Dimensions.paddingSizeSmall),
          child: const CustomIcon(height: 15, width: 15, icon: CupertinoIcons.location, paddingSize: 7),
        ),
    
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('destination_to'.tr, style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeDefault)),
    
            Text(
              toAddress.address ?? '', maxLines: 2, overflow: TextOverflow.ellipsis,
              style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall/*, color: Theme.of(context).disabledColor*/),
            ),
          ]),
        ),
      ]),
    
    ]);
  }
}


