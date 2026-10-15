import 'package:sixam_mart/api/response_parser.dart';
import 'package:sixam_mart/common/models/pagination_model.dart';
class VendorVehicleCategoryModel {
  int? totalSize;
  int? limit;
  int? offset;
  List<VehiclesCategory>? vehicles;

  VendorVehicleCategoryModel({this.totalSize, this.limit, this.offset, this.vehicles});

  VendorVehicleCategoryModel.fromJson(Map<String, dynamic> json) {
    // Paging arrives flat (`total_size`/`limit`/`offset`) on the legacy format
    // and nested under `pagination` now. Property names are unchanged, so no
    // caller needs an edit.
    final PaginationModel _pg = PaginationModel.fromJson(json);
    totalSize = _pg.totalSize;
    limit = _pg.limit;
    offset = _pg.offset;
    // The list moved to `data` in the new API format. `listOf` checks the legacy
    // key first, so a backend still answering with `vehicles` parses exactly as before
    // and only the new shape is newly understood.
    final List<dynamic>? vehicleEntries = ResponseParser.listOf(json, legacyKey: 'vehicles');
    if (vehicleEntries != null) {
      vehicles = <VehiclesCategory>[];
      for (final dynamic v in vehicleEntries) {
        vehicles!.add(VehiclesCategory.fromJson(v));
      }
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['total_size'] = totalSize;
    data['limit'] = limit;
    data['offset'] = offset;
    if (vehicles != null) {
      data['vehicles'] = vehicles!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class VehiclesCategory {
  int? id;
  String? image;
  String? name;
  String? imageFullUrl;

  VehiclesCategory({this.id, this.image, this.name, this.imageFullUrl});

  VehiclesCategory.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    image = json['image'];
    name = json['name'];
    imageFullUrl = json['image_full_url'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['image'] = image;
    data['name'] = name;
    data['image_full_url'] = imageFullUrl;
    return data;
  }
}
