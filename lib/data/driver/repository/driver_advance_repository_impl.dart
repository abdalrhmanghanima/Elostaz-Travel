import 'package:elostaz_travel/data/driver/data_source/driver_advance_remote_data_source.dart';
import 'package:elostaz_travel/domain/driver/entity/driver_advance_entity.dart';
import 'package:elostaz_travel/domain/driver/repository/driver_advance_repository.dart';

class DriverAdvanceRepositoryImpl implements DriverAdvanceRepository {
  final DriverAdvanceRemoteDataSource remoteDataSource;

  DriverAdvanceRepositoryImpl({
    required this.remoteDataSource,
  });

  @override
  Future<List<DriverAdvanceEntity>> getDriverAdvances(String driverId) async {
    return await remoteDataSource.getDriverAdvances(driverId);
  }

  @override
  Future<void> addDriverAdvance({
    required String driverId,
    required double amount,
    required DateTime date,
    required String note,
  }) {
    return remoteDataSource.addDriverAdvance(
      driverId: driverId,
      amount: amount,
      date: date,
      note: note,
    );
  }

  @override
  Future<void> markDriverAdvancePaid({
    required String driverId,
    required String advanceId,
  }) {
    return remoteDataSource.markDriverAdvancePaid(
      driverId: driverId,
      advanceId: advanceId,
    );
  }
}
