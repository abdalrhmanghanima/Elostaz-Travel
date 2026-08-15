import 'package:elostaz_travel/domain/driver/entity/driver_entity.dart';

abstract class DriverRepository {
  Future<List<DriverEntity>> getDrivers();
  Future<void> addDriver({
    required String name,
    required String phone,
  });
  Future<void> deleteDriver(String driverId);

}