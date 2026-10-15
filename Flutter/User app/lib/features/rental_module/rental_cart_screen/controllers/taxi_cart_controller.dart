import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/api/api_checker.dart';
import 'package:sixam_mart/api/api_client.dart';
import 'package:sixam_mart/common/widgets/confirmation_dialog.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';
import 'package:sixam_mart/features/rental_module/common/models/taxi_coupon_model.dart';
import 'package:sixam_mart/features/rental_module/helper/cart_helper.dart';
import 'package:sixam_mart/features/rental_module/home/domain/models/vehicle_details_model.dart';
import 'package:sixam_mart/features/rental_module/rental_cart_screen/widgets/trip_vehicle_list_dialog.dart';
import 'package:sixam_mart/features/rental_module/rental_location_screen/controller/taxi_location_controller.dart';
import 'package:sixam_mart/features/rental_module/rental_cart_screen/domain/models/car_cart.dart';
import 'package:sixam_mart/features/rental_module/rental_cart_screen/domain/models/car_cart_model.dart';
import 'package:sixam_mart/features/rental_module/rental_cart_screen/domain/services/taxi_cart_service_interface.dart';
import 'package:sixam_mart/features/rental_module/rental_order/screens/taxi_order_details_screen.dart';
import 'package:sixam_mart/helper/price_converter.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/images.dart';

class TaxiCartController extends GetxController implements GetxService {
  final TaxiCartServiceInterface taxiCartServiceInterface;

  TaxiCartController({required this.taxiCartServiceInterface});

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isCouponLoading = false;
  bool get isCouponLoading => _isCouponLoading;

  CarCartModel? _carCartModel;
  CarCartModel? get carCartModel => _carCartModel;

  List<Carts> _cartList = [];
  List<Carts> get cartList => _cartList;

  double _couponDiscount = 0;
  double get couponDiscount => _couponDiscount;

  String _couponCode = '';
  String get couponCode => _couponCode;

  String _couponType = '';
  String get couponType => _couponType;

  String _tripType = 'distance_wise';
  String get tripType => _tripType;

  int? _reelId;
  void setReelOrderId(int? reelId) => _reelId = reelId;

  bool _isFirstTime = true;
  bool get isFirstTime => _isFirstTime;

  double? _tripTax = 0.0;
  double? get tripTax => _tripTax;

  int? _taxIncluded;
  int? get taxIncluded => _taxIncluded;

  void selectTripType(String type, {bool willUpdate = true}) {
    _tripType = type;
    if(willUpdate) {
      update();
    }
  }

  void removeCoupon({bool willUpdate = true}) {
    _couponDiscount = 0;
    _couponType = '';
    if(willUpdate) {
      update();
    }
  }

  Future<bool> addToCart(CarCart cart) async {
    _isLoading = true;
    bool success = false;
    update();

    if(_reelId != null) {
      cart.reelId = _reelId;
      _reelId = null;
    }
    CarCartModel? cartModel = await taxiCartServiceInterface.addToCart(cart);
    if(cartModel != null) {
      _cartList = [];
      _cartList.addAll(cartModel.carts??[]);
      _carCartModel = cartModel;
      success = true;
    }
    _isLoading = false;
    update();

    return success;
  }

  Future<bool> getCarCartList() async {
    _isLoading = true;
    bool success = false;
    // update();
    CarCartModel? cartModel = await taxiCartServiceInterface.getCartList();
    if(cartModel != null) {
      _cartList = [];
      _cartList.addAll(cartModel.carts??[]);
      _carCartModel = cartModel;
      success = true;
    }
    _isLoading = false;
    update();

    return success;
  }

  Future<bool> clearMultipleCart(List<int> ids) async {
    _isLoading = true;
    bool success = false;
    update();
    CarCartModel? cartModel = await taxiCartServiceInterface.clearMultipleTaxiCart(ids);
    if(cartModel != null) {
      _cartList = [];
      _cartList.addAll(cartModel.carts??[]);
      _carCartModel = cartModel;
      success = true;
    }
    _isLoading = false;
    update();

    return success;
  }

