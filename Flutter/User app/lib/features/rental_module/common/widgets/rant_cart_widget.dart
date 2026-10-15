import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/custom_ink_well.dart';
import 'package:sixam_mart/features/rental_module/rental_cart_screen/rental_cart_screen.dart';
import 'package:sixam_mart/features/rental_module/rental_cart_screen/controllers/taxi_cart_controller.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';
class RantCartWidget extends StatelessWidget {
  final bool? fromSelectVehicleScreen;
  final Function(bool)? callback;
  final Color ? color;
  const RantCartWidget({super.key, this.fromSelectVehicleScreen = false, this.callback, this.color});

  @override
  Widget build(BuildContext context) {
    return CustomInkWell(
      // `callback?.call` rather than `callback!`: three of this widget's call
      // sites (all_vehicle_screen, select_vehicle_screen, provider_detail_screen)
      // construct it without a callback, so the force-unwrap threw a null-check
      // error inside this `.then` whenever the cart route was closed from one of
      // them. It fires on removal as well as on a normal pop, so confirming a
      // booking — which now drops the cart route — would have hit it too.
      onTap: ()=> Get.to(()=> RentalCartScreen(fromSelectVehicleScreen: fromSelectVehicleScreen))!.then((value) {
        callback?.call(true);
      }),
      radius: 50,
      child: GetBuilder<TaxiCartController>(
        builder: (taxiCartController) {
          return Stack(clipBehavior: Clip.none, children: [

            Container(
              padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
              decoration: BoxDecoration(color: color ?? Theme.of(context).disabledColor.withValues(alpha: 0.08), shape: BoxShape.circle),
              child: Icon(Icons.directions_car_filled_outlined, size: 22, color: Theme.of(context).primaryColor,),
            ),

            taxiCartController.cartList.isNotEmpty ? Positioned(
              right: 0, top: -5,
              child: Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(color: Theme.of(context).primaryColor, shape: BoxShape.circle),
                child: Text("${taxiCartController.cartList.length}", style: robotoBold.copyWith(color: Colors.white, fontSize: Dimensions.fontSizeExtraSmall)),
              ),
            ) : const SizedBox(),
          ]);
        }
      ),
    );
  }
}
