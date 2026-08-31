import 'package:elostaz_travel/domain/driver/repository/driver_wage_repository.dart';

class AddDriverWageEntryUseCase {
  final DriverWageRepository repository;

  AddDriverWageEntryUseCase(this.repository);

  Future<void> call({
    required String driverId,
    required double amount,
    required DateTime date,
    required String notes,
  }) {
    return repository.addDriverWageEntry(
      driverId: driverId,
      amount: amount,
      date: date,
      notes: notes,
    );
  }
}
