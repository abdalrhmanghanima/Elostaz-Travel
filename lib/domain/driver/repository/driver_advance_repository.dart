import 'package:elostaz_travel/domain/driver/entity/driver_advance_entity.dart';

abstract class DriverAdvanceRepository {
  Future<List<DriverAdvanceEntity>> getDriverAdvances(String driverId);
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
