import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/custom_button.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';
import 'package:sixam_mart/features/rental_module/rental_cart_screen/rental_cart_screen.dart';
import 'package:sixam_mart/features/rental_module/custom/custom_icon.dart';
import 'package:sixam_mart/features/rental_module/rental_location_screen/widgets/location_card.dart';
import 'package:sixam_mart/features/rental_module/common/widgets/pick_up_time_card.dart';
import 'package:sixam_mart/features/rental_module/widgets/rental_date_time_picker_sheet.dart';
import 'package:sixam_mart/features/rental_module/widgets/trip_type_summary_card.dart';
import 'package:sixam_mart/features/rental_module/home/domain/models/vehicle_details_model.dart';
import 'package:sixam_mart/features/rental_module/rental_cart_screen/controllers/taxi_cart_controller.dart';
import 'package:sixam_mart/features/rental_module/rental_cart_screen/domain/models/car_cart.dart';
import 'package:sixam_mart/features/rental_module/rental_location_screen/controller/taxi_location_controller.dart';
import 'package:sixam_mart/features/rental_module/select_vehicle_screen/select_vehicle_screen.dart';
import 'package:sixam_mart/features/rental_module/vendor/controllers/taxi_vendor_controller.dart';
import 'package:sixam_mart/helper/date_converter.dart';
import 'package:sixam_mart/helper/image_cache_helper.dart';
import 'package:sixam_mart/helper/price_converter.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:sixam_mart/util/dimensions.dart';

class RentalLocationConfirmScreen extends StatefulWidget {
  final VehicleModel? vehicle;
  final String? searchName;
  const RentalLocationConfirmScreen({super.key, this.vehicle, this.searchName});

  /// Top of the floating card — also where the map strip ends.
  static double cardTop(Size screen) => screen.height * 2 / 4.1 - 30;

  /// Height of the visible map strip. It reaches just past the card's rounded
  /// corners so nothing shows through them.
  static double mapStripHeight(Size screen) => cardTop(screen) + Dimensions.radiusExtraLarge;

  /// Shape of that strip. The controller crops the map capture to this before
  /// storing it, so the image arrives already matching its box — no stretching to
  /// fit and no rows decoded only to be cropped away.
  static double mapStripAspectRatio(Size screen) => screen.width / mapStripHeight(screen);

  @override
  State<RentalLocationConfirmScreen> createState() => _RentalLocationConfirmScreenState();
}

class _RentalLocationConfirmScreenState extends State<RentalLocationConfirmScreen> {

  bool showTripTypeHourly = true;
  bool showTripTypeDistance = true;
  bool showTripTypeDay = true;
  final FocusNode hourNode = FocusNode();
  final FocusNode dayNode = FocusNode();

