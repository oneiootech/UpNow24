import 'package:get/get_connect/http/src/response/response.dart';
import 'package:sixam_mart/features/rental_module/home/domain/models/last_trip_model.dart';
import 'package:sixam_mart/features/rental_module/vendor/domain/models/verified_provider_model.dart';

abstract class VerifiedProviderServiceInterface {
  Future<VerifiedProviderResponse?> getVerifiedProviders({required int offset, int limit = 10});
  Future<List<LastTripModel>> getLastTrips();
  Future<Response> reorderTrip({required int tripId});
}
