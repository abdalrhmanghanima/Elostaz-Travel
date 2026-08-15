import 'package:elostaz_travel/domain/trip/repository/trip_repository.dart';

class DeleteTripUseCase {
  final TripRepository repository;

  DeleteTripUseCase({
    required this.repository,
  });

  Future<void> call(String tripId) {
    return repository.deleteTrip(tripId);
  }
}