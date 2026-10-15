part of '../rental_vehicle_details_screen.dart';

class _MoreFromProvider extends StatefulWidget {
  const _MoreFromProvider({required this.currentVehicleId});

  final int? currentVehicleId;

  @override
  State<_MoreFromProvider> createState() => _MoreFromProviderState();
}

class _MoreFromProviderState extends State<_MoreFromProvider> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    return GetBuilder<TaxiVendorController>(builder: (vendorController) {
      final List<VehicleModel>? all = vendorController.taxiVendorVehicleList?.vehicles;
      if(all == null) {
        return const TopRatedVehicleShimmerView();
      }
      final List<VehicleModel> others = all
          .where((v) => v.status == 1 && v.id != widget.currentVehicleId)
          .toList();
      if(others.isEmpty) {
        return const SizedBox();
      }
      return Container(
        margin: const EdgeInsets.fromLTRB(Dimensions.paddingSizeDefault, Dimensions.paddingSizeDefault, Dimensions.paddingSizeDefault, 0),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          Padding(
            padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
            child: Row(children: [
              Expanded(child: Text('more_from_the_provider'.tr, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge))),
              _SmallCircleIcon(
                icon: _expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                onTap: () => setState(() => _expanded = !_expanded),
              ),
            ]),
          ),
          const SizedBox(height: Dimensions.paddingSizeExtraSmall),

          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: !_expanded ? const SizedBox(width: double.infinity) : SizedBox(
              height: 300,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: others.length,
                physics: const BouncingScrollPhysics(),
                itemBuilder: (context, index) => Padding(
                  padding: EdgeInsets.only(
                    left: index == 0 ? Dimensions.paddingSizeDefault : 0,
                    right: Dimensions.paddingSizeDefault,
                  ),
                  child: VechicleCardWidget(vehicleModel: others[index]),
                ),
              ),
            ),
          ),
        ]),
      );
    });
  }
}