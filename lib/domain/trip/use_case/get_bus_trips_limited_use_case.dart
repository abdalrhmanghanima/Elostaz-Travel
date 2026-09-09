import 'package:elostaz_travel/domain/trip/entity/trip_entity.dart';
import 'package:elostaz_travel/domain/trip/repository/trip_repository.dart';

class GetBusTripsLimitedUseCase {
  final TripRepository repository;

  GetBusTripsLimitedUseCase({required this.repository});

  Future<List<TripEntity>> call(String busId, {int limit = 3}) {
    return repository.getBusTripsLimited(busId, limit);
  }
}