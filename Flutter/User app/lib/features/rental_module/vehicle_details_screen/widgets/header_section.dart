part of '../rental_vehicle_details_screen.dart';

class _HeaderSection extends StatefulWidget {
  const _HeaderSection({required this.vehicle, required this.isExistInCartPosition, required this.categories});

  final VehicleModel vehicle;
  final int isExistInCartPosition;
  final List<CategoryModel> categories;

  @override
  State<_HeaderSection> createState() => _HeaderSectionState();
}

class _HeaderSectionState extends State<_HeaderSection> {
  static const double _heroHeight = 325;

  int cartQuantity = 1;

  @override
  Widget build(BuildContext context) {
    final String image = (widget.vehicle.imagesFullUrl ?? const <String?>[]).whereType<String>()
        .firstWhere((e) => e.isNotEmpty, orElse: () => widget.vehicle.thumbnailFullUrl ?? '');

    return Column(children: [
      SizedBox(
        height: _heroHeight,
        width: double.infinity,
        child: Stack(children: [
          Positioned.fill(child: CustomImage(
            image: image, fit: BoxFit.cover,
            cacheWidth: ImageCacheHelper.widthPixels(context, null),
          )),
      
          Positioned(
            top: MediaQuery.of(context).padding.top + Dimensions.paddingSizeDefault,
            left: Dimensions.paddingSizeLarge,
            child: _CircleIconButton(icon: Icons.arrow_back, onTap: () => Get.back()),
          ),
      
          Positioned(
            top: MediaQuery.of(context).padding.top + Dimensions.paddingSizeDefault,
            right: Dimensions.paddingSizeLarge,
            child: Container(
              padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
              decoration: BoxDecoration(color: Theme.of(context).cardColor, shape: BoxShape.circle),
              child: TaxiAddFavouriteView(favIconSize: 20, vehicle: widget.vehicle),
            ),
          ),
      
          Positioned(
            top: MediaQuery.of(context).padding.top + Dimensions.paddingSizeDefault,
            right: 76,
            child: GetBuilder<TaxiCartController>(builder: (taxiCartController) {
              if(taxiCartController.cartList.isEmpty) return const SizedBox.shrink();
              return RantCartWidget(color: Theme.of(context).cardColor, callback: (value){
                if(widget.isExistInCartPosition != -1) {
                  setState(() {
                    cartQuantity = taxiCartController.getCartQuantity(widget.isExistInCartPosition);
                  });
                }
              });
            }),
          ),
      
          Positioned(
            right: Dimensions.paddingSizeLarge,
            bottom: Dimensions.paddingSizeLarge,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault, vertical: Dimensions.paddingSizeSmall),
              decoration: BoxDecoration(
                color: const Color(0xFF1FBC73),
                borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge),
              ),
              child: Text((widget.vehicle.status ?? 0) == 1 ? 'Available Now' : 'Unavailable', style: robotoMedium.copyWith(color: Colors.white, fontSize: Dimensions.fontSizeSmall)),
            ),
          ),
        ]),
      ),

      Container(
        color: Theme.of(context).cardColor,
        padding: const EdgeInsets.only(top: Dimensions.paddingSizeSmall, bottom: Dimensions.paddingSizeSmall),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
          child: Row(children: widget.categories.map((category) {
            return Container(
              margin: const EdgeInsets.only(right: Dimensions.paddingSizeSmall),
              padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall, vertical: Dimensions.paddingSizeExtraSmall),
              decoration: BoxDecoration(
                color: Theme.of(context).disabledColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Image.asset(category.icon, height: 14, width: 14, color: Theme.of(context).disabledColor),
                const SizedBox(width: Dimensions.paddingSizeExtraSmall),
                Text(category.name.toTitleCase(), style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).textTheme.bodyLarge!.color!.withValues(alpha: 0.75))),
              ]),
            );
          }).toList()),
        ),
      )
    ]);
  }
}


class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CircleIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(100),
      child: Container(
        padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
        decoration: BoxDecoration(color: Theme.of(context).cardColor, shape: BoxShape.circle),
        child: Icon(icon, color: Theme.of(context).textTheme.bodyLarge!.color, size: 20),
      ),
    );
  }
}

class _AppBarTab {
  final String label;
  final VoidCallback onTap;
  const _AppBarTab({required this.label, required this.onTap});
}

