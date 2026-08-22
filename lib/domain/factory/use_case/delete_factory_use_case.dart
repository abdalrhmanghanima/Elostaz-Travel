import 'package:elostaz_travel/domain/factory/repository/factory_repository.dart';

class DeleteFactoryUseCase {
  final FactoryRepository repository;

  DeleteFactoryUseCase({required this.repository});

  Future<void> call(String factoryId) {
    return repository.deleteFactory(factoryId);
  }
}
