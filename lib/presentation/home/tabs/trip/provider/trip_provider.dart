import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elostaz_travel/data/trip/data_source/trip_remote_data_source.dart';
import 'package:elostaz_travel/data/trip/data_source/trip_remote_data_source_impl.dart';
import 'package:elostaz_travel/data/trip/repository/trip_repository_impl.dart';
import 'package:elostaz_travel/domain/trip/entity/trip_entity.dart';
import 'package:elostaz_travel/domain/trip/repository/trip_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ---------------------------------------------------------------------------
// Infrastructure providers
// ---------------------------------------------------------------------------

final tripRemoteDataSourceProvider = Provider<TripRemoteDataSource>((ref) {
  return TripRemoteDataSourceImpl(
    firestore: FirebaseFirestore.instance,
    auth: FirebaseAuth.instance,
  );
});

final tripRepositoryProvider = Provider<TripRepository>((ref) {
  return TripRepositoryImpl(
    remoteDataSource: ref.read(tripRemoteDataSourceProvider),
  );
});

// ---------------------------------------------------------------------------
// Family provider – fetches all trips for a given year + month
// ---------------------------------------------------------------------------

final monthlyTripsProvider = FutureProvider.family<List<TripEntity>, ({int year, int month})>(
  (ref, params) async {
    final repository = ref.read(tripRepositoryProvider);
    return repository.getMonthlyTrips(year: params.year, month: params.month);
  },
);

final allTripsProvider = FutureProvider<List<TripEntity>>((ref) async {
  final repository = ref.read(tripRepositoryProvider);
  return repository.getAllTrips();
});

