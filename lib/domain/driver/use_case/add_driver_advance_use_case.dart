import 'package:elostaz_travel/domain/driver/repository/driver_advance_repository.dart';

class AddDriverAdvanceUseCase {
  final DriverAdvanceRepository repository;

  AddDriverAdvanceUseCase(this.repository);

  Future<void> call({
    required String driverId,
    required double amount,
    required DateTime date,
    required String note,
  }) {
    return repository.addDriverAdvance(
      driverId: driverId,
      amount: amount,
      date: date,
      note: note,
    );
  }
}
