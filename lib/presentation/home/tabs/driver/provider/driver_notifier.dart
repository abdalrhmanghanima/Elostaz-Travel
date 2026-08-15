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
  Future<void> addDriver({
    required String name,
    required String phone,
  }) async {
    state = const AsyncLoading();

    await AsyncValue.guard(
          () => ref.read(addDriverUseCaseProvider).call(
        name: name,
        phone: phone,
      ),
    );

    state = await AsyncValue.guard(
          () => ref.read(getDriversUseCaseProvider).call(),
    );
  }
  Future<void> deleteDriver(String driverId) async {
    state = const AsyncLoading();

    await AsyncValue.guard(
          () => ref.read(deleteDriverUseCaseProvider).call(driverId),
    );

    state = await AsyncValue.guard(
          () => ref.read(getDriversUseCaseProvider).call(),
    );
  }
}