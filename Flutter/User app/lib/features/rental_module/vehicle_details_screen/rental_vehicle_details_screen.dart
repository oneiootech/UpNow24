import 'dart:developer';
import 'package:sixam_mart/helper/image_cache_helper.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/custom_button.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';
import 'package:sixam_mart/common/widgets/quantity_button.dart';
import 'package:sixam_mart/features/rental_module/rental_location_screen/rental_location_suggestion_screen.dart';
import 'package:sixam_mart/features/rental_module/common/widgets/vechicle_card_widget.dart';
import 'package:sixam_mart/features/rental_module/common/widgets/rant_cart_widget.dart';
import 'package:sixam_mart/features/rental_module/common/widgets/taxi_add_favourite_view.dart';
import 'package:sixam_mart/features/rental_module/home/controllers/taxi_home_controller.dart';
import 'package:sixam_mart/features/rental_module/home/domain/models/vehicle_details_model.dart';
import 'package:sixam_mart/features/rental_module/rental_cart_screen/controllers/taxi_cart_controller.dart';
import 'package:sixam_mart/features/rental_module/rental_cart_screen/domain/models/car_cart.dart';
import 'package:sixam_mart/features/rental_module/rental_location_screen/controller/taxi_location_controller.dart';
import 'package:sixam_mart/features/rental_module/vendor/controllers/taxi_vendor_controller.dart';
import 'package:sixam_mart/features/rental_module/vendor/domain/models/taxi_provider_review_model.dart' hide Provider;
import 'package:sixam_mart/features/rental_module/vendor/domain/models/taxi_vendor_model.dart';
import 'package:sixam_mart/features/rental_module/vendor/screens/provider_detail_screen.dart';
import 'package:sixam_mart/features/rental_module/widgets/taxi_shimmer_view.dart';
import 'package:sixam_mart/helper/date_converter.dart';
import 'package:sixam_mart/helper/price_converter.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/helper/string_extension.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:sixam_mart/common/models/config_model.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';

part 'widgets/bottom_cart_section.dart';
part 'widgets/header_section.dart';
part 'widgets/more_from_provider.dart';
part 'widgets/provider_info_section.dart';
part 'widgets/review_rating_section.dart';
part 'widgets/trip_type_section.dart';
part 'widgets/vehicle_info_section.dart';

class RentalVehicleDetailsScreen extends StatefulWidget {
  final int? vehicleId;
  final bool? fromSelectVehicleScreen;
  const RentalVehicleDetailsScreen({super.key, required this.vehicleId, this.fromSelectVehicleScreen = false});

  @override
  State<RentalVehicleDetailsScreen> createState() => _RentalVehicleDetailsScreenState();
}

class _RentalVehicleDetailsScreenState extends State<RentalVehicleDetailsScreen> {

  List<CategoryModel> _categoryList = [];
  int cartQuantity = 1;
  int isExistInCartPosition = -1;
  bool _tripTypeChosen = false;
  final ScrollController _scrollController = ScrollController();
  final ValueNotifier<bool> _showAppBar = ValueNotifier<bool>(false);
  final ValueNotifier<int> _selectedTabIndex = ValueNotifier<int>(0);
  final ValueNotifier<int> _tripTypePulse = ValueNotifier<int>(0);
  bool _reloading = false;
  bool _hasReviews = false;

  final GlobalKey _overviewKey = GlobalKey();
  final GlobalKey _tripTypeKey = GlobalKey();
  final GlobalKey _reviewsKey = GlobalKey();
  final GlobalKey _providerKey = GlobalKey();

  List<GlobalKey> get _sectionKeys => _hasReviews
      ? [_overviewKey, _tripTypeKey, _reviewsKey, _providerKey]
      : [_overviewKey, _tripTypeKey, _providerKey];

