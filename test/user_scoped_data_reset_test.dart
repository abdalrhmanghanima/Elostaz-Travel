import 'package:elostaz_travel/domain/bus/entity/bus_entity.dart';
import 'package:elostaz_travel/domain/bus/use_cases/get_buses_use_case.dart';
import 'package:elostaz_travel/domain/driver/entity/driver_entity.dart';
import 'package:elostaz_travel/domain/driver/use_case/get_drivers_use_case.dart';
import 'package:elostaz_travel/domain/trip/entity/trip_entity.dart';
import 'package:elostaz_travel/domain/trip/repository/trip_repository.dart';
import 'package:elostaz_travel/presentation/auth/provider/user_data_invalidation.dart';
import 'package:elostaz_travel/presentation/home/tabs/bus/provider/bus_provider.dart';
import 'package:elostaz_travel/presentation/home/tabs/driver/provider/driver_provider.dart';
import 'package:elostaz_travel/presentation/home/tabs/home/provider/home_stats_provider.dart';
import 'package:elostaz_travel/presentation/home/tabs/trip/provider/trip_provider.dart'
    as home_trip;
import 'package:elostaz_travel/presentation/trip/provider/trip_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// ── fakes ────────────────────────────────────────────────────────────────

class _FakeGetBusesUseCase implements GetBusesUseCase {
  final List<BusEntity> backing;
  _FakeGetBusesUseCase(this.backing);

  @override
  dynamic noSuchMethod(Invocation invocation) => null;

  @override
  Future<List<BusEntity>> call() async => List.of(backing);
}

class _FakeGetDriversUseCase implements GetDriversUseCase {
  final List<DriverEntity> backing;
  _FakeGetDriversUseCase(this.backing);

  @override
  dynamic noSuchMethod(Invocation invocation) => null;

  @override
  Future<List<DriverEntity>> call() async => List.of(backing);
}

class _FakeTripRepository implements TripRepository {
  final List<TripEntity> trips;
  _FakeTripRepository(this.trips);

  @override
  Future<List<TripEntity>> getAllTrips() async => List.of(trips);

  @override
  Future<List<TripEntity>> getMonthlyTrips({
    required int year,
    required int month,
  }) async =>
      trips
          .where(
            (t) =>
                t.effectiveDate.year == year && t.effectiveDate.month == month,
          )
          .toList();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

BusEntity _bus(String id) => BusEntity(
      id: id,
      busName: 'باص $id',
      plateNumber: '123',
      brand: 'مرسيدس',
      chassisNumber: 'CH$id',
      engineNumber: 'EN$id',
      passengerCount: 30,
      vehicleType: 'أتوبيس',
      licenseExpiryDate: DateTime(2030, 1, 1),
      specialConditions: '',
      insuranceType: 'مؤمنة',
    );

DriverEntity _driver(String id) => DriverEntity(
      id: id,
      name: 'سائق $id',
      phone: '01',
      tripsCount: 0,
      totalRevenue: 0,
    );

TripEntity _trip(String id, DateTime date) => TripEntity(
      id: id,
      driverId: 'd1',
      driverName: 'سائق',
      busId: 'b1',
      busName: 'باص',
      plateNumber: '123',
      revenue: 100,
      expenses: 10,
      createdAt: date,
      tripDate: date,
    );

void main() {
  // Pumps a trivial Consumer inside the container so the exact same WidgetRef
  // that the production root auth listener uses is available to call
  // invalidateUserScopedData with.
  Future<WidgetRef> captureRef(WidgetTester tester, ProviderContainer container) async {
    late WidgetRef captured;
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: Consumer(
          builder: (context, ref, _) {
            captured = ref;
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    return captured;
  }

  testWidgets(
      'invalidateUserScopedData drops account A data and re-resolves '
      'account B on next read', (tester) async {
    final busA = _bus('busA');
    final busB = _bus('busB');
    final driverA = _driver('drvA');
    final driverB = _driver('drvB');
    final tripA = _trip('tripA', DateTime.now());
    final tripB = _trip('tripB', DateTime.now());

    final buses = <BusEntity>[busA];
    final drivers = <DriverEntity>[driverA];
    final trips = <TripEntity>[tripA];
    final fakeTripRepo = _FakeTripRepository(trips);

    final container = ProviderContainer(
      overrides: [
        getBusesUseCaseProvider.overrideWithValue(_FakeGetBusesUseCase(buses)),
        getDriversUseCaseProvider
            .overrideWithValue(_FakeGetDriversUseCase(drivers)),
        tripRepositoryProvider.overrideWithValue(fakeTripRepo),
        home_trip.tripRepositoryProvider.overrideWithValue(fakeTripRepo),
      ],
    );
    addTearDown(container.dispose);

    final ref = await captureRef(tester, container);

    // Account A data fully loaded into the cached providers.
    expect((await container.read(busProvider.future)).single.id, 'busA');
    expect((await container.read(driversProvider.future)).single.id, 'drvA');
    expect((await container.read(home_trip.allTripsProvider.future)).single.id,
        'tripA');

    // Account switch: backing store now resolves to B's data.
    buses
      ..clear()
      ..add(busB);
    drivers
      ..clear()
      ..add(driverB);
    trips
      ..clear()
      ..add(tripB);

    // Same call the root auth listener performs on uid change.
    invalidateUserScopedData(ref);

    // Without invalidation these would still return A's cached data.
    expect((await container.read(busProvider.future)).single.id, 'busB');
    expect((await container.read(driversProvider.future)).single.id, 'drvB');

    final tripsAfter = await container.read(home_trip.allTripsProvider.future);
    expect(tripsAfter.single.id, 'tripB');
    expect(tripsAfter.any((t) => t.id == 'tripA'), isFalse);

    // Home dashboard recomputes against B, not a mixture of both accounts.
    final stats = await container.read(homeStatsProvider.future);
    expect(stats.totalBuses, 1);
    expect(stats.totalDrivers, 1);
    expect(stats.currentMonthTripCount, 1);
  });

  testWidgets('invalidateUserScopedData is a no-op when no account data is cached',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final ref = await captureRef(tester, container);

    expect(() => invalidateUserScopedData(ref), returnsNormally);
  });
}