  int? getCartId(int cartIndex) {
    return taxiCartServiceInterface.getCartId(cartIndex, _cartList);
  }

  int isExistInCart(int? vehicleId) {
    return taxiCartServiceInterface.isExistInCart(_cartList, vehicleId);
  }

  int getCartQuantity(int cartIndex) {
    return _cartList[cartIndex].quantity??1;
  }


  Future<void> setQuantity(bool isIncrement, int cartIndex, {int? count, int? stock}) async {
    _isLoading = true;
    update();

    if(count != null) {
      _cartList[cartIndex].quantity = count;
    } else {
      _cartList[cartIndex].quantity = await taxiCartServiceInterface.decideCarQuantity(isIncrement, _cartList, cartIndex, stock);
    }

    CarCartModel? cartModel = await taxiCartServiceInterface.updateToCart(_cartList[cartIndex].id!, _cartList[cartIndex].quantity!);
    if(cartModel != null) {
      _cartList = [];
      _cartList.addAll(cartModel.carts??[]);
      _carCartModel = cartModel;
    }
    _isLoading = false;
    update();
  }

  Future<void> removeFromCart(int cartId) async {
    _isLoading = true;
    update();

    CarCartModel? cartModel = await taxiCartServiceInterface.removeFromCart(cartId);
    if(cartModel != null) {
      _cartList = [];
      _cartList.addAll(cartModel.carts??[]);
      _carCartModel = cartModel;
    }
    _isLoading = false;
    update();

  }

  Future<bool> clearTaxiCart({int? vehicleId, int? quantity, String? pickupTime, String? rentalType}) async {
    _isLoading = true;
    update();
    bool success = await taxiCartServiceInterface.clearTaxiCart(vehicleId: vehicleId, quantity: quantity, pickupTime: pickupTime, rentalType: rentalType);
    if(success) {
      _cartList = [];
    }
    _isLoading = false;
    update();
    return success;
  }

  Future<bool> updateUserData({required CarCart cart, required int userId}) async {
    _isLoading = true;
    update();

    Response response = await taxiCartServiceInterface.updateUserData(cart: cart, userId: userId);
    if(response.statusCode != 200) {
      ApiChecker.checkApi(response, getXSnackBar: true);
    }
    _isLoading = false;
    update();
    return (response.statusCode == 200);
  }

  Future<double?> applyTaxiCoupon(String coupon, double orderAmount, int? providerId) async {
    _isCouponLoading = true;
    _couponDiscount = 0;
    _couponType = '';
    update();
    TaxiCouponModel? taxiCouponModel = await taxiCartServiceInterface.applyTaxiCoupon(coupon, providerId);
    if (taxiCouponModel != null) {
      _couponCode = coupon;
      if (taxiCouponModel.minPurchase != null && taxiCouponModel.minPurchase! <= orderAmount) {
        if (taxiCouponModel.discountType == 'percent') {
          if (taxiCouponModel.maxDiscount != null && taxiCouponModel.maxDiscount! > 0) {
            _couponDiscount = (taxiCouponModel.discount! * orderAmount / 100) < taxiCouponModel.maxDiscount! ? (taxiCouponModel
                .discount! * orderAmount / 100) : taxiCouponModel.maxDiscount!;
          } else {
            _couponDiscount = taxiCouponModel.discount! * orderAmount / 100;
          }
        } else {
          _couponDiscount = taxiCouponModel.discount!;
        }
        _couponType = taxiCouponModel.couponType ?? '';
        print("-------------> cupone type: $_couponType");
        showCustomSnackBar('coupon_applied_successfully'.tr, isError: false);
      } else {
        showCustomSnackBar('${'need_minimum_purchase_is'.tr} ${PriceConverter.convertPrice(taxiCouponModel.minPurchase)}');
        _couponDiscount = 0.0;
        _couponCode = '';
      }
    }
    _isCouponLoading = false;
    update();
    return _couponDiscount;
  }


