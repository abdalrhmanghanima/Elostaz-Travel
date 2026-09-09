import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elostaz_travel/domain/trip/repository/trip_repository.dart';

class GetBusTripsPaginatedUseCase {
  final TripRepository repository;

  GetBusTripsPaginatedUseCase({required this.repository});

  Future<PaginatedTripsResult> call(
    String busId,
    int limit,
    DocumentSnapshot<Map<String, dynamic>>? lastDocument,
    TripListFilter filter,
  ) {
    return repository.getBusTripsPaginated(busId, limit, lastDocument, filter);
  }
}