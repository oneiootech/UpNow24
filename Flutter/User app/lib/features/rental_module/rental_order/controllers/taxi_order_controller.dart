import 'package:get/get.dart';
import 'package:sixam_mart/api/api_checker.dart';
import 'package:sixam_mart/api/api_client.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';
import 'package:sixam_mart/features/order/controllers/order_controller.dart';
import 'package:sixam_mart/features/profile/controllers/profile_controller.dart';
import 'package:sixam_mart/features/rental_module/common/models/trip_details_model.dart';
import 'package:sixam_mart/features/rental_module/common/models/trip_model.dart';
import 'package:sixam_mart/features/rental_module/rental_order/domain/services/taxi_order_service_interface.dart';
import 'package:sixam_mart/features/rental_module/rental_order/screens/taxi_payment_screen.dart';
import 'package:sixam_mart/helper/auth_helper.dart';

class TaxiOrderController extends GetxController implements GetxService {
  final TaxiOrderServiceInterface taxiOrderServiceInterface;

  TaxiOrderController({required this.taxiOrderServiceInterface});

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  TripModel? _tripModel;
  TripModel? get tripModel => _tripModel;

  TripModel? _tripHistoryModel;
  TripModel? get tripHistoryModel => _tripHistoryModel;

  TripDetailsModel? _tripDetailsModel;
  TripDetailsModel? get tripDetailsModel => _tripDetailsModel;

  int _paymentMethodIndex = -1;
  int get paymentMethodIndex => _paymentMethodIndex;

  String? _digitalPaymentName;
  String? get digitalPaymentName => _digitalPaymentName;

  // One-shot signal from a failed gateway return, cleared when the view is left.
  int? _failedPaymentTripId;
  int? get failedPaymentTripId => _failedPaymentTripId;

  void setFailedPaymentTrip(int? tripId, {bool willUpdate = true}) {
    _failedPaymentTripId = tripId;
    if(willUpdate) {
      update();
    }
  }

  void setPaymentMethod(int index, {bool isUpdate = true}) {
    _paymentMethodIndex = index;
    if(isUpdate){
      update();
    }
  }

  void changeDigitalPaymentName(String name, {bool willUpdate = true}){
    _digitalPaymentName = name;
    if(willUpdate) {
      update();
    }
  }

  Future<void> getTripList(int offset, {bool isUpdate = false, bool isRunning = true, bool fromHome = false}) async {
    if(offset == 1) {
      if(isRunning) {
        _tripModel = null;
      } else {
        if(!fromHome) {
          _tripHistoryModel = null;
        }
      }
      if(isUpdate) {
        update();
      }
    }
    TripModel? tripModel = await taxiOrderServiceInterface.getTripList(offset: offset, type: isRunning ? 'running' : 'completed');
    if (tripModel != null) {
      if (offset == 1) {
        if(isRunning) {
          _tripModel = tripModel;
        } else {
          _tripHistoryModel = tripModel;
        }
      }else {
        if(isRunning) {
          _tripModel!.totalSize = tripModel.totalSize;
          _tripModel!.offset = tripModel.offset;
          _tripModel!.trips!.addAll(tripModel.trips!);
        } else {
          _tripHistoryModel!.totalSize = tripModel.totalSize;
          _tripHistoryModel!.offset = tripModel.offset;
          _tripHistoryModel!.trips!.addAll(tripModel.trips!);
        }
      }
    }
    update();
  }

  void removeTripFromList(int? id) {
    if(id == null) return;
    _tripModel?.trips?.removeWhere((trip) => trip.id == id);
    _tripHistoryModel?.trips?.removeWhere((trip) => trip.id == id);
    update();
  }

  Future<bool> deleteTrip(int? id) async {
    if(id == null) return false;
    return await taxiOrderServiceInterface.deleteTrip(id: id);
  }

  Future<bool> getTripDetails(int id, {bool willUpdate = true, String? phone}) async {
    _isLoading = true;
    _tripDetailsModel = null;
    if(willUpdate) {
      update();
    }
    _tripDetailsModel = await taxiOrderServiceInterface.getTripDetails(id: id, phone: phone);

    _isLoading = false;
    update();
    return _tripDetailsModel != null;
  }

  Future<bool> cancelTrip({required int id}) async {
    _isLoading = true;
    update();
    bool success = await taxiOrderServiceInterface.cancelTrip(id: id);
    _isLoading = false;
    update();
    return success;
  }

  /// The gateway URL out of a trip-payment response.
  ///
  /// The endpoint used to answer with the bare URL string. It now returns
  /// `{"redirect_link": "https://…"}`, which `unwrapEnvelope` hands over as a
  /// Map — and passing that straight to [TaxiPaymentScreen.paymentUrl] threw
  /// `type '_Map<String, dynamic>' is not a subtype of type 'String?'` while the
  /// route was building. `.toString()` on it is no better: it yields
  /// `"{redirect_link: https://…}"`, a malformed URL that fails silently in the
  /// webview instead of crashing.
  ///
  /// A bare string is still accepted so a backend that has not moved keeps
  /// working, and the alternate key names are read because only `redirect_link`
  /// has been seen in the wild.
  static String? gatewayUrlOf(dynamic body) {
    if (body is String) {
      return body.trim().isEmpty ? null : body.trim();
    }
    if (body is Map) {
      for (final String key in const <String>['redirect_link', 'redirect_url', 'payment_url', 'url']) {
        final dynamic value = body[key];
        if (value is String && value.trim().isNotEmpty) {
          return value.trim();
        }
      }
    }
    return null;
  }

