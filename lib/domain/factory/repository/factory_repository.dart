import 'package:elostaz_travel/domain/factory/entity/factory_entity.dart';

abstract class FactoryRepository {
  Future<List<FactoryEntity>> getFactories();

  Future<void> addFactory({
    required String name,
    required String phone,
    required String details,
    required int tripsCount,
    required double totalRevenue,
  });

  Future<void> updateFactory(FactoryEntity factory);

  Future<void> deleteFactory(String factoryId);
}