class _DetailsAppBar extends StatefulWidget {
  const _DetailsAppBar({required this.vehicle, required this.tabs, required this.selectedIndex, required this.isExistInCartPosition});
  final int isExistInCartPosition;
  final VehicleModel vehicle;
  final List<_AppBarTab> tabs;
  final int selectedIndex;

  @override
  State<_DetailsAppBar> createState() => _DetailsAppBarState();
}

class _DetailsAppBarState extends State<_DetailsAppBar> {
  late List<GlobalKey> _tabKeys = List<GlobalKey>.generate(widget.tabs.length, (_) => GlobalKey());
  int cartQuantity = 1;

  @override
  void didUpdateWidget(_DetailsAppBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if(oldWidget.tabs.length != widget.tabs.length) {
      _tabKeys = List<GlobalKey>.generate(widget.tabs.length, (_) => GlobalKey());
    }
    if(oldWidget.selectedIndex != widget.selectedIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _ensureSelectedTabVisible());
    }
  }

  void _ensureSelectedTabVisible() {
    if(widget.selectedIndex < 0 || widget.selectedIndex >= _tabKeys.length) return;
    final BuildContext? ctx = _tabKeys[widget.selectedIndex].currentContext;
    if(ctx == null) return;
    Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 250), curve: Curves.easeInOut, alignment: 0.5);
  }

  @override
  Widget build(BuildContext context) {
    final double topPadding = MediaQuery.of(context).padding.top;
    return Container(
      padding: EdgeInsets.only(top: topPadding),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [BoxShadow(color: Theme.of(context).disabledColor.withValues(alpha: 0.15), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(Dimensions.paddingSizeDefault, Dimensions.paddingSizeSmall, Dimensions.paddingSizeDefault, Dimensions.paddingSizeSmall),
          child: Row(children: [
            InkWell(
              onTap: () => Get.back(),
              borderRadius: BorderRadius.circular(22),
              child: Container(
                padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                decoration: BoxDecoration(color: Theme.of(context).disabledColor.withValues(alpha: 0.08), shape: BoxShape.circle),
                child: Icon(Icons.arrow_back, color: Theme.of(context).textTheme.bodyLarge!.color, size: 20),
              ),
            ),
            const SizedBox(width: Dimensions.paddingSizeDefault),

            Expanded(child: Text(
              widget.vehicle.name ?? '',
              style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge),
              maxLines: 1, overflow: TextOverflow.ellipsis,
            )),
            const SizedBox(width: Dimensions.paddingSizeSmall),

            GetBuilder<TaxiCartController>(builder: (taxiCartController) {
              if(taxiCartController.cartList.isEmpty) return const SizedBox.shrink();
              return RantCartWidget(callback: (value){
                if(widget.isExistInCartPosition != -1) {
                  setState(() {
                    cartQuantity = taxiCartController.getCartQuantity(widget.isExistInCartPosition);
                  });
                }
              });
            }),
            const SizedBox(width: Dimensions.paddingSizeDefault),

            Container(
              padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
              decoration: BoxDecoration(color: Theme.of(context).disabledColor.withValues(alpha: 0.08), shape: BoxShape.circle),
              child: TaxiAddFavouriteView(favIconSize: 20, vehicle: widget.vehicle),
            ),
          ]),
        ),

        if(widget.tabs.isNotEmpty)
          SizedBox(
            height: 38,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
              itemCount: widget.tabs.length,
              separatorBuilder: (_, _) => const SizedBox(width: Dimensions.paddingSizeSmall),
              itemBuilder: (_, i) {
                final _AppBarTab tab = widget.tabs[i];
                final bool isSelected = i == widget.selectedIndex;
                final Color primary = Theme.of(context).primaryColor;
                return InkWell(
                  key: _tabKeys[i],
                  onTap: tab.onTap,
                  child: IntrinsicWidth(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall),
                        child: Text(
                          tab.label,
                          textAlign: TextAlign.center,
                          style: robotoBold.copyWith(
                            fontSize: Dimensions.fontSizeDefault,
                            color: isSelected ? primary : Theme.of(context).textTheme.bodyLarge!.color!.withValues(alpha: 0.55),
                          ),
                        ),
                      ),
                      const Spacer(),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        height: 2,
                        margin: const EdgeInsets.fromLTRB(Dimensions.paddingSizeExtraSmall, 0, Dimensions.paddingSizeExtraSmall, 2),
                        decoration: BoxDecoration(
                          color: isSelected ? primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ]),
                  ),
                );
              },
            ),
          ),
      ]),
    );
  }
}
