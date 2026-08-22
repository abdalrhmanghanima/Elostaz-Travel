import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elostaz_travel/data/driver/data_source/driver_advance_remote_data_source.dart';
import 'package:elostaz_travel/data/driver/data_source/driver_advance_remote_data_source_impl.dart';
import 'package:elostaz_travel/data/driver/repository/driver_advance_repository_impl.dart';
import 'package:elostaz_travel/domain/driver/entity/driver_advance_entity.dart';
import 'package:elostaz_travel/domain/driver/repository/driver_advance_repository.dart';
import 'package:elostaz_travel/domain/driver/use_case/add_driver_advance_use_case.dart';
import 'package:elostaz_travel/domain/driver/use_case/get_driver_advances_use_case.dart';
import 'package:elostaz_travel/domain/driver/use_case/mark_driver_advance_paid_use_case.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final driverAdvanceRemoteDataSourceProvider =
    Provider<DriverAdvanceRemoteDataSource>((ref) {
  return DriverAdvanceRemoteDataSourceImpl(
    firestore: FirebaseFirestore.instance,
    auth: FirebaseAuth.instance,
  );
});

final driverAdvanceRepositoryProvider =
    Provider<DriverAdvanceRepository>((ref) {
  return DriverAdvanceRepositoryImpl(
    remoteDataSource: ref.read(driverAdvanceRemoteDataSourceProvider),
  );
});

final getDriverAdvancesUseCaseProvider =
    Provider<GetDriverAdvancesUseCase>((ref) {
  return GetDriverAdvancesUseCase(
    ref.read(driverAdvanceRepositoryProvider),
  );
});

final addDriverAdvanceUseCaseProvider =
    Provider<AddDriverAdvanceUseCase>((ref) {
  return AddDriverAdvanceUseCase(
    ref.read(driverAdvanceRepositoryProvider),
  );
});

final markDriverAdvancePaidUseCaseProvider =
    Provider<MarkDriverAdvancePaidUseCase>((ref) {
  return MarkDriverAdvancePaidUseCase(
    ref.read(driverAdvanceRepositoryProvider),
  );
});

final driverAdvancesProvider =
    FutureProvider.family<List<DriverAdvanceEntity>, String>(
  (ref, driverId) async {
    final getAdvances = ref.read(getDriverAdvancesUseCaseProvider);
    return await getAdvances(driverId);
  },
);

class DriverAdvanceNotifier extends AutoDisposeAsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<bool> addAdvance({
    required String driverId,
    required double amount,
    required DateTime date,
    required String note,
  }) async {
    state = const AsyncLoading();

    final result = await AsyncValue.guard(() async {
      await ref.read(addDriverAdvanceUseCaseProvider).call(
            driverId: driverId,
            amount: amount,
            date: date,
            note: note,
          );
      ref.invalidate(driverAdvancesProvider(driverId));
    });

    state = result;
    return !result.hasError;
  }

  Future<bool> markAdvancePaid({
    required String driverId,
    required String advanceId,
  }) async {
    state = const AsyncLoading();

    final result = await AsyncValue.guard(() async {
      await ref.read(markDriverAdvancePaidUseCaseProvider).call(
            driverId: driverId,
            advanceId: advanceId,
          );
      ref.invalidate(driverAdvancesProvider(driverId));
    });

    state = result;
    return !result.hasError;
  }
}

final driverAdvanceNotifierProvider =
    AsyncNotifierProvider.autoDispose<DriverAdvanceNotifier, void>(
  DriverAdvanceNotifier.new,
);
