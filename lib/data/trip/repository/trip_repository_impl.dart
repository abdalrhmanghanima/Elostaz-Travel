import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elostaz_travel/data/trip/data_source/trip_remote_data_source.dart'
    hide PaginatedTripsResult;
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
    return remoteDataSource.addTrip(TripModel.fromEntity(trip));
  }

  @override
  Future<void> updateTrip(TripEntity trip) {
    return remoteDataSource.updateTrip(TripModel.fromEntity(trip));
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

  @override
  Future<List<TripEntity>> getFactoryTrips(String factoryId) {
    return remoteDataSource.getFactoryTrips(factoryId);
  }

  @override
  Future<List<TripEntity>> getAllTrips() {
    return remoteDataSource.getAllTrips();
  }

  @override
  Future<List<TripEntity>> getMonthlyTrips({
    required int year,
    required int month,
  }) {
    return remoteDataSource.getMonthlyTrips(year: year, month: month);
  }

  @override
  Future<List<TripEntity>> getBusTripsLimited(String busId, int limit) {
    return remoteDataSource.getBusTripsLimited(busId, limit);
  }

  @override
  Future<List<TripEntity>> getDriverTripsLimited(String driverId, int limit) {
    return remoteDataSource.getDriverTripsLimited(driverId, limit);
  }

  @override
  Future<List<TripEntity>> getFactoryTripsLimited(String factoryId, int limit) {
    return remoteDataSource.getFactoryTripsLimited(factoryId, limit);
  }

  @override
  Future<PaginatedTripsResult> getBusTripsPaginated(
    String busId,
    int limit,
    DocumentSnapshot<Map<String, dynamic>>? lastDocument,
    TripListFilter filter,
  ) async {
    final result = await remoteDataSource.getBusTripsPaginated(
        busId, limit, lastDocument, filter);
    return _toDomainResult(result);
  }

  @override
  Future<PaginatedTripsResult> getDriverTripsPaginated(
    String driverId,
    int limit,
    DocumentSnapshot<Map<String, dynamic>>? lastDocument,
    TripListFilter filter,
  ) async {
    final result = await remoteDataSource.getDriverTripsPaginated(
        driverId, limit, lastDocument, filter);
    return _toDomainResult(result);
  }

  @override
  Future<PaginatedTripsResult> getFactoryTripsPaginated(
    String factoryId,
    int limit,
    DocumentSnapshot<Map<String, dynamic>>? lastDocument,
    TripListFilter filter,
  ) async {
    final result = await remoteDataSource.getFactoryTripsPaginated(
        factoryId, limit, lastDocument, filter);
    return _toDomainResult(result);
  }

  @override
  Future<List<TripEntity>> getBusTripsForReport(
    String busId,
    TripListFilter filter,
  ) {
    return remoteDataSource.getBusTripsForReport(busId, filter);
  }

  @override
  Future<List<TripEntity>> getDriverTripsForReport(
    String driverId,
    TripListFilter filter,
  ) {
    return remoteDataSource.getDriverTripsForReport(driverId, filter);
  }

  @override
  Future<List<TripEntity>> getFactoryTripsForReport(
    String factoryId,
    TripListFilter filter,
  ) {
    return remoteDataSource.getFactoryTripsForReport(factoryId, filter);
  }
}

PaginatedTripsResult _toDomainResult(dynamic result) {
  final trips = List<TripEntity>.from(result.trips as List);
  return PaginatedTripsResult(
    trips: trips,
    lastDocument: result.lastDocument,
    hasMore: result.hasMore,
  );
}
