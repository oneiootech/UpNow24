part of '../rental_vehicle_details_screen.dart';

class _ReviewRatingSection extends StatefulWidget {
  const _ReviewRatingSection({required this.vehicle, required this.vehicleId});

  final VehicleModel vehicle;
  final int? vehicleId;

  @override
  State<_ReviewRatingSection> createState() => _ReviewRatingSectionState();
}

class _ReviewRatingSectionState extends State<_ReviewRatingSection> {
  bool _expanded = true;

  void _showAllReviews(BuildContext context, List<Reviews> reviews) {
    FocusScope.of(context).unfocus();
    final DraggableScrollableController sheetController = DraggableScrollableController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      sheetAnimationStyle: const AnimationStyle(
        curve: Curves.fastOutSlowIn,
        duration: Duration(milliseconds: 400),
        reverseCurve: Curves.easeInCubic,
        reverseDuration: Duration(milliseconds: 280),
      ),
      builder: (_) => DraggableScrollableSheet(
        controller: sheetController,
        initialChildSize: 0.6,
        minChildSize: 0.56,
        maxChildSize: 1.0,
        expand: false,
        builder: (_, scrollController) => AnimatedBuilder(
          animation: sheetController,
          builder: (ctx, _) {
            final double extent = sheetController.isAttached ? sheetController.size : 0.6;
            final bool isFullScreen = extent >= 0.99;
            final double topPad = isFullScreen ? MediaQuery.of(context).padding.top : 0;
            return Container(
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(isFullScreen ? 0 : Dimensions.radiusExtraLarge),
                ),
              ),
              child: Column(children: [
                SizedBox(height: topPad),
                const SizedBox(height: Dimensions.paddingSizeSmall),
                Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).disabledColor.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault, vertical: Dimensions.paddingSizeDefault),
                  child: Row(children: [
                    Expanded(child: Text('${'reviews'.tr} (${reviews.length})', style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge))),
                    InkWell(
                      onTap: () => Get.back(),
                      borderRadius: BorderRadius.circular(20),
                      child: const Icon(Icons.close),
                    ),
                  ]),
                ),
                Divider(height: 1, color: Theme.of(context).disabledColor.withValues(alpha: 0.15)),
                Expanded(
                  child: ListView.separated(
                    controller: scrollController,
                    padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                    itemCount: reviews.length,
                    separatorBuilder: (_, _) => Divider(height: Dimensions.paddingSizeLarge, thickness: 1, color: Theme.of(context).disabledColor.withValues(alpha: 0.15)),
                    itemBuilder: (_, index) => _VehicleReviewTile(review: reviews[index]),
                  ),
                ),
              ]),
            );
          },
        ),
      ),
    ).then((_) {
      sheetController.dispose();
      FocusManager.instance.primaryFocus?.unfocus();
    });
  }

  @override
  Widget build(BuildContext context) {
    log("-------> ${widget.vehicle.toJson()}----<");
    final List<int> ratingCounts = widget.vehicle.provider?.rating ?? <int>[];
    final int totalReviews = widget.vehicle.totalReviews ?? widget.vehicle.provider?.ratingCount ?? 0;
    final double avgRating = widget.vehicle.avgRating ?? widget.vehicle.provider?.avgRating ?? 0;

    return Container(
      margin: const EdgeInsets.fromLTRB(Dimensions.paddingSizeDefault, Dimensions.paddingSizeDefault, Dimensions.paddingSizeDefault, 0),
      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text('Review & Rating', style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge))),
          _SmallCircleIcon(
            icon: _expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
            onTap: () => setState(() => _expanded = !_expanded),
          ),
        ]),

        AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          alignment: Alignment.topCenter,
          child: !_expanded ? const SizedBox(width: double.infinity) : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: Dimensions.paddingSizeLarge),

        Container(
          padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
          decoration: BoxDecoration(
            color: Theme.of(context).disabledColor.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
          ),
          child: Row(children: [
            Container(
              width: 110, height: 130,
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
              ),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.star, color: Colors.amber, size: 28),
                  const SizedBox(width: Dimensions.paddingSizeExtraSmall),
                  Text(avgRating.toStringAsFixed(1), style: robotoBold.copyWith(fontSize: 26)),
                ]),
                const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                Text('$totalReviews+ ${'reviews'.tr}', style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).disabledColor)),
              ]),
            ),
            const SizedBox(width: Dimensions.paddingSizeDefault),

            Expanded(child: Column(children: [
              _RatingBarRow(label: 'Excellent', value: _ratingCount(ratingCounts, 4), max: totalReviews),
              _RatingBarRow(label: 'good'.tr, value: _ratingCount(ratingCounts, 3), max: totalReviews),
              _RatingBarRow(label: 'average'.tr, value: _ratingCount(ratingCounts, 2), max: totalReviews),
              _RatingBarRow(label: 'Below', value: _ratingCount(ratingCounts, 1), max: totalReviews),
              _RatingBarRow(label: 'Poor', value: _ratingCount(ratingCounts, 0), max: totalReviews),
            ])),
          ]),
        ),
        const SizedBox(height: Dimensions.paddingSizeLarge),

        GetBuilder<TaxiVendorController>(builder: (taxiVendorController) {
          if(taxiVendorController.providerReviewDetails == null) {
            return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${'reviews'.tr} ($totalReviews)', style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge)),
              const SizedBox(height: Dimensions.paddingSizeDefault),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: Dimensions.paddingSizeDefault),
                child: Center(child: SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2))),
              ),
            ]);
          }
          final List<Reviews> vehicleReviews = (taxiVendorController.providerReviewDetails!.reviews ?? <Reviews>[])
              .where((Reviews r) => r.vehicleId == widget.vehicleId).toList();
          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text('${'reviews'.tr} ($totalReviews)', style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge))),
              if (vehicleReviews.length > 3)
                GestureDetector(
                  onTap: () => _showAllReviews(context, vehicleReviews),
                  child: Text('see_all'.tr, style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeDefault, color: Theme.of(context).primaryColor)),
                ),
            ]),
            const SizedBox(height: Dimensions.paddingSizeDefault),
            if (vehicleReviews.isEmpty)
              Text('no_review_found'.tr, style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeDefault, color: Theme.of(context).disabledColor))
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                itemCount: vehicleReviews.length.clamp(0, 3),
                separatorBuilder: (_, _) => Divider(height: Dimensions.paddingSizeLarge, thickness: 1, color: Theme.of(context).disabledColor.withValues(alpha: 0.15)),
                itemBuilder: (_, index) => _VehicleReviewTile(review: vehicleReviews[index]),
              ),
          ]);
        }),
          ]),
        ),
      ]),
    );

  }
}

