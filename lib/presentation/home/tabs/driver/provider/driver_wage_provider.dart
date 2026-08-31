import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elostaz_travel/data/driver/data_source/driver_wage_remote_data_source.dart';
import 'package:elostaz_travel/data/driver/data_source/driver_wage_remote_data_source_impl.dart';
import 'package:elostaz_travel/data/driver/repository/driver_wage_repository_impl.dart';
import 'package:elostaz_travel/domain/driver/entity/driver_wage_entry_entity.dart';
import 'package:elostaz_travel/domain/driver/entity/driver_wage_payment_entity.dart';
import 'package:elostaz_travel/domain/driver/repository/driver_wage_repository.dart';
import 'package:elostaz_travel/domain/driver/use_case/add_driver_wage_entry_use_case.dart';
import 'package:elostaz_travel/domain/driver/use_case/add_driver_wage_payment_use_case.dart';
import 'package:elostaz_travel/domain/driver/use_case/get_all_driver_wage_entries_use_case.dart';
import 'package:elostaz_travel/domain/driver/use_case/get_all_driver_wage_payments_use_case.dart';
import 'package:elostaz_travel/domain/driver/use_case/get_driver_wage_entries_use_case.dart';
import 'package:elostaz_travel/domain/driver/use_case/get_driver_wage_payments_use_case.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final driverWageRemoteDataSourceProvider =
    Provider<DriverWageRemoteDataSource>((ref) {
  return DriverWageRemoteDataSourceImpl(
    firestore: FirebaseFirestore.instance,
    auth: FirebaseAuth.instance,
  );
});

final driverWageRepositoryProvider = Provider<DriverWageRepository>((ref) {
  return DriverWageRepositoryImpl(
    remoteDataSource: ref.read(driverWageRemoteDataSourceProvider),
  );
});

final getDriverWageEntriesUseCaseProvider =
    Provider<GetDriverWageEntriesUseCase>((ref) {
  return GetDriverWageEntriesUseCase(ref.read(driverWageRepositoryProvider));
});

final getDriverWagePaymentsUseCaseProvider =
    Provider<GetDriverWagePaymentsUseCase>((ref) {
  return GetDriverWagePaymentsUseCase(ref.read(driverWageRepositoryProvider));
});

final getAllDriverWageEntriesUseCaseProvider =
    Provider<GetAllDriverWageEntriesUseCase>((ref) {
  return GetAllDriverWageEntriesUseCase(ref.read(driverWageRepositoryProvider));
});

final getAllDriverWagePaymentsUseCaseProvider =
    Provider<GetAllDriverWagePaymentsUseCase>((ref) {
  return GetAllDriverWagePaymentsUseCase(
    ref.read(driverWageRepositoryProvider),
  );
});

final addDriverWageEntryUseCaseProvider =
    Provider<AddDriverWageEntryUseCase>((ref) {
  return AddDriverWageEntryUseCase(ref.read(driverWageRepositoryProvider));
});

final addDriverWagePaymentUseCaseProvider =
    Provider<AddDriverWagePaymentUseCase>((ref) {
  return AddDriverWagePaymentUseCase(ref.read(driverWageRepositoryProvider));
});

final driverWageEntriesProvider =
    FutureProvider.family<List<DriverWageEntryEntity>, String>(
  (ref, driverId) async {
    return ref.read(getDriverWageEntriesUseCaseProvider)(driverId);
  },
);

final driverWagePaymentsProvider =
    FutureProvider.family<List<DriverWagePaymentEntity>, String>(
  (ref, driverId) async {
    return ref.read(getDriverWagePaymentsUseCaseProvider)(driverId);
  },
);

final allDriverWageEntriesProvider =
    FutureProvider<List<DriverWageEntryEntity>>((ref) async {
  return ref.read(getAllDriverWageEntriesUseCaseProvider)();
});

final allDriverWagePaymentsProvider =
    FutureProvider<List<DriverWagePaymentEntity>>((ref) async {
  return ref.read(getAllDriverWagePaymentsUseCaseProvider)();
});

class DriverWageNotifier extends AutoDisposeAsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<bool> addWageEntry({
    required String driverId,
    required double amount,
    required DateTime date,
    required String notes,
  }) async {
    state = const AsyncLoading();

    final result = await AsyncValue.guard(() async {
      await ref.read(addDriverWageEntryUseCaseProvider).call(
            driverId: driverId,
            amount: amount,
            date: date,
            notes: notes,
          );
      ref.invalidate(driverWageEntriesProvider(driverId));
      ref.invalidate(allDriverWageEntriesProvider);
    });

    state = result;
    return !result.hasError;
  }

  Future<bool> addWagePayment({
    required String driverId,
    required double amount,
    required DateTime date,
    required String notes,
  }) async {
    state = const AsyncLoading();

    final result = await AsyncValue.guard(() async {
      await ref.read(addDriverWagePaymentUseCaseProvider).call(
            driverId: driverId,
            amount: amount,
            date: date,
            notes: notes,
          );
      ref.invalidate(driverWagePaymentsProvider(driverId));
      ref.invalidate(allDriverWagePaymentsProvider);
    });

    state = result;
    return !result.hasError;
  }

  Object? get lastError => state.error;
}

final driverWageNotifierProvider =
    AsyncNotifierProvider.autoDispose<DriverWageNotifier, void>(
  DriverWageNotifier.new,
);
