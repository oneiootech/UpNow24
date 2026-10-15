import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/title_widget.dart';
import 'package:sixam_mart/features/address/controllers/address_controller.dart';
import 'package:sixam_mart/features/address/domain/models/address_model.dart';
import 'package:sixam_mart/features/category/domain/models/category_model.dart';
import 'package:sixam_mart/features/dashboard/widgets/category_section.dart';
import 'package:sixam_mart/features/dashboard/widgets/sliver_gap.dart';
import 'package:sixam_mart/features/order/controllers/order_controller.dart';
import 'package:sixam_mart/features/pro/controllers/pro_controller.dart';
import 'package:sixam_mart/features/pro/screens/subscription_plan_screen.dart';
import 'package:sixam_mart/features/pro/widgets/pro_plan_banner_widget.dart';
import 'package:sixam_mart/features/reels/controllers/reels_controller.dart';
import 'package:sixam_mart/features/reels/widgets/reels_section_widget.dart';
import 'package:sixam_mart/features/rental_module/common/widgets/vechicle_card_widget.dart';
import 'package:sixam_mart/features/rental_module/home/controllers/taxi_home_controller.dart';
import 'package:sixam_mart/features/rental_module/home/domain/models/vehicle_category_model.dart';
import 'package:sixam_mart/features/rental_module/home/domain/models/vehicle_details_model.dart';
import 'package:sixam_mart/features/rental_module/home/screens/rental_category_vehicle_screen.dart';
import 'package:sixam_mart/features/rental_module/home/widgets/banner_widget.dart';
import 'package:sixam_mart/features/rental_module/home/widgets/my_address_widget.dart';
import 'package:sixam_mart/features/rental_module/home/widgets/rental_last_trips_section_widget.dart';
import 'package:sixam_mart/features/rental_module/home/widgets/searchbar_widget.dart';
import 'package:sixam_mart/features/rental_module/home/widgets/verified_providers_section_widget.dart';
import 'package:sixam_mart/features/rental_module/rental_favourite/controllers/taxi_favourite_controller.dart';
import 'package:sixam_mart/features/rental_module/rental_location_screen/controller/taxi_location_controller.dart';
import 'package:sixam_mart/features/rental_module/rental_location_screen/rental_location_suggestion_screen.dart';
import 'package:sixam_mart/features/rental_module/rental_order/controllers/taxi_order_controller.dart';
import 'package:sixam_mart/features/rental_module/vendor/controllers/verified_provider_controller.dart';
import 'package:sixam_mart/features/rental_module/widgets/coupons_widget.dart';
import 'package:sixam_mart/features/rental_module/widgets/refer_and_earn_new.dart';
import 'package:sixam_mart/features/rental_module/widgets/taxi_shimmer_view.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/helper/auth_helper.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:sliver_tools/sliver_tools.dart';

class RentalModuleScreen extends StatefulWidget {
  /// Height of the search bar this screen pins itself, inside the scroll view.
  ///
  /// Unlike the store modules, rental does not hand [searchHeaderKey] to a
  /// [SearchAndQuickFilterWidget], so `MainScreen`'s shared pinned-search overlay
  /// never activates here and has no height to measure. `MainScreen` reads this
  /// constant instead, to keep the back-to-top button clear of the bar.
  static const double pinnedHeaderHeight = 70.0;

  final Key searchHeaderKey;
  final Key exploreRestaurantKey;
  const RentalModuleScreen({super.key, required this.searchHeaderKey, required this.exploreRestaurantKey});

  @override
  State<RentalModuleScreen> createState() => _RentalModuleScreenState();
}

class _RentalModuleScreenState extends State<RentalModuleScreen> {

