import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elostaz_travel/domain/trip/entity/trip_entity.dart';

class PaginatedTripsResult {
  final List<TripEntity> trips;
  final DocumentSnapshot<Map<String, dynamic>>? lastDocument;
  final bool hasMore;

  const PaginatedTripsResult({
    required this.trips,
    this.lastDocument,
    required this.hasMore,
  });
}

/// Server-side filter applied to paginated trip queries.
///
/// [startDate]/[endDate] define a half-open date range on the `createdAt`
/// field ([startDate] <= createdAt < [endDate]). [recordType] optionally
/// restricts to a single normalized type (`TripType.trip` or
/// `TripType.nightOuting`). A null [recordType] means both types are included.
class TripListFilter {
  final DateTime? startDate;
  final DateTime? endDate;
  final String? recordType;

  const TripListFilter({
    this.startDate,
    this.endDate,
    this.recordType,
  });

  bool get hasDateFilter => startDate != null || endDate != null;

  bool get isEmpty => !hasDateFilter && recordType == null;

  @override
  bool operator ==(Object other) =>
      other is TripListFilter &&
      other.startDate == startDate &&
      other.endDate == endDate &&
      other.recordType == recordType;

  @override
  int get hashCode => Object.hash(startDate, endDate, recordType);
}

abstract class TripRepository {
  Future<void> addTrip(TripEntity trip);

  Future<void> updateTrip(TripEntity trip);

  Future<void> deleteTrip(String tripId);

  Future<List<TripEntity>> getBusTrips(String busId);

  Future<List<TripEntity>> getDriverTrips(String driverId);

  Future<List<TripEntity>> getFactoryTrips(String factoryId);

  Future<List<TripEntity>> getAllTrips();

  Future<List<TripEntity>> getMonthlyTrips({
    required int year,
    required int month,
  });

  Future<List<TripEntity>> getBusTripsLimited(String busId, int limit);

  Future<List<TripEntity>> getDriverTripsLimited(String driverId, int limit);

  Future<List<TripEntity>> getFactoryTripsLimited(String factoryId, int limit);

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

  /// Returns ALL trips for a bus matching [filter] (used by the print/report
  /// flow). Intentionally not paginated in the UI sense — the data source
  /// iterates all matching documents.
  Future<List<TripEntity>> getBusTripsForReport(
    String busId,
    TripListFilter filter,
  );

  Future<List<TripEntity>> getDriverTripsForReport(
    String driverId,
    TripListFilter filter,
  );

  Future<List<TripEntity>> getFactoryTripsForReport(
    String factoryId,
    TripListFilter filter,
  );
}