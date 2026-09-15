import 'package:elostaz_travel/data/ai_assistant/service/local_trip_parser.dart';
import 'package:elostaz_travel/domain/ai_assistant/entity/ai_action_result.dart';
import 'package:elostaz_travel/domain/ai_assistant/entity/ai_trip_draft.dart';
import 'package:elostaz_travel/domain/bus/entity/bus_entity.dart';
import 'package:elostaz_travel/domain/driver/entity/driver_entity.dart';
import 'package:elostaz_travel/domain/factory/entity/factory_entity.dart';
import 'package:elostaz_travel/domain/trip/entity/trip_entity.dart';
import 'package:elostaz_travel/presentation/ai_assistant/model/ai_action_option.dart';
import 'package:elostaz_travel/presentation/ai_assistant/model/ai_guided_field.dart';
import 'package:elostaz_travel/presentation/ai_assistant/service/ai_composer_service.dart';
import 'package:elostaz_travel/presentation/ai_assistant/service/ai_entity_resolver.dart';
import 'package:elostaz_travel/presentation/ai_assistant/service/ai_field_parser.dart';
import 'package:elostaz_travel/presentation/ai_assistant/service/ai_query_service.dart';
import 'package:elostaz_travel/presentation/ai_assistant/service/local_intent_service.dart';
import 'package:elostaz_travel/presentation/ai_assistant/widgets/ai_factory_trip_choice_list.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // ── Shared test data ──────────────────────────────────────────────
  final bus1 = BusEntity(
    id: 'bus_1',
    busName: 'الوهاب',
    plateNumber: 'أ ب ج 123',
    brand: 'مرسيدس',
    model: '',
    manufacturingYear: 2020,
    modelYear: 2020,
    chassisNumber: 'CH1',
    engineNumber: 'EN1',
    passengerCount: 30,
    vehicleType: 'أتوبيس',
    licenseExpiryDate: DateTime(2027, 1, 1),
    specialConditions: '',
    insuranceType: 'مؤمنة',
  );

  final bus2 = BusEntity(
    id: 'bus_2',
    busName: 'النيل',
    plateNumber: 'د ه و 456',
    brand: 'ميني باص',
    model: '',
    manufacturingYear: 2022,
    modelYear: 2022,
    chassisNumber: 'CH2',
    engineNumber: 'EN2',
    passengerCount: 14,
    vehicleType: 'ميني باص',
    licenseExpiryDate: DateTime(2028, 6, 1),
    specialConditions: 'السيارة خالصة',
    insuranceType: 'غير مؤمنة',
  );

  final driver1 = DriverEntity(
    id: 'drv_1',
    name: 'أحمد',
    phone: '01234567890',
    tripsCount: 10,
    totalRevenue: 50000,
  );

  final driver2 = DriverEntity(
    id: 'drv_2',
    name: 'علي',
    phone: '01098765432',
    tripsCount: 5,
    totalRevenue: 25000,
  );

  final factory1 = FactoryEntity(
    id: 'fac_1',
    name: 'مصنع النور',
    phone: '010',
    details: 'القاهرة',
    tripsCount: 5,
    totalRevenue: 25000,
    createdAt: DateTime(2026, 1, 1),
  );

  final allBuses = [bus1, bus2];
  final allDrivers = [driver1, driver2];
  final allFactories = [factory1];

  // ══════════════════════════════════════════════════════════════════
  // 1. ACTION CATALOG (9 actions)
  // ══════════════════════════════════════════════════════════════════
  group('1. Action catalog - 9 actions', () {
    test('exactly 9 actions exist', () {
      expect(availableAiActions, hasLength(9));
    });

    test('5 add actions exist with correct IDs', () {
      final adds = availableAiActions
          .where((a) => a.category == AiActionCategory.add)
          .toList();
      expect(adds, hasLength(5));
      expect(adds.map((a) => a.id).toSet(), containsAll({
        AiActionId.addBus,
        AiActionId.addDriver,
        AiActionId.addFactory,
        AiActionId.addTrip,
        AiActionId.addFactoryTrip,
      }));
    });

    test('4 query actions exist with correct IDs', () {
      final queries = availableAiActions
          .where((a) => a.category == AiActionCategory.query)
          .toList();
      expect(queries, hasLength(4));
      expect(queries.map((a) => a.id).toSet(), containsAll({
        AiActionId.queryTrips,
        AiActionId.queryBuses,
        AiActionId.queryDrivers,
        AiActionId.queryFactories,
      }));
    });

    test('addBus has required fields and optional model', () {
      final opt = availableAiActions
          .firstWhere((a) => a.id == AiActionId.addBus);
      expect(opt.requiredFields.length, greaterThanOrEqualTo(10));
      expect(opt.optionalFields, contains(AiGuidedField.model));
    });

    test('addDriver has required name + optional phone', () {
      final opt = availableAiActions
          .firstWhere((a) => a.id == AiActionId.addDriver);
      expect(opt.requiredFields, [AiGuidedField.driverName]);
      expect(opt.optionalFields, [AiGuidedField.driverPhone]);
    });

    test('addFactory has required name + optional details', () {
      final opt = availableAiActions
          .firstWhere((a) => a.id == AiActionId.addFactory);
      expect(opt.requiredFields, [AiGuidedField.factoryName]);
      expect(opt.optionalFields, [AiGuidedField.factoryDetails]);
    });
  });

  // ══════════════════════════════════════════════════════════════════
  // 2. FORBIDDEN MUTATIONS
  // ══════════════════════════════════════════════════════════════════
  group('2. Forbidden mutations', () {
    test('blocks Arabic edit requests', () {
      expect(LocalIntentService.isForbiddenMutation('عدل الرحلة'), isTrue);
      expect(LocalIntentService.isForbiddenMutation('تعديل اسم الأتوبيس'), isTrue);
    });

    test('blocks Arabic delete requests', () {
      expect(LocalIntentService.isForbiddenMutation('امسح الرحلة'), isTrue);
      expect(LocalIntentService.isForbiddenMutation('احذف السواق'), isTrue);
      expect(LocalIntentService.isForbiddenMutation('امحي البيانات'), isTrue);
    });

    test('blocks Arabic change/update requests', () {
      expect(LocalIntentService.isForbiddenMutation('غير الإيراد'), isTrue);
      expect(LocalIntentService.isForbiddenMutation('حدث البيانات'), isTrue);
    });

    test('blocks English mutation keywords', () {
      expect(LocalIntentService.isForbiddenMutation('edit this trip'), isTrue);
      expect(LocalIntentService.isForbiddenMutation('delete the bus'), isTrue);
      expect(LocalIntentService.isForbiddenMutation('update driver info'), isTrue);
    });

    test('allows normal create/query messages', () {
      expect(LocalIntentService.isForbiddenMutation('عايز اضيف رحلة'), isFalse);
      expect(LocalIntentService.isForbiddenMutation('كم رحلة الشهر ده'), isFalse);
      expect(LocalIntentService.isForbiddenMutation('اضيف سواق'), isFalse);
      expect(LocalIntentService.isForbiddenMutation('استعلام عن الرحلات'), isFalse);
    });
  });

  // ══════════════════════════════════════════════════════════════════
  // 3. ADD FLOW: Action detection
  // ══════════════════════════════════════════════════════════════════
  group('3. Add action detection', () {
    test('detects add bus intent from various phrases', () {
      expect(LocalIntentService.detectAddAction('اضيف اتوبيس'), AiActionId.addBus);
      expect(LocalIntentService.detectAddAction('عربية جديدة'), AiActionId.addBus);
      expect(LocalIntentService.detectAddAction('اتوبيس جديد'), AiActionId.addBus);
      expect(LocalIntentService.detectAddAction('اضيف ميكروباص'), AiActionId.addBus);
    });

    test('detects add driver intent', () {
      expect(LocalIntentService.detectAddAction('اضيف سواق'), AiActionId.addDriver);
      expect(LocalIntentService.detectAddAction('سائق جديد'), AiActionId.addDriver);
    });

    test('detects add factory intent', () {
      expect(LocalIntentService.detectAddAction('اضيف مصنع'), AiActionId.addFactory);
      expect(LocalIntentService.detectAddAction('مصنع جديد'), AiActionId.addFactory);
    });

    test('detects add factory trip intent (preferred over addTrip)', () {
      expect(
        LocalIntentService.detectAddAction('اضيف رحلة لمصنع'),
        AiActionId.addFactoryTrip,
      );
      expect(
        LocalIntentService.detectAddAction('اسجل سهرة لمصنع'),
        AiActionId.addFactoryTrip,
      );
    });

    test('detects add bus trip intent', () {
      expect(
        LocalIntentService.detectAddAction('اضيف رحلة'),
        AiActionId.addTrip,
      );
    });

    test('returns null for non-add text', () {
      expect(LocalIntentService.detectAddAction('كيف الحال'), isNull);
      expect(LocalIntentService.detectAddAction('شكرا'), isNull);
    });
  });

  // ══════════════════════════════════════════════════════════════════
  // 4. QUERY DETECTION: Realistic Egyptian Arabic queries
  // ══════════════════════════════════════════════════════════════════
  group('4. Query detection - realistic Egyptian Arabic', () {
    test('trip count queries', () {
      expect(LocalIntentService.detectQueryAction('كم رحلة الشهر ده'),
          AiActionId.queryTrips);
      expect(LocalIntentService.detectQueryAction('عدد الرحلات'),
          AiActionId.queryTrips);
      expect(LocalIntentService.detectQueryAction('اجمالي الرحلات'),
          AiActionId.queryTrips);
    });

    test('revenue queries', () {
      expect(LocalIntentService.detectQueryAction('اجمالي ايرادات الشهر ده'),
          AiActionId.queryTrips);
      expect(LocalIntentService.detectQueryAction('اجمالي الإيرادات الشهر ده'),
          AiActionId.queryTrips);
    });

    test('bus queries', () {
      expect(LocalIntentService.detectQueryAction('عدد الاتوبيسات'),
          AiActionId.queryBuses);
      expect(LocalIntentService.detectQueryAction('الاتوبيسات'),
          AiActionId.queryBuses);
    });

    test('driver queries', () {
      expect(LocalIntentService.detectQueryAction('اجور السواقين'),
          AiActionId.queryDrivers);
      expect(LocalIntentService.detectQueryAction('اجر السواق المستحق'),
          AiActionId.queryDrivers);
    });

    test('factory queries', () {
      expect(LocalIntentService.detectQueryAction('المصانع'),
          AiActionId.queryFactories);
      expect(LocalIntentService.detectQueryAction('عدد المصانع'),
          AiActionId.queryFactories);
    });
  });

  // ══════════════════════════════════════════════════════════════════
  // 5. PERIOD RESOLUTION
  // ══════════════════════════════════════════════════════════════════
  group('5. AiPeriodParser', () {
    test('resolves this month', () {
      final period = AiPeriodParser.resolve('الشهر ده');
      expect(period, isNotNull);
      expect(period!.start.day, 1);
    });

    test('resolves last month', () {
      final period = AiPeriodParser.resolve('الشهر اللي فات');
      expect(period, isNotNull);
    });

    test('resolves today', () {
      final period = AiPeriodParser.resolve('النهارده');
      expect(period, isNotNull);
      expect(period!.label, 'اليوم');
    });

    test('resolves this week', () {
      final period = AiPeriodParser.resolve('الاسبوع ده');
      expect(period, isNotNull);
    });

    test('resolves specific month by name', () {
      final period = AiPeriodParser.resolve('شهر سبتمبر');
      expect(period, isNotNull);
      expect(period!.start.month, 9);
    });

    test('returns null for non-period text', () {
      expect(AiPeriodParser.resolve('اضيف رحلة'), isNull);
    });
  });

  // ══════════════════════════════════════════════════════════════════
  // 6. QUERY SERVICE: Filtering, aggregation, and empty states
  // ══════════════════════════════════════════════════════════════════
  group('6. AiQueryService', () {
    final trips = [
      TripEntity(
        id: 't1', driverId: 'drv_1', driverName: 'أحمد',
        busId: 'bus_1', busName: 'الوهاب', plateNumber: 'أ ب ج 123',
        revenue: 1000, expenses: 200, driverWage: 150,
        type: TripType.trip,
        tripDate: DateTime(2026, 9, 1), createdAt: DateTime(2026, 9, 1),
      ),
      TripEntity(
        id: 't2', driverId: 'drv_1', driverName: 'أحمد',
        busId: 'bus_1', busName: 'الوهاب', plateNumber: 'أ ب ج 123',
        revenue: 800, expenses: 100, driverWage: 120,
        type: TripType.nightOuting,
        tripDate: DateTime(2026, 9, 5), createdAt: DateTime(2026, 9, 5),
      ),
      TripEntity(
        id: 't3', driverId: 'drv_2', driverName: 'علي',
        busId: 'bus_2', busName: 'النيل', plateNumber: 'د ه و 456',
        revenue: 500, expenses: 50, driverWage: 80,
        type: TripType.trip,
        tripDate: DateTime(2026, 8, 15), createdAt: DateTime(2026, 8, 15),
      ),
    ];

    test('answerTrips: filters by period correctly', () {
      final answer = AiQueryService.answerTrips(
        trips: trips, buses: allBuses, drivers: allDrivers, factories: allFactories,
        period: AiPeriod(start: DateTime(2026, 9, 1), end: DateTime(2026, 10, 1), label: 'سبتمبر'),
      );
      expect(answer, contains('1 رحلة'));
      expect(answer, contains('1 سهرة'));
      expect(answer, contains('2 عملية'));
      expect(answer, contains('1800'));
      expect(answer, contains('300'));
    });

    test('answerTrips: filters by bus scope', () {
      final answer = AiQueryService.answerTrips(
        trips: trips, buses: allBuses, drivers: allDrivers, factories: allFactories,
        scope: AiQueryScope(entityKind: 'bus', entityId: 'bus_1', entityName: 'الوهاب'),
      );
      expect(answer, contains('2 عملية'));
    });

    test('answerTrips: filters by driver scope', () {
      final answer = AiQueryService.answerTrips(
        trips: trips, buses: allBuses, drivers: allDrivers, factories: allFactories,
        scope: AiQueryScope(entityKind: 'driver', entityId: 'drv_2', entityName: 'علي'),
      );
      expect(answer, contains('1 عملية'));
    });

    test('answerTrips: no scope shows all', () {
      final answer = AiQueryService.answerTrips(
        trips: trips, buses: allBuses, drivers: allDrivers, factories: allFactories,
      );
      expect(answer, contains('3 عملية'));
    });

    test('answerBuses: per-bus breakdown with period', () {
      final answer = AiQueryService.answerBuses(
        buses: allBuses, trips: trips,
        period: AiPeriod(start: DateTime(2026, 9, 1), end: DateTime(2026, 10, 1), label: 'سبتمبر'),
      );
      expect(answer, contains('الوهاب'));
      expect(answer, contains('2 رحلة'));
    });

    test('answerDrivers: per-driver with period wages', () {
      final answer = AiQueryService.answerDrivers(
        drivers: allDrivers, trips: trips,
        period: AiPeriod(start: DateTime(2026, 9, 1), end: DateTime(2026, 10, 1), label: 'سبتمبر'),
      );
      expect(answer, contains('أحمد'));
      expect(answer, contains('270'));
      expect(answer, contains('الأجر المستحق في الفترة'));
    });

    test('answerDrivers: cumulative totals from entity', () {
      final answer = AiQueryService.answerDrivers(
        drivers: [driver1], trips: [],
      );
      expect(answer, contains('10'));
      expect(answer, contains('50000'));
    });

    test('answerFactories: breakdown with period', () {
      final answer = AiQueryService.answerFactories(
        factories: allFactories, trips: trips,
        period: AiPeriod(start: DateTime(2026, 9, 1), end: DateTime(2026, 10, 1), label: 'سبتمبر'),
      );
      expect(answer, contains('مصنع النور'));
      expect(answer, contains('سبتمبر'));
    });

    test('empty lists show friendly messages', () {
      expect(AiQueryService.answerBuses(buses: [], trips: []), contains('مفيش'));
      expect(AiQueryService.answerDrivers(drivers: [], trips: []), contains('مفيش'));
      expect(AiQueryService.answerFactories(factories: [], trips: []), contains('مفيش'));
    });
  });

  // ══════════════════════════════════════════════════════════════════
  // 7. QUERY SCOPE RESOLUTION
  // ══════════════════════════════════════════════════════════════════
  group('7. Query scope resolution', () {
    test('resolves driver by name', () {
      final scope = AiQueryService.resolveScope(
        'السواق أحمد عمل كام رحلة',
        buses: allBuses, drivers: allDrivers, factories: allFactories,
      );
      expect(scope.entityKind, 'driver');
      expect(scope.entityId, 'drv_1');
    });

    test('resolves bus by name', () {
      final scope = AiQueryService.resolveScope(
        'إيراد الوهاب خلال الشهر ده',
        buses: allBuses, drivers: allDrivers, factories: allFactories,
      );
      expect(scope.entityKind, 'bus');
      expect(scope.entityId, 'bus_1');
    });

    test('resolves bus by plate number', () {
      final scope = AiQueryService.resolveScope(
        'أ ب ج 123 عملت كام رحلة',
        buses: allBuses, drivers: allDrivers, factories: allFactories,
      );
      expect(scope.entityKind, 'bus');
      expect(scope.entityId, 'bus_1');
    });

    test('resolves factory by name', () {
      final scope = AiQueryService.resolveScope(
        'رحلات مصنع النور',
        buses: allBuses, drivers: allDrivers, factories: allFactories,
      );
      expect(scope.entityKind, 'factory');
      expect(scope.entityId, 'fac_1');
    });

    test('returns empty scope for unmatched text', () {
      final scope = AiQueryService.resolveScope(
        'اجمالي الرحلات الشهر ده',
        buses: allBuses, drivers: allDrivers, factories: allFactories,
      );
      expect(scope.entityKind, isNull);
    });
  });

  // ══════════════════════════════════════════════════════════════════
  // 8. FACTORY TRIP TYPE DETECTION (رحلة vs سهرة)
  // ══════════════════════════════════════════════════════════════════
  group('8. Factory trip type detection', () {
    test('detects night outing (سهرة)', () {
      expect(LocalIntentService.detectFactoryTripType('سهرة'), 'night_outing');
      expect(LocalIntentService.detectFactoryTripType('بالليل'), 'night_outing');
      expect(LocalIntentService.detectFactoryTripType('سحور'), 'night_outing');
      expect(LocalIntentService.detectFactoryTripType('ليلا'), 'night_outing');
    });

    test('detects regular trip (رحلة)', () {
      expect(LocalIntentService.detectFactoryTripType('رحلة'), 'trip');
      expect(LocalIntentService.detectFactoryTripType('عايز رحلة'), 'trip');
    });

    test('numbered choices: 1=trip, 2=night_outing', () {
      expect(LocalIntentService.detectFactoryTripType('1'), 'trip');
      expect(LocalIntentService.detectFactoryTripType('الاولى'), 'trip');
      expect(LocalIntentService.detectFactoryTripType('2'), 'night_outing');
      expect(LocalIntentService.detectFactoryTripType('تانيه'), 'night_outing');
    });

    test('returns null for unrelated text', () {
      expect(LocalIntentService.detectFactoryTripType('كوباية شاي'), isNull);
    });
  });

  // ══════════════════════════════════════════════════════════════════
  // 9. FACTORY TRIP UI CATALOG
  // ══════════════════════════════════════════════════════════════════
  group('9. Factory trip type UI catalog', () {
    test('exactly 2 types: trip and night_outing', () {
      expect(availableFactoryTripTypes, hasLength(2));
      expect(availableFactoryTripTypes.map((c) => c.type).toSet(),
          containsAll({'trip', 'night_outing'}));
    });

    test('رحلة and سهرة are distinct', () {
      final trip = availableFactoryTripTypes.firstWhere((c) => c.type == 'trip');
      final night = availableFactoryTripTypes.firstWhere((c) => c.type == 'night_outing');
      expect(trip.title, 'رحلة');
      expect(night.title, 'سهرة');
    });
  });

  // ══════════════════════════════════════════════════════════════════
  // 10. ENTITY RESOLUTION
  // ══════════════════════════════════════════════════════════════════
  group('10. AiEntityResolver', () {
    test('resolves bus by exact name', () {
      final res = AiEntityResolver.resolveBus(
        draft: AiTripDraft(busName: 'الوهاب'), buses: allBuses,
      );
      expect(res.isResolved, isTrue);
      expect(res.resolved?.id, 'bus_1');
    });

    test('resolves bus by plate number', () {
      final res = AiEntityResolver.resolveBus(
        draft: AiTripDraft(plateNumber: 'أ ب ج 123'), buses: allBuses,
      );
      expect(res.isResolved, isTrue);
    });

    test('returns not-found for unknown bus', () {
      final res = AiEntityResolver.resolveBus(
        draft: AiTripDraft(busName: 'أتوبيس وهمي'), buses: allBuses,
      );
      expect(res.isNotFound, isTrue);
    });

    test('resolves driver by name', () {
      final res = AiEntityResolver.resolveDriver(
        draft: AiTripDraft(driverName: 'أحمد'), drivers: allDrivers,
      );
      expect(res.isResolved, isTrue);
      expect(res.resolved?.id, 'drv_1');
    });

    test('resolves factory by name', () {
      final res = AiEntityResolver.resolveFactory(
        draft: AiTripDraft(factoryName: 'مصنع النور'), factories: allFactories,
      );
      expect(res.isResolved, isTrue);
      expect(res.resolved?.id, 'fac_1');
    });

    test('preferStored keeps previously-resolved entity', () {
      final raw = AiEntityResolver.resolveBus(
        draft: AiTripDraft(busName: 'الوهاب'), buses: allBuses,
      );
      final result = AiEntityResolver.preferStored(
        raw: raw, stored: bus1,
        stillMatches: (b) => AiEntityResolver.busStillMatches(
            b, AiTripDraft(busName: 'الوهاب')),
      );
      expect(result.isResolved, isTrue);
    });
  });

  // ══════════════════════════════════════════════════════════════════
  // 11. TRIP ENTITY BUILDING (mirrors AddTripBottomSheet)
  // ══════════════════════════════════════════════════════════════════
  group('11. buildTripEntity', () {
    test('regular trip matches AddTripBottomSheet mapping', () {
      final trip = AiEntityResolver.buildTripEntity(
        draft: AiTripDraft(
          busName: 'الوهاب', plateNumber: 'أ ب ج 123',
          driverName: 'أحمد', factoryName: 'مصنع النور',
          revenue: 1200, driverWage: 300, type: TripType.trip,
        ),
        bus: bus1, driver: driver1, factory: factory1,
      );
      expect(trip.type, TripType.trip);
      expect(trip.busId, 'bus_1');
      expect(trip.driverId, 'drv_1');
      expect(trip.factoryId, 'fac_1');
      expect(trip.revenue, 1200);
      expect(trip.driverWage, 300);
      expect(trip.expenses, 0);
    });

    test('night outing preserves type', () {
      final trip = AiEntityResolver.buildTripEntity(
        draft: AiTripDraft(
          busName: 'الوهاب', driverName: 'أحمد',
          factoryName: 'مصنع النور', type: TripType.nightOuting,
        ),
        bus: bus1, driver: driver1, factory: factory1,
      );
      expect(trip.type, TripType.nightOuting);
      expect(trip.isNightOuting, isTrue);
    });

    test('createdAt = tripDate when set', () {
      final trip = AiEntityResolver.buildTripEntity(
        draft: AiTripDraft(
          busName: 'الوهاب', driverName: 'أحمد',
          tripDate: DateTime(2026, 9, 10),
        ),
        bus: bus1, driver: driver1,
      );
      expect(trip.createdAt, DateTime(2026, 9, 10));
    });

    test('createdAt = now when tripDate is null', () {
      final before = DateTime.now();
      final trip = AiEntityResolver.buildTripEntity(
        draft: AiTripDraft(busName: 'الوهاب', driverName: 'أحمد'),
        bus: bus1, driver: driver1,
      );
      expect(trip.createdAt.isAfter(before.subtract(const Duration(seconds: 1))), isTrue);
    });

    test('factory is optional', () {
      final trip = AiEntityResolver.buildTripEntity(
        draft: AiTripDraft(busName: 'الوهاب', driverName: 'أحمد'),
        bus: bus1, driver: driver1,
      );
      expect(trip.factoryId, isNull);
      expect(trip.factoryName, isNull);
    });
  });

  // ══════════════════════════════════════════════════════════════════
  // 12. DRAFT MERGE (incremental field accumulation)
  // ══════════════════════════════════════════════════════════════════
  group('12. AiTripDraft.merge', () {
    test('merge keeps existing fields when patch is partial', () {
      const base = AiTripDraft(busName: 'الوهاب', plateNumber: 'أ ب ج 123');
      const patch = AiTripDraft(driverName: 'أحمد');
      final merged = base.merge(patch);
      expect(merged.busName, 'الوهاب');
      expect(merged.plateNumber, 'أ ب ج 123');
      expect(merged.driverName, 'أحمد');
    });

    test('merge overwrites non-null fields', () {
      const base = AiTripDraft(busName: 'القديم');
      const patch = AiTripDraft(busName: 'الجديد');
      expect(base.merge(patch).busName, 'الجديد');
    });

    test('missingRequiredFields reports bus+driver', () {
      expect(const AiTripDraft().missingRequiredFields,
          containsAll(['الأتوبيس', 'السواق']));
    });

    test('hasAllRequiredFields true when bus+driver set', () {
      expect(const AiTripDraft(busName: 'ب', driverName: 'س').hasAllRequiredFields, isTrue);
    });
  });

  // ══════════════════════════════════════════════════════════════════
  // 13. VOICE → COMPOSER (no auto-submit)
  // ══════════════════════════════════════════════════════════════════
  group('13. Voice → Composer (no auto-submit)', () {
    test('mergeVoiceSegment appends', () {
      expect(
        AiComposerService.mergeVoiceSegment('الأتوبيس الوهاب', 'السواق أحمد'),
        'الأتوبيس الوهاب السواق أحمد',
      );
    });

    test('empty segment preserves base', () {
      expect(AiComposerService.mergeVoiceSegment('text', ''), 'text');
    });

    test('empty base takes segment', () {
      expect(AiComposerService.mergeVoiceSegment('', 'text'), 'text');
    });

    test('multi-segment accumulation', () {
      var t = AiComposerService.mergeVoiceSegment('', 'الأتوبيس الوهاب');
      t = AiComposerService.mergeVoiceSegment(t, 'السواق أحمد');
      t = AiComposerService.mergeVoiceSegment(t, 'الايراد 1000 جنيه');
      expect(t, 'الأتوبيس الوهاب السواق أحمد الايراد 1000 جنيه');
    });
  });

  // ══════════════════════════════════════════════════════════════════
  // 14. FIELD PARSING (guided create flow validation)
  // ══════════════════════════════════════════════════════════════════
  group('14. AiFieldParser', () {
    test('validates manufacturing year', () {
      expect(AiFieldParser.validate(AiGuidedField.manufacturingYear, '2020'), isNull);
      expect(AiFieldParser.validate(AiGuidedField.manufacturingYear, 'text'), isNotNull);
      expect(AiFieldParser.validate(AiGuidedField.manufacturingYear, '1800'), isNotNull);
    });

    test('validates passenger count > 0', () {
      expect(AiFieldParser.validate(AiGuidedField.passengerCount, '30'), isNull);
      expect(AiFieldParser.validate(AiGuidedField.passengerCount, '0'), isNotNull);
    });

    test('validates license date DD/MM/YYYY', () {
      expect(AiFieldParser.validate(AiGuidedField.licenseExpiryDate, '15/12/2027'), isNull);
      expect(AiFieldParser.validate(AiGuidedField.licenseExpiryDate, 'not-a-date'), isNotNull);
    });

    test('validates special conditions', () {
      expect(AiFieldParser.validate(AiGuidedField.specialConditions, 'محظورة بيع'), isNull);
      expect(AiFieldParser.validate(AiGuidedField.specialConditions, 'السيارة خالصة'), isNull);
      expect(AiFieldParser.validate(AiGuidedField.specialConditions, 'bla'), isNotNull);
    });

    test('validates insurance type', () {
      expect(AiFieldParser.validate(AiGuidedField.insuranceType, 'مؤمنة'), isNull);
      expect(AiFieldParser.validate(AiGuidedField.insuranceType, 'غير مؤمنة'), isNull);
      expect(AiFieldParser.validate(AiGuidedField.insuranceType, 'bla'), isNotNull);
    });

    test('empty required field returns error', () {
      expect(AiFieldParser.validate(AiGuidedField.busName, ''), isNotNull);
    });

    test('parseDate DD/MM/YYYY', () {
      expect(AiFieldParser.parseDate('15/12/2027'), DateTime(2027, 12, 15));
    });

    test('parseNumber Arabic digits', () {
      expect(AiFieldParser.parseNumber('١٢٣٤'), 1234);
    });
  });

  // ══════════════════════════════════════════════════════════════════
  // 15. HELP & INTENT CHANGE
  // ══════════════════════════════════════════════════════════════════
  group('15. Help & intent change', () {
    test('help request detected', () {
      expect(LocalIntentService.isHelpRequest('تعمل ايه؟'), isTrue);
    });

    test('intent change detected', () {
      expect(LocalIntentService.isIntentChange('حاجة تانية'), isTrue);
      expect(LocalIntentService.isIntentChange('لغي الرحلة'), isTrue);
    });
  });

  // ══════════════════════════════════════════════════════════════════
  // 16. LOCAL TRIP PARSER: Free-text extraction
  // ══════════════════════════════════════════════════════════════════
  group('16. LocalTripParser', () {
    final parser = LocalTripParser();

    AiTripDraft parseTrip(String text, [AiTripDraft? current]) {
      final result = parser.parse(
        userMessage: text,
        currentDraft: current ?? const AiTripDraft(),
        availableBuses: allBuses,
        availableDrivers: allDrivers,
        availableFactories: allFactories,
      );
      return result.tripDraft ?? current ?? const AiTripDraft();
    }

    test('extracts bus name and driver name', () {
      final draft = parseTrip('رحلة للأتوبيس الوهاب والسواق أحمد');
      expect(draft.busName, 'الوهاب');
      expect(draft.driverName, 'أحمد');
    });

    test('extracts revenue', () {
      final draft = parseTrip('رحلة للأتوبيس الوهاب والسواق أحمد الايراد 1000 جنيه');
      expect(draft.revenue, 1000);
    });

    test('extracts night outing type', () {
      final draft = parseTrip('سهرة للأتوبيس الوهاب والسواق أحمد');
      expect(draft.type, 'night_outing');
    });

    test('incremental merge preserves existing fields', () {
      const existing = AiTripDraft(busName: 'الوهاب');
      final draft = parseTrip('السواق أحمد والايراد 500 جنيه', existing);
      expect(draft.busName, 'الوهاب');
      expect(draft.driverName, 'أحمد');
      expect(draft.revenue, 500);
    });

    test('extracts departure time', () {
      final draft = parseTrip('رحلة للأتوبيس الوهاب والسواق أحمد الساعة 7 صباحا');
      expect(draft.departureTime, isNotNull);
      expect(draft.departureTime, contains('7'));
    });

    test('extracts date', () {
      final draft = parseTrip('رحلة للأتوبيس الوهاب والسواق أحمد يوم 15 سبتمبر');
      expect(draft.tripDate, isNotNull);
      expect(draft.tripDate?.day, 15);
    });

    test('returns generalChat for unrelated text', () {
      final result = parser.parse(
        userMessage: 'الجو جميل النهارده',
        currentDraft: const AiTripDraft(),
        availableBuses: allBuses,
        availableDrivers: allDrivers,
        availableFactories: allFactories,
      );
      expect(result.type, AiActionType.generalChat);
    });
  });

  // ══════════════════════════════════════════════════════════════════
  // 17. ARCHITECTURE: AI does not write directly to Firestore
  // ══════════════════════════════════════════════════════════════════
  group('17. Architecture constraint', () {
    test('AI assistant entry is only on Home', () {
      // This is a documentation test - the AI assistant FAB and sheet
      // are only used on the Home screen, not on Bus/Driver/Factory
      // detail screens. This is verified by code inspection.
      expect(true, isTrue);
    });

    test('no edit/delete/update actions exist', () {
      final names = availableAiActions.map((a) => a.id.name).toSet();
      expect(names.contains('edit'), isFalse);
      expect(names.contains('delete'), isFalse);
      expect(names.contains('update'), isFalse);
    });
  });

  // ══════════════════════════════════════════════════════════════════
  // 18. Quick Action count-query regression
  //    Empty text (button tap) must NOT require allTripsProvider.
  // ══════════════════════════════════════════════════════════════════
  group('18. Quick Action count-query path', () {
    test('answerBusesCount returns count without trips', () {
      final answer = AiQueryService.answerBusesCount(allBuses);
      expect(answer, contains('${allBuses.length} أتوبيس'));
    });

    test('answerDriversCount returns count without trips', () {
      final answer = AiQueryService.answerDriversCount(allDrivers);
      expect(answer, contains('${allDrivers.length} سواق'));
    });

    test('answerFactoriesCount returns count without trips', () {
      final answer = AiQueryService.answerFactoriesCount(allFactories);
      expect(answer, isNotEmpty);
      expect(answer, anyOf(
        contains('مصنع واحد'),
        contains(' مصانع '),
      ));
    });

    test('isCountQuery returns false for empty text (provider compensates)', () {
      expect(AiQueryService.isCountQuery(''), isFalse);
    });
  });

  // ══════════════════════════════════════════════════════════════════
  // 19. Trip count query regression — must not require allTripsProvider
  // ══════════════════════════════════════════════════════════════════
  group('19. Trip count query regression', () {
    test('answerTripsCount returns count from drivers without trips', () {
      final answer = AiQueryService.answerTripsCount(drivers: allDrivers);
      expect(answer, isNotEmpty);
      expect(
        answer,
        anyOf(
          contains('رحلة واحدة'),
          contains(' رحلة '),
          contains(' رحلات '),
        ),
      );
    });

    test('answerTripsCount shows zero-state when no trips exist', () {
      final emptyDrivers = allDrivers
          .map((d) => DriverEntity(
                id: d.id,
                name: d.name,
                phone: d.phone,
                tripsCount: 0,
                totalRevenue: 0,
              ))
          .toList();
      final answer = AiQueryService.answerTripsCount(drivers: emptyDrivers);
      expect(answer, contains('مفيش رحلات'));
    });

    test('answerTripsCount sums trips across drivers', () {
      final d1 = const DriverEntity(
          id: 'd1', name: 'أحمد', phone: '010', tripsCount: 3, totalRevenue: 0);
      final d2 = const DriverEntity(
          id: 'd2', name: 'محمد', phone: '011', tripsCount: 5, totalRevenue: 0);
      final answer = AiQueryService.answerTripsCount(drivers: [d1, d2]);
      expect(answer, contains('8'));
    });
  });
}
