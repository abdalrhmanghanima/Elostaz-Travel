import 'package:elostaz_travel/data/driver/data_source/driver_wage_remote_data_source.dart';
import 'package:elostaz_travel/domain/driver/entity/driver_wage_entry_entity.dart';
import 'package:elostaz_travel/domain/driver/entity/driver_wage_payment_entity.dart';
import 'package:elostaz_travel/domain/driver/repository/driver_wage_repository.dart';

class DriverWageRepositoryImpl implements DriverWageRepository {
  final DriverWageRemoteDataSource remoteDataSource;

  DriverWageRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<DriverWageEntryEntity>> getDriverWageEntries(String driverId) {
    return remoteDataSource.getDriverWageEntries(driverId);
  }

  @override
  Future<List<DriverWagePaymentEntity>> getDriverWagePayments(String driverId) {
    return remoteDataSource.getDriverWagePayments(driverId);
  }

  @override
  Future<List<DriverWageEntryEntity>> getAllWageEntries() {
    return remoteDataSource.getAllWageEntries();
  }

  @override
  Future<List<DriverWagePaymentEntity>> getAllWagePayments() {
    return remoteDataSource.getAllWagePayments();
  }

  @override
  Future<void> addDriverWageEntry({
    required String driverId,
    required double amount,
    required DateTime date,
    required String notes,
  }) {
    return remoteDataSource.addDriverWageEntry(
      driverId: driverId,
      amount: amount,
      date: date,
      notes: notes,
    );
  }

  @override
  Future<void> addDriverWagePayment({
    required String driverId,
    required double amount,
    required DateTime date,
    required String notes,
  }) {
    return remoteDataSource.addDriverWagePayment(
      driverId: driverId,
      amount: amount,
      date: date,
      notes: notes,
    );
  }
}
