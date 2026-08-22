import 'package:elostaz_travel/data/factory/data_source/factory_remote_data_source.dart';
import 'package:elostaz_travel/data/factory/model/factory_model.dart';
import 'package:elostaz_travel/domain/factory/entity/factory_entity.dart';
import 'package:elostaz_travel/domain/factory/repository/factory_repository.dart';

class FactoryRepositoryImpl implements FactoryRepository {
  final FactoryRemoteDataSource remoteDataSource;

  FactoryRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<FactoryEntity>> getFactories() {
    return remoteDataSource.getFactories();
  }

  @override
  Future<void> addFactory({
    required String name,
    required String phone,
    required String details,
    required int tripsCount,
    required double totalRevenue,
  }) {
    return remoteDataSource.addFactory(
      name: name,
      phone: phone,
      details: details,
      tripsCount: tripsCount,
      totalRevenue: totalRevenue,
    );
  }

  @override
  Future<void> updateFactory(FactoryEntity factory) {
    final model = FactoryModel(
      id: factory.id,
      name: factory.name,
      phone: factory.phone,
      details: factory.details,
      tripsCount: factory.tripsCount,
      totalRevenue: factory.totalRevenue,
      createdAt: factory.createdAt,
    );
    return remoteDataSource.updateFactory(model);
  }

  @override
  Future<void> deleteFactory(String factoryId) {
    return remoteDataSource.deleteFactory(factoryId);
  }
}
