import 'package:elostaz_travel/data/trip/model/trip_model.dart';

abstract class TripRemoteDataSource {
  Future<void> addTrip(TripModel trip);

  Future<void> deleteTrip(String tripId);

  Future<List<TripModel>> getBusTrips(String busId);

  Future<List<TripModel>> getDriverTrips(String driverId);

  Future<List<TripModel>> getFactoryTrips(String factoryId);

  /// Returns all trips belonging to the user.
  Future<List<TripModel>> getAllTrips();

  /// Returns all trips whose [createdAt] falls within the given month/year.
  Future<List<TripModel>> getMonthlyTrips({
    required int year,
    required int month,
  });
}