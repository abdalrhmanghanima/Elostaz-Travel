import 'package:elostaz_travel/domain/driver/repository/driver_wage_repository.dart';

class AddDriverWagePaymentUseCase {
  final DriverWageRepository repository;

  AddDriverWagePaymentUseCase(this.repository);

  Future<void> call({
    required String driverId,
    required double amount,
    required DateTime date,
    required String notes,
  }) {
    return repository.addDriverWagePayment(
      driverId: driverId,
      amount: amount,
      date: date,
      notes: notes,
    );
  }
}
