import 'package:elostaz_travel/domain/driver/entity/driver_entity.dart';

abstract class DriverRepository {
  Future<List<DriverEntity>> getDrivers();
  Future<String> addDriver({
    required String name,
    required String phone,
    required int tripsCount,
    required double totalRevenue,
    String? idCardImageUrl,
    String? licenseImageUrl,
  });
  Future<void> updateDriver({
    required String id,
    required String name,
    required String phone,
    required int tripsCount,
    required double totalRevenue,
    String? idCardImageUrl,
    String? licenseImageUrl,
  });
  Future<void> deleteDriver(String driverId);
}