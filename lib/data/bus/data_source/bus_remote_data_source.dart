import 'package:elostaz_travel/domain/bus/entity/bus_entity.dart';

abstract class BusRemoteDataSource {
  Future<List<BusEntity>> getBuses();

  Future<BusEntity> getBus({
    required String busId,
  });

  Future<void> addBus({
    required BusEntity bus,
  });

  Future<void> updateBus({
    required BusEntity bus,
  });

  Future<void> deleteBus({
    required String busId,
  });
}