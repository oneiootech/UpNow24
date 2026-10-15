import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sixam_mart/common/controllers/theme_controller.dart';
import 'package:sixam_mart/common/widgets/custom_app_bar.dart';
import 'package:sixam_mart/common/widgets/custom_button.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';
import 'package:sixam_mart/features/address/domain/models/address_model.dart';
import 'package:sixam_mart/features/location/widgets/location_search_dialog_widget.dart';
import 'package:sixam_mart/features/location/widgets/permission_dialog_widget.dart';
import 'package:sixam_mart/features/rental_module/custom/custom_icon_layout.dart';
import 'package:sixam_mart/features/rental_module/home/domain/models/vehicle_details_model.dart';
import 'package:sixam_mart/features/rental_module/rental_cart_screen/domain/models/car_cart_model.dart';
import 'package:sixam_mart/features/rental_module/rental_location_screen/controller/taxi_location_controller.dart';
import 'package:sixam_mart/features/rental_module/rental_location_screen/widgets/animated_map_icon_extended.dart';
import 'package:sixam_mart/features/rental_module/rental_location_screen/widgets/animated_map_icon_minimized.dart';
import 'package:sixam_mart/features/rental_module/rental_location_screen/widgets/rider_address_input_field.dart';
import 'package:sixam_mart/helper/address_helper.dart';
import 'package:sixam_mart/helper/debouncer.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';

import '../custom/custom_floating_action_button.dart';
import '../custom/custom_vertical_dotted_line.dart';


class TaxiLocationScreen extends StatefulWidget {
  final AddressModel? fromAddress;
  final AddressModel? toAddress;
  final UserData? userData;
  final VehicleModel? vehicle;
  final GoogleMapController? mapController;
  final bool? fromSuggestionScreen;
  final bool? fromSuggestionMap;
  const TaxiLocationScreen({super.key, this.fromAddress, this.toAddress, this.userData, this.vehicle, this.mapController, this.fromSuggestionScreen = false, this.fromSuggestionMap = false});

  @override
  State<TaxiLocationScreen> createState() => _TaxiLocationScreenState();
}

class _TaxiLocationScreenState extends State<TaxiLocationScreen> {

  // bool confirmClick = false;
  GoogleMapController? _mapController;
  CameraPosition? _cameraPosition;
  double _currentZoomLevel = 16.0;
  bool _isPicked = false;
  // bool _isButtonClicked = true;
  final Debouncer _idleDebouncer = Debouncer(delay: const Duration(milliseconds: AppConstants.idleDebounceDuration));

