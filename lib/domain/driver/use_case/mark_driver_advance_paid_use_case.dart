import 'package:elostaz_travel/domain/driver/repository/driver_advance_repository.dart';

class MarkDriverAdvancePaidUseCase {
  final DriverAdvanceRepository repository;

  MarkDriverAdvancePaidUseCase(this.repository);

  Future<void> call({
    required String driverId,
    required String advanceId,
  }) {
    return repository.markDriverAdvancePaid(
      driverId: driverId,
      advanceId: advanceId,
    );
  }
}
