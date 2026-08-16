import 'package:elostaz_travel/data/driver/model/driver_model.dart';

abstract class DriverRemoteDataSource {
  Future<List<DriverModel>> getDrivers();
  Future<void> addDriver({
    required String name,
    required String phone,
    required int tripsCount,
    required double totalRevenue,
  });
  Future<void> deleteDriver(String driverId);
}
