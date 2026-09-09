import 'package:elostaz_travel/domain/trip/entity/trip_entity.dart';
import 'package:elostaz_travel/domain/trip/repository/trip_repository.dart';

class GetBusTripsForReportUseCase {
  final TripRepository repository;

  GetBusTripsForReportUseCase({required this.repository});

  Future<List<TripEntity>> call(String busId, TripListFilter filter) {
    return repository.getBusTripsForReport(busId, filter);
  }
}