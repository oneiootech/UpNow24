import 'package:country_code_picker/country_code_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/enums/data_source_enum.dart';
import 'package:sixam_mart/common/models/config_model.dart';
import 'package:sixam_mart/common/widgets/custom_app_bar.dart';
import 'package:sixam_mart/common/widgets/custom_button.dart';
import 'package:sixam_mart/common/widgets/custom_ink_well.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';
import 'package:sixam_mart/common/widgets/custom_text_field.dart';
import 'package:sixam_mart/features/coupon/domain/models/coupon_model.dart' as coupon_lib;
import 'package:sixam_mart/features/coupon/widgets/coupon_card_widget.dart';
import 'package:sixam_mart/features/home/controllers/home_controller.dart';
import 'package:sixam_mart/features/language/controllers/language_controller.dart';
import 'package:sixam_mart/features/pro/controllers/pro_controller.dart';
import 'package:sixam_mart/features/pro/domain/models/pro_active_offer_model.dart';
import 'package:sixam_mart/features/pro/widgets/pro_coupon_benefit_banner_widget.dart';
import 'package:sixam_mart/features/profile/controllers/profile_controller.dart';
import 'package:sixam_mart/features/rental_module/rental_checkout_screen/widgets/rental_checkout_vehicle_card.dart';
import 'package:sixam_mart/features/rental_module/common/widgets/extra_discount_view_widget.dart';
import 'package:sixam_mart/features/rental_module/helper/taxi_price_helper.dart';
import 'package:sixam_mart/features/rental_module/home/controllers/taxi_home_controller.dart';
import 'package:sixam_mart/features/rental_module/rental_cart_screen/controllers/taxi_cart_controller.dart';
import 'package:sixam_mart/features/rental_module/rental_checkout_screen/widgets/checkout_terms_and_condition.dart';
import 'package:sixam_mart/features/rental_module/rental_location_screen/controller/taxi_location_controller.dart';
import 'package:sixam_mart/features/rental_module/widgets/bill_details_widget.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/helper/auth_helper.dart';
import 'package:sixam_mart/helper/custom_validator.dart';
import 'package:sixam_mart/helper/date_converter.dart';
import 'package:sixam_mart/helper/price_converter.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';

part 'widgets/coupon_bottom_sheet.dart';
part 'widgets/rental_coupon_card.dart';

class RentalCheckoutScreen extends StatefulWidget {
  final String? note;
  const RentalCheckoutScreen({super.key, this.note});

  @override
  State<RentalCheckoutScreen> createState() => _RentalCheckoutScreenState();
}

class _RentalCheckoutScreenState extends State<RentalCheckoutScreen> {
  TextEditingController couponTextController = TextEditingController();

  TextEditingController guestNameTextEditingController = TextEditingController();
  TextEditingController guestNumberTextEditingController = TextEditingController();
  TextEditingController guestEmailController = TextEditingController();
  FocusNode guestNameNode = FocusNode();
  FocusNode guestNumberNode = FocusNode();
  FocusNode guestEmailNode = FocusNode();
  String? countryDialCode = CountryCode.fromCountryCode(Get.find<SplashController>().configModel!.country!).dialCode ?? Get.find<LocalizationController>().locale.countryCode;
  double? _payableAmount = 0;
  bool _isCashBackSnackBarShown = false;

  @override
  void initState() {
    super.initState();
    Get.find<ProController>().getProActiveOffer(moduleType: Get.find<SplashController>().module?.moduleType);
  }

  // Rental has no delivery fee, so the Pro discount applies on the trip subtotal.
  double _calculateProDiscount(double amount, ProActiveBenefit? benefit) {
    if (benefit == null || benefit.type != ProBenefitType.discount || amount <= 0) return 0;
    final bool meetsMinOrder = benefit.minOrderStatus != true || amount >= (benefit.minOrderAmount ?? 0);
    if (!meetsMinOrder) return 0;
    double proDiscount = amount * ((benefit.percentage ?? 0) / 100);
    if (benefit.maxAmount != null && benefit.maxAmount! > 0 && proDiscount > benefit.maxAmount!) {
      proDiscount = benefit.maxAmount!;
    }
    if (proDiscount > amount) proDiscount = amount;
    return PriceConverter.toFixed(proDiscount);
  }

