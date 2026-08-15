import 'package:elostaz_travel/domain/driver/repository/driver_repository.dart';

class DeleteDriverUseCase {
  final DriverRepository repository;

  DeleteDriverUseCase({
    required this.repository,
  });

  Future<void> call(String driverId) {
    return repository.deleteDriver(driverId);
  }
}