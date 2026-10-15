import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sixam_mart/common/widgets/custom_app_bar.dart';
import 'package:sixam_mart/features/address/domain/models/address_model.dart';
import 'package:sixam_mart/features/rental_module/rental_location_screen/widgets/rental_map_recent_saved_address.dart';
import 'package:sixam_mart/features/rental_module/home/domain/models/vehicle_details_model.dart';
import 'package:sixam_mart/features/rental_module/rental_cart_screen/domain/models/car_cart_model.dart';
import 'package:sixam_mart/features/rental_module/rental_location_screen/controller/taxi_location_controller.dart';
import 'package:sixam_mart/features/rental_module/rental_location_screen/widgets/rider_address_input_field.dart';
import 'package:sixam_mart/helper/address_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

class RentalLocationSuggestionScreen extends StatefulWidget {
  final GoogleMapController? mapController;
  final AddressModel? fromAddress;
  final AddressModel? toAddress;
  final UserData? userData;
  final VehicleModel? vehicle;
  final bool? isFromSelected;
  const RentalLocationSuggestionScreen({super.key, this.mapController, this.fromAddress, this.toAddress, this.userData, this.vehicle, this.isFromSelected = false});

  @override
  State<RentalLocationSuggestionScreen> createState() => _RentalLocationSuggestionScreenState();
}

class _RentalLocationSuggestionScreenState extends State<RentalLocationSuggestionScreen> {

  GoogleMapController? _mapController;
  bool _anyFieldActive = false;

  @override
  void initState() {
    super.initState();

    if(widget.mapController != null) {
      _mapController = widget.mapController;
    }

    if(widget.mapController == null) {
      Get.find<TaxiLocationController>().initialSetup(preserveEstimate: true);
      Get.find<TaxiLocationController>().getInitialLocation(widget.fromAddress ?? AddressHelper.getUserAddressFromSharedPref(), _mapController);
    }
    Get.find<TaxiLocationController>().selectLocationType(isForm: widget.isFromSelected!, willUpdate: false);

    Get.find<TaxiLocationController>().getHistoryAddresses();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) async{
        if(widget.userData == null) {
          Get.find<TaxiLocationController>().initialSetup(preserveEstimate: true);
          return;
        }
      },
      child: Scaffold(
        appBar: CustomAppBar(title: 'set_location'.tr),
        body: Column(children: [
          const SizedBox(height: Dimensions.paddingSizeDefault),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
            padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
              border: Border.all(color: Theme.of(context).disabledColor.withValues(alpha: 0.15)),
            ),
            child: Column( children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text('set_pickup_and_destination_location'.tr, style: robotoBold),
              ),
              const SizedBox(height: Dimensions.paddingSizeDefault),
              GetBuilder<TaxiLocationController>(
                builder: (taxiLocationController) {
                  return Column(children: [
                    Container(
                      padding: const EdgeInsets.only(left: Dimensions.paddingSizeSmall),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                        border: Border.all(color: Theme.of(context).disabledColor.withValues(alpha: 0.15)),
                      ),
                      child: Row( mainAxisAlignment: MainAxisAlignment.start, children: [
                        Icon(Icons.location_on_outlined, size: 20,
                          color: _anyFieldActive && taxiLocationController.isFormSelected
                              ? Theme.of(context).primaryColor
                              : Theme.of(context).disabledColor),
                        Expanded(child: RiderAddressInputField(
                          isFormAddress: true, showInMapView: false, mapController: _mapController,
                          vehicle: widget.vehicle, userData: widget.userData,
                          onFieldActivated: () => _anyFieldActive = true,
                        )),
                      ]),
                    ),

                    const SizedBox(height: Dimensions.paddingSizeDefault),

                    Container(
                      padding: const EdgeInsets.only(left: Dimensions.paddingSizeSmall),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                        border: Border.all(color: Theme.of(context).disabledColor.withValues(alpha: 0.15)),
                      ),
                      child: Row(children: [
                        Icon(CupertinoIcons.paperplane, size: 20,
                          color: _anyFieldActive && !taxiLocationController.isFormSelected
                              ? Theme.of(context).primaryColor
                              : Theme.of(context).disabledColor),
                        Expanded(child: RiderAddressInputField(
                          isFormAddress: false, showInMapView: false, mapController: _mapController,
                          vehicle: widget.vehicle, userData: widget.userData,
                          onFieldActivated: () => _anyFieldActive = true,
                        )),
                      ]),
                    ),

                  ]);
                },
              ),
            ]),
          ),

          const SizedBox(height: Dimensions.paddingSizeSmall),

          Expanded(child: RentalMapRecentSavedAddress(mapController: _mapController, userData: widget.userData, vehicle: widget.vehicle,)),

        ]),
      ),
    );
  }
}
