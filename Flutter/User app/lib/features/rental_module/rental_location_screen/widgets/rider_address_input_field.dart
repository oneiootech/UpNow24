import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sixam_mart/features/location/controllers/location_controller.dart';
import 'package:sixam_mart/features/location/domain/models/prediction_model.dart';
import 'package:sixam_mart/features/rental_module/home/domain/models/vehicle_details_model.dart';
import 'package:sixam_mart/features/rental_module/rental_cart_screen/domain/models/car_cart_model.dart';
import 'package:sixam_mart/features/rental_module/rental_location_screen/controller/taxi_location_controller.dart';
import 'package:sixam_mart/features/rental_module/rental_location_screen/taxi_location_screen.dart';
import 'package:sixam_mart/features/rental_module/rental_location_screen/taxi_location_suggestion_screen.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';

class RiderAddressInputField extends StatefulWidget {
  final bool isFormAddress;
  final bool? showInMapView;
  final GoogleMapController? mapController;
  final UserData? userData;
  final VehicleModel? vehicle;
  final bool? fromSuggestionScreen;
  final bool showClearButton;
  final bool autofocus;
  final VoidCallback? onFieldActivated;
  const RiderAddressInputField({super.key, required this.isFormAddress, required this.mapController,
    this.showInMapView = true, this.userData, this.vehicle, this.fromSuggestionScreen = false, this.showClearButton = true, this.autofocus = false, this.onFieldActivated,
  });

  @override
  State<RiderAddressInputField> createState() => _RiderAddressInputFieldState();
}

class _RiderAddressInputFieldState extends State<RiderAddressInputField> {
  // Holds the FocusNode managed by TypeAheadField so the clear button can
  // request focus on this field directly after clearing its text.
  FocusNode? _focusNode;

