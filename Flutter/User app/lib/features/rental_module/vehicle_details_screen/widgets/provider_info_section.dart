part of '../rental_vehicle_details_screen.dart';

class _ProviderInfoSection extends StatefulWidget {
  const _ProviderInfoSection({required this.vehicle});

  final VehicleModel vehicle;

  @override
  State<_ProviderInfoSection> createState() => _ProviderInfoSectionState();
}

class _ProviderInfoSectionState extends State<_ProviderInfoSection> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final Provider? provider = widget.vehicle.provider;
    final double avgRating = provider?.avgRating ?? 0;
    final int ratingCount = provider?.ratingCount ?? 0;

    return Container(
      margin: const EdgeInsets.fromLTRB(Dimensions.paddingSizeDefault, Dimensions.paddingSizeDefault, Dimensions.paddingSizeDefault, 0),
      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text('provider_info'.tr, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge))),
          _SmallCircleIcon(
            icon: _expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
            onTap: () => setState(() => _expanded = !_expanded),
          ),
        ]),

        AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          alignment: Alignment.topCenter,
          child: !_expanded ? const SizedBox(width: double.infinity) : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SizedBox(height: Dimensions.paddingSizeLarge),

          GetBuilder<TaxiVendorController>(builder: (vendorController) {
            final TaxiVendorModel? vendor = vendorController.taxiVendor;
            final String address = vendor?.address ?? '';
            final String deliveryTime = vendor?.deliveryTime ?? '';
            final int totalVehicles = vendorController.taxiVendorVehicleList?.totalSize ?? 0;

            return InkWell(
              onTap: provider?.id == null ? null : () => Get.to(() => ProviderDetailScreen(vendorId: provider!.id)),
              borderRadius: BorderRadius.circular(Dimensions.radiusDefault),

              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                    child: CustomImage(
                      image: provider?.logoFullUrl ?? '', height: 56, width: 56, fit: BoxFit.cover,
                      cacheWidth: ImageCacheHelper.widthPixels(context, 56),
                    ),
                  ),
                  const SizedBox(width: Dimensions.paddingSizeSmall),

                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(provider?.name ?? '', style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge), maxLines: 1, overflow: TextOverflow.ellipsis),
                    if(address.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(address, style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).disabledColor), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ])),
                ]),
                const SizedBox(height: Dimensions.paddingSizeDefault),

                Container(
                  padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeDefault, horizontal: Dimensions.paddingSizeSmall),
                  decoration: BoxDecoration(
                    color: Theme.of(context).disabledColor.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                  ),
                  child: Row(children: [
                    Expanded(child: _ProviderStatCell(
                      valueWidget: Row(mainAxisAlignment: MainAxisAlignment.center, mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.star, color: Colors.amber, size: 18),
                        const SizedBox(width: 4),
                        Text(avgRating.toStringAsFixed(1), style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge)),
                      ]),
                      label: '$ratingCount+ ${'reviews'.tr}',
                    )),
                    const _ProviderStatDivider(),
                    Expanded(child: _ProviderStatCell(
                      valueWidget: Text('$totalVehicles', style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge)),
                      label: 'total_vehicle'.tr,
                    )),
                    const _ProviderStatDivider(),
                    Expanded(child: _ProviderStatCell(
                      valueWidget: Text(deliveryTime.isNotEmpty ? deliveryTime : '--', style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge)),
                      label: 'arrival_time'.tr,
                    )),
                  ]),
                ),
              ]),
            );
          }),
          ]),
        ),
      ]),
    );
  }
}

class _ProviderStatCell extends StatelessWidget {
  const _ProviderStatCell({required this.valueWidget, required this.label});

  final Widget valueWidget;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      valueWidget,
      const SizedBox(height: Dimensions.paddingSizeExtraSmall),
      Text(label, textAlign: TextAlign.center, style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).disabledColor)),
    ]);
  }
}

class _ProviderStatDivider extends StatelessWidget {
  const _ProviderStatDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36, width: 1,
      color: Theme.of(context).disabledColor.withValues(alpha: 0.25),
    );
  }
}
