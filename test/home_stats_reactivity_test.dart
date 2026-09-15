import 'package:elostaz_travel/domain/bus/entity/bus_entity.dart';
import 'package:elostaz_travel/domain/bus/use_cases/add_bus_use_case.dart';
import 'package:elostaz_travel/domain/bus/use_cases/get_buses_use_case.dart';
import 'package:elostaz_travel/domain/driver/entity/driver_entity.dart';
import 'package:elostaz_travel/domain/driver/use_case/add_driver_use_case.dart';
import 'package:elostaz_travel/domain/driver/use_case/get_drivers_use_case.dart';
import 'package:elostaz_travel/domain/factory/entity/factory_entity.dart';
import 'package:elostaz_travel/domain/factory/use_case/add_factory_use_case.dart';
import 'package:elostaz_travel/domain/factory/use_case/get_factories_use_case.dart';
import 'package:elostaz_travel/domain/trip/entity/trip_entity.dart';
import 'package:elostaz_travel/domain/trip/repository/trip_repository.dart';
import 'package:elostaz_travel/presentation/home/tabs/bus/provider/bus_provider.dart';
import 'package:elostaz_travel/presentation/home/tabs/driver/provider/driver_provider.dart';
import 'package:elostaz_travel/presentation/home/tabs/factory/provider/factory_provider.dart';
import 'package:elostaz_travel/presentation/home/tabs/home/provider/home_stats_provider.dart';
import 'package:elostaz_travel/presentation/home/tabs/trip/provider/trip_provider.dart'
    as home_trip;
import 'package:elostaz_travel/presentation/trip/provider/trip_provider.dart';
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

class _FakeAddBusUseCase implements AddBusUseCase {
  final List<BusEntity> backing;
  _FakeAddBusUseCase(this.backing);

  @override
  dynamic noSuchMethod(Invocation invocation) => null;

  @override
  Future<void> call({required BusEntity bus}) async => backing.add(bus);
}

class _FakeGetDriversUseCase implements GetDriversUseCase {
  final List<DriverEntity> backing;
  _FakeGetDriversUseCase(this.backing);

  @override
  dynamic noSuchMethod(Invocation invocation) => null;

  @override
  Future<List<DriverEntity>> call() async => List.of(backing);
}

class _FakeAddDriverUseCase implements AddDriverUseCase {
  final List<DriverEntity> backing;
  _FakeAddDriverUseCase(this.backing);

  @override
  dynamic noSuchMethod(Invocation invocation) => null;

  @override
  Future<String> call({
    required String name,
    required String phone,
    required int tripsCount,
    required double totalRevenue,
    String? idCardImageUrl,
    String? licenseImageUrl,
  }) async {
    final id = 'd_${backing.length + 1}';
    backing.add(
      DriverEntity(
        id: id,
        name: name,
        phone: phone,
        tripsCount: tripsCount,
        totalRevenue: totalRevenue,
      ),
    );
    return id;
  }
}

class _FakeGetFactoriesUseCase implements GetFactoriesUseCase {
  final List<FactoryEntity> backing;
  _FakeGetFactoriesUseCase(this.backing);

  @override
  dynamic noSuchMethod(Invocation invocation) => null;

  @override
  Future<List<FactoryEntity>> call() async => List.of(backing);
}

class _FakeAddFactoryUseCase implements AddFactoryUseCase {
  final List<FactoryEntity> backing;
  _FakeAddFactoryUseCase(this.backing);

  @override
  dynamic noSuchMethod(Invocation invocation) => null;

  @override
  Future<void> call({
    required String name,
    required String phone,
    required String details,
    required int tripsCount,
    required double totalRevenue,
  }) async {
    backing.add(
      FactoryEntity(
        id: 'f_${backing.length + 1}',
        name: name,
        phone: phone,
        details: details,
        tripsCount: tripsCount,
        totalRevenue: totalRevenue,
        createdAt: DateTime.now(),
      ),
    );
  }
}

class _FakeTripRepository implements TripRepository {
  final List<TripEntity> trips;
  _FakeTripRepository(this.trips);

  @override
  Future<void> addTrip(TripEntity trip) async => trips.add(trip);

  @override
  Future<void> updateTrip(TripEntity trip) async {
    final index = trips.indexWhere((t) => t.id == trip.id);
    if (index >= 0) trips[index] = trip;
  }