  /// Re-reads the dashboard's running-orders feed after a trip payment settles.
  ///
  /// That feed is `customer/order/all-running-orders`, and it lists **trips as
  /// well as mart orders** — so a trip that has just been paid keeps appearing
  /// in the running draggable sheet, still asking to be paid, until this is
  /// called. Nothing else refreshes it: the trip screen only re-reads its own
  /// details, and the sheet is otherwise loaded once when the dashboard opens.
  ///
  /// Safe to call after a failed or cancelled attempt too — it re-reads the real
  /// state rather than assuming an outcome.
  void refreshRunningOrders() {
    if (AuthHelper.isLoggedIn()) {
      Get.find<OrderController>().getDashboardOrders();
    }
  }

  Future<bool> makePayment({required int id, required String paymentMethod}) async {
    _isLoading = true;
    update();

    Response response = await taxiOrderServiceInterface.makeTripPayment(id: id, paymentMethod: paymentMethod, paymentGateWayName: _digitalPaymentName);
    // Paying creates a payment record, so accept any 2xx — the same guard
    // retryTripPayment uses against this endpoint.
    final bool isSuccess = ApiClient.isSuccessCode(response.statusCode);
    if(isSuccess && _paymentMethodIndex == 2) {
      final String? gatewayUrl = gatewayUrlOf(response.body);
      if(gatewayUrl != null) {
        Get.back();
        Get.to(()=> TaxiPaymentScreen(paymentUrl: gatewayUrl, orderId: id));
      } else {
        // A 2xx with no usable link is still a payment the user cannot complete.
        showCustomSnackBar('payment_failed'.tr);
      }
    }
    if(AuthHelper.isLoggedIn()) {
      Get.find<ProfileController>().getUserInfo();
    }
    _isLoading = false;
    update();
    return isSuccess && _paymentMethodIndex != 2;
  }

  /// Retries payment for a trip that reached the **shared** payment-failed flow
  /// (`customer/order/payment-failed` answers with `order_type: "trip"` for a
  /// rental booking).
  ///
  /// That flow retries through four different mart endpoints — `codSwitchUri`,
  /// `walletSwitchUri`, the mart payment route and the offline screen — all of
  /// which take an *order* id. Rental has a single endpoint,
  /// `POST rental/user/trip/payment`, keyed by `trip_id`, so the shared flow
  /// routes here instead of handing a trip id to a mart order endpoint.
  ///
  /// Kept separate from [makePayment] because that one keys its webview branch
  /// off this controller's own `_paymentMethodIndex`, which the shared flow never
  /// sets — [gatewayName] being non-null is the signal here instead.
  ///
  /// Returns true when the payment is settled and the caller should run its
  /// success redirect. A digital payment returns false: it opens the gateway
  /// webview, and [TaxiPaymentScreen] decides the outcome on its callback.
  Future<bool> retryTripPayment({required int tripId, required String paymentMethod, String? gatewayName}) async {
    _isLoading = true;
    update();

    final Response response = await taxiOrderServiceInterface.makeTripPayment(
      id: tripId, paymentMethod: paymentMethod, paymentGateWayName: gatewayName,
    );
    _isLoading = false;
    update();

    if (!ApiClient.isSuccessCode(response.statusCode)) {
      ApiChecker.checkApi(response);
      return false;
    }
    if (AuthHelper.isLoggedIn()) {
      Get.find<ProfileController>().getUserInfo();
    }
    if (gatewayName != null) {
      // Same shape as makePayment: the URL arrives as `{redirect_link: …}`, not
      // as a bare string — see [gatewayUrlOf].
      final String? gatewayUrl = gatewayUrlOf(response.body);
      if (gatewayUrl == null) {
        showCustomSnackBar('payment_failed'.tr);
        return false;
      }
      // Dismiss the sheet the retry was started from before opening the gateway.
      // On desktop that sheet is wrapped in a dialog, so both have to be checked.
      if ((Get.isBottomSheetOpen ?? false) || (Get.isDialogOpen ?? false)) {
        Get.back();
      }
      Get.to(() => TaxiPaymentScreen(paymentUrl: gatewayUrl, orderId: tripId));
      return false;
    }
    return true;
  }

  Future<bool> addVehicleReview({required int tripId, required int vehicleId, required int vehicleIdentityId, required int rating, required String comment}) async {
    _isLoading = true;
    update();
    bool success = await taxiOrderServiceInterface.addVehicleReview(tripId: tripId, vehicleId: vehicleId, vehicleIdentityId: vehicleIdentityId, rating: rating, comment: comment);
    _isLoading = false;
    update();
    return success;
  }

}