import 'package:elostaz_travel/data/driver/data_source/driver_remote_data_source.dart';
import 'package:elostaz_travel/domain/driver/entity/driver_entity.dart';
import 'package:elostaz_travel/domain/driver/repository/driver_repository.dart';

class DriverRepositoryImpl implements DriverRepository {
  final DriverRemoteDataSource remoteDataSource;

  DriverRepositoryImpl({
    required this.remoteDataSource,
  });

  @override
  Future<List<DriverEntity>> getDrivers() async {
    return await remoteDataSource.getDrivers();
  }
  @override
  Future<void> addDriver({
    required String name,
    required String phone,
    required int tripsCount,
    required double totalRevenue,
  }) {
    return remoteDataSource.addDriver(
      name: name,
      phone: phone,
      tripsCount: tripsCount,
      totalRevenue: totalRevenue,
    );
  }
  @override
  Future<void> deleteDriver(String driverId) {
    return remoteDataSource.deleteDriver(driverId);
  }
}