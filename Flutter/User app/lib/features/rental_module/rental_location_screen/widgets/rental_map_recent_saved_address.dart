import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sixam_mart/common/widgets/custom_ink_well.dart';
import 'package:sixam_mart/features/address/controllers/address_controller.dart';
import 'package:sixam_mart/features/location/domain/models/prediction_model.dart';
import 'package:sixam_mart/features/rental_module/home/domain/models/vehicle_details_model.dart';
import 'package:sixam_mart/features/rental_module/rental_cart_screen/domain/models/car_cart_model.dart';
import 'package:sixam_mart/features/rental_module/rental_location_screen/controller/taxi_location_controller.dart';
import 'package:sixam_mart/features/rental_module/rental_location_screen/taxi_location_screen.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';

class RentalMapRecentSavedAddress extends StatefulWidget {
  final GoogleMapController? mapController;
  final UserData? userData;
  final VehicleModel? vehicle;
  const RentalMapRecentSavedAddress({super.key, this.mapController, this.userData, this.vehicle});

  @override
  State<RentalMapRecentSavedAddress> createState() => _RentalMapRecentSavedAddressState();
}

class _RentalMapRecentSavedAddressState extends State<RentalMapRecentSavedAddress> {
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {

    return SafeArea(
      child: GetBuilder<TaxiLocationController>(
        builder: (taxiLocationController) {
          if (taxiLocationController.locationSuggestions != null) {
            return Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
                child: _SuggestionsSection(
                  suggestions: taxiLocationController.locationSuggestions!,
                  query: taxiLocationController.isFormSelected
                      ? taxiLocationController.formTextEditingController.text
                      : taxiLocationController.toTextEditingController.text,
                  mapController: widget.mapController,
                  userData: widget.userData,
                  vehicle: widget.vehicle,
                ),
              ),
            );
          }
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, spacing: Dimensions.paddingSizeSmall, children: [
              CustomInkWell(
                onTap: () async {
                  if(widget.userData != null) {
                    Get.back();
                  } else {
                    final bool bothSelected = taxiLocationController.fromAddress != null && taxiLocationController.toAddress != null;
                    if (bothSelected) {
                      await taxiLocationController.clearAddress(taxiLocationController.isFormSelected);
                    }
                    Get.to(()=> TaxiLocationScreen(
                      userData: widget.userData, vehicle: widget.vehicle, fromSuggestionMap: true, fromSuggestionScreen: true,
                      fromAddress: taxiLocationController.isFormSelected ? null : taxiLocationController.fromAddress,
                      toAddress: taxiLocationController.isFormSelected ? taxiLocationController.toAddress : null,
                    ));
                  }
                },
                radius: Dimensions.radiusDefault,
                child: Container(
                  height: MediaQuery.of(context).size.height * 0.08,
                  padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
                    border: Border.all(color: Theme.of(context).disabledColor.withValues(alpha: 0.15)),
                  ),
                  child: Row(children: [
                    Icon(Icons.location_on_outlined, color: Theme.of(context).disabledColor, size: 22),
                    const SizedBox(width: Dimensions.paddingSizeSmall),
                    Text('set_on_map'.tr, style: robotoMedium),
                    const Spacer(),
                    const Icon(Icons.arrow_forward, size: 22),
                  ]),
                ),
              ),

              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                  margin: const EdgeInsets.only(bottom: Dimensions.paddingSizeDefault),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
                    border: Border.all(color: Theme.of(context).disabledColor.withValues(alpha: 0.15)),
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                    Builder(builder: (context) {
                      final bool hasRecent = taxiLocationController.historyAddress != null &&
                          taxiLocationController.historyAddress!.isNotEmpty;
                      final String tab0Content = hasRecent ? 'recent' : 'saved';
                      final String tab1Content = hasRecent ? 'saved' : 'recent';
                      return Row(children: [
                        _AddressTab(
                          label: tab0Content == 'recent' ? 'recent'.tr : 'saved'.tr,
                          isSelected: _selectedTab == 0,
                          onTap: () => setState(() => _selectedTab = 0),
                        ),
                        const SizedBox(width: Dimensions.paddingSizeSmall),
                        _AddressTab(
                          label: tab1Content == 'recent' ? 'recent'.tr : 'saved'.tr,
                          isSelected: _selectedTab == 1,
                          onTap: () => setState(() => _selectedTab = 1),
                        ),
                      ]);
                    }),

                    const SizedBox(height: Dimensions.paddingSizeSmall),
                    Expanded(
                      child: Builder(builder: (context) {
                        final bool hasRecent = taxiLocationController.historyAddress != null &&
                            taxiLocationController.historyAddress!.isNotEmpty;
                        final String selectedContent = _selectedTab == 0
                            ? (hasRecent ? 'recent' : 'saved')
                            : (hasRecent ? 'saved' : 'recent');

                        if (selectedContent == 'recent') {
                          if (taxiLocationController.historyAddress == null ||
                              taxiLocationController.historyAddress!.isEmpty) {
                            return _EmptyAddressState(message: 'no_recent_address_found'.tr);
                          }
                          return ListView.builder(
                            physics: const BouncingScrollPhysics(),
                            itemCount: taxiLocationController.historyAddress!.length.clamp(0, 10),
                            padding: EdgeInsets.zero,
                            itemBuilder: (context, index) {
                              return CustomInkWell(
                                onTap: () async {
                                  if(widget.userData != null) {
                                    Get.back();
                                  }
                                  await taxiLocationController.setSuggestionAddress(taxiLocationController.historyAddress![index], widget.mapController);
                                  if(taxiLocationController.fromAddress != null && taxiLocationController.toAddress != null) {
                                    taxiLocationController.updateCameraMovingStatus(false);
                                    Get.to(()=> TaxiLocationScreen(
                                      fromAddress: taxiLocationController.fromAddress, toAddress: taxiLocationController.toAddress,
                                      fromSuggestionScreen: widget.userData == null, userData: widget.userData, vehicle: widget.vehicle,
                                    ));
                                  }
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                                  child: Row(children: [
                                    Container(
                                      height: 26, width: 26,
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).disabledColor.withValues(alpha: 0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(Icons.location_on_outlined, color: Theme.of(context).disabledColor, size: 18),
                                    ),
                                    const SizedBox(width: Dimensions.paddingSizeSmall),
                                    Expanded(
                                      child: Text(
                                        taxiLocationController.historyAddress![index].address ?? '',
                                        maxLines: 1, overflow: TextOverflow.ellipsis,
                                        style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).textTheme.bodyLarge!.color!.withValues(alpha: 0.5)),
                                      ),
                                    ),
                                  ]),
                                ),
                              );
                            },
                          );
                        }

                        // Saved tab
                        return GetBuilder<AddressController>(
                          builder: (addressController) {
                            if (addressController.addressList == null || addressController.addressList!.isEmpty) {
                              return _EmptyAddressState(message: 'no_saved_address_found'.tr);
                            }
                            return ListView.builder(
                              physics: const BouncingScrollPhysics(),
                              itemCount: addressController.addressList!.length.clamp(0, 10),
                              padding: EdgeInsets.zero,
                              itemBuilder: (context, index) {
                                return CustomInkWell(
                                  onTap: () async {
                                    if(widget.userData != null) {
                                      Get.back();
                                    }
                                    await taxiLocationController.setSuggestionAddress(addressController.addressList![index], widget.mapController);
                                    if(taxiLocationController.fromAddress != null && taxiLocationController.toAddress != null) {
                                      taxiLocationController.updateCameraMovingStatus(false);
                                      Get.to(()=> TaxiLocationScreen(
                                        fromAddress: taxiLocationController.fromAddress, toAddress: taxiLocationController.toAddress,
                                        fromSuggestionScreen: widget.userData == null, userData: widget.userData, vehicle: widget.vehicle,
                                      ));
                                    }
                                  },
                                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                                  child: Row(children: [
                                    Container(
                                      height: 36, width: 36,
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).disabledColor.withValues(alpha: 0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Image.asset(
                                          addressController.addressList![index].addressType == 'home'
                                              ? Images.taxiHomeAddressIcon
                                              : addressController.addressList![index].addressType == 'office'
                                                  ? Images.taxiOfficeAddressIcon
                                                  : Images.taxiOtherAddressIcon,
                                          color: Theme.of(context).disabledColor,
                                          height: 18, width: 18,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: Dimensions.paddingSizeSmall),
                                    Expanded(
                                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                        Text(addressController.addressList![index].addressType?.tr ?? 'other'.tr,
                                            style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall)),
                                        Text(
                                          addressController.addressList![index].address ?? '',
                                          maxLines: 1, overflow: TextOverflow.ellipsis,
                                          style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).textTheme.bodyLarge!.color!.withValues(alpha: 0.5)),
                                        ),
                                      ]),
                                    ),
                                  ]),
                                );
                              },
                            );
                          },
                        );
                      }),
                    ),

                  ]),
                ),
              ),
            ]),
          );
        }
      ),
    );
  }
}

