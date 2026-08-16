import 'package:elostaz_travel/data/trip/data_source/trip_remote_data_source.dart';
import 'package:elostaz_travel/domain/trip/entity/trip_entity.dart';
import 'package:elostaz_travel/domain/trip/repository/trip_repository.dart';
import 'package:elostaz_travel/data/trip/model/trip_model.dart';
class TripRepositoryImpl implements TripRepository {
  final TripRemoteDataSource remoteDataSource;

  TripRepositoryImpl({
    required this.remoteDataSource,
  });

  @override
  Future<void> addTrip(TripEntity trip) {
    final model = TripModel(
      id: trip.id,
      driverId: trip.driverId,
      driverName: trip.driverName,
      busId: trip.busId,
      busName: trip.busName,
      plateNumber: trip.plateNumber,
      details: trip.details,
      revenue: trip.revenue,
      expenses: trip.expenses,
      createdAt: trip.createdAt,
    );

    return remoteDataSource.addTrip(model);
  }

  @override
  Future<void> deleteTrip(String tripId) {
    return remoteDataSource.deleteTrip(tripId);
  }

  @override
  Future<List<TripEntity>> getBusTrips(String busId) {
    return remoteDataSource.getBusTrips(busId);
  }

  @override
  Future<List<TripEntity>> getDriverTrips(String driverId) {
    return remoteDataSource.getDriverTrips(driverId);
  }
}