import 'package:elostaz_travel/domain/bus/entity/bus_entity.dart';
import 'package:elostaz_travel/domain/driver/entity/driver_entity.dart';
import 'package:elostaz_travel/domain/factory/entity/factory_entity.dart';
import 'package:elostaz_travel/domain/trip/entity/trip_entity.dart';
import 'package:elostaz_travel/domain/trip/repository/trip_repository.dart';
import 'package:elostaz_travel/presentation/ai_assistant/model/ai_action_option.dart';
import 'package:elostaz_travel/presentation/ai_assistant/model/ai_guided_field.dart';
import 'package:elostaz_travel/presentation/ai_assistant/provider/ai_assistant_provider.dart';
import 'package:elostaz_travel/presentation/ai_assistant/service/ai_composer_service.dart';
import 'package:elostaz_travel/presentation/ai_assistant/service/ai_entity_resolver.dart';
import 'package:elostaz_travel/presentation/home/tabs/bus/provider/bus_notifier.dart';
import 'package:elostaz_travel/presentation/home/tabs/bus/provider/bus_provider.dart';
import 'package:elostaz_travel/presentation/home/tabs/driver/provider/driver_notifier.dart';
import 'package:elostaz_travel/presentation/home/tabs/driver/provider/driver_provider.dart';
import 'package:elostaz_travel/presentation/home/tabs/factory/provider/factory_notifier.dart';
import 'package:elostaz_travel/presentation/home/tabs/factory/provider/factory_provider.dart';
import 'package:elostaz_travel/presentation/trip/provider/trip_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Verifies the complete "edit the draft before confirming" flow through the
/// AiAssistantNotifier: entering edit mode, speaking a change, re-reviewing,
/// and confirming through the existing creation path.
class _FakeTripRepository implements TripRepository {
  bool addTripCalled = false;
  bool updateTripCalled = false;
  bool deleteTripCalled = false;
  final List<TripEntity> addedTrips = [];

  @override
  Future<void> addTrip(TripEntity trip) async {
    addTripCalled = true;
    addedTrips.add(trip);
  }

  @override
  Future<void> updateTrip(TripEntity trip) async {
    updateTripCalled = true;
  }

  @override
  Future<void> deleteTrip(String tripId) async {
    deleteTripCalled = true;
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

  bool addDriverCalled = false;
  bool updateDriverCalled = false;
  bool deleteDriverCalled = false;
  String? addedDriverName;
  String? addedDriverPhone;

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
    addDriverCalled = true;
    addedDriverName = name;
    addedDriverPhone = phone;
    return 'drv_new';
  }

  @override
  Future<bool> updateDriver({
    required String id,
    required String name,
    required String phone,
    required double totalRevenue,
    required int tripsCount,
    String? idCardImageUrl,
    String? licenseImageUrl,
  }) async {
    updateDriverCalled = true;
    return true;
  }

  @override
  Future<void> deleteDriver(String driverId) async {
    deleteDriverCalled = true;
  }
}

class _TestFactoriesNotifier extends FactoriesNotifier {
  final List<FactoryEntity> _initial;
  _TestFactoriesNotifier(this._initial);

  bool addFactoryCalled = false;
  bool updateFactoryCalled = false;
  bool deleteFactoryCalled = false;
  String? addedFactoryName;
  String? addedFactoryDetails;

  @override
  Future<List<FactoryEntity>> build() async => _initial;

  @override
  Future<bool> addFactory({
    required String name,
    required String phone,
    required String details,
    required double totalRevenue,
    required int tripsCount,
  }) async {
    addFactoryCalled = true;
    addedFactoryName = name;
    addedFactoryDetails = details;
    return true;
  }

  @override
  Future<bool> updateFactory(FactoryEntity factory) async {
    updateFactoryCalled = true;
    return true;
  }

  @override
  Future<bool> deleteFactory(String factoryId) async {
    deleteFactoryCalled = true;
    return true;
  }
}

