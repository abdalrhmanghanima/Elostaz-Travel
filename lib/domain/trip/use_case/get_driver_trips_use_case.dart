import 'package:elostaz_travel/domain/trip/entity/trip_entity.dart';
import 'package:elostaz_travel/domain/trip/repository/trip_repository.dart';

class GetDriverTripsUseCase {
  final TripRepository repository;

  GetDriverTripsUseCase({
    required this.repository,
  });

  Future<List<TripEntity>> call(String driverId) {
    return repository.getDriverTrips(driverId);
  }
}