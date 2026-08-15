import 'package:elostaz_travel/domain/bus/entity/bus_entity.dart';
import 'package:elostaz_travel/domain/bus/repository/bus_repository.dart';

class GetBusesUseCase {
  final BusRepository repository;

  GetBusesUseCase({
    required this.repository,
  });

  Future<List<BusEntity>> call() async {
    return await repository.getBuses();
  }
}