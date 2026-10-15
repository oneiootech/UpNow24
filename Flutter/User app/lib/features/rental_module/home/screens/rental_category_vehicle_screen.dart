import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/custom_button.dart';
import 'package:sixam_mart/common/widgets/no_data_screen.dart';
import 'package:sixam_mart/common/widgets/paginated_list_view.dart';
import 'package:sixam_mart/features/rental_module/common/widgets/vechicle_card_widget.dart';
import 'package:sixam_mart/features/rental_module/common/widgets/vehicle_filter_widget.dart';
import 'package:sixam_mart/features/rental_module/home/controllers/taxi_home_controller.dart';
import 'package:sixam_mart/features/rental_module/home/domain/models/vehicle_category_model.dart';
import 'package:sixam_mart/features/rental_module/rental_cart_screen/controllers/taxi_cart_controller.dart';
import 'package:sixam_mart/features/rental_module/rental_cart_screen/rental_cart_screen.dart';
import 'package:sixam_mart/features/rental_module/rental_location_screen/controller/taxi_location_controller.dart';
import 'package:sixam_mart/features/rental_module/rental_location_screen/rental_location_suggestion_screen.dart';
import 'package:sixam_mart/features/rental_module/select_vehicle_screen/search_vehicle_screen.dart';
import 'package:sixam_mart/helper/address_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

class RentalCategoryVehicleScreen extends StatefulWidget {
  final int? categoryId;
  const RentalCategoryVehicleScreen({super.key, this.categoryId});

  @override
  State<RentalCategoryVehicleScreen> createState() => _RentalCategoryVehicleScreenState();
}

