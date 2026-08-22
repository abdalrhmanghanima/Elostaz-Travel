import 'package:elostaz_travel/domain/factory/entity/factory_entity.dart';
import 'package:elostaz_travel/presentation/home/tabs/factory/provider/factory_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FactoriesNotifier extends AsyncNotifier<List<FactoryEntity>> {
  @override
  Future<List<FactoryEntity>> build() async {
    return await ref.read(getFactoriesUseCaseProvider).call();
  }

  Future<void> getFactories() async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(
      () => ref.read(getFactoriesUseCaseProvider).call(),
    );
  }

  Future<bool> addFactory({
    required String name,
    required String phone,
    required String details,
    required double totalRevenue,
    required int tripsCount,
  }) async {
    state = const AsyncLoading();

    final result = await AsyncValue.guard(
      () => ref.read(addFactoryUseCaseProvider).call(
            name: name,
            phone: phone,
            details: details,
            totalRevenue: totalRevenue,
            tripsCount: tripsCount,
          ),
    );

    if (result.hasError) {
      state = AsyncError(result.error!, result.stackTrace!);
      return false;
    }

    state = await AsyncValue.guard(
      () => ref.read(getFactoriesUseCaseProvider).call(),
    );

    return true;
  }

  Future<bool> updateFactory(FactoryEntity factory) async {
    state = const AsyncLoading();

    final result = await AsyncValue.guard(
      () => ref.read(updateFactoryUseCaseProvider).call(factory),
    );

    if (result.hasError) {
      state = AsyncError(result.error!, result.stackTrace!);
      return false;
    }

    state = await AsyncValue.guard(
      () => ref.read(getFactoriesUseCaseProvider).call(),
    );

    return true;
  }

  Future<bool> deleteFactory(String factoryId) async {
    state = const AsyncLoading();

    final result = await AsyncValue.guard(
      () => ref.read(deleteFactoryUseCaseProvider).call(factoryId),
    );

    if (result.hasError) {
      state = AsyncError(result.error!, result.stackTrace!);
      return false;
    }

    state = await AsyncValue.guard(
      () => ref.read(getFactoriesUseCaseProvider).call(),
    );

    return true;
  }
}
