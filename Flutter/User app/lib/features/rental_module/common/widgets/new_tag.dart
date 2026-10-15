import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

class NewTag extends StatelessWidget {
  final int? isNew;
  final bool? fromRental;
  const NewTag({super.key, required this.isNew, this.fromRental = false});

  @override
  Widget build(BuildContext context) {
    return isNew == 1 ? Container(
      decoration: BoxDecoration(
        color: Colors.orange,
        borderRadius: fromRental == true ? const BorderRadius.all( Radius.circular(Dimensions.radiusDefault)) : const BorderRadius.only(bottomRight: Radius.circular(Dimensions.radiusDefault)),
        // borderRadius: BorderRadius.horizontal(right: Radius.circular(Dimensions.radiusSmall)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall, vertical: 3),
      child: Text('new'.tr, style: robotoMedium.copyWith(color: Colors.white, fontSize: Dimensions.fontSizeExtraSmall)),
    ) : const SizedBox();
  }
}
