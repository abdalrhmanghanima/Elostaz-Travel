import 'package:elostaz_travel/domain/bus/entity/bus_entity.dart';
import 'package:elostaz_travel/domain/driver/entity/driver_entity.dart';
import 'package:elostaz_travel/domain/factory/entity/factory_entity.dart';
import 'package:elostaz_travel/domain/trip/entity/trip_entity.dart';
import 'package:elostaz_travel/domain/trip/repository/trip_repository.dart';
import 'package:elostaz_travel/presentation/ai_assistant/provider/ai_assistant_provider.dart';
import 'package:elostaz_travel/presentation/ai_assistant/widgets/ai_action_confirmation_card.dart';
import 'package:elostaz_travel/presentation/ai_assistant/widgets/ai_assistant_sheet.dart';
import 'package:elostaz_travel/presentation/home/tabs/bus/provider/bus_notifier.dart';
import 'package:elostaz_travel/presentation/home/tabs/bus/provider/bus_provider.dart';
import 'package:elostaz_travel/presentation/home/tabs/driver/provider/driver_notifier.dart';
import 'package:elostaz_travel/presentation/home/tabs/driver/provider/driver_provider.dart';
import 'package:elostaz_travel/presentation/home/tabs/factory/provider/factory_notifier.dart';
import 'package:elostaz_travel/presentation/home/tabs/factory/provider/factory_provider.dart';
import 'package:elostaz_travel/presentation/trip/provider/trip_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Widget-level verification of the post-edit layout in [AiAssistantSheet]:
/// after a draft edit the updated confirmation card must render BELOW the
/// assistant's edit-result message and be auto-scrolled into view (not hidden
/// above the conversational list).
class _FakeTripRepository implements TripRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<void> addTrip(TripEntity trip) async {}

  @override
  Future<void> updateTrip(TripEntity trip) async {}

  @override
  Future<void> deleteTrip(String tripId) async {}
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
}

class _TestFactoriesNotifier extends FactoriesNotifier {
  final List<FactoryEntity> _initial;
  _TestFactoriesNotifier(this._initial);

  @override
  Future<List<FactoryEntity>> build() async => _initial;
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

Future<void> _pumpSheet(
  WidgetTester tester, {
  List<BusEntity> buses = const [],
  List<DriverEntity> drivers = const [],
  List<FactoryEntity> factories = const [],
}) async {
  tester.view.physicalSize = const Size(430, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        tripRepositoryProvider.overrideWithValue(_FakeTripRepository()),
        busProvider.overrideWith(() => _TestBusNotifier(List.of(buses))),
        driversProvider.overrideWith(() => _TestDriversNotifier(List.of(drivers))),
        factoriesProvider.overrideWith(
          () => _TestFactoriesNotifier(List.of(factories)),
        ),
      ],
      child: const MaterialApp(
        home: Scaffold(body: AiAssistantSheet()),
      ),
    ),
  );
  await tester.pumpAndSettle();

  final container = ProviderScope.containerOf(
    tester.element(find.byType(AiAssistantSheet)),
  );
  await container.read(busProvider.future);
  await container.read(driversProvider.future);
  await container.read(factoriesProvider.future);
  await container.read(aiAssistantProvider.future);
  await tester.pumpAndSettle();
}

