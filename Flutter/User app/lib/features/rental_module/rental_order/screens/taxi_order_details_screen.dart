import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/models/config_model.dart';
import 'package:sixam_mart/common/widgets/custom_app_bar.dart';
import 'package:sixam_mart/common/widgets/custom_button.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';
import 'package:sixam_mart/features/rental_module/common/enums/trip_status_enum.dart';
import 'package:sixam_mart/features/rental_module/common/models/trip_details_model.dart';
import 'package:sixam_mart/features/rental_module/rental_order/controllers/taxi_order_controller.dart';
import 'package:sixam_mart/features/rental_module/rental_order/widgets/address_card.dart';
import 'package:sixam_mart/features/rental_module/rental_order/widgets/deliveryman_view.dart';
import 'package:sixam_mart/features/rental_module/rental_order/widgets/provider_view.dart';
import 'package:sixam_mart/features/rental_module/rental_order/widgets/selected_vehicles_view.dart';
import 'package:sixam_mart/features/rental_module/rental_order/widgets/taxi_payment_bottom_sheet.dart';
import 'package:sixam_mart/features/rental_module/rental_order/widgets/trip_payment_failed_view.dart';
import 'package:sixam_mart/features/pro/widgets/pro_savings_banner_widget.dart';
import 'package:sixam_mart/features/rental_module/rental_order/widgets/trip_calculation_view.dart';
import 'package:sixam_mart/features/rental_module/rental_order/widgets/trip_status_view.dart';
import 'package:sixam_mart/features/rental_module/widgets/confirm_booking_request_bottom_sheet.dart';
import 'package:sixam_mart/features/rental_module/widgets/review_bottom_sheet.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/helper/auth_helper.dart';
import 'package:sixam_mart/helper/date_converter.dart';
import 'package:sixam_mart/helper/price_converter.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/images.dart';

import '../../../../util/dimensions.dart';
import '../../../../util/styles.dart';

class TaxiOrderDetailsScreen extends StatefulWidget {
  final int tripId;
  final bool? fromCheckout;
  final String? phone;
  const TaxiOrderDetailsScreen({super.key, required this.tripId, this.fromCheckout = false, this.phone});

  @override
  State<TaxiOrderDetailsScreen> createState() => _TaxiOrderDetailsScreenState();
}

class _TaxiOrderDetailsScreenState extends State<TaxiOrderDetailsScreen> {
  bool _additionalNoteExpanded = false;

