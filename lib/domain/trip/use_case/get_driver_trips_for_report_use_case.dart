import 'package:elostaz_travel/domain/trip/entity/trip_entity.dart';
import 'package:elostaz_travel/domain/trip/repository/trip_repository.dart';

class GetDriverTripsForReportUseCase {
  final TripRepository repository;

  GetDriverTripsForReportUseCase({required this.repository});

  Future<List<TripEntity>> call(String driverId, TripListFilter filter) {
    return repository.getDriverTripsForReport(driverId, filter);
  }
}