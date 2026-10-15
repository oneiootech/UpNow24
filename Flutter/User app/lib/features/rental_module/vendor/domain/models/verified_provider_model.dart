import 'package:sixam_mart/api/response_parser.dart';
import 'package:sixam_mart/common/models/pagination_model.dart';
class VerifiedProviderResponse {
  int? totalSize;
  String? limit;
  String? offset;
  List<VerifiedProvider>? stores;

  VerifiedProviderResponse({this.totalSize, this.limit, this.offset, this.stores});

  VerifiedProviderResponse.fromJson(Map<String, dynamic> json) {
    // Paging is flat on the legacy format and nested under `pagination` now.
    // Field names are unchanged so callers need no edit.
    final PaginationModel _p = PaginationModel.fromJson(json);
    totalSize = _p.totalSize;
    limit = _p.limit?.toString();
    offset = _p.offset?.toString();
    // The list is `data` now; `stores` was the legacy key.
    final List<dynamic>? entries = ResponseParser.listOf(json, legacyKey: 'stores');
    if (entries != null) {
      stores = <VerifiedProvider>[];
      for (final dynamic v in entries) {
        stores!.add(VerifiedProvider.fromJson(v));
      }
    }
  }
}

class VerifiedProvider {
  int? id;
  String? name;
  String? address;
  String? logo;
  String? coverPhoto;
  String? logoFullUrl;
  String? coverPhotoFullUrl;
  String? deliveryTime;
  double? distance;
  double? distanceKm;

  /// The distance already written out in the platform's configured unit, the way
  /// `Store` receives it. Absent from this endpoint today, so the card keeps its
  /// own fallback.
  String? distanceLabel;
  int? vehiclesCount;
  int? tripsCount;
  int? verifiedSeller;
  List<int>? rating;
  int? ad;
  int? open;
  bool? active;
  int? featured;
  String? createdAt;
  VerifiedProviderDiscount? discount;

  VerifiedProvider({this.id, this.name, this.address, this.logo, this.coverPhoto,
    this.logoFullUrl, this.coverPhotoFullUrl, this.deliveryTime, this.distance, this.vehiclesCount,
    this.tripsCount, this.verifiedSeller, this.rating, this.ad, this.open,
    this.active, this.featured, this.createdAt, this.discount,
  });

  VerifiedProvider.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    address = json['address'];
    logo = json['logo'];
    coverPhoto = json['cover_photo'];
    logoFullUrl = json['logo_full_url'];
    coverPhotoFullUrl = json['cover_photo_full_url'];
    deliveryTime = json['delivery_time'];
    distance = json['distance'] != null ? (json['distance'] as num).toDouble() : null;
    distanceKm = json['distance_km'] != null ? (json['distance_km'] as num).toDouble() : null;
    distanceLabel = json['distance_label'] ?? json['distance_lavel'];
    vehiclesCount = json['vehicles_count'];
    tripsCount = json['trips_count'];
    verifiedSeller = json['verified_seller'];
    if (json['rating'] != null) {
      rating = (json['rating'] as List).map((e) => (e as num).toInt()).toList();
    }
    ad = json['ad'];
    open = json['open'];
    active = json['active'];
    featured = json['featured'];
    createdAt = json['created_at'];
    discount = json['discount'] != null ? VerifiedProviderDiscount.fromJson(json['discount']) : null;
  }

  double avgRating() {
    if (rating == null || rating!.isEmpty) return 0;
    int weightedSum = 0;
    int totalCount = 0;
    for (int i = 0; i < rating!.length; i++) {
      int stars = rating!.length - i;
      int count = rating![i];
      weightedSum += stars * count;
      totalCount += count;
    }
    if (totalCount == 0) return 0;
    return weightedSum / totalCount;
  }

  int totalRatingCount() {
    if (rating == null || rating!.isEmpty) return 0;
    return rating!.fold<int>(0, (sum, c) => sum + c);
  }

  bool isNew() {
    if (createdAt == null) return false;
    try {
      final DateTime created = DateTime.parse(createdAt!).toLocal();
      final Duration diff = DateTime.now().difference(created);
      return diff.inDays >= 0 && diff.inDays <= 30;
    } catch (_) {
      return false;
    }
  }
}

class VerifiedProviderDiscount {
  double? discount;
  String? discountType;

  VerifiedProviderDiscount({this.discount, this.discountType});

  VerifiedProviderDiscount.fromJson(Map<String, dynamic> json) {
    discount = json['discount'] != null ? (json['discount'] as num).toDouble() : null;
    discountType = json['discount_type'];
  }
}