  @override
  void initState() {
    super.initState();

    // Opening the screen is a fresh visit, so a failure left over from an earlier
    // one never shows again. Silent: an update() here rebuilds live GetBuilders.
    Get.find<TaxiOrderController>().setFailedPaymentTrip(null, willUpdate: false);

    if(widget.phone == null) {
      Get.find<TaxiOrderController>().getTripDetails(widget.tripId, willUpdate: false);
    }

    if(widget.fromCheckout!) {
      Future.delayed(const Duration(microseconds: 600), () {
        Get.bottomSheet(const ConfirmBookingRequestBottomSheet(isScheduleBooking: false, isBooking: true));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<TaxiOrderController>(
      builder: (taxiOrderController) {
        TripDetailsModel? tripDetailsModel = taxiOrderController.tripDetailsModel;
        bool halfCompleted = false;
        bool tripCanceled = tripDetailsModel?.tripStatus == TripStatusEnum.canceled.name;
        bool paymentFailed = tripDetailsModel != null && taxiOrderController.failedPaymentTripId == tripDetailsModel.id;
        double discount = 0;
        double couponDiscount = 0;
        double tax = 0;
        double taxPercent = 0;
        bool taxInclude = true;
        double additionalCharge = 0;
        double tripCost = 0;
        double subTotal = 0;
        double total = 0;
        final errorColor = Theme.of(context).colorScheme.error;
        if(tripDetailsModel != null) {
          halfCompleted = tripDetailsModel.tripStatus == TripStatusEnum.completed.name && tripDetailsModel.paymentStatus != 'paid';
          discount = tripDetailsModel.discountOnTrip??0;
          couponDiscount = tripDetailsModel.couponDiscountAmount??0;
          tax = tripDetailsModel.taxAmount??0;
          taxPercent = tripDetailsModel.taxPercentage??0;
          taxInclude = tripDetailsModel.taxStatus == 'included';
          additionalCharge = tripDetailsModel.additionalCharge??0;
          total = tripDetailsModel.tripAmount??0;
          tripCost = _calculateTripCost(tripDetailsModel.tripDetails);
          subTotal = tripCost - discount - couponDiscount;
        }

        return tripDetailsModel != null ? PopScope(
          canPop: paymentFailed ? false : Navigator.canPop(context),
          onPopInvokedWithResult: (didPop, result) async {
            if(paymentFailed) {
              taxiOrderController.setFailedPaymentTrip(null);
              return;
            }
            if(widget.fromCheckout!) {
              Future.delayed(const Duration(milliseconds: 100) , () {
                Get.offAllNamed(RouteHelper.getInitialRoute());
              });
            } else {
              return;
            }
          },
          child: Scaffold(
            backgroundColor: Theme.of(context).colorScheme.surface,
            appBar: CustomAppBar(
              title: 'trip_details'.tr,
              onBackPressed: () {
                // Back out of the failure first; the trip details sit underneath it.
                if(paymentFailed) {
                  taxiOrderController.setFailedPaymentTrip(null);
                } else if(widget.fromCheckout!) {
                  Get.offAllNamed(RouteHelper.getInitialRoute());
                } else {
                  Navigator.pop(context);
                }
              },
              menuWidget: Row(children: [
                // tripDetailsModel.tripStatus == TripStatusEnum.completed.name || tripDetailsModel.tripStatus == TripStatusEnum.paymentFailed.name ? _AppBarIconButton(icon: Images.docsIcon, onTap: () {}) : const SizedBox.shrink(),
                // SizedBox(width: tripDetailsModel.tripStatus == TripStatusEnum.completed.name || tripDetailsModel.tripStatus == TripStatusEnum.paymentFailed.name ? Dimensions.paddingSizeSmall : 0),
                _AppBarIconButton(icon: Images.supprotIcon, onTap: () => Get.toNamed(RouteHelper.getSupportRoute())),
                const SizedBox(width: Dimensions.paddingSizeSmall),
              ]),
            ),

            body: paymentFailed ? TripPaymentFailedView(tripDetailsModel: tripDetailsModel) : Column(children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(children: [
                    // Status Header Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall, vertical: Dimensions.paddingSizeLarge),
                      color: Theme.of(context).disabledColor.withValues(alpha: 0.05),
                      child: TripStatusView(tripDetailsModel: tripDetailsModel),
                    ),

                    const SizedBox(height: Dimensions.paddingSizeSmall),

                    // Main Container with rounded top corners
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(Dimensions.radiusExtraLarge)),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, -4))],
                      ),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const SizedBox(height: Dimensions.paddingSizeDefault),

                        // Trip Details Card
                        _TripDetailsCard(tripDetailsModel: tripDetailsModel),
                        const _SectionDivider(),

                        // Deliveryman View (if assigned)
                        if(!tripCanceled && tripDetailsModel.vehicleIdentity != null && tripDetailsModel.vehicleIdentity!.isNotEmpty)
                          DeliverymanView(vehicleIdentity: tripDetailsModel.vehicleIdentity, tripId: tripDetailsModel.id!, paymentStatus: tripDetailsModel.paymentStatus),

                        // Address Section (Pickup and Destination)
                        AddressCard(
                          fromAddress: tripDetailsModel.pickupLocation?.locationName ?? '',
                          toAddress: tripDetailsModel.destinationLocation?.locationName ?? '',
                          extraOneAddress: '', extraTwoAddress: '',
                          entrance: '',
                        ),

                        // Additional Note (collapsible)
                        if(tripDetailsModel.tripNote != null) ...[
                          const SizedBox(height: Dimensions.paddingSizeSmall),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeLarge),
                            child: InkWell(
                              onTap: () => setState(() => _additionalNoteExpanded = !_additionalNoteExpanded),
                              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                                Text('additional_note'.tr, style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeDefault, color: Colors.blueAccent)),
                                Icon(_additionalNoteExpanded ? Icons.expand_less : Icons.expand_more, color: Colors.blueAccent),
                              ]),
                            ),
                          ),
                          if(_additionalNoteExpanded) ...[
                            const SizedBox(height: Dimensions.paddingSizeSmall),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeLarge),
                              child: Text(tripDetailsModel.tripNote!, style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Colors.grey.shade700)),
                            ),
                          ],
                        ],
                        const SizedBox(height: Dimensions.paddingSizeDefault),
                        const _SectionDivider(),

                        // Selected Vehicles View (collapsible)
                        if(!tripCanceled && tripDetailsModel.tripDetails != null && tripDetailsModel.tripDetails!.isNotEmpty)...[
                          const SizedBox(height: Dimensions.paddingSizeSmall),
                          _ExpandableSection(
                            title: 'vehicle_info'.tr,
                            initiallyExpanded: true,
                            child: Column(children: [
                              SelectedVehiclesView(tripDetailsList: tripDetailsModel.tripDetails!, tripType: tripDetailsModel.tripType, estimatedHours: tripDetailsModel.estimatedHours),
                              // Provider View
                              if(!tripCanceled && tripDetailsModel.provider != null)...[
                                const SizedBox(height: Dimensions.paddingSizeSmall),
                                ProviderView(provider: tripDetailsModel.provider!, tripId: tripDetailsModel.id!),
                              ]
                            ]),
                          ),
                        ],

                        const SizedBox(height: Dimensions.paddingSizeDefault),
                        const _SectionDivider(),
                        const SizedBox(height: Dimensions.paddingSizeSmall),

                        // Trip Calculation View
                        TripCalculationView(
                          tripCost: tripCost,
                          discount: discount,
                          couponDiscount: couponDiscount,
                          isProCoupon: tripDetailsModel.isProCoupon,
                          proDiscount: tripDetailsModel.proDiscount ?? 0,
                          subTotal: subTotal,
                          tax: tax,
                          total: total,
                          serviceFee: additionalCharge,
                          taxPercent: taxPercent,
                          taxInclude: taxInclude,
                        ),

                        const SizedBox(height: Dimensions.paddingSizeDefault),
                      ]),
                    ),
                  ]),
                ),
              ),

              Builder(builder: (context) {
                final double proSavings = (tripDetailsModel.proDiscount ?? 0) + (tripDetailsModel.isProCoupon ? couponDiscount : 0);
                final bool showPayNow = (tripDetailsModel.tripStatus == TripStatusEnum.completed.apiValue || tripDetailsModel.tripStatus == TripStatusEnum.paymentFailed.apiValue) && tripDetailsModel.paymentStatus != 'paid';
                final bool showReview = tripDetailsModel.tripStatus == TripStatusEnum.completed.name && tripDetailsModel.paymentStatus == 'paid' && _canReview(tripDetailsModel.vehicleIdentity ?? []) && tripDetailsModel.provider!.reviewSection! && AuthHelper.isLoggedIn();
                if (proSavings <= 0 && !showPayNow && !showReview) return const SizedBox();
                return Container(
                  color: Theme.of(context).cardColor,
                  child: SafeArea(top: false, child: Column(mainAxisSize: MainAxisSize.min, children: [
                    ProSavingsBannerWidget(amount: proSavings),
                    if (showPayNow) Padding(
                      padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeLarge, vertical: Dimensions.paddingSizeDefault),
                      child: Column(children: [
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          Text('est_fair'.tr, style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeDefault)),
                          Text(' (${taxInclude == true ? 'inc_vat_tax'.tr : 'exc_vat_tax'.tr})', style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).disabledColor)),
                          const Spacer(),
                          Text(PriceConverter.convertPrice(total, forTaxi: true), style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge), textDirection: TextDirection.ltr),
                        ]),
                        const SizedBox(height: Dimensions.paddingSizeSmall),
                        CustomButton(
                          buttonText: 'pay_now'.tr,
                          onPressed: () {
                            showModalBottomSheet(
                              isScrollControlled: true,
                              context: context,
                              builder: (BuildContext context) => TaxiPaymentBottomSheet(id: tripDetailsModel.id!, totalPrice: total),
                            ).then((success) {
                              if(success != null && success) {
                                Get.find<TaxiOrderController>().getTripDetails(tripDetailsModel.id!, willUpdate: false);
                              }
                            });
                          },
                        ),
                      ]),
                    ) else if (showReview) Padding(
                      padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeLarge, vertical: Dimensions.paddingSizeDefault),
                      child: ElevatedButton(
                        onPressed: () {
                          if(tripDetailsModel.vehicleIdentity!.isNotEmpty) {
                            Get.bottomSheet(ReviewBottomSheet(vehicleList: tripDetailsModel.vehicleIdentity!), isScrollControlled: true);
                          } else {
                            showCustomSnackBar('not_found_any_assigned_vehicle'.tr);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          minimumSize: const Size(double.infinity, 45),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5), side: BorderSide(color: Theme.of(context).primaryColor, width: 1.0)),
                        ),
                        child: Text('give_review'.tr, style: robotoBold.copyWith(color: Theme.of(context).cardColor, fontSize: 16)),
                      ),
                    ),
                  ])),
                );
              }),
            ]),
          ),
        ) : const Center(child: CircularProgressIndicator());
      }
    );
  }

  double _calculateTripCost(List<TripDetails>? tripDetails) {
    double tripCost = 0;
    if(tripDetails != null) {
      for (var trip in tripDetails) {
        tripCost += trip.calculatedPrice??0;
      }
    }
    return tripCost;
  }

  bool _canReview(List<VehicleIdentity> vehicleList) {
    if(AuthHelper.isLoggedIn()) {
      for (int i = 0; i < vehicleList.length; i++) {
        if (vehicleList[i].rating == null) {
          return true;
        }
      }
    }
    return false;
  }
}

