import 'package:elostaz_travel/domain/driver/entity/driver_advance_entity.dart';
import 'package:elostaz_travel/domain/driver/repository/driver_advance_repository.dart';

class GetDriverAdvancesUseCase {
  final DriverAdvanceRepository repository;

  GetDriverAdvancesUseCase(this.repository);

  Future<List<DriverAdvanceEntity>> call(String driverId) {
    return repository.getDriverAdvances(driverId);
  }
}
