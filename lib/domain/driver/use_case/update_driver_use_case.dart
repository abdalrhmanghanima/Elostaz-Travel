import 'package:elostaz_travel/domain/driver/repository/driver_repository.dart';

class UpdateDriverUseCase {
  final DriverRepository repository;

  UpdateDriverUseCase(this.repository);

  Future<void> call({
    required String id,
    required String name,
    required String phone,
    required int tripsCount,
    required double totalRevenue,
    String? idCardImageUrl,
    String? licenseImageUrl,
  }) {
    return repository.updateDriver(
      id: id,
      name: name,
      phone: phone,
      tripsCount: tripsCount,
      totalRevenue: totalRevenue,
      idCardImageUrl: idCardImageUrl,
      licenseImageUrl: licenseImageUrl,
    );
  }
}
