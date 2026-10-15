part of 'rental_date_time_picker_sheet.dart';

class TimePickerSpinner extends StatefulWidget {
  final int minutesInterval, secondsInterval;
  final bool is24HourMode, isShowSeconds, isForce2Digits, showAmPmInline;
  final TextStyle? highlightedTextStyle, normalTextStyle;
  final double? itemHeight, itemWidth, spacing;
  final DateTime? time;
  final AlignmentGeometry? alignment;
  final TimePickerCallback? onTimeChange;
  final Function(bool) scrollOff;

  const TimePickerSpinner({super.key,
    this.time, this.minutesInterval = 1, this.secondsInterval = 1, this.is24HourMode = true, this.isShowSeconds = false,
    this.highlightedTextStyle, this.normalTextStyle, this.itemHeight, this.itemWidth, this.alignment, this.spacing,
    this.isForce2Digits = false, this.onTimeChange, required this.scrollOff, this.showAmPmInline = true,
  });

  @override
  TimePickerSpinnerState createState() => TimePickerSpinnerState();
}

class TimePickerSpinnerState extends State<TimePickerSpinner> {
  ScrollController hourController = ScrollController();
  ScrollController minuteController = ScrollController();
  ScrollController secondController = ScrollController();
  ScrollController apController = ScrollController();
  int currentSelectedHourIndex = -1;
  int currentSelectedMinuteIndex = -1;
  int currentSelectedSecondIndex = -1;
  int currentSelectedAPIndex = -1;
  DateTime? currentTime;
  bool isHourScrolling = false;
  bool isMinuteScrolling = false;
  bool isSecondsScrolling = false;
  bool isAPScrolling = false;

  TextStyle defaultHighlightTextStyle = const TextStyle(fontSize: 32, color: Colors.black);
  TextStyle defaultNormalTextStyle = const TextStyle(fontSize: 32, color: Colors.black54);
  double defaultItemHeight = 60;
  double defaultItemWidth = 45;
  double defaultSpacing = 20;
  AlignmentGeometry defaultAlignment = Alignment.centerRight;

  TextStyle? _getHighlightedTextStyle() => widget.highlightedTextStyle ?? defaultHighlightTextStyle;
  TextStyle? _getNormalTextStyle() => widget.normalTextStyle ?? defaultNormalTextStyle;
  int _getHourCount() => widget.is24HourMode ? 24 : 12;
  int _getMinuteCount() => (60 / widget.minutesInterval).floor();
  int _getSecondCount() => (60 / widget.secondsInterval).floor();
  double? _getItemHeight() => widget.itemHeight ?? defaultItemHeight;
  double? _getItemWidth() => widget.itemWidth ?? defaultItemWidth;
  double? _getSpacing() => widget.spacing ?? defaultSpacing;
  AlignmentGeometry? _getAlignment() => widget.alignment ?? defaultAlignment;
  bool isLoop(int value) => value > 10;

  DateTime getDateTime() {
    int hour = currentSelectedHourIndex - _getHourCount();
    if (!widget.is24HourMode && currentSelectedAPIndex == 2) hour += 12;
    int minute = (currentSelectedMinuteIndex - (isLoop(_getMinuteCount()) ? _getMinuteCount() : 1)) * widget.minutesInterval;
    int second = (currentSelectedSecondIndex - (isLoop(_getSecondCount()) ? _getSecondCount() : 1)) * widget.secondsInterval;
    return DateTime(currentTime!.year, currentTime!.month, currentTime!.day, hour, minute, second);
  }

  void setAmPm(int value) {
    setState(() { currentSelectedAPIndex = value; });
    isAPScrolling = false;
    if (widget.onTimeChange != null) {
      widget.onTimeChange!(getDateTime());
    }
  }

  @override
  void initState() {
    currentTime = widget.time ?? DateTime.now();

    currentSelectedHourIndex = (currentTime!.hour % (widget.is24HourMode ? 24 : 12)) + _getHourCount();
    hourController = ScrollController(initialScrollOffset: (currentSelectedHourIndex - 1) * _getItemHeight()!);

    currentSelectedMinuteIndex = (currentTime!.minute / widget.minutesInterval).floor() + (isLoop(_getMinuteCount()) ? _getMinuteCount() : 1);
    minuteController = ScrollController(initialScrollOffset: (currentSelectedMinuteIndex - 1) * _getItemHeight()!);

    currentSelectedSecondIndex = (currentTime!.second / widget.secondsInterval).floor() + (isLoop(_getSecondCount()) ? _getSecondCount() : 1);
    secondController = ScrollController(initialScrollOffset: (currentSelectedSecondIndex - 1) * _getItemHeight()!);

    currentSelectedAPIndex = currentTime!.hour >= 12 ? 2 : 1;
    apController = ScrollController(initialScrollOffset: (currentSelectedAPIndex - 1) * _getItemHeight()!);

    super.initState();
  }

  @override
  void dispose() {
    hourController.dispose();
    minuteController.dispose();
    secondController.dispose();
    apController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> contents = [
      Container(
        padding: const EdgeInsets.symmetric(vertical: 1),
        width: _getItemWidth(),
        height: _getItemHeight()! * 2.9,
        child: spinner(
          hourController, _getHourCount(), currentSelectedHourIndex, isHourScrolling, 1,
          (index) { currentSelectedHourIndex = index; isHourScrolling = true; },
          () => isHourScrolling = false,
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeExtraSmall),
        child: Text(':', style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeLarge)),
      ),
      Container(
        padding: const EdgeInsets.symmetric(vertical: 1),
        width: _getItemWidth(), height: _getItemHeight()! * 2.9,
        child: spinner(
          minuteController, _getMinuteCount(), currentSelectedMinuteIndex, isMinuteScrolling, widget.minutesInterval,
          (index) { currentSelectedMinuteIndex = index; isMinuteScrolling = true; },
          () => isMinuteScrolling = false,
        ),
      ),
    ];

