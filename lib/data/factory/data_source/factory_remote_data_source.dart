import 'package:elostaz_travel/data/factory/model/factory_model.dart';

abstract class FactoryRemoteDataSource {
  Future<List<FactoryModel>> getFactories();

  Future<void> addFactory({
    required String name,
    required String phone,
    required String details,
    required int tripsCount,
    required double totalRevenue,
  });

  Future<void> updateFactory(FactoryModel factory);

  Future<void> deleteFactory(String factoryId);
}