  @override
  void initState() {
    super.initState();

    Get.find<TaxiHomeController>().getTaxiBannerList(false);
    Get.find<TaxiHomeController>().getTopRatedCarList(1, false);
    Get.find<TaxiHomeController>().getVehicleCategoryList();
    Get.find<ReelsController>().getReelsList(offset: 1);
    Get.find<VerifiedProviderController>().getVerifiedProviders(1, notify: false);
    if(_repeatOrderEnabled) {
      Get.find<VerifiedProviderController>().getLastTrips();
    }

    if (AuthHelper.isLoggedIn()) {
      Get.find<AddressController>().getAddressList();
      if(_repeatOrderEnabled) {
        Get.find<OrderController>().getLastOrders(reload: false, isHome: false);
      }
      Get.find<TaxiOrderController>().getTripList(1, isRunning: false, fromHome: true);
      Get.find<TaxiHomeController>().getTaxiCouponList(false);
      Get.find<TaxiFavouriteController>().getFavouriteTaxiList();
    }

    Get.find<TaxiLocationController>().getHistoryAddresses();
  }

  bool get _repeatOrderEnabled => Get.find<SplashController>().configModel?.repeatOrderOption == 1;

  @override
  Widget build(BuildContext context) {
    final bool isLoggedIn = AuthHelper.isLoggedIn();

    return MultiSliver(children: [

      sliverGepY(value: Dimensions.paddingSizeSmall),

      const SliverPersistentHeader(
        pinned: true,
        delegate: _RentalSearchBarDelegate(),
      ),

      sliverGepY(value: Dimensions.paddingSizeSmall),
      const SliverToBoxAdapter(child: _RentalRecentAddressChips()),

      // Each section below is paired with the gap that precedes it, so a section that
      // has nothing to show takes no vertical space either. Previously the gap was an
      // unconditional `sliverGepY` while only the section collapsed, which left a band
      // of empty space wherever a section was hidden.
      const _SectionSliver<TaxiHomeController>(
        gap: 0,
        visible: BannerWidget.hasContent,
        child: BannerWidget(),
      ),

      // browse by category
      _SectionSliver<TaxiHomeController>(
        gap: Dimensions.paddingSizeExtremeLarge,
        visible: _hasVehicleCategories,
        child: GetBuilder<TaxiHomeController>(builder: (taxiHomeController) {
          // Still loading. `_hasVehicleCategories` has already reserved the slot,
          // so returning nothing here left a blank band where the strip will be —
          // the shared category shimmer fills it with the real cell geometry.
          if (taxiHomeController.vehicleCategoryModel == null) {
            return Column(children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
                child: TitleWidget(title: 'browse_by_categories'.tr),
              ),
              const SizedBox(height: Dimensions.paddingSizeDefault),
              const CategoryShimmer(asList: true),
            ]);
          }
          final List<CategoryModel> categories = taxiHomeController.vehicleCategoryModel?.vehicles?.map((vehicle) {
            return CategoryModel(
              id: vehicle.id,
              name: vehicle.name,
              imageFullUrl: vehicle.imageFullUrl,
            );
          }).toList() ?? [];
          return categories.isNotEmpty ? Column(children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault), 
              child: TitleWidget(title: 'browse_by_categories'.tr),
            ),
            const SizedBox(height: Dimensions.paddingSizeDefault),
            CategoryGridWidget(
              categories: categories, asList: true,
              onCategoryTap: (category) => Get.to(() => RentalCategoryVehicleScreen(categoryId: category.id)),
            ),
          ]) : const SizedBox();
        }),
      ),

      // pro plan banner — only for a pro-enabled install
      if(Get.find<SplashController>().proStaus) ...[
        sliverGepY(value: Dimensions.paddingSizeLarge),
        const SliverToBoxAdapter(child: _RentalProPlanBanner()),
      ],

      // Section: last trips — repeating a trip is all it offers, so it goes with it.
      if(_repeatOrderEnabled) const _SectionSliver<VerifiedProviderController>(
        gap: Dimensions.paddingSizeLarge,
        visible: RentalLastTripsSectionWidget.hasContent,
        child: RentalLastTripsSectionWidget(),
      ),

      // Add Address
      if(isLoggedIn && MyAddressWidget.hasContent()) ...[
        sliverGepY(value: Dimensions.paddingSizeDefault),
        const SliverToBoxAdapter(child: MyAddressWidget()),
      ],

      const _SectionSliver<ReelsController>(
        gap: Dimensions.paddingSizeDefault,
        visible: _hasReels,
        child: ReelsSectionWidget(),
      ),

      // Top rated vehicles
      _SectionSliver<TaxiHomeController>(
        gap: Dimensions.paddingSizeDefault,
        visible: _hasTopRatedVehicles,
        child: Container(
          color: Theme.of(context).scaffoldBackgroundColor,
          padding: const EdgeInsets.only(top: Dimensions.paddingSizeLarge),
          child: GetBuilder<TaxiHomeController>(builder: (taxiHomeController) {
            return taxiHomeController.topRatedCarsModel != null && taxiHomeController.topRatedCarsModel!.vehicles != null
              ? taxiHomeController.topRatedCarsModel!.vehicles!.where((vehicle) => vehicle.status == 1).isNotEmpty
              ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('discover_local_favorites'.tr, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge)),
                      const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                      Text(
                        'most_trusted_vehicles_chosen_by_thousands_of_users'.tr,
                        style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).hintColor),
                      ),
                    ]),
                  ),
                  const SizedBox(height: Dimensions.paddingSizeDefault),

                  // Shared with the loading state so the rail cannot change height
                  // when the vehicles arrive.
                  SizedBox(height: TopRatedVehicleShimmerView.railHeight, child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: taxiHomeController.topRatedCarsModel!.vehicles!.length,
                    padding: const EdgeInsets.only(left: 16),
                    physics: const BouncingScrollPhysics(),
                    itemBuilder: (context, index) {
                      if(taxiHomeController.topRatedCarsModel!.vehicles![index].status != 1) {
                        return const SizedBox();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(right: Dimensions.paddingSizeDefault),
                        child: VechicleCardWidget(vehicleModel: taxiHomeController.topRatedCarsModel!.vehicles![index]),
                      );
                    },
                  )),
                ]) : const SizedBox() : const TopRatedVehicleShimmerView();}),
        ),
      ),

      const _SectionSliver<VerifiedProviderController>(
        gap: Dimensions.paddingSizeLarge,
        visible: VerifiedProvidersSectionWidget.hasContent,
        child: VerifiedProvidersSectionWidget(),
      ),

      if(isLoggedIn) const _SectionSliver<TaxiHomeController>(
        gap: Dimensions.paddingSizeSmall,
        visible: CouponWidget.hasContent,
        child: CouponWidget(),
      ),

      sliverGepY(value: Dimensions.paddingSizeSmall),
      const SliverToBoxAdapter(child: ReferAndEarnCard()),

    ]);
  }

  /// Mirrors the browse-by-category section's own condition.
  static bool _hasVehicleCategories(TaxiHomeController controller) {
    return controller.vehicleCategoryModel == null
        || (controller.vehicleCategoryModel!.vehicles ?? const <Vehicles>[]).isNotEmpty;
  }

  /// Mirrors the top-rated section's own condition, including the `status == 1` filter
  /// it applies before deciding whether to draw.
  static bool _hasTopRatedVehicles(TaxiHomeController controller) {
    final List<VehicleModel>? vehicles = controller.topRatedCarsModel?.vehicles;
    if (vehicles == null) {
      return true; // still loading — the shimmer needs the slot
    }
    return vehicles.any((VehicleModel vehicle) => vehicle.status == 1);
  }

  /// Mirrors ReelsSectionWidget's own condition; it is shared, so it cannot carry this.
  static bool _hasReels(ReelsController controller) {
    if (controller.reelsList == null) {
      return controller.isLoading; // shimmer only while the first load is in flight
    }
    return controller.reelsList!.isNotEmpty;
  }
}