  @override
  void dispose() {
    _focusNode?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<TaxiLocationController>(
      builder: (taxiLocationController) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
            color: Theme.of(context).cardColor,
          ),
          child: Row(
            children: [
              Expanded(
                child: widget.showInMapView! ? InkWell(
                  onTap: () async {
                    taxiLocationController.selectLocationType(isForm: widget.isFormAddress);
                    if(widget.fromSuggestionScreen!) {
                      await taxiLocationController.clearAddress(widget.isFormAddress);
                      Get.back();
                    } else {
                      await taxiLocationController.clearAddress(widget.isFormAddress);
                      Get.off(() => TaxiLocationSuggestionScreen(mapController: widget.mapController, userData: widget.userData, vehicle: widget.vehicle, isFromSelected: widget.isFormAddress));
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall),
                    child: Text(
                        widget.isFormAddress
                            ? taxiLocationController.formTextEditingController.text.isEmpty ? 'enter_pickup'.tr : taxiLocationController.formTextEditingController.text
                            : taxiLocationController.toTextEditingController.text.isEmpty ? 'enter_destination'.tr : taxiLocationController.toTextEditingController.text,
                      style: robotoRegular.copyWith(color: widget.isFormAddress
                          ? taxiLocationController.formTextEditingController.text.isEmpty ? Theme.of(context).disabledColor : Theme.of(context).textTheme.bodyLarge!.color
                          : taxiLocationController.toTextEditingController.text.isEmpty ? Theme.of(context).disabledColor : Theme.of(context).textTheme.bodyLarge!.color,
                      ),
                      maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.left,
                    ),
                  ),
                ) : TypeAheadField(
                  hideOnEmpty: true,
                  hideOnLoading: !widget.showInMapView!,
                  controller: widget.isFormAddress ? taxiLocationController.formTextEditingController : taxiLocationController.toTextEditingController,
                  builder: (context, controller, focusNode) {
                    _focusNode = focusNode;
                    return TextField(
                      controller: controller,
                      focusNode: focusNode,
                      textInputAction: TextInputAction.search,
                      autofocus: widget.autofocus,
                      onTap: () {
                        widget.onFieldActivated?.call();
                        taxiLocationController.selectLocationType(isForm: widget.isFormAddress);
                      },
                      onChanged: (value) {
                        if(!widget.showInMapView!) {
                          if(value.isEmpty) {
                            Get.find<TaxiLocationController>().updateLocationSuggestions(null);
                          } else if(Get.find<TaxiLocationController>().locationSuggestions == null) {
                            Get.find<TaxiLocationController>().updateLocationSuggestions([]);
                          }
                        }
                      },
                      textCapitalization: TextCapitalization.words,
                      keyboardType: TextInputType.streetAddress,
                      decoration: InputDecoration(
                        hintText: widget.isFormAddress ? 'enter_pickup'.tr : 'set_destination'.tr,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(style: BorderStyle.none, width: 0),
                        ),
                        hintStyle: Theme.of(context).textTheme.displayMedium!.copyWith(
                          fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).disabledColor,
                        ),
                        filled: true, fillColor: Theme.of(context).cardColor,
                      ),
                      style: Theme.of(context).textTheme.displayMedium!.copyWith(
                        color: Theme.of(context).textTheme.bodyLarge!.color, fontSize: Dimensions.fontSizeDefault,
                      ),
                    );
                  },

                  suggestionsCallback: (pattern) async {
                    if(pattern.isNotEmpty) {
                      final results = await Get.find<LocationController>().searchLocation(context, pattern);
                      if(!widget.showInMapView!) {
                        Get.find<TaxiLocationController>().updateLocationSuggestions(results);
                        return <PredictionModel>[];
                      }
                      return results;
                    } else {
                      if(!widget.showInMapView!) {
                        Get.find<TaxiLocationController>().updateLocationSuggestions(null);
                      }
                      return <PredictionModel>[];
                    }
                  },
                  itemBuilder: (context, PredictionModel suggestion) {
                    return Padding(
                      padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                      child: Row(children: [
                        widget.isFormAddress ? Image.asset(Images.taxiPickup, height: 16, width: 16, color: Theme.of(context).primaryColor)
                            : Icon(Icons.location_on_rounded, size: 16, color: Theme.of(context).primaryColor),
                        const SizedBox(width: Dimensions.paddingSizeExtraSmall),

                        Expanded(
                          child: Text(suggestion.description!, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.displayMedium!.copyWith(
                            color: Theme.of(context).textTheme.bodyLarge!.color, fontSize: Dimensions.fontSizeLarge,
                          )),
                        ),
                      ]),
                    );
                  },
                  onSelected: (PredictionModel suggestion) async {
                    await taxiLocationController.setLocationFromPlace(suggestion.placeId, suggestion.description, widget.isFormAddress, widget.mapController);

                    if(widget.userData != null) {
                      Get.back();
                    }

                    if (taxiLocationController.fromAddress != null && taxiLocationController.toAddress != null) {
                      taxiLocationController.updateCameraMovingStatus(false);
                      Get.to(() => TaxiLocationScreen(
                        fromAddress: taxiLocationController.fromAddress, toAddress: taxiLocationController.toAddress,
                        fromSuggestionScreen: widget.userData == null, userData: widget.userData, vehicle: widget.vehicle,
                      ));
                    }

                  },

                  errorBuilder : (_,value) {
                    return const SizedBox();
                  },
                ),
              ),

              widget.showClearButton && (widget.isFormAddress ? taxiLocationController.formTextEditingController.text != '' : taxiLocationController.toTextEditingController.text != '')
              ? InkWell(
                onTap: () {
                  taxiLocationController.clearAddress(widget.isFormAddress);
                  taxiLocationController.selectLocationType(isForm: widget.isFormAddress);
                  taxiLocationController.updateLocationSuggestions(null);
                  widget.onFieldActivated?.call();
                  _focusNode?.requestFocus();
                  if(widget.fromSuggestionScreen!) {
                    Get.back();
                  }
                },
                child: const SizedBox(
                  height: 30, width: 30,
                  child: Icon(Icons.clear, size: 16),
                )) : const SizedBox()

            ],
          ),
        );
      }
    );
  }
}
