import 'package:sixam_mart/api/response_parser.dart';
import 'package:sixam_mart/common/models/pagination_model.dart';
import 'package:sixam_mart/features/rental_module/home/domain/models/vehicle_details_model.dart';

class TopRatedCarsModel {
  int? totalSize;
  int? limit;
  int? offset;
  List<VehicleModel>? vehicles;

  TopRatedCarsModel({this.totalSize, this.limit, this.offset, this.vehicles});

  TopRatedCarsModel.fromJson(Map<String, dynamic> json) {
    // Paging is flat on the legacy format and nested under `pagination` now.
    // Field names are unchanged so callers need no edit.
    final PaginationModel _p = PaginationModel.fromJson(json);
    totalSize = _p.totalSize;
    limit = _p.limit;
    offset = _p.offset;
    // The list is `data` now; `vehicles` was the legacy key.
    final List<dynamic>? entries = ResponseParser.listOf(json, legacyKey: 'vehicles');
    if (entries != null) {
      vehicles = <VehicleModel>[];
      for (final dynamic v in entries) {
        vehicles!.add(VehicleModel.fromJson(v));
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