class _SuggestionsSection extends StatelessWidget {
  final List<PredictionModel> suggestions;
  final String query;
  final GoogleMapController? mapController;
  final UserData? userData;
  final VehicleModel? vehicle;
  const _SuggestionsSection({required this.suggestions, required this.query,
    this.mapController, this.userData, this.vehicle});

  @override
  Widget build(BuildContext context) {
    final BoxDecoration cardDecoration = BoxDecoration(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
      border: Border.all(color: Theme.of(context).disabledColor.withValues(alpha: 0.15)),
    );

    if (suggestions.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
        decoration: cardDecoration,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Text('suggestions'.tr, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeDefault)),
          const SizedBox(height: Dimensions.paddingSizeSmall),
          const SizedBox(
            height: 40,
            child: Center(child: SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))),
          ),
        ]),
      );
    }

    return Container(
      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
      decoration: cardDecoration,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        Text('suggestions'.tr, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeDefault)),
        const SizedBox(height: Dimensions.paddingSizeSmall),
        Expanded(
          child: ListView.builder(
            physics: const BouncingScrollPhysics(),
            itemCount: suggestions.length,
            padding: EdgeInsets.zero,
            itemBuilder: (context, index) => _SuggestionItem(
              suggestion: suggestions[index], query: query,
              mapController: mapController, userData: userData, vehicle: vehicle,
            ),
          ),
        ),
      ]),
    );
  }
}

