import 'package:elostaz_travel/domain/bus/entity/bus_entity.dart';
import 'package:elostaz_travel/domain/bus/repository/bus_repository.dart';

class UpdateBusUseCase {
  final BusRepository repository;

  UpdateBusUseCase({
    required this.repository,
  });

  Future<void> call({
    required BusEntity bus,
  }) async {
    await repository.updateBus(
      bus: bus,
    );
  }
}