Future<void> _submit(WidgetTester tester, String text) async {
  await tester.enterText(find.byType(TextField), text);
  await tester.testTextInput.receiveAction(TextInputAction.done);
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  testWidgets(
    'bus trip: after an edit the updated card shows the new driver, renders '
    'right below the edit-result message and is auto-scrolled into view',
    (tester) async {
      await _pumpSheet(
        tester,
        buses: [_bus('bus_1', 'الوهاب', 'أ ب ج 123')],
        drivers: [
          _driver('drv_1', 'أحمد', '012'),
          _driver('drv_2', 'محمود', '013'),
        ],
      );

      await _submit(
        tester,
        'عايز أعمل رحلة للأتوبيس الوهاب والسواق أحمد والايراد 5000',
      );
      expect(find.text('تأكيد وتنفيذ'), findsOneWidget);

      await tester.tap(find.text('تعديل'));
      await tester.pumpAndSettle();

      await _submit(tester, 'غير السواق يبقى محمود');

      final card = find.byType(AiActionConfirmationCard);
      expect(card, findsOneWidget);
      expect(
        find.descendant(of: card, matching: find.text('محمود')),
        findsOneWidget,
        reason: 'the card must reflect the NEW driver after the edit',
      );
      expect(find.text('أحمد'), findsNothing);

      final message = find.text(tripEditedMessage);
      expect(message, findsOneWidget);

      final messageRect = tester.getRect(message);
      final cardRect = tester.getRect(card);
      final listRect = tester.getRect(find.byType(ListView));

      expect(
        messageRect.top,
        lessThan(cardRect.top),
        reason: 'the edit-result message must render above the updated card',
      );
      expect(
        cardRect.top,
        greaterThanOrEqualTo(listRect.top - 1),
        reason: 'the updated card must be auto-scrolled into the viewport',
      );
      expect(cardRect.bottom, lessThanOrEqualTo(listRect.bottom + 1));
    },
  );

  testWidgets(
    'bus trip: multiple consecutive edits keep the updated card below the '
    'edit-result message, auto-scrolled into view each time',
    (tester) async {
      await _pumpSheet(
        tester,
        buses: [_bus('bus_1', 'الوهاب', 'أ ب ج 123')],
        drivers: [
          _driver('drv_1', 'أحمد', '012'),
          _driver('drv_2', 'محمود', '013'),
        ],
      );

      await _submit(
        tester,
        'عايز أعمل رحلة للأتوبيس الوهاب والسواق أحمد والايراد 5000',
      );
      expect(find.text('تأكيد وتنفيذ'), findsOneWidget);

      await tester.tap(find.text('تعديل'));
      await tester.pumpAndSettle();
      await _submit(tester, 'غير السواق يبقى محمود');

      expect(find.text(tripEditedMessage), findsOneWidget);

      await tester.tap(find.text('تعديل'));
      await tester.pumpAndSettle();
      await _submit(tester, 'الايراد يبقى 9000');

      final card = find.byType(AiActionConfirmationCard);
      expect(card, findsOneWidget);
      final lastEditedMessage = find.text(tripEditedMessage).last;
      expect(
        lastEditedMessage,
        findsWidgets,
        reason: 'the latest edit-result message must be built and visible',
      );
      expect(
        find.descendant(of: card, matching: find.text('محمود')),
        findsOneWidget,
        reason: 'the card must keep the first edit after a second edit',
      );
      expect(
        find.descendant(of: card, matching: find.text('9000 ج.م')),
        findsOneWidget,
        reason: 'the card must reflect the second edit',
      );
      expect(find.text('أحمد'), findsNothing);
      expect(find.text('5000'), findsNothing);

      final lastMessageRect = tester.getRect(lastEditedMessage);
      final cardRect = tester.getRect(card);
      final listRect = tester.getRect(find.byType(ListView));

      expect(
        lastMessageRect.top,
        lessThan(cardRect.top),
        reason: 'the latest edit-result message must render above the card',
      );
      expect(cardRect.top, greaterThanOrEqualTo(listRect.top - 1));
      expect(cardRect.bottom, lessThanOrEqualTo(listRect.bottom + 1));
    },
  );

  testWidgets(
    'add driver: after a create-flow edit the review card renders below the '
    'messages and is auto-scrolled into view',
    (tester) async {
      await _pumpSheet(tester);

      await _submit(
        tester,
        'عايز أضيف سواق اسمه علي ورقم تليفونه 01012345678',
      );
      expect(find.text('تأكيد وتنفيذ'), findsOneWidget);

      await tester.tap(find.text('تعديل'));
      await tester.pumpAndSettle();

      await _submit(tester, 'غير الاسم يبقى محمود');

      final card = find.byType(AiCreateConfirmationCard);
      expect(card, findsOneWidget);
      expect(
        find.descendant(of: card, matching: find.text('محمود')),
        findsOneWidget,
        reason: 'the create review card must show the NEW name',
      );
      expect(find.text('علي'), findsNothing);

      final guideMessage = find
          .text('تمام، راجع البيانات واضغط "تأكيد وتنفيذ" 👇')
          .last;
      expect(guideMessage, findsWidgets);

      final guideRect = tester.getRect(guideMessage);
      final cardRect = tester.getRect(card);
      final listRect = tester.getRect(find.byType(ListView));

      expect(
        guideRect.top,
        lessThan(cardRect.top),
        reason: 'the edit guideline message must render above the review card',
      );
      expect(
        cardRect.top,
        greaterThanOrEqualTo(listRect.top - 1),
        reason: 'the review card must be auto-scrolled into the viewport',
      );
      expect(cardRect.bottom, lessThanOrEqualTo(listRect.bottom + 1));
    },
  );
}