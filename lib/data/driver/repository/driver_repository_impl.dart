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
  Future<String> addDriver({
    required String name,
    required String phone,
    required int tripsCount,
    required double totalRevenue,
    String? idCardImageUrl,
    String? licenseImageUrl,
  }) async {
    return await remoteDataSource.addDriver(
      name: name,
      phone: phone,
      tripsCount: tripsCount,
      totalRevenue: totalRevenue,
      idCardImageUrl: idCardImageUrl,
      licenseImageUrl: licenseImageUrl,
    );
  }

  @override
  Future<void> updateDriver({
    required String id,
    required String name,
    required String phone,
    required int tripsCount,
    required double totalRevenue,
    String? idCardImageUrl,
    String? licenseImageUrl,
  }) async {
    return await remoteDataSource.updateDriver(
      id: id,
      name: name,
      phone: phone,
      tripsCount: tripsCount,
      totalRevenue: totalRevenue,
      idCardImageUrl: idCardImageUrl,
      licenseImageUrl: licenseImageUrl,
    );
  }

  @override
  Future<void> deleteDriver(String driverId) {
    return remoteDataSource.deleteDriver(driverId);
  }
}