class _AppBarIconButton extends StatelessWidget {
  final String icon;
  final VoidCallback onTap;
  const _AppBarIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Image.asset(icon, width: 20, height: 20),
      ),
    );
  }
}

class _SectionDivider extends StatelessWidget {
  const _SectionDivider();

  @override
  Widget build(BuildContext context) {
    return Divider(height: 1, thickness: 1, color: Theme.of(context).disabledColor.withAlpha(50),
    endIndent: Dimensions.paddingSizeDefault, indent: Dimensions.paddingSizeDefault);
  }
}

class _TripDetailsCard extends StatelessWidget {
  final TripDetailsModel tripDetailsModel;
  const _TripDetailsCard({required this.tripDetailsModel});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeLarge),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // ID with Copy Icon and Status Badge
        Row(mainAxisAlignment: MainAxisAlignment.start, children: [
          Text('#ID ${tripDetailsModel.id}', style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge)),
          const SizedBox(width: Dimensions.paddingSizeSmall),
          InkWell(
            onTap: () {
              Clipboard.setData(ClipboardData(text: tripDetailsModel.id.toString()));
              showCustomSnackBar('copied'.tr, isError: false);
            },
            child: Image.asset(Images.copyIcon, width: 18),
          ),

          const SizedBox(width: Dimensions.paddingSizeDefault),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall, vertical: 3),
            decoration: BoxDecoration(
              color: _getStatusColor(tripDetailsModel.tripStatus).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              tripDetailsModel.tripStatus!.tr,
              style: robotoMedium.copyWith(
                fontSize: Dimensions.fontSizeSmall,
                color: _getStatusColor(tripDetailsModel.tripStatus),
              ),
            ),
          ),
        ]),
        const SizedBox(height: Dimensions.paddingSizeDefault),

        // Booking Placed
        Text(
          'Booking Placed: ${DateConverter.dateTimeStringToDateTime(tripDetailsModel.createdAt!)}',
          style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).disabledColor),
        ),
        const SizedBox(height: Dimensions.paddingSizeSmall),

        // Rent Type
        Text(
          'Rent type is ${tripDetailsModel.tripType == 'hourly' ? tripDetailsModel.tripType!.tr : tripDetailsModel.tripType!.tr}',
          style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).disabledColor),
        ),
        const SizedBox(height: Dimensions.paddingSizeDefault),

        // Pickup Time
        Container(
          padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall, vertical: Dimensions.paddingSizeSmall),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
            color: Theme.of(context).disabledColor.withValues(alpha: 0.08),
          ),
          child: Row(children: [
            Icon(Icons.date_range_outlined, size: 24, color: Theme.of(context).disabledColor),
            const SizedBox(width: Dimensions.paddingSizeDefault),
            Text('pickup_time'.tr, style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall)),
            const SizedBox(height: 2),
            const Spacer(),
            Text(
              DateConverter.dateTimeStringToDateTime(tripDetailsModel.scheduleAt!),
              style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall),
            ),
          ]),
        ),
        if (tripDetailsModel.tripStatus == TripStatusEnum.completed.name) ...[
          const SizedBox(height: Dimensions.paddingSizeDefault),
          tripDetailsModel.tripType == 'hourly' ? Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text('total_hour'.tr, style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).textTheme.bodyLarge!.color!.withValues(alpha: 0.6))),
            Text(' - ${tripDetailsModel.estimatedHours}', style: robotoBold.copyWith(fontSize: Dimensions.fontSizeSmall, color: Colors.black))
          ]) : tripDetailsModel.tripType == 'day_wise' ? Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text('total'.tr, style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).textTheme.bodyLarge!.color!.withValues(alpha: 0.6))),
            Text(' - ${((tripDetailsModel.estimatedHours ?? 0) / 24).toStringAsFixed(0)} ${'day'.tr}', style: robotoBold.copyWith(fontSize: Dimensions.fontSizeSmall, color: Colors.black))
          ]) : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text('total_distance'.tr, style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Colors.grey.shade600)),
            Text(' - ${_distanceInConfiguredUnit.toStringAsFixed(2)} ${_distanceUnitSuffix}', style: robotoBold.copyWith(fontSize: Dimensions.fontSizeSmall, color: Colors.black))
          ])] ,
        const SizedBox(height: Dimensions.paddingSizeDefault),
      ]),
    );
  }

  ConfigModel? get _config =>
      Get.isRegistered<SplashController>() ? Get.find<SplashController>().configModel : null;

  String get _distanceUnitSuffix => _config?.distanceUnitSuffix ?? 'km';

  /// The stored trip distance is already expressed in the platform's configured
  /// distance unit, so it is rendered as sent and only the suffix follows the config.
  double get _distanceInConfiguredUnit => tripDetailsModel.distance ?? 0;

  Color _getStatusColor(String? status) {
    switch(status) {
      case 'completed': return Colors.green;
      case 'canceled': return Colors.red;
      case 'ongoing': return Colors.blue;
      case 'on_the_way': return Colors.orange;
      case 'confirmed': return Colors.teal;
      case 'pending': return Colors.grey;
      default: return Colors.grey;
    }
  }
}

