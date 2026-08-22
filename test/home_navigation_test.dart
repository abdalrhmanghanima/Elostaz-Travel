import 'package:elostaz_travel/domain/bus/entity/bus_entity.dart';
import 'package:elostaz_travel/main.dart';
import 'package:elostaz_travel/presentation/home/provider/bottom_nav_provider.dart';
import 'package:elostaz_travel/presentation/home/tabs/home/home_tab.dart';
import 'package:elostaz_travel/presentation/home/tabs/home/provider/home_stats_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HomeTab Navigation to Notifications Tab Tests', () {
    final now = DateTime.now();

    final testBusExpiringSoon = BusEntity(
      id: 'bus_1',
      busName: 'أتوبيس النيل',
      plateNumber: 'د ه و 2002',
      brand: 'مان',
      modelYear: 2019,
      chassisNumber: 'CHS-100002',
      engineNumber: 'ENG-100002',
      passengerCount: 50,
      vehicleType: 'سياحي',
      licenseExpiryDate: now.add(const Duration(days: 7)),
      specialConditions: 'مكيف',
      insuranceType: 'شاملة',
    );

    final testHomeStats = HomeStats(
      totalBuses: 6,
      totalDrivers: 4,
      currentMonthTripCount: 7,
      currentMonthRevenue: 29700,
      currentMonthExpenses: 6900,
      currentMonthNetRevenue: 22800,
      busesExpiringWithin30Days: [testBusExpiringSoon],
      expiredBuses: [],
      validLicenseCount: 5,
    );

    testWidgets('TEST A: Tapping notification bell icon on HomeTab changes bottomNavProvider to 4',
        (tester) async {
      final container = ProviderContainer(
        overrides: [
          homeStatsProvider.overrideWith((ref) => Future.value(testHomeStats)),
        ],
      );

      expect(container.read(bottomNavProvider), equals(0));

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            navigatorKey: navigatorKey,
            home: const HomeTab(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find notification bell icon in AppBar
      final bellFinder = find.byWidgetPredicate(
        (widget) =>
            widget is GestureDetector &&
            widget.child is SizedBox,
      );
      expect(bellFinder, findsWidgets);

      // Tap the first matching action GestureDetector (AppBar notification bell)
      await tester.tap(bellFinder.first);
      await tester.pumpAndSettle();

      // Verify bottomNavProvider index changed to 4 (NotificationsTab)
      expect(container.read(bottomNavProvider), equals(4));
    });

    testWidgets('TEST B: Tapping "عرض الكل" in "يحتاج إجراء" changes bottomNavProvider to 4',
        (tester) async {
      final container = ProviderContainer(
        overrides: [
          homeStatsProvider.overrideWith((ref) => Future.value(testHomeStats)),
        ],
      );

      expect(container.read(bottomNavProvider), equals(0));

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            navigatorKey: navigatorKey,
            home: const HomeTab(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find "عرض الكل" text
      final showAllFinder = find.text('عرض الكل');
      expect(showAllFinder, findsOneWidget);

      // Scroll into view within SingleChildScrollView
      await tester.ensureVisible(showAllFinder);
      await tester.pumpAndSettle();

      // Tap "عرض الكل"
      await tester.tap(showAllFinder);
      await tester.pumpAndSettle();

      // Verify bottomNavProvider index changed to 4 (NotificationsTab)
      expect(container.read(bottomNavProvider), equals(4));
    });
  });
}