class _Harness {
  final ProviderContainer container;
  final _FakeTripRepository tripRepo;
  final _TestDriversNotifier driversNotifier;
  final _TestFactoriesNotifier factoriesNotifier;

  const _Harness({
    required this.container,
    required this.tripRepo,
    required this.driversNotifier,
    required this.factoriesNotifier,
  });

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
  final tripRepo = _FakeTripRepository();
  final driversNotifier = _TestDriversNotifier(List.of(drivers));
  final factoriesNotifier = _TestFactoriesNotifier(List.of(factories));
  final container = ProviderContainer(
    overrides: [
      tripRepositoryProvider.overrideWithValue(tripRepo),
      busProvider.overrideWith(() => _TestBusNotifier(List.of(buses))),
      driversProvider.overrideWith(() => driversNotifier),
      factoriesProvider.overrideWith(() => factoriesNotifier),
    ],
  );
  addTearDown(container.dispose);
  return _Harness(
    container: container,
    tripRepo: tripRepo,
    driversNotifier: driversNotifier,
    factoriesNotifier: factoriesNotifier,
  );
}

/// Opens a confirmation for a regular bus trip: الوهاب + أحمد + ايراد 5000.
Future<void> _openBusTripConfirmation(_Harness h) async {
  await h.notifier
      .processUserMessage('عايز أعمل رحلة للأتوبيس الوهاب والسواق أحمد والايراد 5000');
}

