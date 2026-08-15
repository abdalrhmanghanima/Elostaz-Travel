import 'package:elostaz_travel/domain/bus/entity/bus_entity.dart';
import 'package:elostaz_travel/domain/bus/repository/bus_repository.dart';

class GetBusUseCase {
  final BusRepository repository;

  GetBusUseCase({
    required this.repository,
  });

  Future<BusEntity> call({
    required String busId,
  }) async {
    return await repository.getBus(
      busId: busId,
    );
  }
}