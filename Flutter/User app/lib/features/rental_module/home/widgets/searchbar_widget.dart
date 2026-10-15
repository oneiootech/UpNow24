import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/rental_module/rental_location_screen/rental_location_suggestion_screen.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';


class SearchbarWidget extends StatelessWidget {
  const SearchbarWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final Color borderColor = Theme.of(context).disabledColor.withValues(alpha: 0.18);
    final Color backgroundColor = Theme.of(context).disabledColor.withValues(alpha: 0.15);

    return GestureDetector(
      onTap: ()=> Get.to(()=> const RentalLocationSuggestionScreen()),
      child: Container(
        margin: const EdgeInsets.only(left: 16, right: 16),
        height: 50,
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: Dimensions.paddingSizeDefault,
          vertical: Dimensions.paddingSizeSmall,
        ),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge + Dimensions.radiusDefault),
          border: Border.all(color: borderColor, width: 0.1),
        ),
        child: Row(children: [
          Icon(
            CupertinoIcons.location,
            size: Dimensions.fontSizeLarge,
            color: Theme.of(context).textTheme.bodyLarge!.color,
          ),
          const SizedBox(width: Dimensions.paddingSizeSmall),
          Expanded(
            child: Text(
              'where_to_go'.tr,
              style: robotoBold.copyWith(
                fontSize: Dimensions.fontSizeDefault,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
              maxLines: 1, overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: Dimensions.paddingSizeDefault),
          Icon(
            CupertinoIcons.search,
            size: 20,
            color: Theme.of(context).textTheme.bodyLarge!.color,
          ),
        ]),
      ),
    );
  }
}