class _SuggestionItem extends StatelessWidget {
  final PredictionModel suggestion;
  final String query;
  final GoogleMapController? mapController;
  final UserData? userData;
  final VehicleModel? vehicle;
  const _SuggestionItem({required this.suggestion, required this.query,
    this.mapController, this.userData, this.vehicle});

  @override
  Widget build(BuildContext context) {
    final taxiLocationController = Get.find<TaxiLocationController>();
    return CustomInkWell(
      onTap: () async {
        await taxiLocationController.setLocationFromPlace(
          suggestion.placeId, suggestion.description,
          taxiLocationController.isFormSelected, mapController,
        );
        taxiLocationController.updateLocationSuggestions(null);
        if(userData != null) {
          Get.back();
        }
        if(taxiLocationController.fromAddress != null && taxiLocationController.toAddress != null) {
          taxiLocationController.updateCameraMovingStatus(false);
          Get.to(() => TaxiLocationScreen(
            fromAddress: taxiLocationController.fromAddress, toAddress: taxiLocationController.toAddress,
            fromSuggestionScreen: userData == null, userData: userData, vehicle: vehicle,
          ));
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(children: [
          Container(
            height: 36, width: 36,
            decoration: BoxDecoration(
              color: Theme.of(context).disabledColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.location_on_outlined, color: Theme.of(context).disabledColor, size: 18),
          ),
          const SizedBox(width: Dimensions.paddingSizeSmall),
          Expanded(child: _buildHighlightedText(context, suggestion.description ?? '', query)),
        ]),
      ),
    );
  }

  Widget _buildHighlightedText(BuildContext context, String text, String query) {
    final baseStyle = robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).textTheme.bodyLarge!.color);
    final boldStyle = robotoBold.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).textTheme.bodyLarge!.color);

    if (query.isEmpty) return Text(text, maxLines: 1, overflow: TextOverflow.ellipsis, style: baseStyle);

    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    final matchIndex = lowerText.indexOf(lowerQuery);

    if (matchIndex == -1) return Text(text, maxLines: 1, overflow: TextOverflow.ellipsis, style: baseStyle);

    return RichText(
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(children: [
        if (matchIndex > 0) TextSpan(text: text.substring(0, matchIndex), style: baseStyle),
        TextSpan(text: text.substring(matchIndex, matchIndex + query.length), style: boldStyle),
        if (matchIndex + query.length < text.length) TextSpan(text: text.substring(matchIndex + query.length), style: baseStyle),
      ]),
    );
  }
}

class _EmptyAddressState extends StatelessWidget {
  final String message;
  const _EmptyAddressState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeExtraOverLarge),
      child: Center(
        child: Text(message, style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).disabledColor), textAlign: TextAlign.center),
      ),
    );
  }
}

class _AddressTab extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  const _AddressTab({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeLarge, vertical: Dimensions.paddingSizeSmall),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).primaryColor : Theme.of(context).disabledColor.withAlpha(100),
          borderRadius: BorderRadius.circular(50),
          
        ),
        child: Text(
          label,
          style: robotoMedium.copyWith(
            color: isSelected ? Colors.white : Theme.of(context).textTheme.bodyLarge?.color,
            fontSize: Dimensions.fontSizeSmall,
          ),
        ),
      ),
    );
  }
}
