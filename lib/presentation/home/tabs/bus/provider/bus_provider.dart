import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elostaz_travel/data/bus/data_source/bus_remote_data_source.dart';
import 'package:elostaz_travel/data/bus/data_source/bus_remote_data_source_impl.dart';
import 'package:elostaz_travel/data/bus/repository/bus_repository_impl.dart';
import 'package:elostaz_travel/domain/bus/repository/bus_repository.dart';
import 'package:elostaz_travel/domain/bus/use_cases/add_bus_use_case.dart';
import 'package:elostaz_travel/domain/bus/use_cases/delete_bus_use_case.dart';
import 'package:elostaz_travel/domain/bus/use_cases/get_bus_use_case.dart';
import 'package:elostaz_travel/domain/bus/use_cases/get_buses_use_case.dart';
import 'package:elostaz_travel/domain/bus/use_cases/update_bus_use_case.dart';
import 'package:elostaz_travel/domain/bus/entity/bus_entity.dart';
import 'package:elostaz_travel/presentation/home/tabs/bus/provider/bus_notifier.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final firebaseFirestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

final busRemoteDataSourceProvider = Provider<BusRemoteDataSource>((ref) {
  return BusRemoteDataSourceImpl(
    firestore: ref.read(firebaseFirestoreProvider),
    firebaseAuth: ref.read(firebaseAuthProvider),
  );
});

final busRepositoryProvider = Provider<BusRepository>((ref) {
  return BusRepositoryImpl(
    remoteDataSource: ref.read(busRemoteDataSourceProvider),
  );
});

final getBusesUseCaseProvider = Provider<GetBusesUseCase>((ref) {
  return GetBusesUseCase(
    repository: ref.read(busRepositoryProvider),
  );
});

final getBusUseCaseProvider = Provider<GetBusUseCase>((ref) {
  return GetBusUseCase(
    repository: ref.read(busRepositoryProvider),
  );
});

final addBusUseCaseProvider = Provider<AddBusUseCase>((ref) {
  return AddBusUseCase(
    repository: ref.read(busRepositoryProvider),
  );
});

final updateBusUseCaseProvider = Provider<UpdateBusUseCase>((ref) {
  return UpdateBusUseCase(
    repository: ref.read(busRepositoryProvider),
  );
});

final deleteBusUseCaseProvider = Provider<DeleteBusUseCase>((ref) {
  return DeleteBusUseCase(
    repository: ref.read(busRepositoryProvider),
  );
});

final busProvider =
AsyncNotifierProvider<BusNotifier, List<BusEntity>>(
  BusNotifier.new,
);