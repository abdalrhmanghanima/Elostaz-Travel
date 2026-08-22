import 'package:elostaz_travel/data/driver/model/driver_model.dart';

abstract class DriverRemoteDataSource {
  Future<List<DriverModel>> getDrivers();
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
