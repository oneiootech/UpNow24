part of '../rental_vehicle_details_screen.dart';

class _TripTypeSection extends StatefulWidget {
  const _TripTypeSection({
    required this.vehicle, required this.discountType, required this.hourlyDiscount, required this.distanceWiseDiscount, required this.dayWiseDiscount,
    required this.tripTypeChosen, required this.onSelected, required this.pulseListenable,
  });

  final VehicleModel vehicle;
  final String discountType;
  final double hourlyDiscount;
  final double distanceWiseDiscount;
  final double dayWiseDiscount;
  final bool tripTypeChosen;
  final VoidCallback onSelected;
  final ValueListenable<int> pulseListenable;

  @override
  State<_TripTypeSection> createState() => _TripTypeSectionState();
}

class _TripTypeSectionState extends State<_TripTypeSection> with SingleTickerProviderStateMixin {
  bool _expanded = true;
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
      value: 1.0,
    );
    _pulseAnimation = CurvedAnimation(parent: _pulseController, curve: Curves.easeOutCubic);
    widget.pulseListenable.addListener(_runPulse);
  }

  void _runPulse() {
    if (!mounted) return;
    if (!_expanded) setState(() => _expanded = true);
    _pulseController.forward(from: 0.0);
  }

  @override
  void dispose() {
    widget.pulseListenable.removeListener(_runPulse);
    _pulseController.dispose();
    super.dispose();
  }

  /// The full unit word for the fare line — `mile` when the platform is
  /// configured that way, `kilometre` otherwise. The rate itself is never
  /// converted: the admin enters it against whichever unit is configured, so only
  /// the word beside it changes.
  /// `distance_unit_label` decides, so the word can never disagree with the
  /// suffix shown elsewhere. `units.distance.name` is only a fallback for a unit
  /// this app has no word for.
  String get _distanceUnitName {
    final ConfigModel? config = Get.isRegistered<SplashController>()
        ? Get.find<SplashController>().configModel : null;
    final String label = (config?.distanceUnitLabel ?? config?.distanceUnit?.label ?? 'km').trim().toLowerCase();
    if (label == 'mi') {
      return 'mile'.tr;
    }
    if (label == 'km') {
      return 'kilometre'.tr;
    }
    final String? name = config?.distanceUnit?.name;
    return (name != null && name.trim().isNotEmpty) ? name.trim() : 'kilometre'.tr;
  }

  void _select(TaxiLocationController controller, String type) {
    controller.selectTripType(type);
    widget.onSelected();
  }

  @override
  Widget build(BuildContext context) {
    if(!(widget.vehicle.tripHourly! || widget.vehicle.tripDistance! || widget.vehicle.tripDayWise!)) return const SizedBox();
    return GetBuilder<TaxiLocationController>(builder: (locationController) {
      final String selected = locationController.tripType;
      final bool chosen = widget.tripTypeChosen;
      return AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          final double intensity = (1 - _pulseAnimation.value).clamp(0.0, 1.0);
          return Container(
            margin: const EdgeInsets.fromLTRB(Dimensions.paddingSizeDefault, Dimensions.paddingSizeLarge, Dimensions.paddingSizeDefault, 0),
            padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge),
              border: Border.all(
                color: Theme.of(context).colorScheme.error.withValues(alpha: intensity),
                width: intensity * 2,
                style: intensity > 0.01 ? BorderStyle.solid : BorderStyle.none,
              ),
            ),
            child: child,
          );
        },
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('trip_type'.tr, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge)),
              const SizedBox(height: 2),
              Text('Select any of 1', style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).disabledColor)),
            ])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall, vertical: Dimensions.paddingSizeExtraSmall),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge),
              ),
              child: Text('required'.tr, style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).colorScheme.error)),
            ),
            const SizedBox(width: Dimensions.paddingSizeSmall),
            _SmallCircleIcon(
              icon: _expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              onTap: () => setState(() => _expanded = !_expanded),
            ),
          ]),

          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: _expanded ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const SizedBox(height: Dimensions.paddingSizeLarge),

              if(widget.vehicle.tripHourly!)
                _TripOptionCard(
                  title: 'hourly'.tr,
                  subtitle: '${'fare_per'.tr} ${'hour'.tr}',
                  price: PriceConverter.convertPrice((widget.vehicle.hourlyPrice ?? 0) - widget.hourlyDiscount, forTaxi: true),
                  isSelected: chosen && selected == AppConstants.hourly,
                  showEstimateInput: chosen && selected == AppConstants.hourly,
                  estimateController: locationController.estimateTimeController,
                  estimateHint: 'Ex : 2 hours',
                  onTap: () => _select(locationController, AppConstants.hourly),
                ),

              if(widget.vehicle.tripDayWise!)
                _TripOptionCard(
                  title: 'day_wise'.tr,
                  subtitle: '${'fare_per'.tr} ${'day'.tr}',
                  price: PriceConverter.convertPrice((widget.vehicle.dayWisePrice ?? 0) - widget.dayWiseDiscount, forTaxi: true),
                  isSelected: chosen && selected == AppConstants.dayWise,
                  showEstimateInput: chosen && selected == AppConstants.dayWise,
                  estimateController: locationController.estimateDayController,
                  estimateHint: 'Ex : 2 days',
                  onTap: () => _select(locationController, AppConstants.dayWise),
                ),

              if(widget.vehicle.tripDistance!)
                _TripOptionCard(
                  title: 'distance_wise'.tr,
                  subtitle: '${'fare_per'.tr} $_distanceUnitName',
                  price: PriceConverter.convertPrice((widget.vehicle.distancePrice ?? 0) - widget.distanceWiseDiscount, forTaxi: true),
                  isSelected: chosen && selected == AppConstants.distanceWise,
                  onTap: () => _select(locationController, AppConstants.distanceWise),
                ),
            ]) : const SizedBox(width: double.infinity),
          ),
        ]),
      );
    });
  }
}

