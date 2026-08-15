import 'package:elostaz_travel/domain/driver/entity/driver_entity.dart';
import 'package:elostaz_travel/domain/driver/repository/driver_repository.dart';

class GetDriversUseCase {
  final DriverRepository repository;

  GetDriversUseCase({
    required this.repository,
  });

  Future<List<DriverEntity>> call() async {
    return await repository.getDrivers();
  }
}