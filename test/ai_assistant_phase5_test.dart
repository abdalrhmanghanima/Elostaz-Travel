import 'package:elostaz_travel/domain/ai_assistant/entity/ai_trip_draft.dart';
import 'package:elostaz_travel/domain/bus/entity/bus_entity.dart';
import 'package:elostaz_travel/domain/driver/entity/driver_entity.dart';
import 'package:elostaz_travel/domain/factory/entity/factory_entity.dart';
import 'package:elostaz_travel/domain/trip/entity/trip_entity.dart';
import 'package:elostaz_travel/presentation/ai_assistant/model/ai_action_option.dart';
import 'package:elostaz_travel/presentation/ai_assistant/model/ai_entry_context.dart';
import 'package:elostaz_travel/presentation/ai_assistant/service/ai_entity_resolver.dart';
import 'package:elostaz_travel/presentation/ai_assistant/service/local_intent_service.dart';
import 'package:elostaz_travel/presentation/ai_assistant/widgets/ai_factory_trip_choice_list.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AiEntryContext (context awareness)', () {
    final bus = BusEntity(
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

    final factory = FactoryEntity(
      id: 'fac_1',
      name: 'مصنع النور',
      phone: '01',
      details: '',
      tripsCount: 0,
      totalRevenue: 0,
      createdAt: DateTime(2026, 1, 1),
    );

    test('default context is global with no bus or factory', () {
      const ctx = AiEntryContext();
      expect(ctx.type, AiEntryContextType.global);
      expect(ctx.isGlobal, isTrue);
      expect(ctx.isBusContext, isFalse);
      expect(ctx.isFactoryContext, isFalse);
      expect(ctx.contextLabel, '');
    });

    test('bus context carries the selected BusEntity', () {
      final ctx = AiEntryContext.bus(bus);
      expect(ctx.type, AiEntryContextType.bus);
      expect(ctx.isBusContext, isTrue);
      expect(ctx.bus?.busName, 'الوهاب');
      expect(ctx.contextLabel, 'الأتوبيس: الوهاب');
    });

    test('factory context carries the selected FactoryEntity', () {
      final ctx = AiEntryContext.factory(factory);
      expect(ctx.type, AiEntryContextType.factory);
      expect(ctx.isFactoryContext, isTrue);
      expect(ctx.factory?.name, 'مصنع النور');
      expect(ctx.contextLabel, 'المصنع: مصنع النور');
    });
  });

  group('Action catalog', () {
    test('catalog exposes all supported actions', () {
      expect(availableAiActions, hasLength(9));
      final ids = availableAiActions.map((e) => e.id).toList();
      expect(ids, contains(AiActionId.addTrip));
      expect(ids, contains(AiActionId.addFactoryTrip));
      expect(ids, contains(AiActionId.addBus));
      expect(ids, contains(AiActionId.addDriver));
      expect(ids, contains(AiActionId.addFactory));
      expect(ids, contains(AiActionId.queryTrips));
      expect(ids, contains(AiActionId.queryBuses));
      expect(ids, contains(AiActionId.queryDrivers));
      expect(ids, contains(AiActionId.queryFactories));
      final tripAction = availableAiActions.firstWhere((a) => a.id == AiActionId.addTrip);
      expect(tripAction.title.contains('إضافة رحلة'), isTrue);
      expect(tripAction.title.isNotEmpty, isTrue);
      expect(tripAction.description.isNotEmpty, isTrue);
    });

    test('factory trip choices expose only trip and night outing', () {
      expect(availableFactoryTripTypes, hasLength(2));
      final types =
          availableFactoryTripTypes.map((e) => e.type).toSet();
      expect(types, containsAll({'trip', 'night_outing'}));
    });
  });

  group('Factory trip selection', () {
    test('detects سهرة as night outing', () {
      expect(
        LocalIntentService.detectFactoryTripType('عايز سهرة'),
        'night_outing',
      );
      expect(
        LocalIntentService.detectFactoryTripType('سهرة'),
        'night_outing',
      );
      expect(
        LocalIntentService.detectFactoryTripType('بالليل'),
        'night_outing',
      );
    });

    test('detects رحلة as trip', () {
      expect(
        LocalIntentService.detectFactoryTripType('عايز رحلة'),
        'trip',
      );
      expect(
        LocalIntentService.detectFactoryTripType('رحلة عادية'),
        'trip',
      );
    });

    test('returns null for unrelated text', () {
      expect(
        LocalIntentService.detectFactoryTripType('كوباية شاي'),
        isNull,
      );
    });
  });

  group('Execution bridge (AiEntityResolver.buildTripEntity)', () {
    final bus = BusEntity(
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

    final driver = DriverEntity(
      id: 'drv_1',
      name: 'أحمد',
      phone: '012',
      tripsCount: 0,
      totalRevenue: 0,
    );

    final factory = FactoryEntity(
      id: 'fac_1',
      name: 'مصنع النور',
      phone: '01',
      details: '',
      tripsCount: 0,
      totalRevenue: 0,
      createdAt: DateTime(2026, 1, 1),
    );

    test('regular trip mirrors AddTripBottomSheet mapping', () {
      final trip = AiEntityResolver.buildTripEntity(
        draft: AiTripDraft(
          busName: 'الوهاب',
          plateNumber: 'أ ب ج 123',
          driverName: 'أحمد',
          factoryName: 'مصنع النور',
          revenue: 1200,
          driverWage: 300,
          type: TripType.trip,
        ),
        bus: bus,
        driver: driver,
        factory: factory,
      );

      expect(trip.type, TripType.trip);
      expect(trip.busId, 'bus_1');
      expect(trip.busName, 'الوهاب');
      expect(trip.plateNumber, 'أ ب ج 123');
      expect(trip.driverId, 'drv_1');
      expect(trip.driverName, 'أحمد');
      expect(trip.factoryId, 'fac_1');
      expect(trip.factoryName, 'مصنع النور');
      expect(trip.revenue, 1200);
      expect(trip.driverWage, 300);
    });

    test('night outing factory trip preserves outing type via draft', () {
      final trip = AiEntityResolver.buildTripEntity(
        draft: AiTripDraft(
          busName: 'الوهاب',
          driverName: 'أحمد',
          factoryName: 'مصنع النور',
          type: TripType.nightOuting,
        ),
        bus: bus,
        driver: driver,
        factory: factory,
      );

      expect(trip.type, TripType.nightOuting);
      expect(trip.isNightOuting, isTrue);
      expect(trip.factoryId, 'fac_1');
    });

    test('draft merge keeps context-injected bus while driver updates', () {
      final contextInjected = AiTripDraft(busName: 'الوهاب', plateNumber: 'أ ب ج 123');
      final userMessage = AiTripDraft(driverName: 'أحمد');

      final merged = contextInjected.merge(userMessage);

      expect(merged.busName, 'الوهاب');
      expect(merged.plateNumber, 'أ ب ج 123');
      expect(merged.driverName, 'أحمد');
      expect(merged.missingRequiredFields, isEmpty);
    });

    test('draft without context bus still reports bus missing', () {
      const draft = AiTripDraft(driverName: 'أحمد');
      expect(draft.missingRequiredFields, contains('الأتوبيس'));
    });
  });

  group('LocalIntentService regression', () {
    test('isHelpRequest recognizes capability questions', () {
      expect(
        LocalIntentService.isHelpRequest('إيه اللي تقدر تعمله؟'),
        isTrue,
      );
      expect(
        LocalIntentService.isHelpRequest('ممكن تعمل إيه؟'),
        isTrue,
      );
    });

    test('isAddTripIntent recognizes add-trip intent without data', () {
      expect(
        LocalIntentService.isAddTripIntent(
          'عايز أضيف رحلة',
          containsTripData: false,
        ),
        isTrue,
      );
      expect(
        LocalIntentService.isAddTripIntent(
          'عايز أضيف رحلة',
          containsTripData: true,
        ),
        isFalse,
      );
    });
  });
}