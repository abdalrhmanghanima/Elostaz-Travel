import 'package:elostaz_travel/domain/bus/repository/bus_repository.dart';

class DeleteBusUseCase {
  final BusRepository repository;

  DeleteBusUseCase({
    required this.repository,
  });

  Future<void> call({
    required String busId,
  }) async {
    await repository.deleteBus(
      busId: busId,
    );
  }
}