class _RatingBarRow extends StatelessWidget {
  final String label;
  final int value;
  final int max;
  const _RatingBarRow({required this.label, required this.value, required this.max});

  @override
  Widget build(BuildContext context) {
    final double percent = max == 0 ? 0 : (value / max).clamp(0, 1);
    return Padding(
      padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
      child: Row(children: [
        SizedBox(width: 70, child: Text(label, style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).disabledColor))),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
            child: LinearProgressIndicator(
              value: percent,
              minHeight: 3,
              backgroundColor: Theme.of(context).disabledColor.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation<Color>(Colors.amber.shade700),
            ),
          ),
        ),
        const SizedBox(width: Dimensions.paddingSizeSmall),
        SizedBox(width: 28, child: Text('$value', textAlign: TextAlign.end, style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).disabledColor))),
      ]),
    );
  }
}

 int _ratingCount(List<int> ratings, int index) {
    return ratings.length > index ? ratings[index] : 0;
  }

class _VehicleReviewTile extends StatefulWidget {
  final Reviews review;
  const _VehicleReviewTile({required this.review});

  @override
  State<_VehicleReviewTile> createState() => _VehicleReviewTileState();
}

class _VehicleReviewTileState extends State<_VehicleReviewTile> {
  bool _commentExpanded = false;
  bool _replyExpanded = false;
  int? maxLines = 2;