  Future<bool> tripBook({required double tripAmount, required String tripType, required int providerId, required String note, String? guestName, String? guestPhone, String? guestEmail, String? couponCode, required String scheduleTime, required bool isSchedule}) async {
    _isLoading = true;
    bool success = false;
    update();
    Response response = await taxiCartServiceInterface.tripBook(tripAmount: tripAmount, tripType: tripType, providerId: providerId, note: note, guestName: guestName, guestPhone: guestPhone, guestEmail: guestEmail, couponCode: couponCode, scheduleTime: scheduleTime, isSchedule: isSchedule);
    // Booking a trip CREATES one, so the API can answer 201 as well as 200 —
    // `== 200` would have reported a booked trip as a failure.
    if(ApiClient.isSuccessCode(response.statusCode)) {
      success = true;
      _couponDiscount = 0;
      _couponCode = '';
      getCarCartList();
      _isLoading = false;

      final int? tripId = _tripIdOf(response.body);
      if(tripId != null) {
        // `Get.off` replaced only the checkout screen, leaving the rental cart
        // directly beneath it. getCarCartList() above has just emptied that
        // cart (the trip is booked, so there is nothing left in it), so the
        // cart rebuilt into its "your cart is empty" state and was revealed for
        // the length of the transition — the customer saw an empty cart flash
        // between confirming the booking and the trip opening.
        //
        // Dropping the cart and checkout routes together means the details
        // screen lands on whatever preceded the cart instead. Nothing about
        // going back changes: TaxiOrderDetailsScreen is opened with
        // `fromCheckout: true`, and both its app-bar back button and its
        // PopScope already override back to `Get.offAllNamed(initial route)`,
        // so these two routes were unreachable from here either way.
        await Get.offUntil(
          GetPageRoute<dynamic>(
            page: () => TaxiOrderDetailsScreen(tripId: tripId, fromCheckout: true),
            routeName: '/TaxiOrderDetailsScreen',
            transitionDuration: const Duration(milliseconds: 100),
          ),
          _isRentalCartOrCheckoutRoute,
        );
      } else {
        // The trip is booked either way — never report failure here. Only the
        // jump to its detail screen is skipped, because we have no id to open.
        // The localized string is used rather than `response.statusText`, which
        // falls back to the bare HTTP reason phrase ("OK") when the envelope
        // carried no message.
        showCustomSnackBar('trip_booked_successfully'.tr, isError: false);
        Get.back();
      }
      Get.find<TaxiLocationController>().initialSetup();
    }
    _isLoading = false;
    update();

    return success;
  }

  /// Stop-condition for the `offUntil` above: keep every route except the
  /// rental cart and rental checkout, which are dropped so the just-emptied
  /// cart can't be revealed behind the incoming trip-details screen.
  ///
  /// The cart is reachable two different ways, so both name shapes are matched:
  ///
  ///  - anonymous `Get.to(() => RentalCartScreen(...))` (the cart widget, the
  ///    category screen, the location-confirm screen), which GetX names from the
  ///    builder's return type — `/RentalCartScreen Function()` — and is stable
  ///    across the `const` and argument-carrying constructors those use; and
  ///  - the named `RouteHelper.rentalCart` (`/rental-cart`) route, which the
  ///    vehicle-details bottom bar pushes via `Get.toNamed`.
  ///
  /// `route.isFirst` short-circuits first so the app's base route can never be
  /// stripped: if this flow is somehow reached with nothing but cart/checkout on
  /// the stack, the details screen still has something to sit on rather than
  /// leaving back-out-of-the-app as the only option.
  static bool _isRentalCartOrCheckoutRoute(Route<dynamic> route) {
    if (route.isFirst) {
      return true;
    }
    final String name = route.settings.name ?? '';
    return !name.contains('RentalCartScreen')
        && !name.contains('RentalCheckoutScreen')
        && name != RouteHelper.rentalCart;
  }

