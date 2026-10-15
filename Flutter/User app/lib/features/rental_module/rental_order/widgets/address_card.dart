import 'package:flutter/material.dart';
import 'package:sixam_mart/features/rental_module/rental_order/widgets/address_view_section.dart';
import 'package:sixam_mart/util/dimensions.dart';

class AddressCard extends StatelessWidget {
  final String fromAddress;
  final String toAddress;
  final String extraOneAddress;
  final String extraTwoAddress;
  final String entrance;
  const AddressCard({super.key,
    required this.fromAddress, required this.toAddress,
    required this.extraOneAddress, required this.extraTwoAddress, required this.entrance,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault, vertical: Dimensions.paddingSizeExtraSmall),
      child: AddressViewSection(
        fromAddress: fromAddress, toAddress: toAddress,
        extraOneAddress: extraOneAddress, extraTwoAddress: extraTwoAddress,
        entrance: entrance,
        fromOngoing: true,
      ),
    );
  }
}
