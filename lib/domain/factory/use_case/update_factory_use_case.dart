import 'package:elostaz_travel/domain/factory/entity/factory_entity.dart';
import 'package:elostaz_travel/domain/factory/repository/factory_repository.dart';

class UpdateFactoryUseCase {
  final FactoryRepository repository;

  UpdateFactoryUseCase({required this.repository});

  Future<void> call(FactoryEntity factory) {
    return repository.updateFactory(factory);
  }
}