    if (widget.isShowSeconds) {
      contents.add(spacer());
      contents.add(Container(
        decoration: BoxDecoration(
          color: Theme.of(context).disabledColor.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        ),
        padding: const EdgeInsets.symmetric(vertical: 1),
        width: _getItemWidth(),
        height: _getItemHeight()! * 2.9,
        child: spinner(
          secondController, _getSecondCount(), currentSelectedSecondIndex, isSecondsScrolling, widget.secondsInterval,
          (index) { currentSelectedSecondIndex = index; isSecondsScrolling = true; },
          () => isSecondsScrolling = false,
        ),
      ));
    }

    if (!widget.is24HourMode && widget.showAmPmInline) {
      contents.add(const SizedBox(width: Dimensions.paddingSizeSmall));
      contents.add(SizedBox(width: 90, height: 50, child: apSpinner()));
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: contents,
    );
  }

  Widget spacer() {
    return SizedBox(width: _getSpacing(), height: _getItemHeight()! * 3);
  }

  Widget spinner(
      ScrollController controller,
      int max,
      int selectedIndex,
      bool isScrolling,
      int interval,
      SelectedIndexCallback onUpdateSelectedIndex,
      VoidCallback onScrollEnd) {

    Widget spinnerWidget = NotificationListener<ScrollNotification>(
      onNotification: (scrollNotification) {
        if (scrollNotification is UserScrollNotification) {
          if (scrollNotification.direction.toString() == "ScrollDirection.idle") {
            if (isLoop(max)) {
              int segment = (selectedIndex / max).floor();
              if (segment == 0) {
                onUpdateSelectedIndex(selectedIndex + max);
                controller.jumpTo(controller.offset + (max * _getItemHeight()!));
              } else if (segment == 2) {
                onUpdateSelectedIndex(selectedIndex - max);
                controller.jumpTo(controller.offset - (max * _getItemHeight()!));
              }
            }
            setState(() {
              onScrollEnd();
              widget.scrollOff(true);
              if (widget.onTimeChange != null) {
                widget.onTimeChange!(getDateTime());
              }
            });
          }
        } else if (scrollNotification is ScrollUpdateNotification) {
          setState(() {
            widget.scrollOff(false);
            onUpdateSelectedIndex((controller.offset / _getItemHeight()!).round() + 1);
          });
        }
        return true;
      },
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
        child: ListView.builder(
          itemBuilder: (context, index) {
            String text = '';
            if (isLoop(max)) {
              text = ((index % max) * interval).toString();
            } else if (index != 0 && index != max + 1) {
              text = (((index - 1) % max) * interval).toString();
            }
            if (!widget.is24HourMode && controller == hourController && text == '0') {
              text = '12';
            }
            if (widget.isForce2Digits && text != '') {
              text = text.padLeft(2, '0');
            }
            return Container(
              height: _getItemHeight(),
              alignment: _getAlignment(),
              child: Center(
                child: Text(
                  text,
                  style: selectedIndex == index ? _getHighlightedTextStyle() : _getNormalTextStyle(),
                ),
              ),
            );
          },
          controller: controller,
          itemCount: isLoop(max) ? max * 3 : max + 2,
          physics: ItemScrollPhysics(itemHeight: _getItemHeight(), targetPixelsLimit: 0),
          padding: EdgeInsets.zero,
        ),
      ),
    );

    return Stack(
      children: <Widget>[
        Positioned.fill(child: spinnerWidget),
        isScrolling
            ? Positioned.fill(child: Container(color: Colors.black.withValues(alpha: 0)))
            : Container(),
      ],
    );
  }

  Widget apSpinner() {
    bool isAmSelect = currentSelectedAPIndex == 1;
    bool isPmSelect = currentSelectedAPIndex == 2;

    Widget spinnerWidget = NotificationListener<ScrollNotification>(
      onNotification: (scrollNotification) {
        if (scrollNotification is UserScrollNotification) {
          if (scrollNotification.direction.toString() == "ScrollDirection.idle") {
            isAPScrolling = false;
            if (widget.onTimeChange != null) {
              widget.onTimeChange!(getDateTime());
            }
          }
        } else if (scrollNotification is ScrollUpdateNotification) {
          setState(() {
            currentSelectedAPIndex = (apController.offset / _getItemHeight()!).round() + 1;
            isAPScrolling = true;
          });
        }
        return true;
      },
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).disabledColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [

          InkWell(
            onTap: () => setAmPm(1),
            child: Container(
              width: 45, height: 50,
              decoration: BoxDecoration(
                color: isAmSelect ? Theme.of(context).primaryColor : Colors.transparent,
                borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
              ),
              child: Center(
                child: Text('am'.tr, style: robotoBold.copyWith(color: isAmSelect ? Colors.white : Theme.of(context).textTheme.bodyMedium!.color)),
              ),
            ),
          ),

          InkWell(
            onTap: () => setAmPm(2),
            child: Container(
              width: 45, height: 50,
              decoration: BoxDecoration(
                color: isPmSelect ? Theme.of(context).primaryColor : Colors.transparent,
                borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
              ),
              child: Center(
                child: Text('pm'.tr, style: robotoBold.copyWith(color: isPmSelect ? Colors.white : Theme.of(context).textTheme.bodyMedium!.color)),
              ),
            ),
          ),

        ]),
      ),
    );

    return Stack(
      children: <Widget>[
        Positioned.fill(child: spinnerWidget),
        isAPScrolling ? Positioned.fill(child: Container()) : Container(),
      ],
    );
  }
}
