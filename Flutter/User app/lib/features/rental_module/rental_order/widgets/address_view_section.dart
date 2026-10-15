import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/rental_module/rental_order/widgets/location_from_to_widget.dart';
import 'package:sixam_mart/features/ride_share_module/ride_location/controllers/search_location_controller.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';
class AddressViewSection extends StatelessWidget {
  final String fromAddress;
  final String toAddress;
  final String extraOneAddress;
  final String extraTwoAddress;
  final Color? bgColor;
  final String entrance;
  final bool? fromOngoing;
  const AddressViewSection({super.key, required this.fromAddress, required this.toAddress, required this.extraOneAddress, required this.extraTwoAddress, this.bgColor, required this.entrance, this.fromOngoing = false});

  @override
  Widget build(BuildContext context) {
    return Column( crossAxisAlignment: CrossAxisAlignment.start, children: [
        fromOngoing == true ? const SizedBox.shrink() : Text("Trip Location", style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge)),
        const SizedBox(height: Dimensions.paddingSizeDefault),
        Row(children: [
          LocationFromToWidget(defaultPadding: false, selectedLocationType: LocationType.to, extraOneAddress: extraOneAddress, extraTwoAddress: extraTwoAddress),
        
          const SizedBox(width: Dimensions.paddingSizeDefault),
        
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.start, children: [
            SizedBox(height: entrance.isNotEmpty ? Dimensions.paddingSizeLarge : 0),
        
            Text(
              "pickup_from".tr, 
              style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).disabledColor),
            ),
            const SizedBox(height: Dimensions.paddingSizeExtraSmall),
            Text(
              fromAddress, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: robotoMedium,
            ),
            const SizedBox(height: Dimensions.paddingSizeDefault),
        
            if(extraOneAddress.isNotEmpty)...[
              Text(
              "stoppage_1".tr, 
              style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).disabledColor),
            ),
              Padding(
                padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeDefault),
                child: Text(
                  '- $extraOneAddress', maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: robotoMedium.copyWith(color: Theme.of(context).disabledColor),
                ),
              ),
            ],
        
            if(extraTwoAddress.isNotEmpty)...[
              Text(
                "stoppage_2".tr, 
                style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).disabledColor),
              ), 
              Padding(
                padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeDefault),
                child: Text(
                  '- $extraTwoAddress', maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: robotoMedium.copyWith(color: Theme.of(context).disabledColor),
                ),
              ),
            ],
        
            SizedBox(height: extraTwoAddress.isEmpty && extraOneAddress.isEmpty ? Dimensions.paddingSizeLarge+6 : Dimensions.paddingSizeDefault),

            Text(
              "destination_to".tr, 
              style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).disabledColor),
            ),
            Text(
              toAddress, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: robotoMedium,
            ),
        
            if(entrance.isNotEmpty)
              Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                SizedBox(height: 25, child: Image.asset(Images.curvedArrow, color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7))),
                const SizedBox(width: Dimensions.paddingSizeSmall),
        
                Flexible(
                  child: Container(
                    transform: Matrix4.translationValues(0, 10, 0),
                    child: Text(entrance, maxLines: 2, overflow: TextOverflow.ellipsis, style: robotoRegular.copyWith(
                        fontSize: Dimensions.fontSizeDefault,
                        color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha:0.4)
                    )),
                  ),
                ),
              ]),
          ])),
        ]),
      ],
    );
  }

}
