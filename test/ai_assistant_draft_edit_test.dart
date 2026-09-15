import 'package:elostaz_travel/data/ai_assistant/service/draft_edit_parser.dart';
import 'package:elostaz_travel/presentation/ai_assistant/model/ai_action_option.dart';
import 'package:elostaz_travel/presentation/ai_assistant/model/ai_guided_field.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DraftEditParser.parseTrip', () {
    test('changes the driver name', () {
      final r = DraftEditParser.parseTrip('غير السواق يبقى محمود');
      expect(r.hasChanges, isTrue);
      expect(r.patch.driverName, 'محمود');
      expect(r.editedType, isFalse);
      expect(r.patch.revenue, isNull);
    });

    test('changes revenue without touching the trip type', () {
      final r = DraftEditParser.parseTrip('الايراد يبقى 5000');
      expect(r.hasChanges, isTrue);
      expect(r.patch.revenue, 5000);
      expect(r.editedType, isFalse);
      expect(r.patch.type, isNull);
    });

    test('changes the driver wage', () {
      final r = DraftEditParser.parseTrip('الاجر يبقى 800');
      expect(r.patch.driverWage, 800);
    });

    test('changes the trip expenses', () {
      final r = DraftEditParser.parseTrip('المصروف يبقى 1200');
      expect(r.patch.expenses, 1200);
      expect(r.patch.revenue, isNull);
    });

    test('changes date to tomorrow', () {
      final r = DraftEditParser.parseTrip('غير التاريخ لبكره');
      expect(r.hasChanges, isTrue);
      expect(r.patch.tripDate, isNotNull);
      expect(
        r.patch.tripDate!.isAfter(
          DateTime.now().subtract(const Duration(days: 1)),
        ),
        isTrue,
      );
    });

    test('changes date to today', () {
      final r = DraftEditParser.parseTrip('التاريخ يبقى النهارده');
      expect(r.patch.tripDate, isNotNull);
      final today = DateTime.now();
      expect(
        r.patch.tripDate!.year == today.year &&
            r.patch.tripDate!.month == today.month &&
            r.patch.tripDate!.day == today.day,
        isTrue,
      );
    });

    test('parses an explicit slash date', () {
      final r = DraftEditParser.parseTrip('التاريخ يبقى 15/12/2026');
      expect(r.patch.tripDate, DateTime(2026, 12, 15));
    });

    test('parses day + Arabic month', () {
      final r = DraftEditParser.parseTrip('التاريخ يوم 15 سبتمبر');
      final now = DateTime.now();
      expect(r.patch.tripDate, DateTime(now.year, 9, 15));
    });

    test('parses a 24h time with minutes', () {
      final r = DraftEditParser.parseTrip('الوقت يكون 14:30');
      expect(r.patch.departureTime, '14:30');
    });

    test('parses a 12h evening time', () {
      final r = DraftEditParser.parseTrip('الوقت يبقى الساعه 5 مساء');
      expect(r.patch.departureTime, '17:00');
    });

    test('changes the bus name', () {
      final r = DraftEditParser.parseTrip('غير الاتوبيس يبقى الوهاب');
      expect(r.patch.busName, 'الوهاب');
    });

    test('changes the plate number and normalizes digits', () {
      final r = DraftEditParser.parseTrip('غير اللوحه يبقى ٤٥٦٧');
      expect(r.patch.plateNumber, '4567');
    });

    test('changes the factory name', () {
      final r = DraftEditParser.parseTrip('غير المصنع يبقى النيل');
      expect(r.patch.factoryName, 'النيل');
    });

    test('changes the trip type to night outing', () {
      final r = DraftEditParser.parseTrip('النوع يبقى سهرة');
      expect(r.editedType, isTrue);
      expect(r.patch.type, 'night_outing');
    });

    test('changes the trip type to trip', () {
      final r = DraftEditParser.parseTrip('النوع يبقى رحلة');
      expect(r.editedType, isTrue);
      expect(r.patch.type, 'trip');
    });

    test('changes details', () {
      final r = DraftEditParser.parseTrip('التفاصيل يبقى شغل كله');
      expect(r.patch.details, 'شغل كله');
    });

    test('changes expense details', () {
      final r = DraftEditParser.parseTrip('تفاصيل المصروف يبقى كام بوابة');
      expect(r.patch.expenseDetails, 'كام بوابه');
      expect(r.patch.expenses, isNull);
    });

    test('parses multiple fields in one utterance', () {
      final r = DraftEditParser.parseTrip(
        'غير الاتوبيس يبقى الوهاب والايراد يبقى 9000',
      );
      expect(r.patch.busName, 'الوهاب');
      expect(r.patch.revenue, 9000);
      expect(r.hasChanges, isTrue);
    });

    test('returns no changes for a non-edit utterance', () {
      final r = DraftEditParser.parseTrip('تمام');
      expect(r.hasChanges, isFalse);
      expect(r.patch.isEmpty, isTrue);
    });

    // ── Replacement pattern tests (A through M) ─────────────────────────

    test('A: single driver replacement with "من … خليه …"', () {
      final r = DraftEditParser.parseTrip(
        'غير السواق من احمد محمد خليه عبدالرحمن محمد',
      );
      expect(r.hasChanges, isTrue);
      expect(r.patch.driverName, 'عبدالرحمن محمد');
      expect(r.patch.busName, isNull,
          reason: 'old value after من must not leak into busName');
    });

    test('B: single bus replacement with "بدل … يكون …"', () {
      final r = DraftEditParser.parseTrip(
        'الأتوبيس بدل الوهاب يكون أتوبيس الاسكندرية',
      );
      expect(r.hasChanges, isTrue);
      expect(r.patch.busName, 'اتوبيس الاسكندريه');
    });

    test('C: driver + bus replacement in one sentence', () {
      final r = DraftEditParser.parseTrip(
        'غير السواق من احمد محمد خليه عبدالرحمن محمد والأتوبيس بدل الوهاب يكون أتوبيس الاسكندرية',
      );
      expect(r.patch.driverName, 'عبدالرحمن محمد');
      expect(r.patch.busName, 'اتوبيس الاسكندريه');
      expect(r.patch.revenue, isNull,
          reason: 'unmentioned fields must remain null');
    });

    test('D: revenue replacement', () {
      final r = DraftEditParser.parseTrip('الايراد يبقى 3000 بدل 2000');
      expect(r.patch.revenue, 3000);
    });

    test('E: multiple fields with replacement pattern in one sentence', () {
      final r = DraftEditParser.parseTrip(
        'غير السواق من احمد خليه محمود والاجره يبقى 700 بدل 500',
      );
      expect(r.patch.driverName, 'محمود');
      expect(r.patch.driverWage, 700);
    });

    test('F: old entity name after من is never extracted as the new entity', () {
      final r = DraftEditParser.parseTrip(
        'غير السواق من احمد محمد خليه عبدالرحمن محمد',
      );
      expect(r.patch.driverName, isNot('احمد محمد'),
          reason: 'the old value "احمد محمد" must never be the new value');
      expect(r.patch.driverName, 'عبدالرحمن محمد');
    });

    test('G: preserve all unmentioned fields when using replacement pattern', () {
      final r = DraftEditParser.parseTrip(
        'غير السواق من احمد محمد خليه عبدالرحمن محمد',
      );
      expect(r.patch.driverName, 'عبدالرحمن محمد');
      expect(r.patch.busName, isNull);
      expect(r.patch.revenue, isNull);
      expect(r.patch.driverWage, isNull);
      expect(r.patch.tripDate, isNull);
      expect(r.patch.departureTime, isNull);
      expect(r.patch.details, isNull);
      expect(r.patch.expenses, isNull);
      expect(r.patch.expenseDetails, isNull);
      expect(r.patch.type, isNull);
    });

    test('J: ambiguous new entity is not a parser concern but new value is extracted', () {
      final r = DraftEditParser.parseTrip(
        'غير السواق من احمد خليه سعيد',
      );
      expect(r.patch.driverName, 'سعيد');
    });

    test('L: typed edit flow - "خلي X Y بدل Z"', () {
      final r = DraftEditParser.parseTrip(
        'خلي السواق عبدالرحمن بدل احمد محمد',
      );
      expect(r.patch.driverName, 'عبدالرحمن');
    });

    test('replacement pattern with "يبقى" indicator', () {
      final r = DraftEditParser.parseTrip(
        'غير السواق من احمد يبقى عبدالرحمن',
      );
      expect(r.patch.driverName, 'عبدالرحمن');
    });

    test('replacement pattern with "يكون" indicator', () {
      final r = DraftEditParser.parseTrip(
        'غير الاتوبيس من الوهاب يكون الخضراء',
      );
      expect(r.patch.busName, 'الخضراء');
    });

    test('replacement pattern - بدل X بـ Y', () {
      final r = DraftEditParser.parseTrip(
        'بدل السواق احمد بـ عبدالرحمن',
      );
      expect(r.patch.driverName, 'عبدالرحمن');
    });

    test('replacement pattern - بدل X في Y', () {
      final r = DraftEditParser.parseTrip(
        'بدل الاتوبيس الوهاب في الخضراء',
      );
      expect(r.patch.busName, 'الخضراء');
    });

    test('old value in replacement pattern does not leak into patch', () {
      final r = DraftEditParser.parseTrip(
        'غير السواق من احمد محمد خليه عبدالرحمن محمد',
      );
      expect(r.patch.driverName, 'عبدالرحمن محمد');
      // The old value should not appear anywhere in the patch
      expect(r.patch.driverName!.contains('احمد'), isFalse);
    });

    test('simple edit without replacement pattern still works', () {
      final r = DraftEditParser.parseTrip('غير السواق يبقى محمود');
      expect(r.patch.driverName, contains('محمود'));
    });
  });

  group('DraftEditParser.parseCreate', () {
    test('addDriver: changes the name', () {
      final r = DraftEditParser.parseCreate('غير الاسم يبقى محمود', AiActionId.addDriver);
      expect(r.hasChanges, isTrue);
      expect(r.edits, hasLength(1));
      expect(r.edits.single.field, AiGuidedField.driverName);
      expect(r.edits.single.rawValue, 'محمود');
    });

    test('addDriver: changes the phone', () {
      final r = DraftEditParser.parseCreate(
        'رقم التليفون يبقى 01012345678',
        AiActionId.addDriver,
      );
      expect(r.edits, hasLength(1));
      expect(r.edits.single.field, AiGuidedField.driverPhone);
      expect(r.edits.single.rawValue, '01012345678');
    });

    test('addDriver: changes name and phone at once', () {
      final r = DraftEditParser.parseCreate(
        'غير الاسم يبقى محمود ورقم التليفون يبقى 01012345678',
        AiActionId.addDriver,
      );
      expect(r.edits, hasLength(2));
      final fields = r.edits.map((e) => e.field).toSet();
      expect(fields, {AiGuidedField.driverName, AiGuidedField.driverPhone});
    });

    test('addBus: changes the bus name', () {
      final r = DraftEditParser.parseCreate(
        'اسم الاتوبيس يبقى الوهاب',
        AiActionId.addBus,
      );
      expect(r.edits.single.field, AiGuidedField.busName);
      expect(r.edits.single.rawValue, 'الوهاب');
    });

    test('addBus: changes the plate number', () {
      final r = DraftEditParser.parseCreate(
        'رقم اللوحه يبقى ط س ر 1234',
        AiActionId.addBus,
      );
      expect(r.edits.single.field, AiGuidedField.plateNumber);
      expect(r.edits.single.rawValue, 'ط س ر 1234');
    });

    test('addBus: changes special conditions', () {
      final r = DraftEditParser.parseCreate(
        'الاشتراطات يبقى محظوره بيع',
        AiActionId.addBus,
      );
      expect(r.edits.single.field, AiGuidedField.specialConditions);
      expect(r.edits.single.rawValue, 'محظوره بيع');
    });

    test('addBus: changes the prohibited bank name', () {
      final r = DraftEditParser.parseCreate(
        'اسم البنك يبقى الاهلي',
        AiActionId.addBus,
      );
      expect(r.edits.single.field, AiGuidedField.prohibitedBankName);
      expect(r.edits.single.rawValue, 'الاهلي');
    });

    test('addFactory: changes the name', () {
      final r = DraftEditParser.parseCreate(
        'اسم المصنع يبقى النيل',
        AiActionId.addFactory,
      );
      expect(r.edits.single.field, AiGuidedField.factoryName);
      expect(r.edits.single.rawValue, 'النيل');
    });

    test('addFactory: changes the details', () {
      final r = DraftEditParser.parseCreate(
        'تفاصيل المصنع يبقى القاهره',
        AiActionId.addFactory,
      );
      expect(r.edits.single.field, AiGuidedField.factoryDetails);
      expect(r.edits.single.rawValue, 'القاهره');
    });

    test('addBus: no changes for a non-edit utterance', () {
      final r = DraftEditParser.parseCreate('تمام', AiActionId.addBus);
      expect(r.hasChanges, isFalse);
      expect(r.edits, isEmpty);
    });
  });
}