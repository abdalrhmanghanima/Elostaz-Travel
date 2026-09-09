import 'package:elostaz_travel/domain/trip/entity/trip_entity.dart';
import 'package:elostaz_travel/domain/trip/repository/trip_repository.dart';

class GetDriverTripsLimitedUseCase {
  final TripRepository repository;

  GetDriverTripsLimitedUseCase({required this.repository});

  Future<List<TripEntity>> call(String driverId, {int limit = 3}) {
    return repository.getDriverTripsLimited(driverId, limit);
  }
}