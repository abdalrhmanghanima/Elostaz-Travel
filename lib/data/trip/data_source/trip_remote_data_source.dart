import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elostaz_travel/data/trip/model/trip_model.dart';
import 'package:elostaz_travel/domain/trip/repository/trip_repository.dart'
    show TripListFilter;

class PaginatedTripsResult {
  final List<TripModel> trips;
  final DocumentSnapshot<Map<String, dynamic>>? lastDocument;
  final bool hasMore;

  const PaginatedTripsResult({
    required this.trips,
    this.lastDocument,
    required this.hasMore,
  });
}

abstract class TripRemoteDataSource {
  Future<void> addTrip(TripModel trip);

  Future<void> updateTrip(TripModel trip);

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

  Future<List<TripModel>> getBusTripsLimited(String busId, int limit);

  Future<List<TripModel>> getDriverTripsLimited(String driverId, int limit);

  Future<List<TripModel>> getFactoryTripsLimited(String factoryId, int limit);

  Future<PaginatedTripsResult> getBusTripsPaginated(
    String busId,
    int limit,
    DocumentSnapshot<Map<String, dynamic>>? lastDocument,
    TripListFilter filter,
  );

  Future<PaginatedTripsResult> getDriverTripsPaginated(
    String driverId,
    int limit,
    DocumentSnapshot<Map<String, dynamic>>? lastDocument,
    TripListFilter filter,
  );

  Future<PaginatedTripsResult> getFactoryTripsPaginated(
    String factoryId,
    int limit,
    DocumentSnapshot<Map<String, dynamic>>? lastDocument,
    TripListFilter filter,
  );

  /// Returns ALL matching bus trips for [filter] (print/report flow). The
  /// implementation iterates all matching documents internally in batches.
  Future<List<TripModel>> getBusTripsForReport(
    String busId,
    TripListFilter filter,
  );

  Future<List<TripModel>> getDriverTripsForReport(
    String driverId,
    TripListFilter filter,
  );

  Future<List<TripModel>> getFactoryTripsForReport(
    String factoryId,
    TripListFilter filter,
  );
}