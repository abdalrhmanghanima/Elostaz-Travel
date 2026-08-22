import 'package:elostaz_travel/core/services/driver_local_image_service.dart';
import 'package:elostaz_travel/domain/driver/entity/driver_entity.dart';
import 'package:elostaz_travel/presentation/home/tabs/driver/provider/driver_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DriversNotifier extends AsyncNotifier<List<DriverEntity>> {
  @override
  Future<List<DriverEntity>> build() async {
    return await ref.read(getDriversUseCaseProvider).call();
  }

  Future<void> getDrivers() async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(
      () => ref.read(getDriversUseCaseProvider).call(),
    );
  }

  Future<String?> addDriver({
    required String name,
    required String phone,
    required double totalRevenue,
    required int tripsCount,
    String? idCardImageUrl,
    String? licenseImageUrl,
  }) async {
    state = const AsyncLoading();

    String? createdId;
    final result = await AsyncValue.guard(() async {
      createdId = await ref.read(addDriverUseCaseProvider).call(
            name: name,
            phone: phone,
            totalRevenue: totalRevenue,
            tripsCount: tripsCount,
            idCardImageUrl: idCardImageUrl,
            licenseImageUrl: licenseImageUrl,
          );
      return await ref.read(getDriversUseCaseProvider).call();
    });

    state = result;
    return createdId;
  }

  Future<bool> updateDriver({
    required String id,
    required String name,
    required String phone,
    required double totalRevenue,
    required int tripsCount,
    String? idCardImageUrl,
    String? licenseImageUrl,
  }) async {
    state = const AsyncLoading();

    bool success = false;
    final result = await AsyncValue.guard(() async {
      await ref.read(updateDriverUseCaseProvider).call(
            id: id,
            name: name,
            phone: phone,
            totalRevenue: totalRevenue,
            tripsCount: tripsCount,
            idCardImageUrl: idCardImageUrl,
            licenseImageUrl: licenseImageUrl,
          );
      success = true;
      return await ref.read(getDriversUseCaseProvider).call();
    });

    state = result;
    return success;
  }

  Future<void> deleteDriver(String driverId) async {
    state = const AsyncLoading();

    await AsyncValue.guard(
      () => ref.read(deleteDriverUseCaseProvider).call(driverId),
    );

    await DriverLocalImageService.instance.deleteDriverImages(driverId);

    state = await AsyncValue.guard(
      () => ref.read(getDriversUseCaseProvider).call(),
    );
  }
}