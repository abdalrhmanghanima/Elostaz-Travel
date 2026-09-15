import 'package:elostaz_travel/presentation/ai_assistant/model/ai_action_option.dart';
import 'package:elostaz_travel/presentation/ai_assistant/model/ai_guided_field.dart';
import 'package:elostaz_travel/presentation/ai_assistant/widgets/ai_action_confirmation_card.dart';
import 'package:elostaz_travel/presentation/ai_assistant/widgets/ai_action_options_list.dart';
import 'package:elostaz_travel/presentation/ai_assistant/widgets/ai_entity_choice_list.dart';
import 'package:elostaz_travel/presentation/ai_assistant/widgets/ai_factory_trip_choice_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(
        child: child,
      ),
    ),
  );
}

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  group('Phase 8 UI Verification: Action Catalog Grouping', () {
    testWidgets('renders only the إضافة section and all 5 add actions '
        '(Queries section hidden, query catalog intact)', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      AiActionOption? selected;

      await tester.pumpWidget(
        _wrap(
          AiActionOptionsList(
            options: availableAiActions,
            onSelect: (opt) => selected = opt,
          ),
        ),
      );
      await tester.pump();

      expect(find.text('إضافة'), findsOneWidget);
      expect(find.text('استعلام'), findsNothing);

      expect(find.text('إضافة أتوبيس'), findsOneWidget);
      expect(find.text('إضافة سائق'), findsOneWidget);
      expect(find.text('إضافة مصنع'), findsOneWidget);
      expect(find.text('إضافة رحلة أتوبيس'), findsOneWidget);
      expect(find.text('إضافة رحلة مصنع'), findsOneWidget);

      expect(find.text('الاستعلام عن الرحلات'), findsNothing);
      expect(find.text('الاستعلام عن الأتوبيسات'), findsNothing);
      expect(find.text('الاستعلام عن السائقين'), findsNothing);
      expect(find.text('الاستعلام عن المصانع'), findsNothing);

      await tester.tap(find.text('إضافة أتوبيس'));
      await tester.pump();
      expect(selected?.id, AiActionId.addBus);
    });

    testWidgets('every rendered action is an Add action '
        '(covers the show-actions/أظهرلي الخيارات path)', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        _wrap(
          AiActionOptionsList(
            options: availableAiActions,
            onSelect: (_) {},
          ),
        ),
      );
      await tester.pump();

      final addCount = availableAiActions.where((o) => o.isCreate).length;

      final optionTitles = [
        for (final o in availableAiActions.where((o) => o.isCreate)) o.title,
      ];
      for (final title in optionTitles) {
        expect(find.text(title), findsOneWidget);
      }

      expect(find.byType(InkWell), findsNWidgets(addCount));
    });

    testWidgets('query actions remain in the source catalog '
        '(query functionality is not deleted)', (tester) async {
      final queryIds = availableAiActions.where((o) => o.isQuery).map((o) => o.id);
      expect(queryIds, containsAll([
        AiActionId.queryTrips,
        AiActionId.queryBuses,
        AiActionId.queryDrivers,
        AiActionId.queryFactories,
      ]));
      expect(availableAiActions, hasLength(9));
    });
  });

  group('Phase 8 UI Verification: AiCreateConfirmationCard', () {
    testWidgets('renders addBus fields, summary, confirm and cancel callbacks',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      var confirmed = false;
      var cancelled = false;

      final values = {
        AiGuidedField.busName.name: 'الوهاب',
        AiGuidedField.plateNumber.name: 'ط س ر ١٢٣٤',
        AiGuidedField.passengerCount.name: '30',
        AiGuidedField.insuranceType.name: 'مؤمنة',
      };

      await tester.pumpWidget(
        _wrap(
          AiCreateConfirmationCard(
            action: AiActionId.addBus,
            values: values,
            onConfirm: () => confirmed = true,
            onEdit: () {},
            onCancel: () => cancelled = true,
            isConfirming: false,
            canConfirm: true,
          ),
        ),
      );
      await tester.pump();

      expect(find.text('تأكيد إضافة أتوبيس'), findsOneWidget);
      expect(find.text('الوهاب'), findsOneWidget);
      expect(find.text('ط س ر ١٢٣٤'), findsOneWidget);
      expect(find.text('مؤمنة'), findsOneWidget);
      expect(find.text('هل تريد حفظ هذه البيانات؟'), findsOneWidget);

      await tester.tap(find.text('تأكيد وتنفيذ'));
      await tester.pump();
      expect(confirmed, isTrue);

      await tester.tap(find.text('إلغاء'));
      await tester.pump();
      expect(cancelled, isTrue);
    });

    testWidgets('shows loading indicator and disables button when isConfirming is true',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        _wrap(
          AiCreateConfirmationCard(
            action: AiActionId.addDriver,
            values: {AiGuidedField.driverName.name: 'محمود'},
            onConfirm: () {},
            onEdit: () {},
            onCancel: () {},
            isConfirming: true,
            canConfirm: true,
          ),
        ),
      );
      await tester.pump();

      expect(find.text('جاري الحفظ...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });

  group('Phase 8 UI Verification: Factory choice and trip type choice widgets', () {
    testWidgets('AiFactoryTripChoiceList renders رحلة and سهرة and handles tap',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      String? selectedType;

      await tester.pumpWidget(
        _wrap(
          AiFactoryTripChoiceList(
            factoryName: 'مصنع النور',
            onSelect: (type) => selectedType = type,
          ),
        ),
      );
      await tester.pump();

      expect(find.textContaining('مصنع النور'), findsOneWidget);
      expect(find.text('رحلة'), findsOneWidget);
      expect(find.text('سهرة'), findsOneWidget);

      await tester.tap(find.text('سهرة'));
      await tester.pump();
      expect(selectedType, 'night_outing');
    });

    testWidgets('AiEntityChoiceList renders factory candidates correctly',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      String? chosenId;

      await tester.pumpWidget(
        _wrap(
          AiEntityChoiceList(
            question: 'اختار المصنع:',
            options: const [
              AiEntityChoiceItem(id: 'f1', title: 'مصنع النور', subtitle: '01000000000'),
              AiEntityChoiceItem(id: 'f2', title: 'مصنع الأمل', subtitle: '01111111111'),
            ],
            onSelect: (id) => chosenId = id,
          ),
        ),
      );
      await tester.pump();

      expect(find.text('اختار المصنع:'), findsOneWidget);
      expect(find.text('مصنع النور'), findsOneWidget);
      expect(find.text('مصنع الأمل'), findsOneWidget);

      await tester.tap(find.text('مصنع النور'));
      await tester.pump();
      expect(chosenId, 'f1');
    });
  });
}
