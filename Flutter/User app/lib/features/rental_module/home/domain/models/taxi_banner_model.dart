import 'package:sixam_mart/api/response_parser.dart';
class TaxiBannerModel {
  List<Banners>? banners;

  TaxiBannerModel({this.banners});

  TaxiBannerModel.fromJson(Map<String, dynamic> json) {
    // `/rental/banners` still returns a named `banners` list rather than `data`
    // — one of the few list endpoints that did not move. Accept both.
    final List<dynamic>? entries = ResponseParser.listOf(json, legacyKey: 'banners');
    if (entries != null) {
      banners = <Banners>[];
      for (final dynamic v in entries) {
        banners!.add(Banners.fromJson(v));
      }
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (banners != null) {
      data['banners'] = banners!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Banners {
  int? id;
  String? title;
  String? type;
  String? image;
  String? link;
  int? providerId;
  String? imageFullUrl;

  Banners(
      {this.id,
        this.title,
        this.type,
        this.image,
        this.link,
        this.providerId,
        this.imageFullUrl});

  Banners.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    title = json['title'];
    type = json['type'];
    image = json['image'];
    link = json['link'];
    providerId = json['provider_id'];
    imageFullUrl = json['image_full_url'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['title'] = title;
    data['type'] = type;
    data['image'] = image;
    data['link'] = link;
    data['provider_id'] = providerId;
    data['image_full_url'] = imageFullUrl;
    return data;
  }
}