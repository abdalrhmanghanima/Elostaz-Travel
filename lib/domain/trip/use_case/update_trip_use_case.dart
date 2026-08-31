import 'package:elostaz_travel/domain/trip/entity/trip_entity.dart';
import 'package:elostaz_travel/domain/trip/repository/trip_repository.dart';

class UpdateTripUseCase {
  final TripRepository repository;

  UpdateTripUseCase({required this.repository});

  Future<void> call(TripEntity trip) {
    return repository.updateTrip(trip);
  }
}
