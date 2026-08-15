import 'package:elostaz_travel/data/bus/data_source/bus_remote_data_source.dart';
import 'package:elostaz_travel/domain/bus/entity/bus_entity.dart';
import 'package:elostaz_travel/domain/bus/repository/bus_repository.dart';

class BusRepositoryImpl implements BusRepository {
  final BusRemoteDataSource remoteDataSource;

  BusRepositoryImpl({
    required this.remoteDataSource,
  });

  @override
  Future<List<BusEntity>> getBuses() async {
    return await remoteDataSource.getBuses();
  }

  @override
  Future<BusEntity> getBus({
    required String busId,
  }) async {
    return await remoteDataSource.getBus(
      busId: busId,
    );
  }

  @override
  Future<void> addBus({
    required BusEntity bus,
  }) async {
    await remoteDataSource.addBus(
      bus: bus,
    );
  }

  @override
  Future<void> updateBus({
    required BusEntity bus,
  }) async {
    await remoteDataSource.updateBus(
      bus: bus,
    );
  }

  @override
  Future<void> deleteBus({
    required String busId,
  }) async {
    await remoteDataSource.deleteBus(
      busId: busId,
    );
  }
}