  @override
  void initState() {
    super.initState();

    if(widget.mapController != null) {
      _mapController = widget.mapController;
    }

    if(widget.fromAddress != null && widget.toAddress != null) {
      Get.find<TaxiLocationController>().fromToEnable();
    }

    if(!widget.fromSuggestionMap!) {
      Future.delayed(const Duration(milliseconds: 200),() {
        // Preserve the estimate (hours/days) the user already entered on the details screen.
        Get.find<TaxiLocationController>().initialSetup(preserveEstimate: true);
      });
    }

    Future.delayed(const Duration(milliseconds: 400), (){
      Get.find<TaxiLocationController>().getZoneList();

      if(widget.toAddress == null && widget.fromAddress == null && !widget.fromSuggestionMap!) {
        Get.find<TaxiLocationController>().getInitialLocation(widget.fromAddress ?? AddressHelper.getUserAddressFromSharedPref(), _mapController);

      }
      // Pick-on-map edit: exactly one address is set (the other is being picked).
      // Handles both the normal flow and the cart-edit flow (userData != null);
      // routing here avoids the both-address-required `else` below crashing on null.
      else if(widget.fromSuggestionScreen! && widget.fromAddress == null && widget.toAddress != null) {
        Get.find<TaxiLocationController>().setAddressFromUpdate(widget.fromAddress, widget.toAddress!);

      }
      else if(widget.fromSuggestionScreen! && widget.toAddress == null && widget.fromAddress != null) {
        Get.find<TaxiLocationController>().setAddressFromUpdate(widget.fromAddress!, widget.toAddress);

      }
      else if(widget.fromSuggestionScreen! && widget.userData == null) {
        Get.find<TaxiLocationController>().setAddressFromUpdate(widget.fromAddress!, widget.toAddress!);
        Future.delayed(const Duration(milliseconds: 200) , () async {
          Get.find<TaxiLocationController>().setFromToMarker(
            _mapController,
            from: LatLng(double.parse(widget.fromAddress!.latitude!), double.parse(widget.fromAddress!.longitude!)),
            to: LatLng(double.parse(widget.toAddress!.latitude!), double.parse(widget.toAddress!.longitude!)),
            /*userData: widget.userData, canUpdateProfile: widget.userData != null,*/ clickFromButton: false,
          );
        });
      }
      else {
        Get.find<TaxiLocationController>().setAddressFromUpdate(widget.fromAddress!, widget.toAddress!);
        Future.delayed(const Duration(milliseconds: 200) , () async {
          Get.find<TaxiLocationController>().setFromToMarker(
            _mapController,
            from: LatLng(double.parse(widget.fromAddress!.latitude!), double.parse(widget.fromAddress!.longitude!)),
            to: LatLng(double.parse(widget.toAddress!.latitude!), double.parse(widget.toAddress!.longitude!)),
            userData: widget.userData, canUpdateProfile: widget.userData != null, clickFromButton: false,
          );
        });

      }
    });
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _idleDebouncer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<TaxiLocationController>(
        builder: (taxiLocationController) {
        final bool showAddressPillAppBar = widget.fromSuggestionMap! && !_isPicked;
        return Scaffold(
          appBar: showAddressPillAppBar
              ? _LocationAddressAppBar(controller: taxiLocationController, mapController: _mapController)
              : CustomAppBar(title: 'location'.tr),
          body: Stack(children: [
            GoogleMap(
              mapType: MapType.normal,
              markers: taxiLocationController.markers,
              // `setFromToMarker` routes the trip and fills these, but the map was never
              // handed them, so the line it had already fetched was never drawn.
              polylines: Set<Polyline>.of(taxiLocationController.polyLines.values),
              zoomControlsEnabled: false,
              padding: EdgeInsets.only(top: showAddressPillAppBar ? 0 : 140),
              scrollGesturesEnabled: !taxiLocationController.isButtonClick,
              initialCameraPosition: CameraPosition(target: Get.find<TaxiLocationController>().initialPosition, zoom: _currentZoomLevel),
              onMapCreated: (controller) {
                _mapController = controller;
                if(widget.toAddress == null && widget.fromAddress == null) {
                  taxiLocationController.getInitialLocation(widget.fromAddress, _mapController);
                }
              },
              onCameraMove: (CameraPosition cameraPosition) {
                _cameraPosition = cameraPosition;
              },
              onCameraMoveStarted: () {
                _idleDebouncer.cancel();
                taxiLocationController.updateCameraMovingStatus(true);
                taxiLocationController.disableButton();
              },
              onCameraIdle: () {
                taxiLocationController.updateCameraMovingStatus(false);
                try{
                  if(!taxiLocationController.showFromToMarker) {
                    _idleDebouncer.run(() {
                      if (!mounted) return;
                      taxiLocationController.updatePosition(_cameraPosition?.target, taxiLocationController.isFormSelected, _mapController);
                    });
                  }
                }catch(e){
                  if (kDebugMode) {
                    print(e);
                  }
                }
              },
              style: Get.isDarkMode ? Get.find<ThemeController>().darkMap : Get.find<ThemeController>().lightMapTaxi,
            ),

            !taxiLocationController.showFromToMarker ? Center(child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if(taxiLocationController.isCameraMoving)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                      borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                    ),
                    child: Text('is_this_your_location'.tr, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
                  ),
                const SizedBox(height: 0),
                Padding(
                  padding: const EdgeInsets.only(bottom: Dimensions.pickMapIconSize * 0.65),
                  child: taxiLocationController.isCameraMoving ? const AnimatedMapIconExtended() : const AnimatedMapIconMinimised(),
                ),
              ],
            )) : const SizedBox(),

            showAddressPillAppBar ? const SizedBox() : Positioned(
              top: Dimensions.paddingSizeLarge,
              left: Dimensions.paddingSizeLarge,
              right: Dimensions.paddingSizeLarge,
              child: AbsorbPointer(
                absorbing: taxiLocationController.isButtonClick ? true : false,
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                    boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha: 0.2), spreadRadius: 2, blurRadius: 4, offset: const Offset(0, 2))],
                  ),
                  child: doubleLocationView(),
                ),
              ),
            ),

            Positioned(right: 16, bottom: GetPlatform.isIOS ? 120 : 100,
              child: Column(children: [

                CustomFloatingActionButton(
                  icon: Icons.add, heroTag: 'add_button',
                  onTap: () {
                    _currentZoomLevel++;
                    _mapController?.animateCamera(CameraUpdate.zoomTo(_currentZoomLevel));
                  },
                ),

                CustomFloatingActionButton(
                  icon: Icons.remove, heroTag: 'remove_button',
                  onTap: () {
                    _currentZoomLevel--;
                    _mapController?.animateCamera(CameraUpdate.zoomTo(_currentZoomLevel));
                  },
                ),

                widget.fromSuggestionMap! && !_isPicked ? Container(
                  width: 50, height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(context).cardColor,
                    // boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 6, spreadRadius: 0.5, offset: const Offset(0, 4))],
                  ),
                  child: FloatingActionButton(
                    backgroundColor: Theme.of(context).cardColor,
                    onPressed: () {
                      _checkPermission(() {
                        taxiLocationController.getCurrentLocation(_mapController);
                      });
                    },
                    child: Icon(Icons.my_location, size: 35, color: Theme.of(context).primaryColor),
                  ),
                ) : const SizedBox(),
              ]),
            ),

            Positioned(
              bottom: 0, right: 0, left: 0,
              child: Container(
                decoration: BoxDecoration(
                  boxShadow: [BoxShadow(color: Theme.of(context).disabledColor.withValues(alpha: 0.2), blurRadius: 10)],
                  color: Theme.of(context).cardColor,
                ),
                padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                child: SafeArea(
                  child: CustomButton(
                    buttonText: !taxiLocationController.inZone ? 'service_not_available_in_this_area'.tr : widget.fromSuggestionMap! && !_isPicked ? 'pick_address'.tr : 'confirm'.tr,
                    isLoading: taxiLocationController.isButtonClick && taxiLocationController.isLoading,
                    onPressed: taxiLocationController.isLoading || !taxiLocationController.inZone ? null : () async {
                      taxiLocationController.buttonClicked(true);

                      if(widget.fromSuggestionMap! && !_isPicked && taxiLocationController.fromAddress != null && taxiLocationController.toAddress != null) {
                        setState(() {
                          _isPicked = true;
                        });
                        Get.find<TaxiLocationController>().setFromToMarker(
                          _mapController,
                          from: LatLng(double.parse(taxiLocationController.fromAddress!.latitude!), double.parse(taxiLocationController.fromAddress!.longitude!)),
                          to: LatLng(double.parse(taxiLocationController.toAddress!.latitude!), double.parse(taxiLocationController.toAddress!.longitude!)),
                          userData: widget.userData, canUpdateProfile: widget.userData != null, clickFromButton: false,
                        );
                      } else if((taxiLocationController.fromAddress == null || taxiLocationController.toAddress == null)) {
                        Get.back();
                      } else {

                        await taxiLocationController.setFromToMarker(
                          _mapController, fromAddress: taxiLocationController.fromAddress!,
                          from: LatLng(double.parse(taxiLocationController.fromAddress!.latitude!), double.parse(taxiLocationController.fromAddress!.longitude!)),
                          to: LatLng(double.parse(taxiLocationController.toAddress!.latitude!), double.parse(taxiLocationController.toAddress!.longitude!)),
                          // Cart edit is determined solely by userData. The previous
                          // `widget.toAddress != null` check broke the pick-on-map flow,
                          // where the edited field is passed null — sending the cart edit
                          // into the new-booking flow (RentalLocationConfirmScreen) instead
                          // of updating the cart and returning.
                          userData: widget.userData, canUpdateProfile: widget.userData != null, vehicle: widget.vehicle,
                        );
                      }

                      taxiLocationController.buttonClicked(false);

                    },
                  ),
                ),
              ),
            ),

          ]),
        );
      }
    );
  }

  Widget doubleLocationView() {
    return Row(
      children: [
        const Padding(
          padding: EdgeInsets.all(Dimensions.paddingSizeSmall),
          child: Column(children: [

            CustomIconLayout(height: 20, width: 20, icon: Icons.location_on_rounded),

            CustomVerticalDottedLine(dotCount: 6,),

            CustomIconLayout(height: 15, width: 15, iconImage: Images.navigationArrowIcon),
          ]),
        ),

        Expanded(child: Column(children: [
          RiderAddressInputField(
            isFormAddress: true, showInMapView: true, mapController: _mapController,
            userData: widget.userData, vehicle: widget.vehicle, fromSuggestionScreen: (widget.fromSuggestionMap! || widget.fromSuggestionScreen!),
          ),

          const Divider(endIndent: 10),
          RiderAddressInputField(
            isFormAddress: false, showInMapView: true, mapController: _mapController,
            userData: widget.userData, vehicle: widget.vehicle, fromSuggestionScreen: (widget.fromSuggestionMap! || widget.fromSuggestionScreen!),
          ),
        ])),

      ],
    );
  }

  void _checkPermission(Function onTap) async {
    LocationPermission permission = await Geolocator.checkPermission();
    if(permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if(permission == LocationPermission.denied) {
      showCustomSnackBar('you_have_to_allow'.tr);
    }else if(permission == LocationPermission.deniedForever) {
      Get.dialog(const PermissionDialogWidget());
    }else {
      onTap();
    }
  }
}