class _RentalCategoryVehicleScreenState extends State<RentalCategoryVehicleScreen> {
  String searchName = '';
  int? _selectedCategoryId;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _selectedCategoryId = widget.categoryId;
    Get.find<TaxiHomeController>().initFilterSetup(categoryId: widget.categoryId);
    Get.find<TaxiCartController>().getCarCartList();
    _initAndLoad();
  }

  Future<void> _initAndLoad() async {
    final locationController = Get.find<TaxiLocationController>();
    if (locationController.fromAddress == null) {
      final savedAddress = AddressHelper.getUserAddressFromSharedPref();
      if (savedAddress != null) {
        await locationController.getInitialLocation(savedAddress, null);
      } else {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Get.off(() => const RentalLocationSuggestionScreen());
        });
        return;
      }
    }
    Get.find<TaxiHomeController>().getSelectedCars(offset: 1, name: null);
  }

  void _onCategoryTabTap(int id) {
    setState(() {
      _selectedCategoryId = id;
      searchName = '';
    });
    final taxiHomeController = Get.find<TaxiHomeController>();
    taxiHomeController.initFilterSetup(categoryId: id);
    taxiHomeController.getSelectedCars(offset: 1, name: null);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).cardColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
          style: IconButton.styleFrom(
            backgroundColor: Theme.of(context).disabledColor.withValues(alpha: 0.2),
            shape: const OvalBorder(),
          ),
        ),
        title: Text('vehicle_categories'.tr, style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeLarge)),
        backgroundColor: Theme.of(context).cardColor,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),

      body: GetBuilder<TaxiHomeController>(
        builder: (taxiHomeController) {
          final List<Vehicles> categories = taxiHomeController.vehicleCategoryModel?.vehicles ?? [];
          return Column(children: [

            if (categories.isNotEmpty)
              _CategoryTabRow(
                categories: categories,
                selectedCategoryId: _selectedCategoryId,
                onCategoryTap: _onCategoryTabTap,
              ),

            Expanded(child: CustomScrollView(controller: _scrollController, slivers: [

              SliverPersistentHeader(
                pinned: true,
                delegate: _SliverDelegate(
                  height: searchName.isNotEmpty ? 88 : 48,
                  child: Container(
                    color: Theme.of(context).cardColor,
                    padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeLarge),
                    child: Column(children: [

                      if (searchName.isNotEmpty) ...[
                        const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                        taxiHomeController.selectedCarsModel != null ? Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                            color: Theme.of(context).colorScheme.surface,
                            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 4, offset: const Offset(0, 1))],
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall, vertical: Dimensions.paddingSizeExtraSmall),
                          child: Row(children: [
                             Expanded(
                              child: RichText(maxLines: 1, overflow: TextOverflow.ellipsis, text: TextSpan(children: [
                                TextSpan(text: '${taxiHomeController.selectedCarsModel?.totalSize ?? 0} ', style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).textTheme.bodyLarge!.color)),
                                TextSpan(text: 'result_found_for'.tr, style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).disabledColor)),
                                TextSpan(text: ' $searchName', style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).textTheme.bodyLarge!.color)),
                              ]))),
                            
                            InkWell(
                              onTap: () async {
                                setState(() { searchName = ''; });
                                await taxiHomeController.getSelectedCars(offset: 1, name: null);
                              },
                              child: Icon(Icons.close, size: Dimensions.fontSizeExtraLarge, color: Theme.of(context).disabledColor),
                            ),
                          ]),
                        ) : const SizedBox.shrink(),
                      ],

                      const SizedBox(height: Dimensions.paddingSizeSmall),

                      Row(children: [
                        taxiHomeController.selectedCarsModel != null ? Expanded(
                          child: Text(
                            '${taxiHomeController.selectedCarsModel?.totalSize ?? 0} ${'vehicle_found'.tr}',
                            style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeDefault),
                          ),
                        ) : const SizedBox.shrink(),
                        if (taxiHomeController.selectedCarsModel != null) ...[
                          _IconActionButton(
                            icon: Icons.search,
                            onTap: () {
                              Get.to(() => const SearchVehicleScreen())?.then((value) async {
                                if (value != null) {
                                  setState(() { searchName = value; });
                                  await taxiHomeController.getSelectedCars(offset: 1, name: searchName);
                                }
                              });
                            },
                          ),
                          const SizedBox(width: Dimensions.paddingSizeSmall),
                          _IconActionButton(
                            icon: Icons.tune,
                            onTap: () {
                              Get.bottomSheet(
                                VehicleFilterWidget(
                                  searchCarName: searchName,
                                  minPrice: taxiHomeController.selectedCarsModel?.minPrice ?? 0,
                                  maxPrice: taxiHomeController.selectedCarsModel?.maxPrice ?? 1000,
                                  tripType: taxiHomeController.tripType,
                                  fromCategory: true,
                                ),
                                backgroundColor: Colors.transparent, isScrollControlled: true,
                              );
                            },
                          ),
                        ],
                      ]),
                    ]),
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: taxiHomeController.selectedCarsModel != null
                  ? taxiHomeController.selectedCarsModel!.vehicles!.isNotEmpty
                    ? PaginatedListView(
                        scrollController: _scrollController,
                        totalSize: taxiHomeController.selectedCarsModel!.totalSize,
                        offset: taxiHomeController.selectedCarsModel!.offset,
                        onPaginate: (int? offset) async => taxiHomeController.getSelectedCars(offset: offset!, name: searchName),
                        itemView: ListView.separated(
                          scrollDirection: Axis.vertical,
                          itemCount: taxiHomeController.selectedCarsModel!.vehicles!.length,
                          padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeDefault, right: Dimensions.paddingSizeLarge, left: Dimensions.paddingSizeLarge),
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          separatorBuilder: (BuildContext context, int index) => const SizedBox(height: Dimensions.paddingSizeExtraLarge),
                          itemBuilder: (context, index) => VechicleCardWidget(vehicleModel: taxiHomeController.selectedCarsModel!.vehicles![index]),
                        ),
                      )
                    : NoDataScreen(text: 'no_vehicle_available'.tr)
                  : const Center(child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 100),
                      child: CircularProgressIndicator(),
                    )),
              ),

            ])),

            GetBuilder<TaxiCartController>(
              builder: (taxiCartController) {
                return taxiCartController.cartList.isNotEmpty ? Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    boxShadow: [BoxShadow(color: Theme.of(context).disabledColor.withValues(alpha: 0.5), blurRadius: 10)],
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeLarge, vertical: Dimensions.paddingSizeExtraSmall),
                  child: SafeArea(
                    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Text('${taxiCartController.cartList.length} ${'vehicle_selected'.tr}', style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeDefault, color: Theme.of(context).disabledColor)),
                      CustomButton(
                        buttonText: 'view_cart'.tr,
                        width: 100, height: 40,
                        onPressed: () => Get.to(() => const RentalCartScreen(fromSelectVehicleScreen: true)),
                      ),
                    ]),
                  ),
                ) : const SizedBox();
              },
            ),

          ]);
        },
      ),
    );
  }
}

