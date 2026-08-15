import 'package:elostaz_travel/domain/trip/entity/trip_entity.dart';
import 'package:elostaz_travel/domain/trip/repository/trip_repository.dart';

class AddTripUseCase {
  final TripRepository repository;

  AddTripUseCase({
    required this.repository,
  });

  Future<void> call(TripEntity trip) {
    return repository.addTrip(trip);
  }
}