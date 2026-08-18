import 'package:elostaz_travel/domain/bus/entity/bus_entity.dart';
import 'package:elostaz_travel/presentation/home/tabs/bus/provider/bus_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum BusNotificationFilter {
  all(title: 'الكل', emptyMessage: 'لا توجد تنبيهات'),
  valid(title: 'ساري', emptyMessage: 'لا توجد أتوبيسات سارية'),
  expiringSoon(title: 'ينتهي قريبًا', emptyMessage: 'لا توجد أتوبيسات تنتهي قريبًا'),
  expired(title: 'منتهي', emptyMessage: 'لا توجد أتوبيسات منتهية');

  final String title;
  final String emptyMessage;

  const BusNotificationFilter({
    required this.title,
    required this.emptyMessage,
  });
}

class BusNotificationItem {
  final BusEntity bus;
  final BusNotificationFilter status;
  final int daysLeft;

  const BusNotificationItem({
    required this.bus,
    required this.status,
    required this.daysLeft,
  });
}

class NotificationCounts {
  final int all;
  final int valid;
  final int expiringSoon;
  final int expired;

  const NotificationCounts({
    required this.all,
    required this.valid,
    required this.expiringSoon,
    required this.expired,
  });

  static const zero = NotificationCounts(
    all: 0,
    valid: 0,
    expiringSoon: 0,
    expired: 0,
  );
}

final selectedNotificationFilterProvider =
    StateProvider<BusNotificationFilter>((ref) => BusNotificationFilter.all);

final notificationCountsProvider = Provider<NotificationCounts>((ref) {
  final busesAsync = ref.watch(busProvider);
  return busesAsync.maybeWhen(
    data: (buses) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final in30 = today.add(const Duration(days: 30));

      int valid = 0;
      int expiringSoon = 0;
      int expired = 0;

      for (final bus in buses) {
        final expiry = DateTime(
          bus.licenseExpiryDate.year,
          bus.licenseExpiryDate.month,
          bus.licenseExpiryDate.day,
        );

        if (expiry.isBefore(today) || expiry.isAtSameMomentAs(today)) {
          expired++;
        } else if (expiry.isBefore(in30) || expiry.isAtSameMomentAs(in30)) {
          expiringSoon++;
        } else {
          valid++;
        }
      }

      return NotificationCounts(
        all: buses.length,
        valid: valid,
        expiringSoon: expiringSoon,
        expired: expired,
      );
    },
    orElse: () => NotificationCounts.zero,
  );
});

final busNotificationsProvider =
    Provider.autoDispose<AsyncValue<List<BusNotificationItem>>>((ref) {
  final busesAsync = ref.watch(busProvider);
  final selectedFilter = ref.watch(selectedNotificationFilterProvider);

  return busesAsync.whenData((buses) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final in30 = today.add(const Duration(days: 30));

    final items = <BusNotificationItem>[];

    for (final bus in buses) {
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

      if (selectedFilter == BusNotificationFilter.all ||
          selectedFilter == status) {
        items.add(
          BusNotificationItem(
            bus: bus,
            status: status,
            daysLeft: daysLeft,
          ),
        );
      }
    }

    // Sort: Expired & expiring soon first by closest expiry date, then valid
    items.sort((a, b) {
      // Prioritize expired and expiring soon over valid
      if (a.status == BusNotificationFilter.expired && b.status != BusNotificationFilter.expired) {
        return -1;
      }
      if (b.status == BusNotificationFilter.expired && a.status != BusNotificationFilter.expired) {
        return 1;
      }
      if (a.status == BusNotificationFilter.expiringSoon && b.status == BusNotificationFilter.valid) {
        return -1;
      }
      if (b.status == BusNotificationFilter.expiringSoon && a.status == BusNotificationFilter.valid) {
        return 1;
      }
      return a.bus.licenseExpiryDate.compareTo(b.bus.licenseExpiryDate);
    });

    return items;
  });
});
