import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/confirmation_dialog.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';
import 'package:sixam_mart/features/order/domain/models/reorder_response_model.dart';
import 'package:sixam_mart/features/rental_module/home/domain/models/last_trip_model.dart';
import 'package:sixam_mart/features/rental_module/vendor/domain/models/verified_provider_model.dart';
import 'package:sixam_mart/features/rental_module/vendor/domain/services/verified_provider_service_interface.dart';
import 'package:sixam_mart/features/rental_module/rental_cart_screen/controllers/taxi_cart_controller.dart';
import 'package:sixam_mart/util/images.dart';

class VerifiedProviderController extends GetxController implements GetxService {
  final VerifiedProviderServiceInterface verifiedProviderServiceInterface;

  VerifiedProviderController({required this.verifiedProviderServiceInterface});

  VerifiedProviderResponse? _verifiedProviderResponse;
  VerifiedProviderResponse? get verifiedProviderResponse => _verifiedProviderResponse;

  List<LastTripModel>? _lastTrips;
  List<LastTripModel>? get lastTrips => _lastTrips;

  int? _reorderingTripId;
  int? get reorderingTripId => _reorderingTripId;

  final Set<int> _favouriteIds = <int>{};
  Set<int> get favouriteIds => _favouriteIds;

  Future<void> getVerifiedProviders(int offset, {bool reload = false, bool notify = true, int limit = 10}) async {
    if (reload || offset == 1) {
      _verifiedProviderResponse = null;
      if (notify) update();
    }
    final VerifiedProviderResponse? response = await verifiedProviderServiceInterface.getVerifiedProviders(
      offset: offset, limit: limit,
    );
    if (response != null) {
      if (offset == 1 || _verifiedProviderResponse == null) {
        _verifiedProviderResponse = response;
      } else {
        _verifiedProviderResponse!.totalSize = response.totalSize;
        _verifiedProviderResponse!.offset = response.offset;
        _verifiedProviderResponse!.stores!.addAll(response.stores ?? []);
      }
    }
    update();
  }

  Future<void> getLastTrips({bool reload = false, bool notify = true}) async {
    if (reload) {
      _lastTrips = null;
      if (notify) update();
    }
    final List<LastTripModel> response = await verifiedProviderServiceInterface.getLastTrips();
    _lastTrips = response;
    update();
  }

  bool isFavourite(int? id) {
    if (id == null) return false;
    return _favouriteIds.contains(id);
  }

  void toggleFavourite(int? id) {
    if (id == null) return;
    if (_favouriteIds.contains(id)) {
      _favouriteIds.remove(id);
    } else {
      _favouriteIds.add(id);
    }
    update();
  }

  Future<void> reorderTrip(int tripId) async {
    final bool hasItemsInCart = Get.isRegistered<TaxiCartController>() && Get.find<TaxiCartController>().cartList.isNotEmpty;

    if (hasItemsInCart) {
      Get.dialog(ConfirmationDialog(
        icon: Images.warning,
        title: 'reorder_trip'.tr,
        description: 'reordering_will_clear_your_current_cart_do_you_want_to_continue'.tr,
        onYesPressed: () {
          Get.back();
          _performReorder(tripId);
        },
      ), barrierDismissible: false);
    } else {
      _performReorder(tripId);
    }
  }

  String _buildReorderStatusMessage(ReorderResponseModel response) {
    final hasAdded = response.addedCount != null && response.addedCount! > 0;
    final hasUnavailable = response.unavailableItems != null && response.unavailableItems!.isNotEmpty;

    String unavailableLabel = '';
    if (hasUnavailable) {
      final List<String> names = response.unavailableItems!
          .map((item) => item.name ?? '')
          .where((name) => name.isNotEmpty)
          .toList();
      unavailableLabel = names.isNotEmpty ? names.join(', ') : '${response.unavailableItems!.length} ${'items'.tr}';
    }

    if (hasAdded && hasUnavailable) {
      return '${response.addedCount} ${'items_added_to_cart'.tr}, $unavailableLabel ${'items_unavailable'.tr}';
    } else if (hasAdded) {
      return '${response.addedCount} ${'items_added_to_cart'.tr}';
    } else if (hasUnavailable) {
      return 'items_unavailable'.tr;
    }

    return 'reorder_completed'.tr;
  }

  Future<void> _performReorder(int tripId) async {
    _reorderingTripId = tripId;
    update();

    try {
      final response = await verifiedProviderServiceInterface.reorderTrip(tripId: tripId);

      if (response.statusCode == 200) {
        final ReorderResponseModel reorderResponse = ReorderResponseModel.fromJson(response.body);
        showCustomSnackBar(_buildReorderStatusMessage(reorderResponse), isError: reorderResponse.unavailableItems?.isNotEmpty ?? false);
        await getLastTrips();
        if (Get.isRegistered<TaxiCartController>()) {
          await Get.find<TaxiCartController>().getCarCartList();
        }
      } else {
        showCustomSnackBar('repeat_order_is_currently_disabled'.tr);
      }
    } catch (e) {
      showCustomSnackBar('failed_to_reorder_trip'.tr);
    }

    _reorderingTripId = null;
    update();
  }
}