class _LocationAddressAppBar extends StatelessWidget implements PreferredSizeWidget {
  final TaxiLocationController controller;
  final GoogleMapController? mapController;
  const _LocationAddressAppBar({required this.controller, required this.mapController});

  @override
  Widget build(BuildContext context) {
    final Color textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
    final Color iconBg = Theme.of(context).disabledColor.withValues(alpha: 0.1);

    final bool isForm = controller.isFormSelected;
    final String text = isForm ? controller.formTextEditingController.text : controller.toTextEditingController.text;
    final String hint = isForm ? 'enter_pickup'.tr : 'enter_destination'.tr;
    final bool isEmpty = text.isEmpty;

    return AppBar(
      backgroundColor: Theme.of(context).cardColor,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      automaticallyImplyLeading: false,
      titleSpacing: 0,
      title: AbsorbPointer(
        absorbing: controller.isButtonClick,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: Dimensions.paddingSizeExtraSmall),
          child: LocationSearchDialogWidget(
            mapController: mapController,
            fullWidthBar: true,
            pickedLocation: isEmpty ? '' : text,
            leading: InkWell(
              onTap: () => Navigator.pop(context),
              borderRadius: BorderRadius.circular(40),
              child: Container(
                height: 40, width: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
                child: Icon(Icons.arrow_back, color: textColor, size: 20),
              ),
            ),
            onSelected: (suggestion) {
              controller.setLocationFromPlace(suggestion.placeId, suggestion.description, controller.isFormSelected, mapController);
            },
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(40),
                border: Border.all(color: Theme.of(context).disabledColor.withValues(alpha: 0.2), width: 1.5),
              ),
              child: Row(children: [

                const Icon(CupertinoIcons.placemark, size: 20),

                const SizedBox(width: Dimensions.paddingSizeSmall),

                Expanded(
                  child: Text(
                    isEmpty ? hint : text,
                    style: robotoRegular.copyWith(
                      color: isEmpty ? Theme.of(context).disabledColor : textColor,
                      fontSize: Dimensions.fontSizeDefault,
                    ),
                    maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.left,
                  ),
                ),

                isEmpty ? const SizedBox() : InkWell(
                  onTap: () {
                    controller.clearAddress(isForm);
                    controller.selectLocationType(isForm: isForm);
                    controller.updateLocationSuggestions(null);
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: SizedBox(
                    height: 30, width: 30,
                    child: Icon(Icons.close, size: 18, color: textColor),
                  ),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(60);
}