  /// The booked trip's id, or null when the response doesn't carry one.
  ///
  /// This used to be `int.parse(response.body.toString())`, which only worked
  /// while the endpoint answered with a bare id. Under the envelope the body is
  /// whatever `content` holds — an object for every other rental endpoint — so
  /// `int.parse` was handed something like `"{trip_id: 12}"` and threw
  /// FormatException *after* the trip had already been created: the checkout
  /// loader span forever and the user never saw their booking.
  ///
  /// Every shape the id has been seen in is accepted, so this keeps working
  /// against the legacy backend and against a `content` object either way.
  int? _tripIdOf(dynamic body) {
    if (body == null) return null;
    if (body is int) return body;
    if (body is num) return body.toInt();
    if (body is String) return int.tryParse(body.trim());
    if (body is Map) {
      for (final String key in const <String>['trip_id', 'id', 'tripId']) {
        final int? id = _tripIdOf(body[key]);
        if (id != null) return id;
      }
      // One level of nesting: {trip: {id}} / {data: {id}}.
      for (final String key in const <String>['trip', 'data']) {
        final dynamic nested = body[key];
        if (nested is Map) {
          final int? id = _tripIdOf(nested);
          if (id != null) return id;
        }
      }
    }
    return null;
  }

  Future<void> getTripTax({required double tripAmount, required String tripType, required int providerId, String? couponCode, required String scheduleTime, required bool isSchedule}) async {
    Response response = await taxiCartServiceInterface.getTripTax(tripAmount: tripAmount, tripType: tripType, providerId: providerId, couponCode: couponCode, scheduleTime: scheduleTime, isSchedule: isSchedule);
    if(response.statusCode == 200) {
      _isFirstTime = false;
      _tripTax = double.tryParse(response.body['tax_amount'].toString()) ?? 0.0;
      _taxIncluded = response.body['tax_included'];
    } else {
      _isFirstTime = false;
    }
    update();
  }

  void updateFirstTime() {
    _isFirstTime = true;
    update();
  }

