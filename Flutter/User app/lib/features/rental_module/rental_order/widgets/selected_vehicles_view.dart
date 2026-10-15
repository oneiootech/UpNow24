import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/models/config_model.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/common/widgets/custom_ink_well.dart';
import 'package:sixam_mart/features/rental_module/common/models/trip_details_model.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/helper/image_cache_helper.dart';
import 'package:sixam_mart/util/styles.dart';

const double _thumbInnerWidth = 64 - (3 * 2);
const double _singleThumbInnerWidth = 64 - (2 * 2);

class SelectedVehiclesView extends StatefulWidget {
  final List<TripDetails> tripDetailsList;
  final String? tripType;
  final double? estimatedHours;
  const SelectedVehiclesView({super.key, required this.tripDetailsList, this.tripType, this.estimatedHours});

  @override
  State<SelectedVehiclesView> createState() => _SelectedVehiclesViewState();
}

class _SelectedVehiclesViewState extends State<SelectedVehiclesView> {
  bool showCarList = false;

  @override
  Widget build(BuildContext context) {
    return Column(spacing: Dimensions.paddingSizeSmall, children: [
      if(widget.tripDetailsList.length > 2 && !showCarList)
        showMultipleView(context, widget.tripDetailsList),
    
      if(showCarList || widget.tripDetailsList.length <= 2)
      ListView.builder(
        scrollDirection: Axis.vertical,
        itemCount: widget.tripDetailsList.length,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        itemBuilder: (context, index) {
          return TripVehicleCard(tripDetails: widget.tripDetailsList[index], tripType: widget.tripType, estimatedHours: widget.estimatedHours);
        },
      ),
    
    ]);
  }

  Widget showMultipleView(BuildContext context, List<TripDetails> tripDetailsList) {
    return Row(children: [

      Stack(clipBehavior: Clip.none, children: [
        Container(
          height: 60, width: 64,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
            border: Border.all(color: Theme.of(context).cardColor, width: 3),
            boxShadow: [BoxShadow(color: Colors.grey.shade50.withValues(alpha: 1), blurRadius: 1, offset: const Offset(0.005, 0.005))],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
            child: CustomImage(
              image: tripDetailsList[0].vehicleDetails!.thumbnailFullUrl??'',
              cacheWidth: ImageCacheHelper.pixels(context, 64),
              cacheHeight: ImageCacheHelper.pixels(context, 60),
            ),
          ),
        ),

        Positioned(
          left: 40, top: 0, bottom: 0,
          child: Container(
            height: 60, width: 64,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
              border: Border.all(color: Theme.of(context).cardColor, width: 3),
              boxShadow: [BoxShadow(color: Colors.grey.shade50.withValues(alpha: 1), blurRadius: 1, offset: const Offset(0.005, 0.005))],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
              child: CustomImage(image: tripDetailsList[1].vehicleDetails!.thumbnailFullUrl??'', cacheWidth: ImageCacheHelper.pixels(context, _thumbInnerWidth)),
            ),
          ),
        ),

        Positioned(
          left: 80, top: 0, bottom: 0,
          child: Container(
            height: 60, width: 64,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
              border: Border.all(color: Theme.of(context).cardColor, width: 3),
              boxShadow: [BoxShadow(color: Colors.grey.shade50.withValues(alpha: 1), blurRadius: 1, offset: const Offset(0.005, 0.005))],
            ),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                  child: CustomImage(
                    image: tripDetailsList[2].vehicleDetails!.thumbnailFullUrl??'',
                    fit: BoxFit.cover, height: 60, width: 64,
                    cacheWidth: ImageCacheHelper.pixels(context, _thumbInnerWidth),
                  ),
                ),

                if(tripDetailsList.length > 3)
                  Positioned(
                    top: 0, right: 0, left: 0, bottom: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black45,
                        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                      ),
                      child: Center(child: Text('${tripDetailsList.length - 3}+', style: robotoBold.copyWith(color: Colors.white, fontSize: Dimensions.fontSizeExtraLarge),)),
                    ),
                  )
              ],
            ),
          ),
        ),
      ]),
      const Spacer(),

      Text(
        '${'total'.tr} ${tripDetailsList.length} ${'vehicle_selected'.tr}',
        style: robotoMedium.copyWith(color: Theme.of(context).textTheme.bodyLarge!.color!.withValues(alpha: 0.8)),
      ), 
      const SizedBox(width: Dimensions.paddingSizeSmall),
      widget.tripDetailsList.length > 2 ? CustomInkWell(
        onTap: () {
          setState(() {
            showCarList = !showCarList;
          });
        },
        child: Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(50), color: Theme.of(context).primaryColor),
          child: Icon(showCarList ? Icons.keyboard_arrow_up_sharp : Icons.keyboard_arrow_down, size: Dimensions.fontSizeExtraLarge, color: Theme.of(context).cardColor),
        ),
      ) : const SizedBox(),
    ]);
  }
}

