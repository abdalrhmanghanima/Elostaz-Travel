import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elostaz_travel/data/factory/data_source/factory_remote_data_source.dart';
import 'package:elostaz_travel/data/factory/data_source/factory_remote_data_source_impl.dart';
import 'package:elostaz_travel/data/factory/repository/factory_repository_impl.dart';
import 'package:elostaz_travel/domain/factory/entity/factory_entity.dart';
import 'package:elostaz_travel/domain/factory/repository/factory_repository.dart';
import 'package:elostaz_travel/domain/factory/use_case/add_factory_use_case.dart';
import 'package:elostaz_travel/domain/factory/use_case/delete_factory_use_case.dart';
import 'package:elostaz_travel/domain/factory/use_case/get_factories_use_case.dart';
import 'package:elostaz_travel/domain/factory/use_case/update_factory_use_case.dart';
import 'package:elostaz_travel/presentation/home/tabs/factory/provider/factory_notifier.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final factoryRemoteDataSourceProvider =
    Provider<FactoryRemoteDataSource>((ref) {
  return FactoryRemoteDataSourceImpl(
    firestore: FirebaseFirestore.instance,
    auth: FirebaseAuth.instance,
  );
});

final factoryRepositoryProvider = Provider<FactoryRepository>((ref) {
  return FactoryRepositoryImpl(
    remoteDataSource: ref.read(factoryRemoteDataSourceProvider),
  );
});

final getFactoriesUseCaseProvider = Provider<GetFactoriesUseCase>((ref) {
  return GetFactoriesUseCase(
    repository: ref.read(factoryRepositoryProvider),
  );
});

final addFactoryUseCaseProvider = Provider<AddFactoryUseCase>((ref) {
  return AddFactoryUseCase(
    repository: ref.read(factoryRepositoryProvider),
  );
});

final updateFactoryUseCaseProvider = Provider<UpdateFactoryUseCase>((ref) {
  return UpdateFactoryUseCase(
    repository: ref.read(factoryRepositoryProvider),
  );
});

final deleteFactoryUseCaseProvider = Provider<DeleteFactoryUseCase>((ref) {
  return DeleteFactoryUseCase(
    repository: ref.read(factoryRepositoryProvider),
  );
});

final factoriesProvider =
    AsyncNotifierProvider<FactoriesNotifier, List<FactoryEntity>>(
  FactoriesNotifier.new,
);