  void decideAddToCart(TaxiCartController taxiCartController, CarCart cart, VehicleModel vehicle, {String? selectedLocationRentalType, int? cartIndex, bool? isIncrement}) {
    String vehicleRentalType = '';
    bool haveBothTripType = vehicle.tripHourly! && vehicle.tripDistance! && vehicle.tripDayWise!;
    UserData? userData = taxiCartController.carCartModel!.userData!;

    vehicleRentalType = _configureType(vehicle);

    bool isTrueForSameProviderVehicleType = !haveBothTripType && taxiCartController.cartList[0].providerId == vehicle.providerId && vehicleRentalType.isNotEmpty && taxiCartController.carCartModel!.userData!.rentalType != vehicleRentalType && selectedLocationRentalType == null;
    bool isTrueForSameProviderLocationType = taxiCartController.cartList[0].providerId == vehicle.providerId && selectedLocationRentalType != null && taxiCartController.carCartModel!.userData!.rentalType != selectedLocationRentalType;

    if(taxiCartController.cartList[0].providerId != vehicle.providerId) {
      vehicleRentalType = userData.rentalType!;

      bool containUserRentalType = _checkVehicleRentalType(vehicleRentalType, vehicle);
      if(!containUserRentalType) {
        vehicleRentalType = _configureType(vehicle);
      }

      if(vehicleRentalType == 'hourly' && cart.rentalType != 'hourly') {
        cart.estimatedHour = cart.destinationTime.toString();
      }
      cart.rentalType = vehicleRentalType;

      Get.dialog(ConfirmationDialog(
        icon: Images.warning,
        title: 'are_you_sure_to_reset'.tr,
        description: 'another_vendors_car_exist_in_your_cart'.tr,
        onYesPressed: () {
          Get.back();
          Get.find<TaxiCartController>().clearTaxiCart(
            vehicleId: vehicle.id,
            quantity: 1,
            pickupTime: userData.pickupTime,
            rentalType: vehicleRentalType,
          ).then((success) async {
            if(success) {
              taxiCartController.addToCart(cart);
            }
          });

        },
      ), barrierDismissible: false);
    } else if(isTrueForSameProviderVehicleType || isTrueForSameProviderLocationType) {

      if(isTrueForSameProviderVehicleType) {
        cart.rentalType = vehicleRentalType;
      } else if (isTrueForSameProviderLocationType) {
        cart.rentalType = selectedLocationRentalType;
      }
      Get.dialog(ConfirmationDialog(
        icon: Images.warning,
        title: 'do_you_want_to_change_trip_type'.tr,
        description: '${'are_you_sure_you_want_to_switch_from'.tr} ${taxiCartController.carCartModel!.userData!.rentalType?.tr} ${'based_to'.tr} ${cart.rentalType?.tr}.',
        onYesPressed: () async {
          Get.back();
          bool isCartExistType = await CartHelper.checkTypeInCart(taxiCartController.cartList, cart.rentalType!);

          String estimatedHour = userData.estimatedHours?.toString() ?? '1';
          if(userData.estimatedHours == 0) {
            estimatedHour = '1';
          }
          CarCart userInfo = CarCart(
            applyMethod: true, distance: userData.distance, destinationTime: userData.destinationTime,
            rentalType: cart.rentalType, estimatedHour: estimatedHour,
          );

          if(isCartExistType) {
            taxiCartController.updateUserData(cart: userInfo, userId: userData.id!).then((success) async {
              if(success) {
                if(cartIndex != null) {
                  taxiCartController.setQuantity(isIncrement!, cartIndex, stock: vehicle.vehicleIdentitiesCount);
                } else {
                  cart.estimatedHour = estimatedHour;
                  await taxiCartController.addToCart(cart);
                  await taxiCartController.getCarCartList();
                }
              }
            });
          } else {
            Future.delayed(const Duration(milliseconds: 200));
            Get.dialog(TripVehicleListDialog(
              rentalType: vehicleRentalType, cart: userInfo, userId: userData.id!, newVehicle: cart,
              cartIndex: cartIndex, isIncrement: isIncrement,
            ));
          }
        },
      ));
    } else if(selectedLocationRentalType == 'hourly' && selectedLocationRentalType == userData.rentalType && userData.estimatedHours != double.parse(Get.find<TaxiLocationController>().estimateTimeController.text)) {

      Get.dialog(ConfirmationDialog(
        icon: Images.warning,
        title: 'do_you_want_to_change_trip_duration'.tr,
        description: '${'are_you_sure_you_want_to_update_trip_duration_to'.tr} ${Get.find<TaxiLocationController>().estimateTimeController.text} ${'hours'.tr}',
        onYesPressed: () async {
          Get.back();
          CarCart userInfo = CarCart(
            applyMethod: true, distance: userData.distance, destinationTime: userData.destinationTime,
            rentalType: selectedLocationRentalType, estimatedHour: Get.find<TaxiLocationController>().estimateTimeController.text,
          );

          taxiCartController.updateUserData(cart: userInfo, userId: userData.id!).then((success) async {
            if(success) {
              taxiCartController.addToCart(cart);
            }
          });
        },
      ));
    }
    else {
      taxiCartController.addToCart(cart);
    }
  }

  bool _checkVehicleRentalType(String type, VehicleModel vehicle) {
    if(type == 'hourly') {
      return vehicle.tripHourly!;
    }else if(type == 'day_wise'){
      return vehicle.tripDayWise!;
    } else {
      return vehicle.tripDistance!;
    }
  }

  String _configureType(VehicleModel vehicle) {
    String type = '';
    if(vehicle.tripHourly!) {
      type = 'hourly';
    }else if(vehicle.tripDayWise!) {
      type = 'day_wise';
    }  else if(vehicle.tripDistance!) {
      type = 'distance_wise';
    }
    return type;
  }

}