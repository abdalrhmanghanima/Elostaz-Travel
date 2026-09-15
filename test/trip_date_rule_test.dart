import 'package:elostaz_travel/domain/bus/entity/bus_entity.dart';
import 'package:elostaz_travel/domain/driver/entity/driver_entity.dart';
import 'package:elostaz_travel/domain/factory/entity/factory_entity.dart';
import 'package:elostaz_travel/domain/trip/entity/trip_entity.dart';
import 'package:elostaz_travel/domain/trip/repository/trip_repository.dart';
import 'package:elostaz_travel/domain/trip/use_case/add_trip_use_case.dart';
import 'package:elostaz_travel/domain/trip/validation/trip_date_rule.dart';
import 'package:elostaz_travel/presentation/ai_assistant/provider/ai_assistant_provider.dart';
import 'package:elostaz_travel/presentation/home/tabs/bus/provider/bus_notifier.dart';
import 'package:elostaz_travel/presentation/home/tabs/bus/provider/bus_provider.dart';
import 'package:elostaz_travel/presentation/home/tabs/driver/provider/driver_notifier.dart';
import 'package:elostaz_travel/presentation/home/tabs/driver/provider/driver_provider.dart';
import 'package:elostaz_travel/presentation/home/tabs/factory/provider/factory_notifier.dart';
import 'package:elostaz_travel/presentation/home/tabs/factory/provider/factory_provider.dart';
import 'package:elostaz_travel/presentation/trip/provider/trip_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// ── Shared fixtures ──────────────────────────────────────────────────────────

final _today = DateTime(2026, 9, 14);

TripEntity _trip({
  DateTime? tripDate,
  DateTime? createdAt,
}) {
  return TripEntity(
    id: 't1',
    driverId: 'd1',
    driverName: 'أحمد',
    busId: 'b1',
    busName: 'الوهاب',
    plateNumber: 'أ ب ج 123',
    revenue: 1000,
    createdAt: createdAt ?? tripDate ?? DateTime(2026, 9, 14),
    tripDate: tripDate,
  );
}

class _RecordingTripRepository implements TripRepository {
  bool addTripCalled = false;
  TripEntity? addedTrip;