/// A section paired with the gap that precedes it.
///
/// Renders `gap + child` when [visible] says the section will draw, and nothing at all
/// otherwise, so a hidden section leaves no empty band behind. The predicate runs inside
/// this sliver's own [GetBuilder], so only this section rebuilds when its data arrives.
class _SectionSliver<T extends GetxController> extends StatelessWidget {
  final double gap;
  final bool Function(T controller) visible;
  final Widget child;

  const _SectionSliver({required this.gap, required this.visible, required this.child});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: GetBuilder<T>(builder: (T controller) {
        if (!visible(controller)) {
          return const SizedBox.shrink();
        }
        return Column(children: [
          if (gap > 0) SizedBox(height: gap),
          child,
        ]);
      }),
    );
  }
}

class _RentalProPlanBanner extends StatelessWidget {
  const _RentalProPlanBanner();

  @override
  Widget build(BuildContext context) {
    if (!Get.find<SplashController>().proStaus) return const SizedBox();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
      child: ProPlanBannerWidget(
        onSubscribe: () {
          // Rental home lives on the dashboard's home tab (active module = rental), so save that
          // route to redirect back here after subscribing instead of relying on Get.currentRoute.
          Get.find<ProController>().saveCurrentPath(route: RouteHelper.getMainRoute('home'));
          SubscriptionPlanScreen.open();
        },
      ),
    );
  }
}

