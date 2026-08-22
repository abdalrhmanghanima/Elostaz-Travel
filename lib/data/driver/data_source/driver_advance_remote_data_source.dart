import 'package:elostaz_travel/data/driver/model/driver_advance_model.dart';

abstract class DriverAdvanceRemoteDataSource {
  Future<List<DriverAdvanceModel>> getDriverAdvances(String driverId);
  Future<void> addDriverAdvance({
    required String driverId,
    required double amount,
    required DateTime date,
    required String note,
  });
  Future<void> markDriverAdvancePaid({
    required String driverId,
    required String advanceId,
  });
}