  @override
  void initState() {
    super.initState();

    final TaxiLocationController locationController = Get.find<TaxiLocationController>();

    // Keep the trip type the user already selected on the details screen.
    // Only fall back to a default when the current selection isn't supported by this vehicle.
    String tripType = locationController.tripType;
    if(widget.vehicle != null && !_isTripTypeSupported(tripType)) {
      if(widget.vehicle!.tripDistance!) {
        tripType = AppConstants.distanceWise;
      } else if(widget.vehicle!.tripHourly!) {
        tripType = AppConstants.hourly;
        locationController.estimateTimeController.text = '1';
      } else if(widget.vehicle!.tripDayWise!) {
        tripType = AppConstants.dayWise;
      }
    }

    locationController.selectTripType(tripType, willUpdate: false);
    locationController.setTripDate(DateTime.now(), willUpdate: false);
    locationController.setTripTime(DateTime.now(), willUpdate: false);
    locationController.takeCurrentTime(true, willUpdate: false);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _applyProviderScheduleRule();
    });
  }

  Future<void> _applyProviderScheduleRule() async {
    final int? providerId = widget.vehicle?.providerId;
    if(providerId == null) return;

    final TaxiVendorController vendorController = Get.find<TaxiVendorController>();
    if(vendorController.taxiVendor?.id != providerId) {
      await vendorController.getTaxiVendorDetails(providerId);
    }
    if(!vendorController.isScheduleAllowed(providerId)) {
      // A pickup time carried over from an earlier vehicle must not survive into a
      // provider that only takes instant trips.
      Get.find<TaxiLocationController>().setFinalTripDateTime(DateTime.now());
    }
  }

  bool _isTripTypeSupported(String type) {
    final VehicleModel? vehicle = widget.vehicle;
    if(vehicle == null) return true;
    return (type == AppConstants.distanceWise && vehicle.tripDistance!)
        || (type == AppConstants.hourly && vehicle.tripHourly!)
        || (type == AppConstants.dayWise && vehicle.tripDayWise!);
  }

  @override
  void dispose() {
    hourNode.dispose();
    dayNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double discount = 0;
    String discountType = 'percent';
    double hourlyDiscount = 0;
    double distanceWiseDiscount = 0;
    double dayWiseDiscount = 0;

    if(widget.vehicle != null) {
      showTripTypeHourly = widget.vehicle!.tripHourly!;
      showTripTypeDistance = widget.vehicle!.tripDistance!;
      showTripTypeDay = widget.vehicle!.tripDayWise!;

      discount = widget.vehicle!.discountPrice ?? 0;
      discountType = widget.vehicle!.discountType ?? 'percent';

      distanceWiseDiscount = PriceConverter.calculation(widget.vehicle!.distancePrice!, discount, discountType, 1);
      hourlyDiscount = PriceConverter.calculation(widget.vehicle!.hourlyPrice!, discount, discountType, 1);
      dayWiseDiscount = PriceConverter.calculation(widget.vehicle!.dayWisePrice!, discount, discountType, 1);
    }

    final double topPadding = MediaQuery.of(context).padding.top;
    final Size screen = MediaQuery.of(context).size;
    final double mapWidth = screen.width;
    final double cardTop = RentalLocationConfirmScreen.cardTop(screen);
    final double mapHeight = RentalLocationConfirmScreen.mapStripHeight(screen);

    return Scaffold(
      body: GetBuilder<TaxiLocationController>(builder: (taxiLocationController) {
        return SizedBox.expand(child: Stack(children: [
          // Map image — spans the visible strip above the card, edge-to-edge
          SizedBox(
            height: mapHeight,
            width: mapWidth,
            child: Image.memory(taxiLocationController.mapScreenshot!, fit: BoxFit.cover,
              cacheWidth: ImageCacheHelper.pixels(context, mapWidth),
              cacheHeight: ImageCacheHelper.pixels(context, mapHeight),
            ),
          ),

          // Floating back button
          Positioned(
            top: topPadding + Dimensions.paddingSizeSmall,
            left: Dimensions.paddingSizeDefault,
            child: const _BackButton(),
          ),

          // Bottom card floating over the map
          Positioned(
            left: 0, right: 0, bottom: 0,
            top: cardTop,
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(Dimensions.radiusExtraLarge), topRight: Radius.circular(Dimensions.radiusExtraLarge)),
                boxShadow: [BoxShadow(color: Theme.of(context).disabledColor.withValues(alpha: 0.2), blurRadius: 10, offset: const Offset(0, -2))],
              ),
              padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const SizedBox(height: Dimensions.paddingSizeSmall),

                        LocationCard(
                          fromAddress: taxiLocationController.fromAddress!,
                          toAddress: taxiLocationController.toAddress!,
                        ),
                        const SizedBox(height: Dimensions.paddingSizeDefault),
                        const Divider(),

                        const SizedBox(height: Dimensions.paddingSizeSmall),
                        GetBuilder<TaxiVendorController>(builder: (vendorController) {
                          return PickUpTimeCard(
                            icon: const CustomIcon(height: 32, width: 32, icon: Icons.date_range_outlined),
                            taxiLocationController: taxiLocationController,
                            scheduleAllowed: vendorController.isScheduleAllowed(widget.vehicle?.providerId),
                            onTap: () {
                              Get.bottomSheet(
                                const RentalDateTimePickerSheet(fromCart: false),
                                backgroundColor: Colors.transparent, isScrollControlled: true,
                              ).then((date) {
                                if (kDebugMode) {
                                  print('======Deleted date is: $date');
                                }
                              });
                            },
                          );
                        }),
                        const SizedBox(height: Dimensions.paddingSizeSmall),

                        const Divider(),
                        const SizedBox(height: Dimensions.paddingSizeSmall),

                        TripTypeSummaryCard(
                          vehicle: widget.vehicle,
                          showTripTypeHourly: showTripTypeHourly,
                          showTripTypeDistance: showTripTypeDistance,
                          showTripTypeDay: showTripTypeDay,
                          hourlyDiscount: hourlyDiscount,
                          distanceWiseDiscount: distanceWiseDiscount,
                          dayWiseDiscount: dayWiseDiscount,
                          discountType: discountType,
                        ),
                        const SizedBox(height: Dimensions.paddingSizeLarge),
                      ]),
                    ),
                  ),

                  SafeArea(
                    child: GetBuilder<TaxiCartController>(
                      builder: (taxiCartController) {
                        return !taxiCartController.isLoading ? CustomButton(
                          buttonText: widget.vehicle != null ? 'add_to_cart'.tr : 'confirm_and_search_vehicle'.tr,
                          onPressed: () async {
                            if(taxiLocationController.finalTripDateTime == null) {
                              showCustomSnackBar('please_select_pickup_time'.tr);
                            } else if(taxiLocationController.tripType == 'hourly' && taxiLocationController.estimateTimeController.text.isEmpty) {
                              showCustomSnackBar('please_enter_estimate_time'.tr);
                            } else if(taxiLocationController.tripType == 'hourly' && double.parse(taxiLocationController.estimateTimeController.text) <= 0) {
                              hourNode.requestFocus();
                              showCustomSnackBar('please_enter_valid_estimate_time'.tr);
                            } else if(taxiLocationController.tripType == 'day_wise' && taxiLocationController.estimateDayController.text.isEmpty) {
                              showCustomSnackBar('please_enter_estimate_days'.tr);
                            } else if(taxiLocationController.tripType == 'day_wise' && double.parse(taxiLocationController.estimateDayController.text) <= 0) {
                              dayNode.requestFocus();
                              showCustomSnackBar('please_enter_valid_estimate_days'.tr);
                            } else {
                              if(widget.vehicle != null) {
                                _addToCart(taxiLocationController, taxiCartController, widget.vehicle!);
                              } else {
                                Get.to(() => SelectVehicleScreen(fromAddress: taxiLocationController.fromAddress, toAddress: taxiLocationController.toAddress));
                              }
                            }
                          },
                        ) : const Center(child: CircularProgressIndicator());
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ]));
      }),
    );
  }

  Future<void> _addToCart(TaxiLocationController locationController,TaxiCartController taxiCartController, VehicleModel vehicle) async {
    CartLocation pick = CartLocation(lat: locationController.fromAddress!.latitude, lng: locationController.fromAddress!.longitude, locationName: locationController.fromAddress!.address);
    CartLocation destination = CartLocation(lat: locationController.toAddress!.latitude, lng: locationController.toAddress!.longitude, locationName: locationController.toAddress!.address);
    double? estimatedDay = (double.tryParse(locationController.estimateDayController.text) ?? 0) * 24;

    CarCart cart = CarCart(
      vehicleId: vehicle.id, quantity: 1, pickupLocation: pick, destinationLocation: destination,
      pickupTime: DateConverter.formatDate(locationController.finalTripDateTime!),
      rentalType: locationController.tripType, estimatedHour: locationController.tripType == 'day_wise' ? estimatedDay.toStringAsFixed(0) : locationController.estimateTimeController.text,
      destinationTime: locationController.duration, distance: locationController.distance,
    );

    await taxiCartController.addToCart(cart).then((success) {
      if(success) {
        Get.back();
        Get.off(()=> const RentalCartScreen());
      }
    });
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Get.back(),
      child: Container(
        height: 40, width: 40,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: const Icon(Icons.arrow_back, size: 20),
      ),
    );
  }
}

// SUMMARY
// Final step of a rental booking. Shows the captured map strip with the pickup and
// destination addresses, the pickup time (schedulable only when the vehicle's provider
// takes scheduled trips) and the trip type pricing, then adds the vehicle to the rental
// cart or moves on to vehicle search when no vehicle was chosen yet.
