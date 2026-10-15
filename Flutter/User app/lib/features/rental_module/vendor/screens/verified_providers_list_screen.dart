import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/custom_app_bar.dart';
import 'package:sixam_mart/common/widgets/no_data_screen.dart';
import 'package:sixam_mart/common/widgets/paginated_list_view.dart';
import 'package:sixam_mart/features/rental_module/vendor/controllers/verified_provider_controller.dart';
import 'package:sixam_mart/features/rental_module/vendor/domain/models/verified_provider_model.dart';
import 'package:sixam_mart/features/rental_module/vendor/widgets/verified_provider_card_widget.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

class VerifiedProvidersListScreen extends StatefulWidget {
  const VerifiedProvidersListScreen({super.key});

  @override
  State<VerifiedProvidersListScreen> createState() => _VerifiedProvidersListScreenState();
}

class _VerifiedProvidersListScreenState extends State<VerifiedProvidersListScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    Get.find<VerifiedProviderController>().getVerifiedProviders(1, reload: true, notify: false);
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
      appBar: CustomAppBar(title: 'verified_providers'.tr),
      // appBar: AppBar(
      //   leading: IconButton(
      //     icon: const Icon(Icons.arrow_back),
      //     onPressed: () => Get.back(),
      //     style: IconButton.styleFrom(
      //       backgroundColor: Theme.of(context).disabledColor.withValues(alpha: 0.2),
      //       shape: const OvalBorder(),
      //     ),
      //   ),
      //   title: Text('verified_providers'.tr, style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeLarge)),
      //   centerTitle: true,
      //   backgroundColor: Theme.of(context).cardColor,
      //   elevation: 0,
      // ),
      body: GetBuilder<VerifiedProviderController>(builder: (controller) {
        final VerifiedProviderResponse? response = controller.verifiedProviderResponse;

        if (response == null) {
          return const Center(child: CircularProgressIndicator());
        }
        final List<VerifiedProvider> providers = response.stores ?? [];
        if (providers.isEmpty) {
          return NoDataScreen(text: 'no_data_found'.tr, isNotScrollable: true);
        }

        return RefreshIndicator(
          onRefresh: () async {
            await controller.getVerifiedProviders(1, reload: true);
          },
          child: SingleChildScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(
              horizontal: Dimensions.paddingSizeDefault,
              vertical: Dimensions.paddingSizeDefault,
            ),
            child: PaginatedListView(
              scrollController: _scrollController,
              totalSize: response.totalSize,
              offset: int.tryParse(response.offset ?? '1'),
              onPaginate: (int? offset) async {
                if (offset != null) {
                  await controller.getVerifiedProviders(offset);
                }
              },
              itemView: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: providers.length,
                separatorBuilder: (_, _) => const SizedBox(height: Dimensions.paddingSizeDefault),
                itemBuilder: (context, index) {
                  return VerifiedProviderCardWidget(
                    provider: providers[index],
                    width: double.infinity,
                  );
                },
              ),
            ),
          ),
        );
      }),
    );
  }
}
