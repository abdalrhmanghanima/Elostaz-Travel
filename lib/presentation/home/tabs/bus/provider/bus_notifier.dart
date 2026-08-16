import 'package:elostaz_travel/domain/bus/entity/bus_entity.dart';
import 'package:elostaz_travel/domain/bus/use_cases/add_bus_use_case.dart';
import 'package:elostaz_travel/domain/bus/use_cases/delete_bus_use_case.dart';
import 'package:elostaz_travel/domain/bus/use_cases/get_bus_use_case.dart';
import 'package:elostaz_travel/domain/bus/use_cases/get_buses_use_case.dart';
import 'package:elostaz_travel/domain/bus/use_cases/update_bus_use_case.dart';
import 'package:elostaz_travel/presentation/home/tabs/bus/provider/bus_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BusNotifier extends AsyncNotifier<List<BusEntity>> {
  late final GetBusesUseCase _getBusesUseCase;
  late final GetBusUseCase _getBusUseCase;
  late final AddBusUseCase _addBusUseCase;
  late final UpdateBusUseCase _updateBusUseCase;
  late final DeleteBusUseCase _deleteBusUseCase;

  @override
  Future<List<BusEntity>> build() async {
    _getBusesUseCase = ref.read(getBusesUseCaseProvider);
    _getBusUseCase = ref.read(getBusUseCaseProvider);
    _addBusUseCase = ref.read(addBusUseCaseProvider);
    _updateBusUseCase = ref.read(updateBusUseCaseProvider);
    _deleteBusUseCase = ref.read(deleteBusUseCaseProvider);

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