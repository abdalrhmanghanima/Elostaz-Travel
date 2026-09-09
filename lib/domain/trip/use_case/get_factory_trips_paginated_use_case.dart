import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elostaz_travel/domain/trip/repository/trip_repository.dart';

class GetFactoryTripsPaginatedUseCase {
  final TripRepository repository;

  GetFactoryTripsPaginatedUseCase({required this.repository});

  Future<PaginatedTripsResult> call(
    String factoryId,
    int limit,
    DocumentSnapshot<Map<String, dynamic>>? lastDocument,
    TripListFilter filter,
  ) {
    return repository.getFactoryTripsPaginated(
        factoryId, limit, lastDocument, filter);
  }
}