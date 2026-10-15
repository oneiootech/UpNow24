import 'package:sixam_mart/api/response_parser.dart';
import 'package:sixam_mart/common/models/pagination_model.dart';
class TaxiBrandModel {
  int? totalSize;
  int? limit;
  int? offset;
  List<Brands>? brands;

  TaxiBrandModel({this.totalSize, this.limit, this.offset, this.brands});

  TaxiBrandModel.fromJson(Map<String, dynamic> json) {
    // Paging is flat on the legacy format and nested under `pagination` now.
    // Field names are unchanged so callers need no edit.
    final PaginationModel _p = PaginationModel.fromJson(json);
    totalSize = _p.totalSize;
    limit = _p.limit;
    offset = _p.offset;
    final List<dynamic>? entries = ResponseParser.listOf(json, legacyKey: 'brands');
    if (entries != null) {
      brands = <Brands>[];
      for (final dynamic v in entries) {
        brands!.add(Brands.fromJson(v));
      }
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['total_size'] = totalSize;
    data['limit'] = limit;
    data['offset'] = offset;
    if (brands != null) {
      data['vehicles'] = brands!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Brands {
  int? id;
  String? image;
  String? name;
  String? imageFullUrl;

  Brands({this.id, this.image, this.name, this.imageFullUrl});

  Brands.fromJson(Map<String, dynamic> json) {
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