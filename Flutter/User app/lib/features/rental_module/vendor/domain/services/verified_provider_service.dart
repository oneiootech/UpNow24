import 'package:get/get_connect/http/src/response/response.dart';
import 'package:sixam_mart/features/rental_module/home/domain/models/last_trip_model.dart';
import 'package:sixam_mart/features/rental_module/vendor/domain/models/verified_provider_model.dart';
import 'package:sixam_mart/features/rental_module/vendor/domain/repositories/verified_provider_repository_interface.dart';
import 'package:sixam_mart/features/rental_module/vendor/domain/services/verified_provider_service_interface.dart';

class VerifiedProviderService implements VerifiedProviderServiceInterface {
  final VerifiedProviderRepositoryInterface verifiedProviderRepositoryInterface;

  VerifiedProviderService({required this.verifiedProviderRepositoryInterface});

  @override
  Future<VerifiedProviderResponse?> getVerifiedProviders({required int offset, int limit = 10}) async {
    return await verifiedProviderRepositoryInterface.getVerifiedProviders(offset: offset, limit: limit);
  }

  @override
  Future<List<LastTripModel>> getLastTrips() async {
    return await verifiedProviderRepositoryInterface.getLastTrips();
  }

  @override
  Future<Response> reorderTrip({required int tripId}) async {
    return await verifiedProviderRepositoryInterface.reorderTrip(tripId: tripId);
  }
}
