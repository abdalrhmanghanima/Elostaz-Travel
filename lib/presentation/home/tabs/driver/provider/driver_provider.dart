import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elostaz_travel/data/driver/data_source/driver_remote_data_source.dart';
import 'package:elostaz_travel/data/driver/data_source/driver_remote_data_source_impl.dart';
import 'package:elostaz_travel/domain/driver/use_case/add_driver_use_case.dart';
import 'package:elostaz_travel/domain/driver/use_case/delete_driver_use_case.dart';
import 'package:elostaz_travel/domain/driver/use_case/get_drivers_use_case.dart';
import 'package:elostaz_travel/domain/driver/use_case/update_driver_use_case.dart';
import 'package:elostaz_travel/presentation/home/tabs/driver/provider/driver_notifier.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:elostaz_travel/data/driver/repository/driver_repository_impl.dart';
import 'package:elostaz_travel/domain/driver/entity/driver_entity.dart';
import 'package:elostaz_travel/domain/driver/repository/driver_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final driverRemoteDataSourceProvider = Provider<DriverRemoteDataSource>((ref) {
  return DriverRemoteDataSourceImpl(
    firestore: FirebaseFirestore.instance,
    auth: FirebaseAuth.instance,
  );
});

final driverRepositoryProvider = Provider<DriverRepository>((ref) {
  return DriverRepositoryImpl(
    remoteDataSource: ref.read(driverRemoteDataSourceProvider),
  );
});

final getDriversUseCaseProvider = Provider<GetDriversUseCase>((ref) {
  return GetDriversUseCase(
    repository: ref.read(driverRepositoryProvider),
  );
});
final addDriverUseCaseProvider =
Provider<AddDriverUseCase>((ref) {
  return AddDriverUseCase(
    ref.read(driverRepositoryProvider),
  );
});

final updateDriverUseCaseProvider =
Provider<UpdateDriverUseCase>((ref) {
  return UpdateDriverUseCase(
    ref.read(driverRepositoryProvider),
  );
});

final deleteDriverUseCaseProvider =
Provider<DeleteDriverUseCase>((ref) {
  return DeleteDriverUseCase(
    repository: ref.read(driverRepositoryProvider),
  );
});

final driversProvider =
AsyncNotifierProvider<DriversNotifier, List<DriverEntity>>(
  DriversNotifier.new,
);

