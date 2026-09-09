import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elostaz_travel/domain/trip/repository/trip_repository.dart';

class GetDriverTripsPaginatedUseCase {
  final TripRepository repository;

  GetDriverTripsPaginatedUseCase({required this.repository});

  Future<PaginatedTripsResult> call(
    String driverId,
    int limit,
    DocumentSnapshot<Map<String, dynamic>>? lastDocument,
    TripListFilter filter,
  ) {
    return repository.getDriverTripsPaginated(
        driverId, limit, lastDocument, filter);
  }
}