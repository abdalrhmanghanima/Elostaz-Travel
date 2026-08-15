import 'package:elostaz_travel/domain/trip/entity/trip_entity.dart';

abstract class TripRepository {
  Future<void> addTrip(TripEntity trip);

  Future<void> deleteTrip(String tripId);

  Future<List<TripEntity>> getBusTrips(String busId);

  Future<List<TripEntity>> getDriverTrips(String driverId);
}