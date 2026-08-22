import 'package:elostaz_travel/domain/trip/entity/trip_entity.dart';
import 'package:elostaz_travel/domain/trip/repository/trip_repository.dart';

class GetFactoryTripsUseCase {
  final TripRepository repository;

  GetFactoryTripsUseCase({required this.repository});

  Future<List<TripEntity>> call(String factoryId) {
    return repository.getFactoryTrips(factoryId);
  }
}