class _RentalRecentAddressChips extends StatelessWidget {
  const _RentalRecentAddressChips();

  @override
  Widget build(BuildContext context) {
    return GetBuilder<TaxiLocationController>(builder: (locationController) {
      final List<AddressModel> addresses = locationController.historyAddress ?? [];
      if (addresses.isEmpty) return const SizedBox.shrink();

      return SizedBox(
        height: 36,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
          itemCount: addresses.length,
          separatorBuilder: (_, _) => const SizedBox(width: Dimensions.paddingSizeSmall),
          itemBuilder: (context, index) => _RentalAddressChip(address: addresses[index]),
        ),
      );
    });
  }
}

class _RentalAddressChip extends StatelessWidget {
  final AddressModel address;
  const _RentalAddressChip({required this.address});

  IconData get _icon {
    switch (address.addressType?.toLowerCase()) {
      case 'home': return Icons.home_rounded;
      case 'office': return Icons.work_rounded;
      default: return Icons.location_on_rounded;
    }
  }

  String get _shortLabel {
    final String raw = (address.address ?? '').trim();
    if(raw.isEmpty) return '';
    return raw.split(',').first.trim();
  }


  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Get.to(() => RentalLocationSuggestionScreen(toAddress: address)),
      borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
          border: Border.all(color: Theme.of(context).disabledColor.withValues(alpha: 0.2)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(_icon, size: 14, color: Theme.of(context).disabledColor),
          const SizedBox(width: 4),
          Text(
            _shortLabel,
            style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ]),
      ),
    );
  }
}

class _RentalSearchBarDelegate extends SliverPersistentHeaderDelegate {
  const _RentalSearchBarDelegate();

  // top(10) + searchbar(50) + bottom(10) = 70
  static const double _height = RentalModuleScreen.pinnedHeaderHeight;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Theme.of(context).cardColor,
      padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall),
      child: const SearchbarWidget(),
    );
  }

  @override double get maxExtent => _height;
  @override double get minExtent => _height;
  @override bool shouldRebuild(_RentalSearchBarDelegate old) => false;
}

// SUMMARY
// Rental module home. Stacks the pinned search bar, recent address chips, banners,
// vehicle categories, the pro banner, last trips, saved addresses, reels, top rated
// vehicles, verified providers, coupons and refer-and-earn — each section collapsing
// with its own gap when it has nothing to show or its feature is switched off.
