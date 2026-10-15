import 'package:get/get.dart';
import 'package:sixam_mart/api/api_client.dart';
import 'package:sixam_mart/api/response_parser.dart';
import 'package:sixam_mart/features/rental_module/home/domain/models/last_trip_model.dart';
import 'package:sixam_mart/features/rental_module/vendor/domain/models/verified_provider_model.dart';
import 'package:sixam_mart/features/rental_module/vendor/domain/repositories/verified_provider_repository_interface.dart';
import 'package:sixam_mart/util/app_constants.dart';

class VerifiedProviderRepository implements VerifiedProviderRepositoryInterface {
  final ApiClient apiClient;

  VerifiedProviderRepository({required this.apiClient});

  @override
  Future<VerifiedProviderResponse?> getVerifiedProviders({required int offset, int limit = 10}) async {
    VerifiedProviderResponse? response;
    Response apiResponse = await apiClient.getData(
      '${AppConstants.getVerifiedProvidersUri}?limit=$limit&offset=$offset',
    );
    if (apiResponse.statusCode == 200) {
      response = VerifiedProviderResponse.fromJson(apiResponse.body);
    }
    return response;
  }

  @override
  Future<List<LastTripModel>> getLastTrips() async {
    List<LastTripModel> trips = [];
    Response apiResponse = await apiClient.getData(AppConstants.rentalLastTrips);
    if (apiResponse.statusCode == 200) {
      // `content` is a bare array here, unlike most rental lists which moved to
      // `data` — read it through the parser so either shape works.
      trips = ResponseParser.listOrEmpty(apiResponse.body)
          .map((trip) => LastTripModel.fromJson(trip as Map<String, dynamic>))
          .toList();
    }
    return trips;
  }

  @override
  Future add(value) {
    throw UnimplementedError();
  }

  @override
  Future delete(int? id) {
    throw UnimplementedError();
  }

  @override
  Future get(String? id) {
    throw UnimplementedError();
  }

  @override
  Future getList({int? offset}) {
    throw UnimplementedError();
  }

  @override
  Future update(Map<String, dynamic> body, int? id) {
    throw UnimplementedError();
  }

  @override
  Future<Response> reorderTrip({required int tripId}) async {
    try {
      Map<String, dynamic> data = {
        "trip_id": tripId,
      };
      Response response = await apiClient.postData(AppConstants.rentalReOrder, data, handleError: false);
      return response;
    } catch (e) {
      print('====> Reorder Trip Repository Exception: $e');
      rethrow;
    }
  }
}