void main() {
  group('Draft-edit flow: bus trip', () {
    test(
        'edit driver only preserves every other field, re-shows the review card, '
        'and final تأكيد creates the trip exactly once (no update/delete)',
        () async {
      final h = _harness(
        buses: [_bus('bus_1', 'الوهاب', 'أ ب ج 123')],
        drivers: [_driver('drv_1', 'أحمد', '012'), _driver('drv_2', 'محمود', '013')],
      );
      await h.ready();

      await _openBusTripConfirmation(h);
      expect(h.state.showConfirmationCard, isTrue);
      expect(h.state.currentDraft.driverName, 'أحمد');

      h.notifier.enterDraftEditMode();
      expect(h.state.isEditingDraft, isTrue);

      await h.notifier.processUserMessage('غير السواق يبقى محمود');
      final after = h.state;
      expect(after.currentDraft.driverName, 'محمود');
      expect(after.currentDraft.revenue, 5000);
      expect(after.currentDraft.busName, 'الوهاب');
      expect(after.currentDraft.plateNumber, 'أ ب ج 123');
      expect(after.currentDraft.driverWage, isNull);
      expect(after.showConfirmationCard, isTrue);
      expect(after.canConfirm, isTrue);
      expect(after.resolvedDriver?.id, 'drv_2');
      expect(after.messages.last.content, isNot(contains(forbiddenMutationMessage)));

      await h.notifier.executeTrip();

      expect(h.tripRepo.addTripCalled, isTrue);
      expect(h.tripRepo.updateTripCalled, isFalse);
      expect(h.tripRepo.deleteTripCalled, isFalse);
      final trip = h.tripRepo.addedTrips.single;
      expect(trip.driverName, 'محمود');
      expect(trip.driverId, 'drv_2');
      expect(trip.revenue, 5000);
      expect(trip.busId, 'bus_1');
      expect(trip.plateNumber, 'أ ب ج 123');
      expect(h.state.selectedAction, isNull);
      expect(h.state.lastSuccessMessage, isNotNull);
    });

    test('multi-field edit changes only the requested fields', () async {
      final h = _harness(
        buses: [_bus('bus_1', 'الوهاب', 'أ ب ج 123')],
        drivers: [_driver('drv_1', 'أحمد', '012')],
      );
      await h.ready();

      await _openBusTripConfirmation(h);
      h.notifier.enterDraftEditMode();

      await h.notifier
          .processUserMessage('الايراد يبقى 9000 والاجر يبقى 800 والمصروف يبقى 500');

      final after = h.state;
      expect(after.currentDraft.revenue, 9000);
      expect(after.currentDraft.driverWage, 800);
      expect(after.currentDraft.expenses, 500);
      expect(after.currentDraft.driverName, 'أحمد');
      expect(after.currentDraft.busName, 'الوهاب');
      expect(after.currentDraft.type, 'trip',
          reason: 'the spoken "رحلة" keeps its trip type; the edit must not touch it');
      expect(after.showConfirmationCard, isTrue);
    });

    test('multiple edit cycles build on the edited draft, not the original',
        () async {
      final h = _harness(
        buses: [_bus('bus_1', 'الوهاب', 'أ ب ج 123')],
        drivers: [_driver('drv_1', 'أحمد', '012'), _driver('drv_2', 'محمود', '013')],
      );
      await h.ready();

      await _openBusTripConfirmation(h);
      h.notifier.enterDraftEditMode();

      await h.notifier.processUserMessage('غير السواق يبقى محمود');
      expect(h.state.currentDraft.driverName, 'محمود');

      await h.notifier.processUserMessage('الايراد يبقى 7000');

      expect(h.state.currentDraft.driverName, 'محمود',
          reason: 'second edit must merge into the already-edited draft');
      expect(h.state.currentDraft.revenue, 7000);
      expect(h.state.showConfirmationCard, isTrue);
    });

    test('confirming a factory trip after a revenue edit keeps factory + type',
        () async {
      final h = _harness(
        buses: [_bus('bus_1', 'الوهاب', 'أ ب ج 123')],
        drivers: [_driver('drv_1', 'أحمد', '012')],
        factories: [_factory('fac_1', 'مصنع النور')],
      );
      await h.ready();

      await h.notifier.processUserMessage(
        'عايز أضيف رحلة في مصنع النور للأتوبيس الوهاب والسواق أحمد والايراد 3000',
      );
      expect(h.state.showConfirmationCard, isTrue);
      expect(h.state.selectedAction, AiActionId.addTrip);
      expect(h.state.currentDraft.type, 'trip');
      expect(h.state.currentDraft.factoryName, 'مصنع النور');

      h.notifier.enterDraftEditMode();
      await h.notifier.processUserMessage('الايراد يبقى 6000');

      final after = h.state;
      expect(after.currentDraft.revenue, 6000);
      expect(after.currentDraft.factoryName, 'مصنع النور',
          reason: 'factory must not be re-asked after a revenue edit');
      expect(after.currentDraft.type, 'trip',
          reason: 'a revenue-only edit must not drop the factory trip type');
      expect(after.resolvedFactory?.id, 'fac_1');
      expect(after.showConfirmationCard, isTrue);
    });

    test(
        'factory trip explicit type edit updates draft.type AND selectedFactoryTripType '
        'so a later context re-apply cannot restore the old type', () async {
      final h = _harness(
        buses: [_bus('bus_1', 'الوهاب', 'أ ب ج 123')],
        drivers: [_driver('drv_1', 'أحمد', '012')],
        factories: [_factory('fac_1', 'مصنع النور')],
      );
      await h.ready();

      await h.notifier.processUserMessage(
        'عايز أضيف رحلة في مصنع النور للأتوبيس الوهاب والسواق أحمد والايراد 3000',
      );
      expect(h.state.currentDraft.type, 'trip');

      h.notifier.enterDraftEditMode();
      await h.notifier.processUserMessage('النوع يبقى سهرة');

      final after = h.state;
      expect(after.currentDraft.type, 'night_outing',
          reason: 'after context re-apply the edited type must win');
      expect(after.selectedFactoryTripType, 'night_outing');
      expect(after.currentDraft.factoryName, 'مصنع النور');
      expect(after.currentDraft.revenue, 3000);
      expect(after.showConfirmationCard, isTrue);
    });

    test('editing the bus name resolves an existing bus and its plate', () async {
      final h = _harness(
        buses: [
          _bus('bus_1', 'الوهاب', 'أ ب ج 123'),
          _bus('bus_2', 'الخضراء', 'ط س ر 999'),
        ],
        drivers: [_driver('drv_1', 'أحمد', '012')],
      );
      await h.ready();

      await _openBusTripConfirmation(h);
      h.notifier.enterDraftEditMode();

      await h.notifier.processUserMessage('غير الاتوبيس يبقى الخضراء');

      expect(h.state.currentDraft.busName, 'الخضراء');
      expect(h.state.currentDraft.plateNumber, 'ط س ر 999');
      expect(h.state.resolvedBus?.id, 'bus_2');
      expect(h.state.currentDraft.driverName, 'أحمد');
      expect(h.state.showConfirmationCard, isTrue);
    });

    test('unknown driver preserves the draft and asks for a known one', () async {
      final h = _harness(
        buses: [_bus('bus_1', 'الوهاب', 'أ ب ج 123')],
        drivers: [_driver('drv_1', 'أحمد', '012')],
      );
      await h.ready();

      await _openBusTripConfirmation(h);
      h.notifier.enterDraftEditMode();

      await h.notifier.processUserMessage('غير السواق يبقى اللي مش موجود');

      expect(h.state.currentDraft.driverName, 'أحمد',
          reason: 'a not-found edit must not corrupt the confirmed draft');
      expect(h.state.currentDraft.revenue, 5000);
      expect(h.state.isEditingDraft, isTrue);
      expect(h.state.showConfirmationCard, isTrue);
      expect(h.state.messages.last.content, contains('مش لاقي سواق'));
    });

    test('ambiguous driver edit defers to a choice and converges on it',
        () async {
      final h = _harness(
        buses: [_bus('bus_1', 'الوهاب', 'أ ب ج 123')],
        drivers: [
          _driver('drv_a', 'أحمد', '010'),
          _driver('drv_s1', 'سعيد', '011'),
          _driver('drv_s2', 'سعيد', '012'),
        ],
      );
      await h.ready();

      await _openBusTripConfirmation(h);
      expect(h.state.resolvedDriver?.id, 'drv_a');
      h.notifier.enterDraftEditMode();

      await h.notifier.processUserMessage('غير السواق يبقى سعيد');

      expect(h.state.pendingChoiceField, AiEntityField.driver);
      expect(h.state.isEditingDraft, isTrue);
      expect(h.state.driverCandidates, hasLength(2));
      expect(h.state.currentDraft.driverName, 'أحمد',
          reason: 'ambiguous edit must keep the last valid draft as base');

      h.notifier.chooseEntity(AiEntityField.driver, 'drv_s1');

      expect(h.state.resolvedDriver?.id, 'drv_s1',
          reason: 'choosing one of the matches must resolve the edit');
      expect(h.state.currentDraft.driverName, 'سعيد');
      expect(h.state.pendingChoiceField, isNull);
      expect(h.state.showConfirmationCard, isTrue);
    });

    test('ambiguous factory edit defers to a choice and converges on it',
        () async {
      final h = _harness(
        buses: [_bus('bus_1', 'الوهاب', 'أ ب ج 123')],
        drivers: [_driver('drv_1', 'أحمد', '012')],
        factories: [
          _factory('fac_a1', 'مصنع الامل'),
          _factory('fac_a2', 'مصنع الامل'),
        ],
      );
      await h.ready();

      await _openBusTripConfirmation(h);
      h.notifier.enterDraftEditMode();

      await h.notifier.processUserMessage('غير المصنع يبقى مصنع الامل');

      expect(h.state.pendingChoiceField, AiEntityField.factory);
      expect(h.state.factoryCandidates, hasLength(2));
      expect(h.state.currentDraft.factoryName, isNull);

      h.notifier.chooseEntity(AiEntityField.factory, 'fac_a1');

      expect(h.state.resolvedFactory?.id, 'fac_a1');
      expect(h.state.currentDraft.factoryName, 'مصنع الامل');
      expect(h.state.pendingChoiceField, isNull);
      expect(h.state.showConfirmationCard, isTrue);
    });

    test('forbidden mutations are blocked outside edit mode but accepted inside',
        () async {
      final h = _harness(
        buses: [_bus('bus_1', 'الوهاب', 'أ ب ج 123')],
        drivers: [_driver('drv_1', 'أحمد', '012'), _driver('drv_2', 'محمود', '013')],
      );
      await h.ready();

      await h.notifier.processUserMessage('عدل الرحلة');
      expect(h.state.messages.last.content, forbiddenMutationMessage);
      expect(h.state.isEditingDraft, isFalse);

      await h.notifier.processUserMessage('غير السواق يبقى محمود');
      expect(h.state.messages.last.content, forbiddenMutationMessage,
          reason: 'غير outside edit mode is still a forbidden mutation');

      await _openBusTripConfirmation(h);
      h.notifier.enterDraftEditMode();

      await h.notifier.processUserMessage('غير السواق يبقى محمود');
      expect(h.state.messages.last.content, isNot(contains(forbiddenMutationMessage)));
      expect(h.state.currentDraft.driverName, 'محمود',
          reason: 'same phrase is accepted as an edit inside edit mode');
    });

    test('the edit handler works from the final composed voice text', () async {
      final h = _harness(
        buses: [_bus('bus_1', 'الوهاب', 'أ ب ج 123')],
        drivers: [_driver('drv_1', 'أحمد', '012'), _driver('drv_2', 'محمود', '013')],
      );
      await h.ready();

      await _openBusTripConfirmation(h);
      h.notifier.enterDraftEditMode();

      final first = AiComposerService.mergeVoiceSegment('', 'غير السواق');
      final composed = AiComposerService.mergeVoiceSegment(first, 'يبقى محمود');
      expect(composed, 'غير السواق يبقى محمود');
      await h.notifier.processUserMessage(composed);

      expect(h.state.currentDraft.driverName, 'محمود',
          reason: 'voice segments are composed into text and reach the same handler');
    });

    test('a no-change utterance asks for a valid change without corrupting the draft',
        () async {
      final h = _harness(
        buses: [_bus('bus_1', 'الوهاب', 'أ ب ج 123')],
        drivers: [_driver('drv_1', 'أحمد', '012')],
      );
      await h.ready();

      await _openBusTripConfirmation(h);
      h.notifier.enterDraftEditMode();

      await h.notifier.processUserMessage('تمام');

      expect(h.state.currentDraft.driverName, 'أحمد');
      expect(h.state.currentDraft.revenue, 5000);
      expect(h.state.isEditingDraft, isTrue);
      expect(h.state.canConfirm, isTrue,
          reason: 'no silent auto-confirm on a no-change utterance');
      expect(h.state.messages.last.content, contains('قولّي الحقل'));
    });

    // ── Natural-language replacement pattern tests ────────────────────────

    test('A: driver replacement with "من … خليه …" resolves the NEW driver',
        () async {
      final h = _harness(
        buses: [_bus('bus_1', 'الوهاب', 'أ ب ج 123')],
        drivers: [
          _driver('drv_1', 'أحمد', '012'),
          _driver('drv_2', 'عبدالرحمن', '013'),
        ],
      );
      await h.ready();

      await _openBusTripConfirmation(h);
      h.notifier.enterDraftEditMode();

      await h.notifier.processUserMessage(
        'غير السواق من احمد خليه عبدالرحمن',
      );

      final after = h.state;
      expect(after.currentDraft.driverName, 'عبدالرحمن');
      expect(after.resolvedDriver?.id, 'drv_2');
      expect(after.currentDraft.busName, 'الوهاب');
      expect(after.currentDraft.revenue, 5000);
      expect(after.showConfirmationCard, isTrue);
    });

    test('B: bus replacement with "بدل … يكون …" resolves the NEW bus',
        () async {
      final h = _harness(
        buses: [
          _bus('bus_1', 'الوهاب', 'أ ب ج 123'),
          _bus('bus_2', 'الخضراء', 'ط س ر 999'),
        ],
        drivers: [_driver('drv_1', 'أحمد', '012')],
      );
      await h.ready();

      await _openBusTripConfirmation(h);
      h.notifier.enterDraftEditMode();

      await h.notifier.processUserMessage(
        'الأتوبيس بدل الوهاب يكون الخضراء',
      );

      final after = h.state;
      expect(after.currentDraft.busName, 'الخضراء');
      expect(after.currentDraft.plateNumber, 'ط س ر 999');
      expect(after.resolvedBus?.id, 'bus_2');
      expect(after.currentDraft.driverName, 'أحمد');
      expect(after.currentDraft.revenue, 5000);
      expect(after.showConfirmationCard, isTrue);
    });

    test('C: driver + bus replacement in one sentence resolves both',
        () async {
      final h = _harness(
        buses: [
          _bus('bus_1', 'الوهاب', 'أ ب ج 123'),
          _bus('bus_2', 'الخضراء', 'ط س ر 999'),
        ],
        drivers: [
          _driver('drv_1', 'أحمد', '012'),
          _driver('drv_2', 'عبدالرحمن', '013'),
        ],
      );
      await h.ready();

      await _openBusTripConfirmation(h);
      h.notifier.enterDraftEditMode();

      await h.notifier.processUserMessage(
        'غير السواق من احمد خليه عبدالرحمن والأتوبيس بدل الوهاب يكون الخضراء',
      );

      final after = h.state;
      expect(after.currentDraft.driverName, 'عبدالرحمن');
      expect(after.resolvedDriver?.id, 'drv_2');
      expect(after.currentDraft.busName, 'الخضراء');
      expect(after.currentDraft.plateNumber, 'ط س ر 999');
      expect(after.resolvedBus?.id, 'bus_2');
      expect(after.currentDraft.revenue, 5000,
          reason: 'unmentioned revenue must be preserved');
      expect(after.showConfirmationCard, isTrue);
    });

    test('G: preserve all unmentioned fields when only driver is changed via replacement',
        () async {
      final h = _harness(
        buses: [_bus('bus_1', 'الوهاب', 'أ ب ج 123')],
        drivers: [
          _driver('drv_1', 'أحمد', '012'),
          _driver('drv_2', 'محمود', '013'),
        ],
      );
      await h.ready();

      // Build a draft with multiple fields
      await h.notifier.processUserMessage(
        'عايز أعمل رحلة للأتوبيس الوهاب والسواق أحمد والايراد 5000 والاجره 800',
      );
      expect(h.state.showConfirmationCard, isTrue);
      expect(h.state.currentDraft.revenue, 5000);
      expect(h.state.currentDraft.driverWage, 800);

      h.notifier.enterDraftEditMode();

      await h.notifier.processUserMessage(
        'غير السواق من احمد خليه محمود',
      );

      final after = h.state;
      expect(after.currentDraft.driverName, 'محمود');
      expect(after.currentDraft.revenue, 5000,
          reason: 'revenue must not be lost');
      expect(after.currentDraft.driverWage, 800,
          reason: 'driver wage must not be lost');
      expect(after.currentDraft.busName, 'الوهاب',
          reason: 'bus must not be lost');
      expect(after.showConfirmationCard, isTrue);
    });

    test('H: multiple edit cycles with replacement patterns accumulate',
        () async {
      final h = _harness(
        buses: [
          _bus('bus_1', 'الوهاب', 'أ ب ج 123'),
          _bus('bus_2', 'الخضراء', 'ط س ر 999'),
        ],
        drivers: [
          _driver('drv_1', 'أحمد', '012'),
          _driver('drv_2', 'محمود', '013'),
        ],
      );
      await h.ready();

      await _openBusTripConfirmation(h);
      h.notifier.enterDraftEditMode();

      // Edit #1: change driver
      await h.notifier.processUserMessage(
        'غير السواق من احمد خليه محمود',
      );
      expect(h.state.currentDraft.driverName, 'محمود');
      expect(h.state.currentDraft.revenue, 5000);

      // Edit #2: change revenue
      await h.notifier.processUserMessage('الايراد يبقى 7000');
      expect(h.state.currentDraft.driverName, 'محمود',
          reason: 'first edit must survive second edit');
      expect(h.state.currentDraft.revenue, 7000);
      expect(h.state.showConfirmationCard, isTrue);
    });

    test('I: unknown new driver via replacement preserves draft and asks for clarification',
        () async {
      final h = _harness(
        buses: [_bus('bus_1', 'الوهاب', 'أ ب ج 123')],
        drivers: [_driver('drv_1', 'أحمد', '012')],
      );
      await h.ready();

      await _openBusTripConfirmation(h);
      h.notifier.enterDraftEditMode();

      await h.notifier.processUserMessage(
        'غير السواق من احمد خليه اللي مش موجود',
      );

      expect(h.state.currentDraft.driverName, 'أحمد',
          reason: 'not-found replacement must not corrupt the draft');
      expect(h.state.isEditingDraft, isTrue);
      expect(h.state.messages.last.content, contains('مش لاقي سواق'));
    });

    test('K: factory trip edit preserves factory and type after bus replacement',
        () async {
      final h = _harness(
        buses: [
          _bus('bus_1', 'الوهاب', 'أ ب ج 123'),
          _bus('bus_2', 'الخضراء', 'ط س ر 999'),
        ],
        drivers: [_driver('drv_1', 'أحمد', '012')],
        factories: [_factory('fac_1', 'مصنع النور')],
      );
      await h.ready();

      await h.notifier.processUserMessage(
        'عايز أضيف رحلة في مصنع النور للأتوبيس الوهاب والسواق أحمد والايراد 3000',
      );
      expect(h.state.currentDraft.type, 'trip');
      expect(h.state.currentDraft.factoryName, 'مصنع النور');

      h.notifier.enterDraftEditMode();
      await h.notifier.processUserMessage(
        'الأتوبيس بدل الوهاب يكون الخضراء',
      );

      final after = h.state;
      expect(after.currentDraft.busName, 'الخضراء');
      expect(after.currentDraft.factoryName, 'مصنع النور',
          reason: 'factory must survive a bus edit');
      expect(after.currentDraft.type, 'trip',
          reason: 'trip type must survive a bus edit');
      expect(after.currentDraft.revenue, 3000);
      expect(after.showConfirmationCard, isTrue);
    });
  });

  group('Draft-edit flow: create (bus/driver/factory)', () {
    test('add driver: edit name and phone in the review card before confirming',
        () async {
      final h = _harness();
      await h.ready();

      await h.notifier.processUserMessage(
        'عايز أضيف سواق اسمه علي ورقم تليفونه 01012345678',
      );
      expect(h.state.showCreateReviewCard, isTrue);
      expect(h.state.createValues[AiGuidedField.driverName.name], 'علي');
      expect(h.state.createValues[AiGuidedField.driverPhone.name], '01012345678');

      h.notifier.enterDraftEditMode();
      expect(h.state.isEditingDraft, isTrue);

      await h.notifier.processUserMessage('غير الاسم يبقى محمود');
      expect(h.state.createValues[AiGuidedField.driverName.name], 'محمود');
      expect(h.state.createValues[AiGuidedField.driverPhone.name], '01012345678',
          reason: 'phone must be preserved when only the name changes');
      expect(h.state.showCreateReviewCard, isTrue);
      expect(h.state.canCreateConfirm, isTrue);

      await h.notifier.processUserMessage('رقم التليفون يبقى 01122233344');
      expect(h.state.createValues[AiGuidedField.driverName.name], 'محمود');
      expect(h.state.createValues[AiGuidedField.driverPhone.name], '01122233344');

      await h.notifier.executeCreate();

      expect(h.driversNotifier.addDriverCalled, isTrue);
      expect(h.driversNotifier.addedDriverName, 'محمود');
      expect(h.driversNotifier.addedDriverPhone, '01122233344');
      expect(h.driversNotifier.updateDriverCalled, isFalse);
      expect(h.driversNotifier.deleteDriverCalled, isFalse);
      expect(h.state.lastSuccessMessage, isNotNull);
    });

    test('add bus: plate edit in the review card keeps the other create values',
        () async {
      final h = _harness();
      await h.ready();

      await h.notifier.processUserMessage('عايز أضيف أتوبيس');
      await h.notifier.processUserMessage('الوهاب');
      await h.notifier.processUserMessage('ط س ر 1234');
      await h.notifier.processUserMessage('ميكروباص');
      await h.notifier.processUserMessage('مرسيدس');
      await h.notifier.processUserMessage('2019');
      await h.notifier.processUserMessage('CH12345');
      await h.notifier.processUserMessage('EN99');
      await h.notifier.processUserMessage('30');
      await h.notifier.processUserMessage('15/12/2027');
      await h.notifier.processUserMessage('محظورة بيع');
      await h.notifier.processUserMessage('الاهلي');
      await h.notifier.processUserMessage('مؤمنة');
      await h.notifier.processUserMessage('لا');

      expect(h.state.showGenericReview, isTrue);
      expect(h.state.showCreateReviewCard, isTrue);
      expect(h.state.createValues[AiGuidedField.busName.name], 'الوهاب');
      expect(h.state.createValues[AiGuidedField.plateNumber.name], 'ط س ر 1234');
      expect(
          h.state.createValues[AiGuidedField.prohibitedBankName.name], 'الاهلي');

      h.notifier.enterDraftEditMode();
      await h.notifier.processUserMessage('اسم الاتوبيس يبقى الخضراء');

      expect(h.state.createValues[AiGuidedField.busName.name], 'الخضراء');
      expect(h.state.createValues[AiGuidedField.plateNumber.name], 'ط س ر 1234',
          reason: 'unrelated create values survive a single-field edit');
      expect(h.state.createValues[AiGuidedField.brand.name], 'مرسيدس');
      expect(h.state.createValues[AiGuidedField.insuranceType.name], 'مؤمنة');
      expect(h.state.showCreateReviewCard, isTrue);
      expect(h.state.canCreateConfirm, isTrue);
    });

    test(
        'add factory: edit details and name in the review card, '
        'confirm creates once with no update/delete', () async {
      final h = _harness();
      await h.ready();

      await h.notifier.processUserMessage(
        'عايز أضيف مصنع اسمه المصرية للمقاولات وعنوانه المنطقة الصناعية',
      );
      expect(h.state.showCreateReviewCard, isTrue);
      expect(h.state.createValues[AiGuidedField.factoryName.name], 'المصرية للمقاولات');
      expect(h.state.createValues[AiGuidedField.factoryDetails.name], 'المنطقة الصناعية');

      h.notifier.enterDraftEditMode();
      await h.notifier.processUserMessage('تفاصيل المصنع يبقى العاشر من رمضان');
      expect(h.state.createValues[AiGuidedField.factoryDetails.name], 'العاشر من رمضان');
      expect(h.state.createValues[AiGuidedField.factoryName.name], 'المصرية للمقاولات');

      await h.notifier.processUserMessage('اسم المصنع يبقى النيل');
      expect(h.state.createValues[AiGuidedField.factoryName.name], 'النيل');
      expect(h.state.createValues[AiGuidedField.factoryDetails.name], 'العاشر من رمضان');

      await h.notifier.executeCreate();

      expect(h.factoriesNotifier.addFactoryCalled, isTrue);
      expect(h.factoriesNotifier.addedFactoryName, 'النيل');
      expect(h.factoriesNotifier.addedFactoryDetails, 'العاشر من رمضان');
      expect(h.factoriesNotifier.updateFactoryCalled, isFalse);
      expect(h.factoriesNotifier.deleteFactoryCalled, isFalse);
      expect(h.state.lastSuccessMessage, isNotNull);
    });
  });
}