  @override
  void dispose() {
    couponTextController.dispose();
    guestNameTextEditingController.dispose();
    guestNumberTextEditingController.dispose();
    guestEmailController.dispose();
    guestNameNode.dispose();
    guestNumberNode.dispose();
    guestEmailNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: 'checkout'.tr),
      body: GetBuilder<TaxiCartController>(builder: (taxiCartController) {
        return GetBuilder<TaxiLocationController>(builder: (taxiLocationController) {

          String rentalType = taxiCartController.carCartModel!.userData!.rentalType!;

          double estimatedDay = 0;
          estimatedDay = (taxiCartController.carCartModel?.userData?.estimatedHours ?? 0) / 24;

          final ConfigModel? config = Get.find<SplashController>().configModel;
          final double estimatedDistance = taxiCartController.carCartModel?.userData?.distance ?? 0;

          int providerId = taxiCartController.cartList[0].provider!.id!;
          String schedule = taxiCartController.carCartModel!.userData!.pickupTime!;

          DateTime selectedTime = DateConverter.dateTimeStringToDate(schedule);
          String scheduleTime = DateConverter.formatDate(selectedTime);

          if(!DateConverter.isAfterCurrentDateTime(selectedTime)) {
            selectedTime = DateTime.now();
            scheduleTime = DateConverter.formatDate(DateTime.now());
          }
          bool isScheduled = !DateConverter.isSameDate(selectedTime);

          double tripCost = TaxiPriceHelper.calculateTripCost(taxiCartController.cartList, taxiCartController.carCartModel!.userData!);

          double productDiscountPrice = TaxiPriceHelper.calculateDiscountCost(taxiCartController.cartList, taxiCartController.carCartModel!.userData!, tripCost: tripCost, calculateProviderDiscount: false);
          double providerDiscountPrice = TaxiPriceHelper.calculateDiscountCost(taxiCartController.cartList, taxiCartController.carCartModel!.userData!, tripCost: tripCost, calculateProviderDiscount: true);
          double extraDiscount = TaxiPriceHelper.getExtraDiscountPrice(providerDiscountPrice, productDiscountPrice);
          double tripDiscount = TaxiPriceHelper.getDiscountPrice(providerDiscountPrice, productDiscountPrice, tripCost);

          double couponDiscount = taxiCartController.couponDiscount;
          double subtotal = tripCost - tripDiscount - couponDiscount;

          if(taxiCartController.isFirstTime){
            taxiCartController.getTripTax(tripAmount: subtotal, tripType: rentalType, providerId: providerId, couponCode: '', scheduleTime: scheduleTime, isSchedule: isScheduled);
          }

          final ProActiveBenefit? proBenefit = Get.find<ProController>().activeOfferModel?.benefit;
          final bool isPro = AuthHelper.isLoggedIn() && (Get.find<ProfileController>().userInfoModel?.proStatus ?? false);
          double proDiscount = isPro ? _calculateProDiscount(subtotal, proBenefit) : 0;

          double serviceFee = Get.find<SplashController>().configModel!.additionCharge??0;
          double total = subtotal + ((taxiCartController.taxIncluded == 1) ? 0 : taxiCartController.tripTax!) + serviceFee - proDiscount;

          if(!_isCashBackSnackBarShown && total > 0 && AuthHelper.isLoggedIn()) {
            _isCashBackSnackBarShown = true;
            _payableAmount = total;
            showCashBackSnackBar();
          }

          return Column(children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall),
                child: Column(children: [

                  //Selected Vehicle
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeLarge),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
                        border: Border.all(color: Theme.of(context).disabledColor.withValues(alpha: 0.2)),
                      ),
                      child: Column(children: [
                        Padding(
                          padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text('vehicle_info'.tr, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeDefault)),
                              const SizedBox(height: 2),
                              Text('selected_vehicle_for_your_trip'.tr, style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).disabledColor)),
                            ]),
                            CustomInkWell(
                              onTap: () => Get.back(),
                              radius: Dimensions.radiusSmall,
                              child: const Icon(Icons.mode_edit_outline_outlined, size: 24, color: Colors.blue,),
                            ),
                          ]),
                        ),
                        ListView.separated(
                          itemCount: taxiCartController.cartList.length,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          separatorBuilder: (context, index) => Divider(height: 1, color: Theme.of(context).disabledColor.withValues(alpha: 0.2)),
                          itemBuilder: (context, index) {
                            return RentalCheckoutVehicleCard(
                              cart: taxiCartController.cartList[index],
                              rentalType: rentalType,
                            );
                          },
                        ),
                      ]),
                    ),
                  ),

                  if(AuthHelper.isGuestLoggedIn())... [
                    const SizedBox(height: Dimensions.paddingSizeDefault),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeLarge),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                        border: Border.all(color: Theme.of(context).disabledColor.withValues(alpha: 0.2)),
                      ),
                      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('delivery_information'.tr, style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeDefault)),

                        const SizedBox(height: Dimensions.paddingSizeLarge),
                        CustomTextField(
                          labelText: 'contact_person_name'.tr,
                          titleText: 'write_name'.tr,
                          inputType: TextInputType.name,
                          controller: guestNameTextEditingController,
                          focusNode: guestNameNode,
                          nextFocus: guestNumberNode,
                          capitalization: TextCapitalization.words,
                          required: true,
                        ),
                        const SizedBox(height: Dimensions.paddingSizeLarge),

                        CustomTextField(
                          labelText: 'contact_person_number'.tr,
                          titleText: 'write_number'.tr,
                          controller: guestNumberTextEditingController,
                          focusNode: guestNumberNode,
                          nextFocus: guestEmailNode,
                          inputType: TextInputType.phone,
                          isPhone: true,
                          required: true,
                          onCountryChanged: (CountryCode countryCode) {
                            countryDialCode = countryCode.dialCode;
                          },
                          countryDialCode: CountryCode.fromCountryCode(Get.find<SplashController>().configModel!.country!).code ?? Get.find<LocalizationController>().locale.countryCode,
                        ),
                        const SizedBox(height: Dimensions.paddingSizeLarge),

                        CustomTextField(
                          titleText: 'enter_email'.tr,
                          labelText: 'email'.tr,
                          controller: guestEmailController,
                          focusNode: guestEmailNode,
                          inputAction: TextInputAction.done,
                          inputType: TextInputType.emailAddress,
                          prefixIcon: Icons.mail,
                          required: true,
                        ),
                        const SizedBox(height: Dimensions.paddingSizeLarge),
                      ]),
                    ),
                  ],
                  if(AuthHelper.isLoggedIn()) ... [
                    const SizedBox(height: Dimensions.paddingSizeDefault),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeLarge),
                      child: _RentalCouponCard(
                        taxiCartController: taxiCartController, couponTextController: couponTextController,
                        subtotal: subtotal, providerId: providerId, rentalType: rentalType,
                        scheduleTime: scheduleTime, isScheduled: isScheduled,
                      ),
                    ),
                  ],


                  //Pro coupon benefit hint — top of the billing summary, hidden once a coupon is applied.
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeLarge),
                    child: ProCouponBenefitBanner(couponApplied: couponDiscount > 0),
                  ),

                  //Bill Details
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall, horizontal: Dimensions.paddingSizeLarge),
                    child: BillDetailsWidget(
                      tripCost: tripCost, tripDiscountCost: tripDiscount, couponDiscountCost: couponDiscount,
                      subtotal: subtotal, vat: taxiCartController.tripTax!, serviceFee: serviceFee,
                      taxInclude: (taxiCartController.taxIncluded == 1), taxPercent: taxiCartController.cartList[0].provider!.tax,
                      proDiscount: proDiscount, couponType: taxiCartController.couponType,
                    ),
                  ),

                  //Terms & Condition
                  Container(height: 65,
                    margin: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall, left: Dimensions.paddingSizeLarge, right: Dimensions.paddingSizeLarge),
                    decoration: BoxDecoration(
                      color: Get.isDarkMode ? Theme.of(context).cardColor : const Color(0XFFFFFBEB),
                      borderRadius: BorderRadius.circular(Dimensions.radiusDefault)
                    ),
                    child: Padding(padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeLarge, vertical: Dimensions.paddingSizeSmall),
                      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      

                        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                          Text('by_placing_the_booking_you_are_agreed_to_the'.tr, style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall)),

                          InkWell(
                            onTap: (){
                              Get.bottomSheet(
                                const CheckoutTermsAndCondition(),
                                backgroundColor: Colors.transparent, isScrollControlled: true,
                              );
                            },
                            child: Text('terms_and_conditions'.tr, style: robotoMedium.copyWith(
                              fontSize: Dimensions.fontSizeSmall,
                              decoration: TextDecoration.underline,
                              decorationColor: Theme.of(context).textTheme.bodyLarge?.color,
                              decorationThickness: 1.5, // Adjust thickness
                              height: 1.5,
                            )),
                          )
                        ])
                      ]),
                    ),
                  ),
                ]),
              ),
            ),

            ExtraDiscountViewWidget(extraDiscount: extraDiscount),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeLarge, vertical: Dimensions.paddingSizeSmall),
              child: Column(children: [

                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text(
                    '${rentalType == AppConstants.dayWise ? 'duration'.tr : 'estimated'.tr} ${rentalType == AppConstants.distanceWise
                      ? estimatedDistance.toStringAsFixed(3)
                      : rentalType == AppConstants.dayWise ? estimatedDay.toStringAsFixed(0)
                      : taxiCartController.carCartModel?.userData?.estimatedHours??0}'
                      ' ${rentalType == AppConstants.distanceWise ? (config?.distanceUnitSuffix ?? 'km') : rentalType == AppConstants.dayWise ? 'day'.tr : 'hrs'.tr}',
                    style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeDefault),
                  ),

                  Text(PriceConverter.convertPrice(total), style: robotoBold.copyWith(fontSize: Dimensions.fontSizeExtraLarge)),
                ]),
                const SizedBox(height: Dimensions.paddingSizeSmall),

                SafeArea(
                  child: CustomButton(
                    buttonText: 'confirm_booking'.tr,
                    isLoading: taxiCartController.isLoading,
                    onPressed: () async {
                      String numberWithCountryCode = countryDialCode! + guestNumberTextEditingController.text;
                      PhoneValid phoneValid = await CustomValidator.isPhoneValid(numberWithCountryCode);
                      numberWithCountryCode = phoneValid.phone;

                      if(AuthHelper.isGuestLoggedIn() && guestNameTextEditingController.text.isEmpty) {
                        guestNameNode.requestFocus();
                        showCustomSnackBar('please_enter_contact_person_name'.tr);
                      } else if(AuthHelper.isGuestLoggedIn() && guestNumberTextEditingController.text.isEmpty) {
                        guestNumberNode.requestFocus();
                        showCustomSnackBar('please_enter_contact_person_number'.tr);
                      } else if(AuthHelper.isGuestLoggedIn() && !phoneValid.isValid) {
                        showCustomSnackBar('invalid_phone_number'.tr);
                      } else if (AuthHelper.isGuestLoggedIn() && guestEmailController.text.isEmpty) {
                        guestEmailNode.requestFocus();
                        showCustomSnackBar('please_enter_contact_person_email'.tr);
                      } else {
                        DateTime selectedTime = DateConverter.dateTimeStringToDate(schedule);
                        String scheduleTime = DateConverter.formatDate(selectedTime);

                        if(!DateConverter.isAfterCurrentDateTime(selectedTime)) {
                          selectedTime = DateTime.now();
                          scheduleTime = DateConverter.formatDate(DateTime.now());
                        }
                        bool isScheduled = !DateConverter.isSameDate(selectedTime);

                        taxiCartController.tripBook(
                          tripAmount: total, tripType: rentalType, providerId: providerId, note: widget.note ?? '',
                          guestName: guestNameTextEditingController.text, guestPhone: numberWithCountryCode,
                          guestEmail: guestEmailController.text, couponCode: taxiCartController.couponCode,
                          scheduleTime: scheduleTime, isSchedule: isScheduled,
                        );
                      }
                    },
                  ),
                ),
              ]),
            ),

          ]);
        });
      }),
    );
  }

  Future<void> showCashBackSnackBar() async {
    await Get.find<HomeController>().getCashBackData(_payableAmount!);
    double? cashBackAmount = Get.find<HomeController>().cashBackData?.cashbackAmount ?? 0;
    String? cashBackType = Get.find<HomeController>().cashBackData?.cashbackType ?? '';
    String text = '${'you_will_get'.tr} ${cashBackType == 'amount' ? PriceConverter.convertPrice(cashBackAmount) : '${cashBackAmount.toStringAsFixed(0)}%'} ${'cash_back_after_completing_order'.tr}';
    if(cashBackAmount > 0) {
      showCustomSnackBar(text, isError: false);
    }
  }
}