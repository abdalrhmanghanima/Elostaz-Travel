import 'package:elostaz_travel/domain/driver/entity/driver_wage_payment_entity.dart';
import 'package:elostaz_travel/domain/driver/repository/driver_wage_repository.dart';

class GetAllDriverWagePaymentsUseCase {
  final DriverWageRepository repository;

  GetAllDriverWagePaymentsUseCase(this.repository);

  Future<List<DriverWagePaymentEntity>> call() {
    return repository.getAllWagePayments();
  }
}