class _CategoryTabRow extends StatefulWidget {
  final List<Vehicles> categories;
  final int? selectedCategoryId;
  final void Function(int id) onCategoryTap;
  const _CategoryTabRow({required this.categories, this.selectedCategoryId, required this.onCategoryTap});

  @override
  State<_CategoryTabRow> createState() => _CategoryTabRowState();
}

class _CategoryTabRowState extends State<_CategoryTabRow> {
  final ScrollController _scrollController = ScrollController();
  final Map<int, GlobalKey> _tabKeys = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToSelected());
  }

  @override
  void didUpdateWidget(_CategoryTabRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedCategoryId != widget.selectedCategoryId) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToSelected());
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToSelected() {
    if (widget.selectedCategoryId == null) return;
    final int index = widget.categories.indexWhere((c) => c.id == widget.selectedCategoryId);
    if (index < 0) return;
    final GlobalKey? key = _tabKeys[index];
    if (key?.currentContext != null) {
      Scrollable.ensureVisible(key!.currentContext!, alignment: 0.5, duration: const Duration(milliseconds: 300));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      color: Theme.of(context).cardColor,
      child: Column(children: [
        Expanded(
          child: ListView.separated(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
            itemCount: widget.categories.length,
            separatorBuilder: (_, _) => const SizedBox(width: Dimensions.paddingSizeLarge),
            itemBuilder: (context, index) {
              final GlobalKey tabKey = _tabKeys[index] ??= GlobalKey();
              final Vehicles cat = widget.categories[index];
              final bool isSelected = cat.id == widget.selectedCategoryId;
              return _CategoryTab(
                key: tabKey,
                name: cat.name ?? '',
                isSelected: isSelected,
                onTap: cat.id != null ? () => widget.onCategoryTap(cat.id!) : null,
              );
            },
          ),
        ),
        Divider(height: 1, thickness: 1, color: Theme.of(context).disabledColor.withValues(alpha: 0.15)),
      ]),
    );
  }
}

class _CategoryTab extends StatelessWidget {
  final String name;
  final bool isSelected;
  final VoidCallback? onTap;
  const _CategoryTab({super.key, required this.name, required this.isSelected, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? Theme.of(context).primaryColor : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          name,
          style: isSelected
            ? robotoMedium.copyWith(color: Theme.of(context).primaryColor, fontSize: Dimensions.fontSizeDefault)
            : robotoRegular.copyWith(color: Theme.of(context).disabledColor, fontSize: Dimensions.fontSizeDefault),
        ),
      ),
    );
  }
}

class _IconActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _IconActionButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Icon(icon, size: Dimensions.fontSizeOverLarge, color: Theme.of(context).disabledColor),
    );
  }
}

class _SliverDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double height;
  const _SliverDelegate({required this.child, this.height = 48});

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) => child;

  @override
  double get maxExtent => height;

  @override
  double get minExtent => height;

  @override
  bool shouldRebuild(_SliverDelegate oldDelegate) =>
    oldDelegate.height != height || oldDelegate.child != child;
}
