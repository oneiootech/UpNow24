class LastTripModel {
  final int id;
  final int tripAmount;
  final String tripStatus;
  final String? createdAt;
  final String estimatedHours;
  final String tripType;
  final Provider? provider;
  final List<TripDetail> tripDetails;

  LastTripModel({
    required this.id,
    required this.tripAmount,
    required this.tripStatus,
    this.createdAt,
    required this.estimatedHours,
    required this.tripType,
    this.provider,
    required this.tripDetails,
  });

  factory LastTripModel.fromJson(Map<String, dynamic> json) {
    return LastTripModel(
      id: _toInt(json['id']),
      tripAmount: _toInt(json['trip_amount']),
      tripStatus: json['trip_status'] ?? '',
      createdAt: json['created_at'],
      estimatedHours: json['estimated_hours']?.toString() ?? '0',
      tripType: json['trip_type'] ?? '',
      provider: json['provider'] != null ? Provider.fromJson(json['provider']) : null,
      tripDetails: json['trip_details'] != null
          ? List<TripDetail>.from(json['trip_details'].map((x) => TripDetail.fromJson(x)))
          : [],
    );
  }

  static int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}

class Provider {
  final int id;
  final String name;
  final String? logo;
  final String? logoFullUrl;

  Provider({
    required this.id,
    required this.name,
    this.logo,
    this.logoFullUrl,
  });

  factory Provider.fromJson(Map<String, dynamic> json) {
    return Provider(
      id: _toInt(json['id']),
      name: json['name'] ?? '',
      logo: json['logo'],
      logoFullUrl: json['logo_full_url'],
    );
  }

  static int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}

class TripDetail {
  final int id;
  final int vehicleId;
  final int quantity;
  final Vehicle? vehicle;

  TripDetail({
    required this.id,
    required this.vehicleId,
    required this.quantity,
    this.vehicle,
  });

  factory TripDetail.fromJson(Map<String, dynamic> json) {
    return TripDetail(
      id: _toInt(json['id']),
      vehicleId: _toInt(json['vehicle_id']),
      quantity: _toInt(json['quantity']),
      vehicle: json['vehicle'] != null ? Vehicle.fromJson(json['vehicle']) : null,
    );
  }

  static int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}

class Vehicle {
  final int id;
  final String name;
  final String? thumbnail;
  final String? thumbnailFullUrl;
  final List<String> imagesFullUrl;

  Vehicle({
    required this.id,
    required this.name,
    this.thumbnail,
    this.thumbnailFullUrl,
    required this.imagesFullUrl,
  });

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      id: _toInt(json['id']),
      name: json['name'] ?? '',
      thumbnail: json['thumbnail'],
      thumbnailFullUrl: json['thumbnail_full_url'],
      imagesFullUrl: json['images_full_url'] != null
          ? List<String>.from(json['images_full_url'].map((x) => x.toString()))
          : [],
    );
  }

  static int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}