  @override
  Widget build(BuildContext context) {
    final Reviews review = widget.review;
    final String name = review.customerName ?? 'unknown'.tr;
    final String date = (review.createdAt != null && review.createdAt!.isNotEmpty)
        ? DateConverter.stringToLocalDateOnly(review.createdAt!) : '';
    final String comment = review.comment ?? '';
    final double ratingValue = (review.rating ?? 0).toDouble();

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        _InitialsAvatar(name: name),
        const SizedBox(width: Dimensions.paddingSizeSmall),

        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(name, style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeDefault), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(date, style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).disabledColor)),
        ])),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall, vertical: Dimensions.paddingSizeExtraSmall),
          decoration: BoxDecoration(
            color: Colors.amber.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.star, color: Colors.amber, size: 16),
            const SizedBox(width: Dimensions.paddingSizeExtraSmall),
            Text(ratingValue.toStringAsFixed(1), style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall)),
          ]),
        ),
      ]),
      const SizedBox(height: Dimensions.paddingSizeSmall),

      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final textStyle = robotoRegular.copyWith(
                fontSize: Dimensions.fontSizeDefault,
                color: Theme.of(context).textTheme.bodyLarge!.color!.withValues(alpha: 0.7),
              );

              final tp = TextPainter(
                text: TextSpan(text: comment, style: textStyle),
                maxLines: maxLines,
                textDirection: Directionality.of(context),
              )..layout(maxWidth: constraints.maxWidth);

              final isOverflowing = tp.didExceedMaxLines;

              return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(
                  child: AnimatedSize(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    alignment: Alignment.topCenter,
                    child: Text(
                      comment,
                      maxLines: _commentExpanded ? null : maxLines,
                      overflow: _commentExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
                      style: textStyle,
                    ),
                  ),
                ),
                if (isOverflowing) ...[
                  const SizedBox(width: Dimensions.paddingSizeSmall),
                  InkWell(
                    onTap: () => setState(() => _commentExpanded = !_commentExpanded),
                    child: Icon(
                      _commentExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                      size: 20,
                      color: Theme.of(context).disabledColor,
                    ),
                  ),
                ],
              ]);
            },
          ),
        ),
      ]),

      // Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      //   Expanded(
      //     child: AnimatedSize(
      //       duration: const Duration(milliseconds: 250),
      //       curve: Curves.easeInOut,
      //       alignment: Alignment.topCenter,
      //       child: Text(
      //         comment,
      //         maxLines: _commentExpanded ? null : maxLines,
      //         overflow: _commentExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
      //         style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeDefault, color: Theme.of(context).textTheme.bodyLarge!.color!.withValues(alpha: 0.7)),
      //       ),
      //     ),
      //   ),
      //   const SizedBox(width: Dimensions.paddingSizeSmall),
      //   maxLines == 2 ? InkWell(
      //     onTap: () => setState(() => _commentExpanded = !_commentExpanded),
      //     child: Icon(
      //       _commentExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
      //       size: 20, color: Theme.of(context).disabledColor,
      //     ),
      //   ) : const SizedBox.shrink(),
      // ]),

      if (review.reply != null && review.reply!.isNotEmpty) ...[
        const SizedBox(height: Dimensions.paddingSizeSmall),
        Center(child: InkWell(
          onTap: () => setState(() => _replyExpanded = !_replyExpanded),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text(_replyExpanded ? 'see_less'.tr : 'see_more'.tr, style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeDefault, color: Colors.blue)),
            const SizedBox(width: Dimensions.paddingSizeExtraSmall),
            Icon(_replyExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, size: 18, color: Colors.blue),
          ]),
        )),
        AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          alignment: Alignment.topCenter,
          child: _replyExpanded ? Padding(
            padding: const EdgeInsets.only(top: Dimensions.paddingSizeSmall),
            child: Container(
              padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
              decoration: BoxDecoration(
                color: Theme.of(context).disabledColor.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
              ),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(Icons.reply, size: 16, color: Theme.of(context).primaryColor),
                const SizedBox(width: Dimensions.paddingSizeExtraSmall),
                Expanded(child: Text(
                  review.reply!,
                  style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).textTheme.bodyLarge!.color!.withValues(alpha: 0.7)),
                )),
              ]),
            ),
          ) : const SizedBox(width: double.infinity),
        ),
      ],
    ]);
  }
}

class _InitialsAvatar extends StatelessWidget {
  final String name;
  const _InitialsAvatar({required this.name});

  @override
  Widget build(BuildContext context) {
    final String initials = _buildInitials(name);
    return Container(
      width: 36, height: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: Text(initials, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).primaryColor)),
    );
  }

  String _buildInitials(String value) {
    final String trimmed = value.trim();
    if(trimmed.isEmpty) return '?';
    final List<String> parts = trimmed.split(RegExp(r'\s+'));
    if(parts.length == 1) return parts.first.characters.first.toUpperCase();
    return (parts.first.characters.first + parts[1].characters.first).toUpperCase();
  }
}