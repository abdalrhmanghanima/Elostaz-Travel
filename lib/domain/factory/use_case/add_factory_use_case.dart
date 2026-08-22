import 'package:elostaz_travel/domain/factory/repository/factory_repository.dart';

class AddFactoryUseCase {
  final FactoryRepository repository;

  AddFactoryUseCase({required this.repository});

  Future<void> call({
    required String name,
    required String phone,
    required String details,
    required int tripsCount,
    required double totalRevenue,
  }) {
    return repository.addFactory(
      name: name,
      phone: phone,
      details: details,
      tripsCount: tripsCount,
      totalRevenue: totalRevenue,
    );
  }
}
