import 'package:elostaz_travel/domain/trip/entity/trip_entity.dart';
import 'package:elostaz_travel/domain/trip/repository/trip_repository.dart';

class GetFactoryTripsLimitedUseCase {
  final TripRepository repository;

  GetFactoryTripsLimitedUseCase({required this.repository});

  Future<List<TripEntity>> call(String factoryId, {int limit = 3}) {
    return repository.getFactoryTripsLimited(factoryId, limit);
  }
}