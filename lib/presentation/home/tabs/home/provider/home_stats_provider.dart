import 'package:elostaz_travel/domain/bus/entity/bus_entity.dart';
import 'package:elostaz_travel/domain/trip/entity/trip_entity.dart';
import 'package:elostaz_travel/presentation/home/tabs/bus/provider/bus_provider.dart';
import 'package:elostaz_travel/presentation/home/tabs/driver/provider/driver_provider.dart';
import 'package:elostaz_travel/presentation/home/tabs/trip/provider/trip_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ---------------------------------------------------------------------------
// Data class returned by the home stats provider
// ---------------------------------------------------------------------------

class HomeStats {
  final int totalBuses;
  final int totalDrivers;
  final int currentMonthTripCount;
  final double currentMonthRevenue;
  final double currentMonthExpenses;
  final double currentMonthNetRevenue;

  /// Buses whose license expires within the next 30 days (but not yet expired).
  final List<BusEntity> busesExpiringWithin30Days;

  /// Buses whose license has already expired.
  final List<BusEntity> expiredBuses;

  /// Buses with a valid license (> 30 days remaining).
  final int validLicenseCount;

  const HomeStats({
    required this.totalBuses,
    required this.totalDrivers,
    required this.currentMonthTripCount,
    required this.currentMonthRevenue,
    required this.currentMonthExpenses,
    required this.currentMonthNetRevenue,
    required this.busesExpiringWithin30Days,
    required this.expiredBuses,
    required this.validLicenseCount,
  });

  static const empty = HomeStats(
    totalBuses: 0,
    totalDrivers: 0,
    currentMonthTripCount: 0,
    currentMonthRevenue: 0,
    currentMonthExpenses: 0,
    currentMonthNetRevenue: 0,
    busesExpiringWithin30Days: [],
    expiredBuses: [],
    validLicenseCount: 0,
  );
}

// ---------------------------------------------------------------------------
// Computed provider
// ---------------------------------------------------------------------------

final homeStatsProvider = FutureProvider<HomeStats>((ref) async {
  final now = DateTime.now();

  // Watch all three upstream providers (re-computes when any changes)
  final busesAsync = await ref.watch(busProvider.future);
  final driversAsync = await ref.watch(driversProvider.future);
  final tripsAsync = await ref.watch(
    monthlyTripsProvider((year: now.year, month: now.month)).future,
  );

  final buses = busesAsync;
  final drivers = driversAsync;
  final trips = tripsAsync;

  // ---- license categorisation ----
  final today = DateTime(now.year, now.month, now.day);
  final in30 = today.add(const Duration(days: 30));

  final expired = <BusEntity>[];
  final expiringSoon = <BusEntity>[];
  var validCount = 0;

  for (final bus in buses) {
    final expiry = DateTime(
      bus.licenseExpiryDate.year,
      bus.licenseExpiryDate.month,
      bus.licenseExpiryDate.day,
    );
    if (expiry.isBefore(today) || expiry.isAtSameMomentAs(today)) {
      expired.add(bus);
    } else if (expiry.isBefore(in30) || expiry.isAtSameMomentAs(in30)) {
      expiringSoon.add(bus);
    } else {
      validCount++;
    }
  }

  // Sort expiring-soon by closest expiry first
  expiringSoon.sort(
    (a, b) => a.licenseExpiryDate.compareTo(b.licenseExpiryDate),
  );

  // ---- trip stats ----
  double revenue = 0;
  double expenses = 0;
  for (final TripEntity trip in trips) {
    revenue += trip.revenue;
    expenses += trip.expenses;
  }

  return HomeStats(
    totalBuses: buses.length,
    totalDrivers: drivers.length,
    currentMonthTripCount: trips.length,
    currentMonthRevenue: revenue,
    currentMonthExpenses: expenses,
    currentMonthNetRevenue: revenue - expenses,
    busesExpiringWithin30Days: expiringSoon,
    expiredBuses: expired,
    validLicenseCount: validCount,
  );
});
