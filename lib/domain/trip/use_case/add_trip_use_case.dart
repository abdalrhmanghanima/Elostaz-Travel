import 'package:elostaz_travel/domain/trip/entity/trip_entity.dart';
import 'package:elostaz_travel/domain/trip/repository/trip_repository.dart';
import 'package:elostaz_travel/domain/trip/validation/trip_date_rule.dart';

class AddTripUseCase {
  final TripRepository repository;

  AddTripUseCase({
    required this.repository,
  });

  Future<void> call(TripEntity trip) {
    if (!TripDateRule.isTripAllowed(trip, today: DateTime.now())) {
      throw FutureTripDateException(trip.effectiveDate);
    }
    return repository.addTrip(trip);
  }
}