  @override
  Future<void> addTrip(TripEntity trip) async {
    addTripCalled = true;
    addedTrip = trip;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// ── AI Assistant flow harness ───────────────────────────────────────────────

class _FakeTripRepo implements TripRepository {
  final List<TripEntity> addedTrips = [];
  bool addTripCalled = false;

  @override
  Future<void> addTrip(TripEntity trip) async {
    addTripCalled = true;
    addedTrips.add(trip);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _TestBusNotifier extends BusNotifier {
  final List<BusEntity> _initial;
  _TestBusNotifier(this._initial);

  @override
  Future<List<BusEntity>> build() async => _initial;
}

class _TestDriversNotifier extends DriversNotifier {
  final List<DriverEntity> _initial;
  _TestDriversNotifier(this._initial);

  @override
  Future<List<DriverEntity>> build() async => _initial;

  @override
  Future<String?> addDriver({
    required String name,
    required String phone,
    required double totalRevenue,
    required int tripsCount,
    String? idCardImageUrl,
    String? licenseImageUrl,
  }) async {
    return 'drv_new';
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _TestFactoriesNotifier extends FactoriesNotifier {
  final List<FactoryEntity> _initial;
  _TestFactoriesNotifier(this._initial);

  @override
  Future<List<FactoryEntity>> build() async => _initial;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Harness {
  final ProviderContainer container;
  final _FakeTripRepo tripRepo;

  _Harness({required this.container, required this.tripRepo});

  AiAssistantNotifier get notifier =>
      container.read(aiAssistantProvider.notifier);

  AiAssistantState get state => container.read(aiAssistantProvider).value!;

  Future<void> ready() async {
    await container.read(busProvider.future);
    await container.read(driversProvider.future);
    await container.read(factoriesProvider.future);
    await container.read(aiAssistantProvider.future);
  }
}

BusEntity _bus(String id, String name, String plate) => BusEntity(
      id: id,
      busName: name,
      plateNumber: plate,
      brand: 'مرسيدس',
      chassisNumber: 'CH-$id',
      engineNumber: 'EN-$id',
      passengerCount: 30,
      vehicleType: 'أتوبيس',
      licenseExpiryDate: DateTime(2027, 1, 1),
      specialConditions: '',
      insuranceType: 'مؤمنة',
    );

DriverEntity _driver(String id, String name, String phone) => DriverEntity(
      id: id,
      name: name,
      phone: phone,
      tripsCount: 0,
      totalRevenue: 0,
    );

FactoryEntity _factory(String id, String name) => FactoryEntity(
      id: id,
      name: name,
      phone: '',
      details: '',
      tripsCount: 0,
      totalRevenue: 0,
      createdAt: DateTime(2026, 1, 1),
    );

_Harness _harness({
  List<BusEntity> buses = const [],
  List<DriverEntity> drivers = const [],
  List<FactoryEntity> factories = const [],
}) {
  final tripRepo = _FakeTripRepo();
  final container = ProviderContainer(
    overrides: [
      tripRepositoryProvider.overrideWithValue(tripRepo),
      busProvider.overrideWith(() => _TestBusNotifier(List.of(buses))),
      driversProvider.overrideWith(() => _TestDriversNotifier(List.of(drivers))),
      factoriesProvider.overrideWith(
        () => _TestFactoriesNotifier(List.of(factories)),
      ),
    ],
  );
  addTearDown(container.dispose);
  return _Harness(container: container, tripRepo: tripRepo);
}

void main() {
  // ── A–D, K: TripDateRule pure business rule ───────────────────────────────
  group('TripDateRule', () {
    test('A: past date is allowed', () {
      expect(
        TripDateRule.isAllowed(DateTime(2026, 9, 10), today: _today),
        isTrue,
      );
    });

    test('B: today is allowed', () {
      expect(
        TripDateRule.isAllowed(DateTime(2026, 9, 14), today: _today),
        isTrue,
      );
    });

    test('C: tomorrow is rejected', () {
      expect(
        TripDateRule.isAllowed(DateTime(2026, 9, 15), today: _today),
        isFalse,
      );
      expect(TripDateRule.errorFor(DateTime(2026, 9, 15)), isNotNull);
    });

    test('D: a date several days in the future is rejected', () {
      expect(
        TripDateRule.isAllowed(DateTime(2026, 9, 20), today: _today),
        isFalse,
      );
      expect(TripDateRule.errorFor(DateTime(2026, 9, 20)), isNotNull);
    });

    test('K: today is valid regardless of departure time', () {
      expect(
        TripDateRule.isAllowed(DateTime(2026, 9, 14, 23, 59), today: _today),
        isTrue,
      );
      expect(
        TripDateRule.isAllowed(DateTime(2026, 9, 14, 0, 1), today: _today),
        isTrue,
      );
    });

    test('errorFor uses the system clock and matches the Arabic message', () {
      final err = TripDateRule.errorFor(
        DateTime.now().add(const Duration(days: 1)),
      );
      expect(err, TripDateRule.futureDateMessage);
      expect(err, contains('في المستقبل'));
    });
  });

  // ── Central enforcement: AddTripUseCase ───────────────────────────────────
  group('AddTripUseCase central date rule', () {
    test('rejects a future tripDate and never touches the repository', () async {
      final repo = _RecordingTripRepository();
      final useCase = AddTripUseCase(repository: repo);
      final future = DateTime.now().add(const Duration(days: 3));

      await expectLater(
        () => useCase.call(_trip(tripDate: future, createdAt: future)),
        throwsA(isA<FutureTripDateException>()),
      );
      expect(repo.addTripCalled, isFalse);
    });

    test('allows a trip dated today', () async {
      final repo = _RecordingTripRepository();
      final useCase = AddTripUseCase(repository: repo);
      final today = DateTime.now();

      await useCase.call(_trip(tripDate: today, createdAt: today));
      expect(repo.addTripCalled, isTrue);
    });

    test('allows a past trip date', () async {
      final repo = _RecordingTripRepository();
      final useCase = AddTripUseCase(repository: repo);

      await useCase.call(_trip(
        tripDate: DateTime(2020, 5, 1),
        createdAt: DateTime(2020, 5, 1),
      ));
      expect(repo.addTripCalled, isTrue);
    });

    test('rejects a future createdAt when no tripDate is present', () async {
      final repo = _RecordingTripRepository();
      final useCase = AddTripUseCase(repository: repo);
      final future = DateTime.now().add(const Duration(days: 1));

      await expectLater(
        () => useCase.call(_trip(createdAt: future)),
        throwsA(isA<FutureTripDateException>()),
      );
      expect(repo.addTripCalled, isFalse);
    });

    test('I: rejects the manual form shape (future tripDate AND createdAt)',
        () async {
      // This is exactly the TripEntity the manual bottom sheets build when a
      // future date is picked: both tripDate and createdAt are the picked date.
      final repo = _RecordingTripRepository();
      final useCase = AddTripUseCase(repository: repo);
      final future = DateTime.now().add(const Duration(days: 2));

      await expectLater(
        () => useCase.call(_trip(tripDate: future, createdAt: future)),
        throwsA(isA<FutureTripDateException>()),
      );
      expect(repo.addTripCalled, isFalse,
          reason: 'a future date must never reach the repository');
    });

    test('J: a rejected add leaves the caller draft untouched (stateless rule)',
        () async {
      final repo = _RecordingTripRepository();
      final useCase = AddTripUseCase(repository: repo);
      final trip = _trip(
        tripDate: DateTime.now().add(const Duration(days: 4)),
        createdAt: DateTime.now(),
      );

      try {
        await useCase.call(trip);
        fail('expected FutureTripDateException');
      } on FutureTripDateException {
        // The rule only throws; it never mutates the passed-in entity.
      }
      expect(trip.revenue, 1000);
      expect(trip.busName, 'الوهاب');
      expect(trip.driverName, 'أحمد');
    });
  });

  // ── AI Assistant creation path ────────────────────────────────────────────
  group('AI trip creation date rule', () {
    test('E: future date is rejected and no trip is created', () async {
      final h = _harness(
        buses: [_bus('bus_1', 'الوهاب', 'أ ب ج 123')],
        drivers: [_driver('drv_1', 'أحمد', '012')],
      );
      await h.ready();

      await h.notifier.processUserMessage(
        'عايز أعمل رحلة للأتوبيس الوهاب والسواق أحمد والايراد 5000 والتاريخ 10/8/2030',
      );
      expect(h.state.showConfirmationCard, isTrue);

      await h.notifier.executeTrip();

      expect(h.tripRepo.addTripCalled, isFalse,
          reason: 'a future date must not create a trip');
      expect(h.state.messages.last.content, contains('في المستقبل'));
    });

    test('F: today is allowed and the trip is created', () async {
      final h = _harness(
        buses: [_bus('bus_1', 'الوهاب', 'أ ب ج 123')],
        drivers: [_driver('drv_1', 'أحمد', '012')],
      );
      await h.ready();

      await h.notifier.processUserMessage(
        'عايز أعمل رحلة للأتوبيس الوهاب والسواق أحمد والايراد 5000 والتاريخ النهارده',
      );
      expect(h.state.showConfirmationCard, isTrue);

      await h.notifier.executeTrip();

      expect(h.tripRepo.addTripCalled, isTrue);
      final now = DateTime.now();
      final added = h.tripRepo.addedTrips.single;
      expect(added.tripDate, isNotNull);
      expect(added.tripDate!.year, now.year);
      expect(added.tripDate!.month, now.month);
      expect(added.tripDate!.day, now.day);
    });

    test('G: a past date is allowed and the trip is created', () async {
      final h = _harness(
        buses: [_bus('bus_1', 'الوهاب', 'أ ب ج 123')],
        drivers: [_driver('drv_1', 'أحمد', '012')],
      );
      await h.ready();

      await h.notifier.processUserMessage(
        'عايز أعمل رحلة للأتوبيس الوهاب والسواق أحمد والايراد 5000 والتاريخ 10/8/2025',
      );
      expect(h.state.showConfirmationCard, isTrue);

      await h.notifier.executeTrip();

      expect(h.tripRepo.addTripCalled, isTrue);
      final added = h.tripRepo.addedTrips.single;
      expect(added.tripDate, DateTime(2025, 8, 10));
    });

    test('H: factory trip with a future date is rejected', () async {
      final h = _harness(
        buses: [_bus('bus_1', 'الوهاب', 'أ ب ج 123')],
        drivers: [_driver('drv_1', 'أحمد', '012')],
        factories: [_factory('fac_1', 'مصنع النور')],
      );
      await h.ready();

      await h.notifier.processUserMessage(
        'عايز أعمل رحلة في مصنع النور للأتوبيس الوهاب والسواق أحمد والايراد 3000 والتاريخ 10/8/2030',
      );
      expect(h.state.showConfirmationCard, isTrue);

      await h.notifier.executeTrip();

      expect(h.tripRepo.addTripCalled, isFalse,
          reason: 'factory trip with a future date must not be created');
      expect(h.state.messages.last.content, contains('في المستقبل'));
    });

    test('J: rejected future date keeps the whole draft intact', () async {
      final h = _harness(
        buses: [_bus('bus_1', 'الوهاب', 'أ ب ج 123')],
        drivers: [_driver('drv_1', 'أحمد', '012')],
      );
      await h.ready();

      await h.notifier.processUserMessage(
        'عايز أعمل رحلة للأتوبيس الوهاب والسواق أحمد والايراد 5000 والتاريخ 10/8/2030',
      );
      await h.notifier.executeTrip();

      final state = h.state;
      expect(state.currentDraft.busName, 'الوهاب');
      expect(state.currentDraft.driverName, 'أحمد');
      expect(state.currentDraft.revenue, 5000);
      expect(state.currentDraft.tripDate, isNotNull);
      expect(state.isConfirming, isFalse);
      expect(state.showConfirmationCard, isTrue,
          reason: 'the confirmation card must remain so the user can retry');
      expect(h.tripRepo.addTripCalled, isFalse);
    });

    test('after a future rejection the user can correct the date and create',
        () async {
      final h = _harness(
        buses: [_bus('bus_1', 'الوهاب', 'أ ب ج 123')],
        drivers: [_driver('drv_1', 'أحمد', '012')],
      );
      await h.ready();

      await h.notifier.processUserMessage(
        'عايز أعمل رحلة للأتوبيس الوهاب والسواق أحمد والايراد 5000 والتاريخ 10/8/2030',
      );
      await h.notifier.executeTrip();
      expect(h.tripRepo.addTripCalled, isFalse);

      // The user fixes the date through the existing edit flow, then confirms.
      h.notifier.enterDraftEditMode();
      await h.notifier.processUserMessage('التاريخ يبقى النهارده');
      expect(h.state.currentDraft.tripDate, isNotNull);

      await h.notifier.executeTrip();

      expect(h.tripRepo.addTripCalled, isTrue);
      final now = DateTime.now();
      final added = h.tripRepo.addedTrips.single;
      expect(added.tripDate, isNotNull);
      expect(added.tripDate!.year, now.year);
      expect(added.tripDate!.month, now.month);
      expect(added.tripDate!.day, now.day);
    });
  });
}