import 'package:elostaz_travel/data/trip/model/trip_model.dart';

abstract class TripRemoteDataSource {
  Future<void> addTrip(TripModel trip);

  Future<void> deleteTrip(String tripId);

  Future<List<TripModel>> getBusTrips(String busId);

  Future<List<TripModel>> getDriverTrips(String driverId);
}