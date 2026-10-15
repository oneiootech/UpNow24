import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/custom_divider.dart';
import 'package:sixam_mart/features/language/controllers/language_controller.dart';
import 'package:sixam_mart/features/ride_share_module/ride_location/controllers/search_location_controller.dart';
import 'package:sixam_mart/util/dimensions.dart';

class LocationFromToWidget extends StatelessWidget {
  final bool? defaultPadding;
  final LocationType selectedLocationType;
  final bool? fromLocationSelect;
  final String? extraOneAddress;
  final String? extraTwoAddress;
  const LocationFromToWidget({super.key, this.defaultPadding = true, required this.selectedLocationType, this.fromLocationSelect = false,
    this.extraOneAddress, this.extraTwoAddress});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: defaultPadding! ? const EdgeInsets.fromLTRB(Dimensions.paddingSizeSmall, Dimensions.paddingSizeLarge, 0, 0) : EdgeInsets.zero,
      child: Column(children: [

        Container(
          height: 38, width: 38,
          decoration: BoxDecoration(
            color: (selectedLocationType == LocationType.from && fromLocationSelect!) ? Theme.of(context).primaryColor.withValues(alpha: 0.5) : Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge),
          ),
          padding: const EdgeInsets.all(Dimensions.paddingSizeExtraSmall),
          child: const Icon(Icons.location_on_outlined, size: 16),
        ),

        GetBuilder<SearchLocationController>(
            builder: (srcLocationController) {
              return SizedBox(
                height: 40, width: 10,
                child: CustomDivider(
                  height: 5,
                  dashWidth: .75,
                  axis: Axis.vertical,
                  color: Theme.of(context).disabledColor.withAlpha(120),
                ),
              );
            }
        ),

        Container(
          height: 38, width: 38,
          decoration: BoxDecoration(
            color: (selectedLocationType == LocationType.to && fromLocationSelect!) ? Theme.of(context).primaryColor.withValues(alpha: 0.5) : Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge),
          ),
          padding: const EdgeInsets.all(Dimensions.paddingSizeExtraSmall),
          child: Transform(
            alignment: Alignment.center,
            transform: Get.find<LocalizationController>().isLtr ? Matrix4.rotationY(0) : Matrix4.rotationY(math.pi),
            child: const Icon(CupertinoIcons.location, size: 16),
          ),
        ),
      ]),
    );
  }
}