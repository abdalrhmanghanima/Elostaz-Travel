import 'package:elostaz_travel/domain/trip/entity/trip_entity.dart';
import 'package:elostaz_travel/domain/trip/repository/trip_repository.dart';

class GetFactoryTripsForReportUseCase {
  final TripRepository repository;

  GetFactoryTripsForReportUseCase({required this.repository});

  Future<List<TripEntity>> call(String factoryId, TripListFilter filter) {
    return repository.getFactoryTripsForReport(factoryId, filter);
  }
}