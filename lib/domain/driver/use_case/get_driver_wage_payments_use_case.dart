import 'package:elostaz_travel/domain/driver/entity/driver_wage_payment_entity.dart';
import 'package:elostaz_travel/domain/driver/repository/driver_wage_repository.dart';

class GetDriverWagePaymentsUseCase {
  final DriverWageRepository repository;

  GetDriverWagePaymentsUseCase(this.repository);

  Future<List<DriverWagePaymentEntity>> call(String driverId) {
    return repository.getDriverWagePayments(driverId);
  }
}
