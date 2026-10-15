import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/custom_button.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';
import 'package:sixam_mart/features/rental_module/custom/custom_icon.dart';
import 'package:sixam_mart/features/rental_module/rental_cart_screen/controllers/taxi_cart_controller.dart';
import 'package:sixam_mart/features/rental_module/rental_cart_screen/domain/models/car_cart.dart';
import 'package:sixam_mart/features/rental_module/rental_cart_screen/domain/models/car_cart_model.dart';
import 'package:sixam_mart/features/rental_module/rental_location_screen/controller/taxi_location_controller.dart';
import 'package:sixam_mart/helper/date_converter.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';

part 'time_picker_spanner.dart';
part 'time_sec_of_date_time_picker_sheet.dart';

class RentalDateTimePickerSheet extends StatefulWidget {
  final bool? fromCart;
  final UserData? userData;
  const RentalDateTimePickerSheet({super.key, this.fromCart, this.userData});

  @override
  State<RentalDateTimePickerSheet> createState() => _RentalDateTimePickerSheetState();
}

class _RentalDateTimePickerSheetState extends State<RentalDateTimePickerSheet> {

  DateTime? selectTripDate;
  DateTime? selectTripTime;
  bool canUpdate = true;

  @override
  void initState() {
    super.initState();
    selectTripDate = widget.userData != null ? DateConverter.dateTimeStringToDate(widget.userData!.pickupTime!) : Get.find<TaxiLocationController>().selectedTripDate;
    selectTripTime = widget.userData != null ? DateConverter.dateTimeStringToDate(widget.userData!.pickupTime!) : Get.find<TaxiLocationController>().selectedTripTime;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(Dimensions.radiusLarge), topRight: Radius.circular(Dimensions.radiusLarge)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeLarge),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 8),

        Align(
          alignment: Alignment.topRight,
          child: GestureDetector(
            onTap: () => Get.back(),
            child: CustomIcon(icon: Icons.close, height: 24, width: 24, color: Colors.grey[500]),
          ),
        ),

        Text('set_date_and_time'.tr, style: robotoBlack.copyWith(fontSize: Dimensions.fontSizeDefault)),
        Text('choose_your_preferable_date_time_or_instant_delivery'.tr, style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).disabledColor)),
        const SizedBox(height: 16),

        Container(
          height: 320,
          padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
            border: Border.all(color: Theme.of(context).disabledColor.withValues(alpha: 0.2), width: 1),
          ),
          child: SfDateRangePicker(
            backgroundColor: Theme.of(context).cardColor,
            selectionMode: DateRangePickerSelectionMode.single,
            initialSelectedDate: selectTripDate ?? DateTime.now(),
            // Hide the built-in selection layer — the selected look is drawn by _DateCell (with radius + margin).
            selectionColor: Colors.transparent,

            showNavigationArrow: true,
            navigationDirection: DateRangePickerNavigationDirection.horizontal,
            navigationMode: DateRangePickerNavigationMode.snap,
            headerHeight: 56,
            headerStyle: DateRangePickerHeaderStyle(
              backgroundColor: Colors.transparent,
              textAlign: TextAlign.center,
              textStyle: robotoMedium.copyWith(fontSize: Dimensions.fontSizeLarge, color: Theme.of(context).textTheme.bodyLarge?.color),
            ),

            monthViewSettings: DateRangePickerMonthViewSettings(
              firstDayOfWeek: 1,
              dayFormat: 'EEEEE',
              viewHeaderHeight: 44,
              viewHeaderStyle: DateRangePickerViewHeaderStyle(
                backgroundColor: Colors.transparent,
                textStyle: robotoRegular.copyWith(fontSize: Dimensions.fontSizeDefault, color: Theme.of(context).disabledColor),
              ),
            ),

            // Custom cell rendering so we can add a gap (margin) between dates.
            cellBuilder: (BuildContext context, DateRangePickerCellDetails details) {
              final DateTime midDate = details.visibleDates[details.visibleDates.length ~/ 2];
              if (details.date.month != midDate.month) {
                return const SizedBox();
              }
              final DateTime now = DateTime.now();
              final bool isDisabled = !details.date.isAfter(DateTime(now.year, now.month, now.day - 1));
              final bool isToday = details.date.year == now.year && details.date.month == now.month && details.date.day == now.day;
              final bool isSelected = selectTripDate != null && details.date.year == selectTripDate!.year
                  && details.date.month == selectTripDate!.month && details.date.day == selectTripDate!.day;
              return _DateCell(date: details.date, isSelected: isSelected, isDisabled: isDisabled, isToday: isToday);
            },

            onSelectionChanged: (DateRangePickerSelectionChangedArgs args) {
              DateTime selectedDate = DateConverter.dateTimeStringToDate(args.value.toString());
              setState(() { selectTripDate = selectedDate; });
            },
            selectableDayPredicate: (DateTime val) {
              return val.isAfter(DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day - 1));
            },
          ),
        ),

        Container(
          margin: const EdgeInsets.only(top: Dimensions.paddingSizeSmall),
          padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
          height: 90,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(5),
            border: Border.all(color: Colors.grey.shade100, width: 1),
          ),
          alignment: Alignment.center,
          child: _TimeSecOfDateTimePickerSheet(
            selectTripTime: selectTripTime,
            callback: (DateTime time) {
              setState(() { selectTripTime = time; });
            },
            scrollOff: (status) {
              setState(() { canUpdate = status; });
            },
          ),
        ),
        const SizedBox(height: Dimensions.paddingSizeDefault),

        SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeLarge),
            child: GetBuilder<TaxiCartController>(
              builder: (taxiCartController) {
                return !taxiCartController.isLoading ? Row(children: [
                  TextButton(
                    onPressed: () {
                      Get.find<TaxiLocationController>().setTripTime(DateTime.now());
                      Get.find<TaxiLocationController>().setTripDate(DateTime.now());
                      Get.find<TaxiLocationController>().setFinalTripDateTime(DateTime.now());
                      Get.find<TaxiLocationController>().takeCurrentTime(true);
                      if(widget.fromCart != null) {
                        _updateUserData(Get.find<TaxiLocationController>().finalTripDateTime!);
                      } else {
                        Get.back();
                      }
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: Theme.of(context).disabledColor.withAlpha(80),
                      surfaceTintColor: Theme.of(context).textTheme.bodyLarge?.color,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                    ),
                    child: Text(
                      'pickup_now'.tr,
                      style: robotoBold.copyWith(fontSize: Dimensions.fontSizeDefault, color: Theme.of(context).textTheme.bodyMedium!.color),
                    ),
                  ),
                  const Spacer(),

                  TextButton(
                    onPressed: () => Get.back(),
                    child: Text('cancel'.tr, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeDefault, color: Theme.of(context).textTheme.bodyLarge!.color)),
                  ),
                  const SizedBox(width: 9),

                  CustomButton(
                    buttonText: 'save'.tr,
                    height: 40, width: 80, radius: 5,
                    onPressed: canUpdate ? () {
                      Get.find<TaxiLocationController>().setTripDate(selectTripDate);
                      Get.find<TaxiLocationController>().setTripTime(selectTripTime);
                      DateTime date = DateConverter.formattingTripDateTime(
                        Get.find<TaxiLocationController>().selectedTripTime!,
                        Get.find<TaxiLocationController>().selectedTripDate!,
                      );
                      if(DateConverter.isAfterCurrentDateTime(date)) {
                        Get.find<TaxiLocationController>().takeCurrentTime(DateConverter.isSameDate(date));
                        if(widget.fromCart != null && widget.userData != null) {
                          _updateUserData(date);
                        } else {
                          Get.find<TaxiLocationController>().setFinalTripDateTime(date);
                          Get.back();
                        }
                      } else {
                        showCustomSnackBar('you_cannot_select_before_current_time'.tr, getXSnackBar: true);
                      }
                      date = date;
                    } : null,
                  ),

                ]) : const Center(child: CircularProgressIndicator(strokeWidth: 3));
              },
            ),
          ),
        ),

      ]),
    );
  }

  void _updateUserData(DateTime date) {
    CartLocation pick = CartLocation(lat: widget.userData!.pickupLocation!.lat, lng: widget.userData!.pickupLocation!.lng, locationName: widget.userData!.pickupLocation!.locationName);
    CartLocation destination = CartLocation(lat: widget.userData!.destinationLocation!.lat, lng: widget.userData!.destinationLocation!.lng, locationName: widget.userData!.destinationLocation!.locationName);
    CarCart cart = CarCart(
      applyMethod: true, distance: widget.userData!.distance, destinationTime: widget.userData!.destinationTime,
      rentalType: widget.userData!.rentalType, estimatedHour: '${widget.userData!.estimatedHours ?? 0}',
      pickupLocation: pick, destinationLocation: destination, pickupTime: DateConverter.formatDate(date),
    );
    Get.find<TaxiCartController>().updateUserData(cart: cart, userId: widget.userData!.id!).then((success) {
      if(success) {
        Get.back();
        Get.find<TaxiCartController>().getCarCartList();
      }
    });
  }
}

class _DateCell extends StatelessWidget {
  final DateTime date;
  final bool isSelected;
  final bool isDisabled;
  final bool isToday;
  const _DateCell({required this.date, required this.isSelected, required this.isDisabled, required this.isToday});

  @override
  Widget build(BuildContext context) {
    Color background = Colors.transparent;
    Color textColor = Theme.of(context).textTheme.bodyLarge!.color!;
    Border? border;
    if (isSelected) {
      background = Theme.of(context).primaryColor;
      textColor = Colors.white;
    } else if (isDisabled) {
      background = Theme.of(context).disabledColor.withValues(alpha: 0.08);
      textColor = Theme.of(context).disabledColor;
    } else if (isToday) {
      // Same shape as selected, but transparent fill with a primary-colored border.
      border = Border.all(color: Theme.of(context).primaryColor, width: 1);
      textColor = Theme.of(context).primaryColor;
    }

    return Container(
      margin: const EdgeInsets.all(2.5),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: background,
        border: border,
        borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
      ),
      child: Text(
        date.day.toString(),
        style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeDefault, color: textColor),
      ),
    );
  }
}

