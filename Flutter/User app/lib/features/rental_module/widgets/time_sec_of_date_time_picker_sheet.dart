part of 'rental_date_time_picker_sheet.dart';

class _TimeSecOfDateTimePickerSheet extends StatefulWidget {
  final DateTime? selectTripTime;
  final Function(DateTime) callback;
  final Function(bool) scrollOff;
  const _TimeSecOfDateTimePickerSheet({this.selectTripTime, required this.callback, required this.scrollOff});

  @override
  State<_TimeSecOfDateTimePickerSheet> createState() => _TimeSecOfDateTimePickerSheetState();
}

class _TimeSecOfDateTimePickerSheetState extends State<_TimeSecOfDateTimePickerSheet> {
  final GlobalKey<TimePickerSpinnerState> _spinnerKey = GlobalKey<TimePickerSpinnerState>();

  @override
  void initState() {
    super.initState();
    Get.find<TaxiLocationController>().setTripDate(widget.selectTripTime ?? DateTime.now(), willUpdate: false);
    Get.find<TaxiLocationController>().setTripTime(widget.selectTripTime ?? DateTime.now(), willUpdate: false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text('prefarable_time'.tr, style: robotoRegular),

      // Time spinner — HH:MM (+ seconds when isShowSeconds is true)
      TimePickerSpinner(
        key: _spinnerKey,
        time: widget.selectTripTime,
        is24HourMode: false,
        showAmPmInline: false,
        normalTextStyle: robotoBold.copyWith(color: Theme.of(context).textTheme.bodyLarge!.color!.withValues(alpha: 0.5), fontSize: Dimensions.fontSizeSmall),
        highlightedTextStyle: robotoMedium.copyWith(fontSize: Dimensions.fontSizeLarge * 1, color: Theme.of(context).textTheme.bodyLarge!.color),
        spacing: Dimensions.paddingSizeDefault,
        itemHeight: Dimensions.fontSizeLarge + 2,
        itemWidth: 25,
        alignment: Alignment.topCenter,
        isForce2Digits: true,
        onTimeChange: widget.callback,
        scrollOff: widget.scrollOff,
      ),

      // AM/PM
      SizedBox(
        width: 90, height: 50,
        child: _spinnerKey.currentState?.apSpinner(),
      ),
    ]);
  }
}

class ItemScrollPhysics extends ScrollPhysics {
  final double? itemHeight;
  final double targetPixelsLimit;

  const ItemScrollPhysics({
    super.parent,
    this.itemHeight,
    this.targetPixelsLimit = 3.0,
  }) : assert(itemHeight != null && itemHeight > 0);

  @override
  ItemScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return ItemScrollPhysics(parent: buildParent(ancestor), itemHeight: itemHeight);
  }

  double _getItem(ScrollPosition position) {
    double maxScrollItem = (position.maxScrollExtent / itemHeight!).floorToDouble();
    return min(max(0, position.pixels / itemHeight!), maxScrollItem);
  }

  double _getPixels(ScrollPosition position, double item) {
    return item * itemHeight!;
  }

  double _getTargetPixels(ScrollPosition position, Tolerance tolerance, double velocity) {
    double item = _getItem(position);
    if (velocity < -tolerance.velocity) {
      item -= targetPixelsLimit;
    } else if (velocity > tolerance.velocity) {
      item += targetPixelsLimit;
    }
    return _getPixels(position, item.roundToDouble());
  }

  @override
  Simulation? createBallisticSimulation(ScrollMetrics position, double velocity) {
    Tolerance tolerance = const Tolerance();
    final double target = _getTargetPixels(position as ScrollPosition, tolerance, velocity);
    if (target != position.pixels) {
      return ScrollSpringSimulation(spring, position.pixels, target, velocity, tolerance: tolerance);
    }
    return null;
  }

  @override
  bool get allowImplicitScrolling => false;
}

typedef SelectedIndexCallback = void Function(int);
typedef TimePickerCallback = void Function(DateTime);