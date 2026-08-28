import 'package:elostaz_travel/domain/bus/entity/bus_entity.dart';
import 'package:elostaz_travel/domain/bus/use_cases/add_bus_use_case.dart';
import 'package:elostaz_travel/domain/bus/use_cases/delete_bus_use_case.dart';
import 'package:elostaz_travel/domain/bus/use_cases/get_bus_use_case.dart';
import 'package:elostaz_travel/domain/bus/use_cases/get_buses_use_case.dart';
import 'package:elostaz_travel/domain/bus/use_cases/update_bus_use_case.dart';
import 'package:elostaz_travel/presentation/home/tabs/bus/provider/bus_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BusNotifier extends AsyncNotifier<List<BusEntity>> {
  // Use cases are read directly from ref on each use to avoid
  // LateInitializationError when build() is called more than once
  // (e.g. after ref.invalidate(busProvider)).
  GetBusesUseCase get _getBusesUseCase => ref.read(getBusesUseCaseProvider);
  GetBusUseCase get _getBusUseCase => ref.read(getBusUseCaseProvider);
  AddBusUseCase get _addBusUseCase => ref.read(addBusUseCaseProvider);
  UpdateBusUseCase get _updateBusUseCase => ref.read(updateBusUseCaseProvider);
  DeleteBusUseCase get _deleteBusUseCase => ref.read(deleteBusUseCaseProvider);

  @override
  Future<List<BusEntity>> build() async {
    return await _getBusesUseCase();
  }

  Future<void> addBus({
    required BusEntity bus,
  }) async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      await _addBusUseCase(bus: bus);
      return await _getBusesUseCase();
    });
  }

  Future<bool> updateBus({
    required BusEntity bus,
  }) async {
    state = const AsyncLoading();

    final result = await AsyncValue.guard(() async {
      await _updateBusUseCase(bus: bus);
      return await _getBusesUseCase();
    });

    state = result;

    return !result.hasError;
  }

  Future<bool> deleteBus({
    required String busId,
  }) async {
    state = const AsyncLoading();

    final result = await AsyncValue.guard(() async {
      await _deleteBusUseCase(busId: busId);
      return await _getBusesUseCase();
    });

    state = result;

    return !result.hasError;
  }

  Future<BusEntity> getBus({
    required String busId,
  }) async {
    return await _getBusUseCase(busId: busId);
  }

  Future<void> refreshBuses() async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      return await _getBusesUseCase();
    });
  }
}