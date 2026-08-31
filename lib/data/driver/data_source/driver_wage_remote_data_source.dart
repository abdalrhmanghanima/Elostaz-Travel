import 'package:elostaz_travel/data/driver/model/driver_wage_entry_model.dart';
import 'package:elostaz_travel/data/driver/model/driver_wage_payment_model.dart';

abstract class DriverWageRemoteDataSource {
  Future<List<DriverWageEntryModel>> getDriverWageEntries(String driverId);

  Future<List<DriverWagePaymentModel>> getDriverWagePayments(String driverId);

  Future<List<DriverWageEntryModel>> getAllWageEntries();

  Future<List<DriverWagePaymentModel>> getAllWagePayments();

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