class _ExpandableSection extends StatefulWidget {
  final String title;
  final Widget child;
  final bool initiallyExpanded;
  const _ExpandableSection({required this.title, required this.child, this.initiallyExpanded = false});

  @override
  State<_ExpandableSection> createState() => _ExpandableSectionState();
}

class _ExpandableSectionState extends State<_ExpandableSection> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeLarge),
      child: Column(children: [
        InkWell(
          onTap: () => setState(() => _isExpanded = !_isExpanded),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(widget.title, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeDefault)),
              Container(padding: const EdgeInsets.all(Dimensions.paddingSizeExtraSmall-4),
              decoration: BoxDecoration(color: Theme.of(context).disabledColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(Dimensions.radiusLarge)),
              child: Icon(_isExpanded ? Icons.expand_less : Icons.expand_more, color: Theme.of(context).disabledColor)),
            ]),
          ),
        ),
        if(_isExpanded) ...[
          const SizedBox(height: Dimensions.paddingSizeSmall),
          widget.child,
        ],
      ]),
    );
  }
}
// SUMMARY
// Trip details screen for a rental booking. Shows the trip status header, trip and
// vehicle info, addresses and the fare breakdown, with a Pay Now button for an
// unpaid trip and a review button once it is paid. Right after a digital payment
// comes back from the gateway as failed it shows the rental payment-failed view
// instead, until the payment settles or the customer backs out of it.