  @override
  Future<void> deleteTrip(String tripId) async {
    trips.removeWhere((t) => t.id == tripId);
  }

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
  Future<List<TripEntity>> getAllTrips() async => List.of(trips);

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
  ProviderContainer buildContainer(
    List<BusEntity> buses,
    List<DriverEntity> drivers,
    List<FactoryEntity> factories,
    List<TripEntity> trips,
  ) {
    final fakeTripRepo = _FakeTripRepository(trips);
    return ProviderContainer(
      overrides: [
        getBusesUseCaseProvider.overrideWithValue(_FakeGetBusesUseCase(buses)),
        addBusUseCaseProvider.overrideWithValue(_FakeAddBusUseCase(buses)),
        getDriversUseCaseProvider
            .overrideWithValue(_FakeGetDriversUseCase(drivers)),
        addDriverUseCaseProvider
            .overrideWithValue(_FakeAddDriverUseCase(drivers)),
        getFactoriesUseCaseProvider
            .overrideWithValue(_FakeGetFactoriesUseCase(factories)),
        addFactoryUseCaseProvider
            .overrideWithValue(_FakeAddFactoryUseCase(factories)),
        tripRepositoryProvider.overrideWithValue(fakeTripRepo),
        home_trip.tripRepositoryProvider.overrideWithValue(fakeTripRepo),
      ],
    );
  }

  // ── A: home dashboard counts update immediately after adds ──────────────
  test('home dashboard counts update immediately after adds', () async {
    final buses = <BusEntity>[];
    final drivers = <DriverEntity>[];
    final factories = <FactoryEntity>[];
    final trips = <TripEntity>[];

    final container = buildContainer(buses, drivers, factories, trips);
    addTearDown(container.dispose);

    HomeStats stats = await container.read(homeStatsProvider.future);
    expect(stats.totalBuses, 0);
    expect(stats.totalDrivers, 0);
    expect(stats.currentMonthTripCount, 0);

    // Add Bus (normal screen path) → home updates without any manual refresh.
    await container.read(busProvider.notifier).addBus(bus: _bus('b1'));
    stats = await container.read(homeStatsProvider.future);
    expect(stats.totalBuses, 1);

    // Add Driver → home updates immediately.
    await container.read(driversProvider.notifier).addDriver(
          name: 'سائق',
          phone: '01',
          totalRevenue: 0,
          tripsCount: 0,
        );
    stats = await container.read(homeStatsProvider.future);
    expect(stats.totalDrivers, 1);

    // Add Factory → list/count updates immediately.
    await container.read(factoriesProvider.notifier).addFactory(
          name: 'مصنع',
          phone: '',
          details: '',
          totalRevenue: 0,
          tripsCount: 0,
        );
    expect(await container.read(factoriesProvider.future), hasLength(1));

    // Add Trip → home current-month trip count updates immediately.
    final now = DateTime.now();
    await container
        .read(tripProvider.notifier)
        .addTrip(_trip('t1', now));

    stats = await container.read(homeStatsProvider.future);
    expect(stats.currentMonthTripCount, 1);
  });

  // ── D: monthlyTripsProvider refreshes after trip writes ────────────────
  group('monthlyTripsProvider refreshes after trip writes', () {
    test('after addTrip', () async {
      final trips = <TripEntity>[];
      final container = buildContainer([], [], [], trips);
      addTearDown(container.dispose);

      final now = DateTime.now();
      final key = (year: now.year, month: now.month);

      expect(
        await container.read(home_trip.monthlyTripsProvider(key).future),
        isEmpty,
      );

      await container.read(tripProvider.notifier).addTrip(_trip('t1', now));

      expect(
        await container.read(home_trip.monthlyTripsProvider(key).future),
        hasLength(1),
      );
    });

    test('after updateTrip and deleteTrip', () async {
      final trips = <TripEntity>[];
      final container = buildContainer([], [], [], trips);
      addTearDown(container.dispose);

      final now = DateTime.now();
      final key = (year: now.year, month: now.month);

      final t1 = _trip('t1', now);
      final t2 = _trip('t2', now);
      await container.read(tripProvider.notifier).addTrip(t1);
      await container.read(tripProvider.notifier).addTrip(t2);
      expect(
        await container.read(home_trip.monthlyTripsProvider(key).future),
        hasLength(2),
      );

      await container.read(tripProvider.notifier).deleteTrip('t1');
      expect(
        await container.read(home_trip.monthlyTripsProvider(key).future),
        hasLength(1),
      );

      await container
          .read(tripProvider.notifier)
          .updateTrip(t2.copyWith(revenue: 999));
      final fresh = await container.read(home_trip.monthlyTripsProvider(key).future);
      expect(fresh, hasLength(1));
      expect(fresh.single.revenue, 999);
    });
  });

  // ── D: allTripsProvider refreshes after addTrip ─────────────────────────
  test('allTripsProvider refreshes after addTrip (AI assistant path)', () async {
    final trips = <TripEntity>[];
    final container = buildContainer([], [], [], trips);
    addTearDown(container.dispose);

    expect(await container.read(home_trip.allTripsProvider.future), isEmpty);

    await container
        .read(tripProvider.notifier)
        .addTrip(_trip('t1', DateTime.now()));

    expect(await container.read(home_trip.allTripsProvider.future), hasLength(1));
  });
}