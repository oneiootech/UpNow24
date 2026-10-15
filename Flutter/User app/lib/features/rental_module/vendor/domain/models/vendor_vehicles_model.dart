import 'package:sixam_mart/api/response_parser.dart';
import 'package:sixam_mart/common/models/pagination_model.dart';
import 'package:sixam_mart/features/rental_module/home/domain/models/vehicle_details_model.dart';

class VendorVehiclesModel {
  int? totalSize;
  int? limit;
  int? offset;
  double? maxPrice;
  double? minPrice;
  List<VehicleModel>? vehicles;

  VendorVehiclesModel({this.totalSize, this.limit, this.offset, this.maxPrice, this.minPrice, this.vehicles});

  VendorVehiclesModel.fromJson(Map<String, dynamic> json) {
    // Paging arrives flat (`total_size`/`limit`/`offset`) on the legacy format
    // and nested under `pagination` now. Property names are unchanged, so no
    // caller needs an edit.
    final PaginationModel _pg = PaginationModel.fromJson(json);
    totalSize = _pg.totalSize;
    limit = _pg.limit;
    offset = _pg.offset;
    maxPrice = json['max_price']?.toDouble();
    minPrice = json['min_price']?.toDouble();
    // The list moved to `data` in the new API format. `listOf` checks the legacy
    // key first, so a backend still answering with `vehicles` parses exactly as before
    // and only the new shape is newly understood.
    final List<dynamic>? vehicleEntries = ResponseParser.listOf(json, legacyKey: 'vehicles');
    if (vehicleEntries != null) {
      vehicles = <VehicleModel>[];
      for (final dynamic v in vehicleEntries) {
        vehicles!.add(VehicleModel.fromJson(v));
      }
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['total_size'] = totalSize;
    data['limit'] = limit;
    data['offset'] = offset;
    data['max_price'] = maxPrice;
    data['min_price'] = minPrice;
    if (vehicles != null) {
      data['vehicles'] = vehicles!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}