  double get _appBarBottomY => MediaQuery.of(context).padding.top + 110;

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _showAppBar.dispose();
    _selectedTabIndex.dispose();
    _tripTypePulse.dispose();
    super.dispose();
  }

  void _pulseTripType() {
    _scrollToKey(_tripTypeKey);
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _tripTypePulse.value = _tripTypePulse.value + 1;
    });
  }

  void _onScroll() {
    final bool shouldShow = _scrollController.offset > 260;
    if(shouldShow != _showAppBar.value) {
      _showAppBar.value = shouldShow;
    }
    _updateActiveTab();
  }

  void _updateActiveTab() {
    if(!mounted) return;
    final double threshold = _appBarBottomY + 16;
    int activeIndex = 0;
    double bestDy = -double.infinity;
    final List<GlobalKey> keys = _sectionKeys;
    for(int i = 0; i < keys.length; i++) {
      final BuildContext? ctx = keys[i].currentContext;
      if(ctx == null) continue;
      final RenderObject? ro = ctx.findRenderObject();
      if(ro is! RenderBox) continue;
      final double dy = ro.localToGlobal(Offset.zero).dy;
      if(dy <= threshold && dy > bestDy) {
        bestDy = dy;
        activeIndex = i;
      }
    }
    if(activeIndex != _selectedTabIndex.value) {
      _selectedTabIndex.value = activeIndex;
    }
  }

  void _loadData() {
    Get.find<TaxiHomeController>().getVehicleDetails(widget.vehicleId!).then((_) {
      final VehicleModel? vehicle = Get.find<TaxiHomeController>().vehicleDetailsModel;
      if(vehicle?.providerId != null) {
        final TaxiVendorController vendorController = Get.find<TaxiVendorController>();
        vendorController.getTaxiProviderReviewDetails(vehicle!.providerId!);
        vendorController.setCategoryId(null, canUpdate: false);
        vendorController.initFilterSetup(willUpdate: false);
        vendorController.getTaxiVendorDetails(vehicle.providerId!);
        vendorController.getVendorVehicleList(offset: 1, vendorId: vehicle.providerId!, searchName: '', canUpdate: false);
      }
    });
  }

  void _scrollToKey(GlobalKey key) {
    if(key == _overviewKey) {
      _scrollController.animateTo(0.0, duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
      return;
    }
    final BuildContext? ctx = key.currentContext;
    if(ctx == null) return;
    final RenderObject? ro = ctx.findRenderObject();
    if(ro is! RenderBox) return;
    final double position = ro.localToGlobal(Offset.zero).dy;
    final double maxExtent = _scrollController.position.maxScrollExtent;
    final double target = (_scrollController.offset + position - _appBarBottomY).clamp(0.0, maxExtent);
    _scrollController.animateTo(target, duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    if(!widget.fromSelectVehicleScreen!) {
      Get.find<TaxiLocationController>().initialSetup();
    }
    _loadData();
    isExistInCartPosition = Get.find<TaxiCartController>().isExistInCart(widget.vehicleId!);
    if(isExistInCartPosition != -1) {
      cartQuantity = Get.find<TaxiCartController>().getCartQuantity(isExistInCartPosition);
    }

  }

  void generateCategories(VehicleModel? vehicle) {
    _categoryList = [];
    if(vehicle != null) {
      if(vehicle.seatingCapacity != null) {
        _categoryList.add(CategoryModel(icon: Images.taxiSeatIcon, name: '${vehicle.seatingCapacity!} ${'seats'.tr}'));
      }
      if(vehicle.airCondition != null) {
        _categoryList.add(CategoryModel(icon: Images.taxiACIcon, name: vehicle.airCondition! ? 'ac'.tr : 'non_ac'.tr));
      }
      if(vehicle.transmissionType != null) {
        _categoryList.add(CategoryModel(icon: Images.taxiAutomaticIcon, name: vehicle.transmissionType!));
      }
      if(vehicle.type != null) {
        _categoryList.add(CategoryModel(icon: Images.taxiCarSideIcon, name: vehicle.type!));
      }
      if(vehicle.engineCapacity != null) {
        _categoryList.add(CategoryModel(icon: Images.taxiLiterIcon, name: '${vehicle.engineCapacity!}_L'));
      }
      if(vehicle.fuelType != null) {
        _categoryList.add(CategoryModel(icon: Images.taxiPetrolIcon, name: vehicle.fuelType!));
      }
    }
  }


  @override
  Widget build(BuildContext context) {

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.translucent,
      child: Scaffold(
      backgroundColor: Theme.of(context).disabledColor.withValues(alpha: 0.08),
      body: GetBuilder<TaxiHomeController>(
        builder: (taxiHomeController) {
          VehicleModel? vehicle = taxiHomeController.vehicleDetailsModel;
          generateCategories(vehicle);
          double discount = 0;
          String discountType = 'percent';
          int totalVehicles = 0;
          double hourlyDiscount = 0;
          double distanceWiseDiscount = 0;
          double dayWiseDiscount = 0;

          if(vehicle != null) {
            totalVehicles = vehicle.totalVehicles != 0 ? vehicle.totalVehicles! : 0;
            discount = vehicle.discountPrice ?? 0;
            discountType = vehicle.discountType ?? 'percent';

            distanceWiseDiscount = PriceConverter.calculation(vehicle.distancePrice ?? 0, discount, discountType, 1);
            hourlyDiscount = PriceConverter.calculation(vehicle.hourlyPrice ?? 0, discount, discountType, 1);
            dayWiseDiscount = PriceConverter.calculation(vehicle.dayWisePrice ?? 0, discount, discountType, 1);
          }

          final bool isOurVehicle = vehicle != null && vehicle.id == widget.vehicleId;
          final bool isTopRoute = ModalRoute.of(context)?.isCurrent ?? false;
          if(vehicle != null && !isOurVehicle && !_reloading && isTopRoute) {
            _reloading = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if(mounted) _loadData();
            });
          } else if(isOurVehicle && _reloading) {
            _reloading = false;
          }

          final bool hasReviews = vehicle != null &&
              ((vehicle.totalReviews ?? 0) > 0 || (vehicle.provider?.ratingCount ?? 0) > 0);
          if (hasReviews != _hasReviews) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() => _hasReviews = hasReviews);
            });
          }

          final List<_AppBarTab> tabs = vehicle == null ? const <_AppBarTab>[] : <_AppBarTab>[
            _AppBarTab(label: 'overview'.tr, onTap: () => _scrollToKey(_overviewKey)),
            _AppBarTab(label: 'trip_type'.tr, onTap: () => _scrollToKey(_tripTypeKey)),
            if (_hasReviews) _AppBarTab(label: 'reviews'.tr, onTap: () => _scrollToKey(_reviewsKey)),
            _AppBarTab(label: 'provider_info'.tr, onTap: () => _scrollToKey(_providerKey)),
          ];

          return isOurVehicle ? Stack(children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(
                child: CustomScrollView(controller: _scrollController, slivers: [

                  SliverToBoxAdapter(child: _HeaderSection(vehicle: vehicle, isExistInCartPosition: isExistInCartPosition, categories: _categoryList)),

                  SliverToBoxAdapter(child: Container(key: _overviewKey, child: _VehicleInfoSection(vehicle: vehicle, totalVehicles: totalVehicles))),

                  SliverToBoxAdapter(child: Container(key: _tripTypeKey, child: _TripTypeSection(
                    vehicle: vehicle, discountType: discountType, hourlyDiscount: hourlyDiscount, distanceWiseDiscount: distanceWiseDiscount, dayWiseDiscount: dayWiseDiscount,
                    tripTypeChosen: _tripTypeChosen,
                    onSelected: () { if(!_tripTypeChosen) setState(() => _tripTypeChosen = true); },
                    pulseListenable: _tripTypePulse,
                  ))),

                  if (_hasReviews)
                    SliverToBoxAdapter(
                      child: Container(key: _reviewsKey, child: _ReviewRatingSection(vehicle: vehicle, vehicleId: widget.vehicleId)),
                    ),

                  SliverToBoxAdapter(child: Container(key: _providerKey, child: _ProviderInfoSection(vehicle: vehicle))),
                  SliverToBoxAdapter(child: _MoreFromProvider(currentVehicleId: widget.vehicleId)),

                  const SliverToBoxAdapter(child: SizedBox(height: Dimensions.paddingSizeExtraLarge)),
                ]),
              ),

              _BottomCartSection(vehicle: vehicle, discount: discount, discountType: discountType,
              totalVehicles: totalVehicles, cartQuantity: cartQuantity, tripTypeChosen: _tripTypeChosen,
              onRequestTripType: _pulseTripType),
            ]),

            Positioned(top: 0, left: 0, right: 0, child: ValueListenableBuilder<bool>(
              valueListenable: _showAppBar,
              builder: (_, bool showAppBar, _) => IgnorePointer(
                ignoring: !showAppBar,
                child: AnimatedOpacity(
                  opacity: showAppBar ? 1 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: ValueListenableBuilder<int>(
                    valueListenable: _selectedTabIndex,
                    builder: (_, int selectedIndex, _) => _DetailsAppBar(vehicle: vehicle, tabs: tabs, selectedIndex: selectedIndex, isExistInCartPosition: isExistInCartPosition),
                  ),
                ),
              ),
            )),
          ]) : const Center(child: CircularProgressIndicator());
        }
      ),
    ));
  }
}

class _SmallCircleIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _SmallCircleIcon({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    final Widget circle = Container(
      height: 24, width: 24,
      decoration: BoxDecoration(color: Theme.of(context).disabledColor.withValues(alpha: 0.08), shape: BoxShape.circle),
      child: Icon(icon, size: 16),
    );
    return onTap != null
        ? InkWell(onTap: onTap, borderRadius: BorderRadius.circular(14), child: circle)
        : circle;
  }
}

class CategoryModel {
  String icon;
  String name;
  CategoryModel({required this.icon, required this.name});
}
