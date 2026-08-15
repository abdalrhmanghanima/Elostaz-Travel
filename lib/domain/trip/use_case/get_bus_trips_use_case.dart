import 'package:elostaz_travel/domain/trip/entity/trip_entity.dart';
import 'package:elostaz_travel/domain/trip/repository/trip_repository.dart';

class GetBusTripsUseCase {
  final TripRepository repository;

  GetBusTripsUseCase({
    required this.repository,
  });

  Future<List<TripEntity>> call(String busId) {
    return repository.getBusTrips(busId);
  }
}