import 'package:elostaz_travel/domain/driver/entity/driver_wage_entry_entity.dart';
import 'package:elostaz_travel/domain/driver/repository/driver_wage_repository.dart';

class GetAllDriverWageEntriesUseCase {
  final DriverWageRepository repository;

  GetAllDriverWageEntriesUseCase(this.repository);

  Future<List<DriverWageEntryEntity>> call() {
    return repository.getAllWageEntries();
  }
}