class _TripOptionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String price;
  final bool isSelected;
  final bool showEstimateInput;
  final VoidCallback? onTap;
  final TextEditingController? estimateController;
  final String? estimateHint;

  const _TripOptionCard({
    required this.title, required this.subtitle, required this.price, this.isSelected = false, this.showEstimateInput = false,
    this.onTap, this.estimateController, this.estimateHint,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: Dimensions.paddingSizeDefault),
        padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
          border: Border.all(color: isSelected ? Theme.of(context).primaryColor.withValues(alpha: 0.8) : Theme.of(context).disabledColor.withValues(alpha: 0.18)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge)),
              const SizedBox(height: 2),
              Text(subtitle, style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).disabledColor)),
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('start_from'.tr, style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).disabledColor)),
              Text(price, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeDefault)),
            ]),
            const SizedBox(width: Dimensions.paddingSizeDefault),
            Icon(isSelected ? Icons.radio_button_checked : Icons.radio_button_off, color: isSelected ? Theme.of(context).primaryColor : Theme.of(context).disabledColor),
          ]),
          if(showEstimateInput) ...[
            const SizedBox(height: Dimensions.paddingSizeDefault),
            RichText(text: TextSpan(
              text: 'Estimate Trip Time',
              style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeDefault, color: Theme.of(context).textTheme.bodyLarge!.color),
              children: [
                TextSpan(text: ' *', style: robotoMedium.copyWith(color: Theme.of(context).colorScheme.error)),
              ],
            )),
            const SizedBox(height: Dimensions.paddingSizeSmall),
            SizedBox(
              height: 44,
              child: TextField(
                controller: estimateController,
                keyboardType: TextInputType.number,
                style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeDefault),
                decoration: InputDecoration(
                  hintText: estimateHint ?? '',
                  hintStyle: robotoRegular.copyWith(fontSize: Dimensions.fontSizeDefault, color: Theme.of(context).hintColor),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault, vertical: Dimensions.paddingSizeSmall),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                    borderSide: BorderSide(color: Theme.of(context).disabledColor.withValues(alpha: 0.2)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                    borderSide: BorderSide(color: Theme.of(context).disabledColor.withValues(alpha: 0.2)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                    borderSide: BorderSide(color: Theme.of(context).primaryColor.withValues(alpha: 0.6)),
                  ),
                ),
              ),
            ),
          ],
        ]),
      ),
    );
  }
}