class TripVehicleCard extends StatefulWidget {
  final TripDetails tripDetails;
  final String? tripType;
  final double? estimatedHours;
  const TripVehicleCard({super.key, required this.tripDetails, this.tripType, this.estimatedHours});

  @override
  State<TripVehicleCard> createState() => _TripVehicleCardState();
}

class _TripVehicleCardState extends State<TripVehicleCard> {
  bool showLicense = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
      child: Column(children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Vehicle Image
          Container(
            height: 60, width: 64,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
              border: Border.all(color: Theme.of(context).cardColor, width: 2),
              boxShadow: [BoxShadow(color: Colors.grey.shade50.withValues(alpha: 1), blurRadius: 1, offset: const Offset(0.005, 0.005))],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
              child: CustomImage(image: widget.tripDetails.vehicleDetails!.thumbnailFullUrl??'', cacheWidth: ImageCacheHelper.pixels(context, _singleThumbInnerWidth)),
            ),
          ),
          const SizedBox(width: Dimensions.paddingSizeDefault),

          // Vehicle Details
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Vehicle Name
              Text(
                widget.tripDetails.vehicleDetails!.name ?? '',
                style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              // Price and Duration (Dynamic based on trip type)
              Wrap(
                children: [
                  Text(
                    '\$${_getPrice()}',
                    style: robotoBold.copyWith(fontSize: Dimensions.fontSizeDefault),
                  ),
                  Text(
                    _getPriceUnit(),
                    style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).disabledColor),
                  ),
                ],
              ),
              const SizedBox(height: 2),

              // License Number
              widget.tripDetails.licensePlateNumber != null && widget.tripDetails.licensePlateNumber!.isNotEmpty ? Text(
                'License Number: ${widget.tripDetails.licensePlateNumber!.join('-') }',
                style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).disabledColor),
              ) : const SizedBox.shrink(),
            ]),
          ),

          // Quantity Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall, vertical: 6),
            decoration: BoxDecoration(
              color: Theme.of(context).disabledColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
            ),
            child: Text(
              'Qty : ${widget.tripDetails.quantity}',
              style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall),
            ),
          ),
        ]),
      ]),
    );
  }

  String _getPrice() {
    if(widget.tripType == 'hourly') {
      if(widget.tripDetails.vehicleDetails?.hourlyPrice != null && widget.tripDetails.vehicleDetails!.hourlyPrice != 0) {
        return widget.tripDetails.vehicleDetails!.hourlyPrice!.toStringAsFixed(2);
      }
    } else if(widget.tripType == 'distance_wise') {
      if(widget.tripDetails.vehicleDetails?.distancePrice != null && widget.tripDetails.vehicleDetails!.distancePrice != 0) {
        return widget.tripDetails.vehicleDetails!.distancePrice!.toStringAsFixed(2);
      }
    }
    return '0.00';
  }

  String _getPriceUnit() {
    if(widget.tripType == 'hourly') {
      return ' /${'hr'.tr}';
    } else if(widget.tripType == 'distance_wise') {
      final ConfigModel? config = Get.isRegistered<SplashController>()
          ? Get.find<SplashController>().configModel : null;
      return ' /${config?.distanceUnitSuffix ?? 'km'}';
    } else {
      return ' /${'unit'.tr}';
    }
  }
}

