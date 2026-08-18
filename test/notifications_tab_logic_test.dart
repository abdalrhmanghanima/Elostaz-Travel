import 'package:elostaz_travel/domain/bus/entity/bus_entity.dart';
import 'package:elostaz_travel/presentation/home/tabs/notifications/provider/notifications_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NotificationsTab Filter & Expiry Logic Tests', () {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    BusEntity createBus({
      required String id,
      required String name,
      required int daysFromNow,
    }) {
      return BusEntity(
        id: id,
        busName: name,
        plateNumber: '123',
        brand: 'Mercedes',
        modelYear: 2022,
        chassisNumber: 'CHS-$id',
        engineNumber: 'ENG-$id',
        passengerCount: 45,
        vehicleType: 'سياحي',
        licenseExpiryDate: today.add(Duration(days: daysFromNow)),
        specialConditions: '',
        insuranceType: 'شاملة',
      );
    }

    test('Categorizes buses accurately according to expiry rules', () {
      final busExpired = createBus(id: '1', name: 'منتهي', daysFromNow: -2);
      final busExpiring7 = createBus(id: '2', name: 'قريب 7', daysFromNow: 7);
      final busExpiring20 = createBus(id: '3', name: 'قريب 20', daysFromNow: 20);
      final busExpiring30 = createBus(id: '4', name: 'قريب 30', daysFromNow: 30);
      final busValid35 = createBus(id: '5', name: 'ساري 35', daysFromNow: 35);
      final busValid90 = createBus(id: '6', name: 'ساري 90', daysFromNow: 90);

      final buses = [
        busExpired,
        busExpiring7,
        busExpiring20,
        busExpiring30,
        busValid35,
        busValid90,
      ];

      final in30 = today.add(const Duration(days: 30));

      final items = buses.map((bus) {
        final expiry = DateTime(
          bus.licenseExpiryDate.year,
          bus.licenseExpiryDate.month,
          bus.licenseExpiryDate.day,
        );
        final daysLeft = expiry.difference(today).inDays;

        final BusNotificationFilter status;
        if (expiry.isBefore(today) || expiry.isAtSameMomentAs(today)) {
          status = BusNotificationFilter.expired;
        } else if (expiry.isBefore(in30) || expiry.isAtSameMomentAs(in30)) {
          status = BusNotificationFilter.expiringSoon;
        } else {
          status = BusNotificationFilter.valid;
        }

        return BusNotificationItem(
          bus: bus,
          status: status,
          daysLeft: daysLeft,
        );
      }).toList();

      expect(items[0].status, equals(BusNotificationFilter.expired));
      expect(items[1].status, equals(BusNotificationFilter.expiringSoon));
      expect(items[2].status, equals(BusNotificationFilter.expiringSoon));
      expect(items[3].status, equals(BusNotificationFilter.expiringSoon));
      expect(items[4].status, equals(BusNotificationFilter.valid));
      expect(items[5].status, equals(BusNotificationFilter.valid));

      // Filter: All -> 6
      expect(items.length, equals(6));

      // Filter: Expired -> 1
      final expiredOnly = items.where((e) => e.status == BusNotificationFilter.expired).toList();
      expect(expiredOnly.length, equals(1));
      expect(expiredOnly.first.bus.busName, equals('منتهي'));

      // Filter: Expiring Soon -> 3
      final expiringSoonOnly = items.where((e) => e.status == BusNotificationFilter.expiringSoon).toList();
      expect(expiringSoonOnly.length, equals(3));

      // Filter: Valid -> 2
      final validOnly = items.where((e) => e.status == BusNotificationFilter.valid).toList();
      expect(validOnly.length, equals(2));
    });

    test('Filter tab titles and empty messages are defined correctly in Arabic', () {
      expect(BusNotificationFilter.all.title, equals('الكل'));
      expect(BusNotificationFilter.valid.title, equals('ساري'));
      expect(BusNotificationFilter.expiringSoon.title, equals('ينتهي قريبًا'));
      expect(BusNotificationFilter.expired.title, equals('منتهي'));

      expect(BusNotificationFilter.all.emptyMessage, equals('لا توجد تنبيهات'));
      expect(BusNotificationFilter.valid.emptyMessage, equals('لا توجد أتوبيسات سارية'));
      expect(BusNotificationFilter.expiringSoon.emptyMessage, equals('لا توجد أتوبيسات تنتهي قريبًا'));
      expect(BusNotificationFilter.expired.emptyMessage, equals('لا توجد أتوبيسات منتهية'));
    });
  });
}
