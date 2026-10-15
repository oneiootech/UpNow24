part of '../rental_vehicle_details_screen.dart';

class _VehicleInfoSection extends StatelessWidget {
  const _VehicleInfoSection({required this.vehicle, required this.totalVehicles});

  final VehicleModel vehicle;
  final int totalVehicles;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).cardColor,
      padding: const EdgeInsets.fromLTRB(Dimensions.paddingSizeLarge, Dimensions.paddingSizeLarge, Dimensions.paddingSizeLarge, Dimensions.paddingSizeDefault),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(vehicle.name??'', style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge), maxLines: 2, overflow: TextOverflow.ellipsis),
        const SizedBox(height: Dimensions.paddingSizeExtraSmall),

        Row(children: [
          const Icon(Icons.star, color: Colors.amber, size: 18),
          const SizedBox(width: Dimensions.paddingSizeExtraSmall),
          Text('${vehicle.avgRating?.toStringAsFixed(1) ?? '0.0'} (${vehicle.totalReviews ?? 0}+ ${'reviews'.tr})', style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeDefault, color: Theme.of(context).disabledColor)),
        ]),
        const SizedBox(height: Dimensions.paddingSizeSmall),

        Text(
          vehicle.description??'',
          textAlign: TextAlign.start,
          style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeDefault, color: Theme.of(context).textTheme.bodyLarge!.color!.withValues(alpha: 0.55)),
        ),
        const SizedBox(height: Dimensions.paddingSizeDefault),

        Container(
          width: double.infinity,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall),
          decoration: BoxDecoration(
            color: Colors.blueAccent.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
          ),
          child: Text('$totalVehicles Same vehicles available', style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall)),
        ),
      ]),
    );
  }
}