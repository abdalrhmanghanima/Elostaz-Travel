import 'package:elostaz_travel/domain/factory/entity/factory_entity.dart';
import 'package:elostaz_travel/domain/factory/repository/factory_repository.dart';

class GetFactoriesUseCase {
  final FactoryRepository repository;

  GetFactoriesUseCase({required this.repository});

  Future<List<FactoryEntity>> call() {
    return repository.getFactories();
  }
}
