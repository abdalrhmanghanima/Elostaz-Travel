import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elostaz_travel/data/trip/data_source/trip_remote_data_source_impl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elostaz_travel/data/trip/data_source/trip_remote_data_source.dart';
import 'package:elostaz_travel/data/trip/repository/trip_repository_impl.dart';

import 'package:elostaz_travel/domain/trip/entity/trip_entity.dart';
import 'package:elostaz_travel/domain/trip/repository/trip_repository.dart';

import 'package:elostaz_travel/domain/trip/use_case/add_trip_use_case.dart';
import 'package:elostaz_travel/domain/trip/use_case/update_trip_use_case.dart';
import 'package:elostaz_travel/domain/trip/use_case/delete_trip_use_case.dart';
import 'package:elostaz_travel/domain/trip/use_case/get_bus_trips_use_case.dart';
import 'package:elostaz_travel/domain/trip/use_case/get_driver_trips_use_case.dart';
import 'package:elostaz_travel/domain/trip/use_case/get_factory_trips_use_case.dart';
import 'package:elostaz_travel/domain/trip/use_case/get_bus_trips_limited_use_case.dart';
import 'package:elostaz_travel/domain/trip/use_case/get_driver_trips_limited_use_case.dart';
import 'package:elostaz_travel/domain/trip/use_case/get_factory_trips_limited_use_case.dart';
import 'package:elostaz_travel/domain/trip/use_case/get_bus_trips_paginated_use_case.dart';
import 'package:elostaz_travel/domain/trip/use_case/get_driver_trips_paginated_use_case.dart';
import 'package:elostaz_travel/domain/trip/use_case/get_factory_trips_paginated_use_case.dart';
import 'package:elostaz_travel/domain/trip/use_case/get_bus_trips_for_report_use_case.dart';
import 'package:elostaz_travel/domain/trip/use_case/get_driver_trips_for_report_use_case.dart';
import 'package:elostaz_travel/domain/trip/use_case/get_factory_trips_for_report_use_case.dart';
import 'package:elostaz_travel/presentation/home/tabs/trip/provider/trip_provider.dart'
    as home_trip;

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

final updateTripUseCaseProvider = Provider<UpdateTripUseCase>((ref) {
  return UpdateTripUseCase(
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

final getFactoryTripsUseCaseProvider =
Provider<GetFactoryTripsUseCase>((ref) {
  return GetFactoryTripsUseCase(
    repository: ref.read(tripRepositoryProvider),
  );
});

final getBusTripsLimitedUseCaseProvider =
Provider<GetBusTripsLimitedUseCase>((ref) {
  return GetBusTripsLimitedUseCase(
    repository: ref.read(tripRepositoryProvider),
  );
});

final getDriverTripsLimitedUseCaseProvider =
Provider<GetDriverTripsLimitedUseCase>((ref) {
  return GetDriverTripsLimitedUseCase(
    repository: ref.read(tripRepositoryProvider),
  );
});

final getFactoryTripsLimitedUseCaseProvider =
Provider<GetFactoryTripsLimitedUseCase>((ref) {
  return GetFactoryTripsLimitedUseCase(
    repository: ref.read(tripRepositoryProvider),
  );
});

final getBusTripsPaginatedUseCaseProvider =
Provider<GetBusTripsPaginatedUseCase>((ref) {
  return GetBusTripsPaginatedUseCase(
    repository: ref.read(tripRepositoryProvider),
  );
});

final getDriverTripsPaginatedUseCaseProvider =
Provider<GetDriverTripsPaginatedUseCase>((ref) {
  return GetDriverTripsPaginatedUseCase(
    repository: ref.read(tripRepositoryProvider),
  );
});

final getFactoryTripsPaginatedUseCaseProvider =
    Provider<GetFactoryTripsPaginatedUseCase>((ref) {
  return GetFactoryTripsPaginatedUseCase(
    repository: ref.read(tripRepositoryProvider),
  );
});

final getBusTripsForReportUseCaseProvider =
    Provider<GetBusTripsForReportUseCase>((ref) {
  return GetBusTripsForReportUseCase(
    repository: ref.read(tripRepositoryProvider),
  );
});

final getDriverTripsForReportUseCaseProvider =
    Provider<GetDriverTripsForReportUseCase>((ref) {
  return GetDriverTripsForReportUseCase(
    repository: ref.read(tripRepositoryProvider),
  );
});

final getFactoryTripsForReportUseCaseProvider =
    Provider<GetFactoryTripsForReportUseCase>((ref) {
  return GetFactoryTripsForReportUseCase(
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

    final result = await AsyncValue.guard(() async {
      await ref.read(addTripUseCaseProvider).call(trip);
      _invalidateTripAggregates();
    });

    state = result;

    return !result.hasError;
  }

  Future<bool> updateTrip(TripEntity trip) async {
    state = const AsyncLoading();

    final result = await AsyncValue.guard(() async {
      await ref.read(updateTripUseCaseProvider).call(trip);
      _invalidateTripAggregates();
    });

    state = result;

    return !result.hasError;
  }

  Future<bool> deleteTrip(String tripId) async {
    state = const AsyncLoading();

    final result = await AsyncValue.guard(() async {
      await ref.read(deleteTripUseCaseProvider).call(tripId);
      _invalidateTripAggregates();
    });

    state = result;

    return !result.hasError;
  }

  /// Home dashboard/company summary read the trip count + revenue from the
  /// cached [home_trip.monthlyTripsProvider]/[home_trip.allTripsProvider].
  /// These cache the aggregate forever unless invalidated, so every successful
  /// trip write must refresh them or the latest trip never shows on Home.
  void _invalidateTripAggregates() {
    ref.invalidate(home_trip.monthlyTripsProvider);
    ref.invalidate(home_trip.allTripsProvider);
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

final factoryTripsProvider =
FutureProvider.family<List<TripEntity>, String>(
      (ref, factoryId) {
    return ref
        .read(getFactoryTripsUseCaseProvider)
        .call(factoryId);
  },
);

// Limited trips providers (for details pages - 3 trips)
final busTripsLimitedProvider =
FutureProvider.family<List<TripEntity>, String>(
      (ref, busId) {
    return ref
        .read(getBusTripsLimitedUseCaseProvider)
        .call(busId, limit: 3);
  },
);

final driverTripsLimitedProvider =
FutureProvider.family<List<TripEntity>, String>(
      (ref, driverId) {
    return ref
        .read(getDriverTripsLimitedUseCaseProvider)
        .call(driverId, limit: 3);
  },
);

final factoryTripsLimitedProvider =
FutureProvider.family<List<TripEntity>, String>(
      (ref, factoryId) {
    return ref
        .read(getFactoryTripsLimitedUseCaseProvider)
        .call(factoryId, limit: 3);
  },
);