import 'package:elostaz_travel/domain/bus/entity/bus_entity.dart';
import 'package:elostaz_travel/domain/driver/entity/driver_entity.dart';
import 'package:elostaz_travel/domain/factory/entity/factory_entity.dart';
import 'package:elostaz_travel/presentation/ai_assistant/model/ai_action_option.dart';
import 'package:elostaz_travel/presentation/ai_assistant/model/ai_guided_field.dart';
import 'package:elostaz_travel/presentation/ai_assistant/provider/ai_assistant_provider.dart';
import 'package:elostaz_travel/presentation/ai_assistant/service/ai_duplicate_checker.dart';
import 'package:elostaz_travel/presentation/ai_assistant/service/local_intent_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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

  final busSameName = BusEntity(
    id: 'bus_2',
    busName: 'الوهاب',
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
    specialConditions: '',
    insuranceType: 'غير مؤمنة',
  );

  final driverAhmed1 = DriverEntity(
    id: 'drv_1',
    name: 'احمد محمد',
    phone: '01234567890',
    tripsCount: 3,
    totalRevenue: 15000,
  );

  final driverAhmed2 = DriverEntity(
    id: 'drv_2',
    name: 'احمد محمد',
    phone: '01098765432',
    tripsCount: 5,
    totalRevenue: 25000,
  );

  final factoryNour = FactoryEntity(
    id: 'fac_1',
    name: 'مصنع النور',
    phone: '010',
    details: 'القاهرة',
    tripsCount: 5,
    totalRevenue: 25000,
    createdAt: DateTime(2026, 1, 1),
  );

  String? checkDriver(
    Map<String, String> values,
    List<DriverEntity> drivers,
  ) {
    return AiDuplicateChecker.checkCreate(
      action: AiActionId.addDriver,
      values: values,
      buses: [bus1],
      drivers: drivers,
      factories: [factoryNour],
    );
  }

  String? checkBus(Map<String, String> values, List<BusEntity> buses) {
    return AiDuplicateChecker.checkCreate(
      action: AiActionId.addBus,
      values: values,
      buses: buses,
      drivers: [],
      factories: [],
    );
  }

  // ── Area 1: duplicate-safety for Add Driver ──────────────────────────
  group('Add Driver duplicate-safety', () {
    test('existing "احمد محمد" with same data -> block, show identifying info',
        () {
      final msg = checkDriver(
        {
          AiGuidedField.driverName.name: 'احمد محمد',
          AiGuidedField.driverPhone.name: '01234567890',
        },
        [driverAhmed1],
      );
      expect(msg, isNotNull);
      expect(msg, contains('احمد محمد'));
      expect(msg, contains('01234567890'));
      expect(msg, contains('موجود بالفعل'));
    });

    test('existing name with Arabic-Indic spelling variants still matches', () {
      final msg = checkDriver(
        {AiGuidedField.driverName.name: 'أحمد محمد'},
        [driverAhmed1],
      );
      expect(msg, isNotNull);
      expect(msg, contains('احمد محمد'));
    });

    test('same name, different phone -> conflict, never create/update', () {
      final msg = checkDriver(
        {
          AiGuidedField.driverName.name: 'احمد محمد',
          AiGuidedField.driverPhone.name: '01999999999',
        },
        [driverAhmed1],
      );
      expect(msg, isNotNull);
      expect(msg, contains('تليفون مختلف'));
      expect(msg, contains('مش هعدل'));
    });

    test('multiple "احمد محمد" -> clarification, no creation', () {
      final msg = checkDriver(
        {AiGuidedField.driverName.name: 'احمد محمد'},
        [driverAhmed1, driverAhmed2],
      );
      expect(msg, isNotNull);
      expect(msg, contains('أكتر من سايق'));
    });

    test('no existing driver -> null (normal creation path)', () {
      final msg = checkDriver(
        {AiGuidedField.driverName.name: 'محمد الجديد'},
        [driverAhmed1],
      );
      expect(msg, isNull);
    });
  });

  // ── Area 1: duplicate-safety for Add Bus ────────────────────────────
  group('Add Bus duplicate-safety', () {
    test('existing bus by plate (Arabic-Indic digits in input) -> block, '
        'show name+plate', () {
      final msg = checkBus(
        {
          AiGuidedField.busName.name: 'اتوبيس مختلف',
          AiGuidedField.plateNumber.name: 'أ ب ج ١٢٣',
        },
        [bus1],
      );
      expect(msg, isNotNull);
      expect(msg, contains('الوهاب'));
      expect(msg, contains('أ ب ج 123'));
      expect(msg, contains('موجود بالفعل'));
    });

    test('existing bus by name with a different plate -> block, show existing',
        () {
      final msg = checkBus(
        {
          AiGuidedField.busName.name: 'الوهاب',
          AiGuidedField.plateNumber.name: 'ط ط ط 999',
        },
        [busSameName],
      );
      expect(msg, isNotNull);
      expect(msg, contains('د ه و 456'));
    });

    test('multiple buses with same plate -> clarification, no creation', () {
      final second = BusEntity(
        id: 'bus_3',
        busName: 'النيل',
        plateNumber: 'أ ب ج 123',
        brand: 'ميكروباص',
        model: '',
        manufacturingYear: 2019,
        modelYear: 2019,
        chassisNumber: 'CH3',
        engineNumber: 'EN3',
        passengerCount: 14,
        vehicleType: 'ميكروباص',
        licenseExpiryDate: DateTime(2026, 5, 1),
        specialConditions: '',
        insuranceType: 'غير مؤمنة',
      );
      final msg = checkBus(
        {
          AiGuidedField.busName.name: 'أي',
          AiGuidedField.plateNumber.name: 'أ ب ج 123',
        },
        [bus1, second],
      );
      expect(msg, isNotNull);
      expect(msg, contains('أكتر من أتوبيس'));
    });

    test('no existing bus -> null (normal creation path)', () {
      final msg = checkBus(
        {
          AiGuidedField.busName.name: 'عربية جديدة',
          AiGuidedField.plateNumber.name: 'ط س ر 999',
        },
        [bus1],
      );
      expect(msg, isNull);
    });
  });

  // ── Area 1: duplicate-safety for Add Factory ────────────────────────
  group('Add Factory duplicate-safety', () {
    test('existing factory by name -> block, show info', () {
      final msg = AiDuplicateChecker.checkCreate(
        action: AiActionId.addFactory,
        values: {
          AiGuidedField.factoryName.name: 'مصنع النور',
          AiGuidedField.factoryDetails.name: 'القاهرة الجديدة',
        },
        buses: [],
        drivers: [],
        factories: [factoryNour],
      );
      expect(msg, isNotNull);
      expect(msg, contains('مصنع النور'));
      expect(msg, contains('موجود بالفعل'));
    });

    test('multiple factories with same name -> clarification, no creation',
        () {
      final msg = AiDuplicateChecker.checkCreate(
        action: AiActionId.addFactory,
        values: {AiGuidedField.factoryName.name: 'مصنع النور'},
        buses: [],
        drivers: [],
        factories: [
          factoryNour,
          FactoryEntity(
            id: 'fac_2',
            name: 'مصنع النور',
            phone: '',
            details: 'أكتوبر',
            tripsCount: 0,
            totalRevenue: 0,
            createdAt: DateTime(2026, 2, 1),
          ),
        ],
      );
      expect(msg, isNotNull);
      expect(msg, contains('أكتر من مصنع'));
    });

    test('no existing factory -> null (normal creation path)', () {
      final msg = AiDuplicateChecker.checkCreate(
        action: AiActionId.addFactory,
        values: {AiGuidedField.factoryName.name: 'مصنع غروب'},
        buses: [],
        drivers: [],
        factories: [factoryNour],
      );
      expect(msg, isNull);
    });
  });

  // ── Area 1: duplicate notification state/event ─────────────────────
  group('Duplicate notification (SnackBar event)', () {
    test('snack text for existing driver', () {
      expect(
        AiDuplicateChecker.snackMessageFor(AiActionId.addDriver),
        'معرفتش أضيف السواق، موجود بالفعل',
      );
    });

    test('snack text for existing bus', () {
      expect(
        AiDuplicateChecker.snackMessageFor(AiActionId.addBus),
        'معرفتش أضيف الأتوبيس، موجود بالفعل',
      );
    });

    test('snack text for existing factory', () {
      expect(
        AiDuplicateChecker.snackMessageFor(AiActionId.addFactory),
        'معرفتش أضيف المصنع، موجود بالفعل',
      );
    });

    test('state carries the duplicate notification event', () {
      const state = AiAssistantState();
      final withEvent = state.copyWith(
        clearCreate: true,
        clearSelectedAction: true,
        showActionList: true,
        lastDuplicateMessage: 'معرفتش أضيف السواق، موجود بالفعل',
      );
      expect(withEvent.lastDuplicateMessage,
          'معرفتش أضيف السواق، موجود بالفعل');
      expect(withEvent.showActionList, isTrue);
      expect(withEvent.selectedAction, isNull);
      expect(withEvent.showGenericReview, isFalse);
    });

    test('consumeLastDuplicate clears the notification event', () {
      const state = AiAssistantState();
      final withEvent = state.copyWith(lastDuplicateMessage: 'x');
      expect(withEvent.lastDuplicateMessage, 'x');
      final cleared = withEvent.copyWith(clearLastDuplicate: true);
      expect(cleared.lastDuplicateMessage, isNull);
    });
  });

  // ── Area 2: show-actions intent + catalog ordering ──────────────────
  group('Show-actions intent', () {
    test('Arabic requests detected', () {
      expect(LocalIntentService.isShowOptionsRequest('اظهرلي الخيارات'),
          isTrue);
      expect(LocalIntentService.isShowOptionsRequest('وريني الخيارات'), isTrue);
      expect(LocalIntentService.isShowOptionsRequest('اريني الاكشنز'), isTrue);
      expect(LocalIntentService.isShowOptionsRequest('عايز الخيارات'), isTrue);
    });

    test('English requests detected', () {
      expect(LocalIntentService.isShowOptionsRequest('show actions'), isTrue);
      expect(LocalIntentService.isShowOptionsRequest('show options'), isTrue);
      expect(LocalIntentService.isShowOptionsRequest('what can you do'), isTrue);
    });

    test('does NOT steal add/create intents', () {
      expect(LocalIntentService.isShowOptionsRequest('عايز اضيف رحلة'),
          isFalse);
      expect(LocalIntentService.isShowOptionsRequest('اضيف اتوبيس'), isFalse);
    });

    test('does NOT steal entity query intents', () {
      expect(LocalIntentService.isShowOptionsRequest('وريني الرحلات'),
          isFalse);
      expect(LocalIntentService.isShowOptionsRequest('وريني العربيات'),
          isFalse);
      expect(LocalIntentService.isShowOptionsRequest('وريني المصانع'),
          isFalse);
    });

    test('show-options phrases are never classified as add/query actions', () {
      for (final phrase in [
        'اظهرلي الخيارات',
        'وريني الخيارات',
        'show actions',
        'what can you do',
      ]) {
        expect(LocalIntentService.detectAddAction(phrase), isNull,
            reason: 'should not create for: $phrase');
        expect(LocalIntentService.detectQueryAction(phrase), isNull,
            reason: 'should not query for: $phrase');
      }
    });

    test('catalog keeps the required order (5 add then 4 query)', () {
      expect(
        availableAiActions.map((a) => a.id).toList(),
        [
          AiActionId.addTrip,
          AiActionId.addFactoryTrip,
          AiActionId.addBus,
          AiActionId.addDriver,
          AiActionId.addFactory,
          AiActionId.queryTrips,
          AiActionId.queryBuses,
          AiActionId.queryDrivers,
          AiActionId.queryFactories,
        ],
      );
    });
  });
}