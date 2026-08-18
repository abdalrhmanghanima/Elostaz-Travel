import 'package:elostaz_travel/core/services/license_notification_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LicenseNotificationService Unit Tests', () {
    test('generateNotificationId creates deterministic and unique IDs per bus', () {
      final service = LicenseNotificationService.instance;

      const bus1Id = 'bus_abc_123';
      const bus2Id = 'bus_xyz_789';

      // Verify stability across calls
      final bus1Id30First = service.generateNotificationId(
        bus1Id,
        LicenseNotificationType.thirtyDays,
      );
      final bus1Id30Second = service.generateNotificationId(
        bus1Id,
        LicenseNotificationType.thirtyDays,
      );
      expect(bus1Id30First, equals(bus1Id30Second));

      // Verify 4 distinct notification IDs for same bus
      final bus1_30 = service.generateNotificationId(
        bus1Id,
        LicenseNotificationType.thirtyDays,
      );
      final bus1_7 = service.generateNotificationId(
        bus1Id,
        LicenseNotificationType.sevenDays,
      );
      final bus1_1 = service.generateNotificationId(
        bus1Id,
        LicenseNotificationType.oneDay,
      );
      final bus1_0 = service.generateNotificationId(
        bus1Id,
        LicenseNotificationType.expired,
      );

      final allFour = {bus1_30, bus1_7, bus1_1, bus1_0};
      expect(allFour.length, equals(4));

      // Verify IDs fit within positive 32-bit integer range
      for (final id in allFour) {
        expect(id >= 0, isTrue);
        expect(id <= 2147483647, isTrue);
      }

      // Verify different buses generate different IDs
      final bus2_30 = service.generateNotificationId(
        bus2Id,
        LicenseNotificationType.thirtyDays,
      );
      expect(bus1_30 != bus2_30, isTrue);
    });

    test('Calendar date math correctly computes notification dates', () {
      final expiryDate = DateTime(2026, 9, 15, 14, 30);
      final expiryBase = DateTime(
        expiryDate.year,
        expiryDate.month,
        expiryDate.day,
        9,
        0,
        0,
      );

      final date30 = expiryBase.subtract(
        Duration(days: LicenseNotificationType.thirtyDays.daysBefore),
      );
      final date7 = expiryBase.subtract(
        Duration(days: LicenseNotificationType.sevenDays.daysBefore),
      );
      final date1 = expiryBase.subtract(
        Duration(days: LicenseNotificationType.oneDay.daysBefore),
      );
      final date0 = expiryBase.subtract(
        Duration(days: LicenseNotificationType.expired.daysBefore),
      );

      expect(date30, equals(DateTime(2026, 8, 16, 9, 0)));
      expect(date7, equals(DateTime(2026, 9, 8, 9, 0)));
      expect(date1, equals(DateTime(2026, 9, 14, 9, 0)));
      expect(date0, equals(DateTime(2026, 9, 15, 9, 0)));
    });
  });
}
