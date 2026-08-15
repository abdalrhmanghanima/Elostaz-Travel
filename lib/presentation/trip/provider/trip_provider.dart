import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elostaz_travel/data/trip/data_source/trip_remote_data_source_impl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elostaz_travel/data/trip/data_source/trip_remote_data_source.dart';
import 'package:elostaz_travel/data/trip/repository/trip_repository_impl.dart';

import 'package:elostaz_travel/domain/trip/entity/trip_entity.dart';
import 'package:elostaz_travel/domain/trip/repository/trip_repository.dart';

import 'package:elostaz_travel/domain/trip/use_case/add_trip_use_case.dart';
import 'package:elostaz_travel/domain/trip/use_case/delete_trip_use_case.dart';
import 'package:elostaz_travel/domain/trip/use_case/get_bus_trips_use_case.dart';
import 'package:elostaz_travel/domain/trip/use_case/get_driver_trips_use_case.dart';

final tripRemoteDataSourceProvider =
Provider<TripRemoteDataSource>((ref) {
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

final addTripUseCaseProvider = Provider<AddTripUseCase>((ref) {
  return AddTripUseCase(
    repository: ref.read(tripRepositoryProvider),
  );
});

final deleteTripUseCaseProvider = Provider<DeleteTripUseCase>((ref) {
  return DeleteTripUseCase(
    repository: ref.read(tripRepositoryProvider),
  );
});

final getBusTripsUseCaseProvider =
Provider<GetBusTripsUseCase>((ref) {
  return GetBusTripsUseCase(
    repository: ref.read(tripRepositoryProvider),
  );
});

final getDriverTripsUseCaseProvider =
Provider<GetDriverTripsUseCase>((ref) {
  return GetDriverTripsUseCase(
    repository: ref.read(tripRepositoryProvider),
  );
});

final tripProvider =
AsyncNotifierProvider<TripNotifier, void>(
  TripNotifier.new,
);

class TripNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<bool> addTrip(TripEntity trip) async {
    state = const AsyncLoading();

    final result = await AsyncValue.guard(
          () => ref.read(addTripUseCaseProvider).call(trip),
    );

    state = result;

    return !result.hasError;
  }

  Future<bool> deleteTrip(String tripId) async {
    state = const AsyncLoading();

    final result = await AsyncValue.guard(
          () => ref.read(deleteTripUseCaseProvider).call(tripId),
    );

    state = result;

    return !result.hasError;
  }
}

final busTripsProvider =
FutureProvider.family<List<TripEntity>, String>(
      (ref, busId) {
    return ref
        .read(getBusTripsUseCaseProvider)
        .call(busId);
  },
);

final driverTripsProvider =
FutureProvider.family<List<TripEntity>, String>(
      (ref, driverId) {
    return ref
        .read(getDriverTripsUseCaseProvider)
        .call(driverId);
  },
);