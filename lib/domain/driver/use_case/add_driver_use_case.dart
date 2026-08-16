import 'package:elostaz_travel/domain/driver/repository/driver_repository.dart';

class AddDriverUseCase {
  final DriverRepository repository;

  AddDriverUseCase(this.repository);

  Future<void> call({
    required String name,
    required String phone,
    required int tripsCount,
    required double totalRevenue,
  }) {
    return repository.addDriver(
      name: name,
      phone: phone,
      tripsCount: tripsCount,
      totalRevenue: totalRevenue,
    );
  }
}