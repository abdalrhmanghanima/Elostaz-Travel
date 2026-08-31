import 'package:elostaz_travel/domain/driver/entity/driver_wage_entry_entity.dart';
import 'package:elostaz_travel/domain/driver/entity/driver_wage_payment_entity.dart';

abstract class DriverWageRepository {
  Future<List<DriverWageEntryEntity>> getDriverWageEntries(String driverId);

  Future<List<DriverWagePaymentEntity>> getDriverWagePayments(String driverId);

  Future<List<DriverWageEntryEntity>> getAllWageEntries();

  Future<List<DriverWagePaymentEntity>> getAllWagePayments();

  Future<void> addDriverWageEntry({
    required String driverId,
    required double amount,
    required DateTime date,
    required String notes,
  });

  Future<void> addDriverWagePayment({
    required String driverId,
    required double amount,
    required DateTime date,
    required String notes,
  });
}
