import 'package:elostaz_travel/domain/driver/repository/driver_repository.dart';

class AddDriverUseCase {
  final DriverRepository repository;

  AddDriverUseCase({
    required this.repository,
  });

  Future<void> call({
    required String name,
    required String phone,
  }) {
    return repository.addDriver(
      name: name,
      phone: phone,
    );
  }
}