import 'package:elostaz_travel/domain/driver/entity/driver_wage_entry_entity.dart';
import 'package:elostaz_travel/domain/driver/repository/driver_wage_repository.dart';

class GetDriverWageEntriesUseCase {
  final DriverWageRepository repository;

  GetDriverWageEntriesUseCase(this.repository);

  Future<List<DriverWageEntryEntity>> call(String driverId) {
    return repository.getDriverWageEntries(driverId);
  }
}
