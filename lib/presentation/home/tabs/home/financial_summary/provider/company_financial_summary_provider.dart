import 'package:elostaz_travel/domain/trip/entity/trip_entity.dart';
import 'package:elostaz_travel/presentation/home/tabs/trip/provider/trip_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum FinancialPeriod {
  currentMonth(title: 'هذا الشهر'),
  previousMonth(title: 'الشهر السابق'),
  all(title: 'الكل');

  final String title;
  const FinancialPeriod({required this.title});
}

class BusFinancialGroup {
  final String busId;
  final String busName;
  final String plateNumber;
  final List<TripEntity> trips;
  final double busRevenue;
  final double busExpenses;
  final double busNet;

  const BusFinancialGroup({
    required this.busId,
    required this.busName,
    required this.plateNumber,
    required this.trips,
    required this.busRevenue,
    required this.busExpenses,
    required this.busNet,
  });
}

class CompanyFinancialSummary {
  final FinancialPeriod period;
  final String periodLabel;
  final int totalTrips;
  final double totalRevenue;
  final double totalExpenses;
  final double totalNetRevenue;
  final List<BusFinancialGroup> busGroups;
  final List<TripEntity> allTrips;

  const CompanyFinancialSummary({
    required this.period,
    required this.periodLabel,
    required this.totalTrips,
    required this.totalRevenue,
    required this.totalExpenses,
    required this.totalNetRevenue,
    required this.busGroups,
    required this.allTrips,
  });

  static const empty = CompanyFinancialSummary(
    period: FinancialPeriod.currentMonth,
    periodLabel: '',
    totalTrips: 0,
    totalRevenue: 0,
    totalExpenses: 0,
    totalNetRevenue: 0,
    busGroups: [],
    allTrips: [],
  );
}

final selectedFinancialPeriodProvider =
    StateProvider<FinancialPeriod>((ref) => FinancialPeriod.currentMonth);

final companyFinancialSummaryProvider =
    FutureProvider.autoDispose<CompanyFinancialSummary>((ref) async {
  final period = ref.watch(selectedFinancialPeriodProvider);
  final now = DateTime.now();

  final int currentYear = now.year;
  final int currentMonth = now.month;

  final int prevMonth = currentMonth == 1 ? 12 : currentMonth - 1;
  final int prevYear = currentMonth == 1 ? currentYear - 1 : currentYear;

  final List<TripEntity> trips;
  final String periodLabel;

  switch (period) {
    case FinancialPeriod.currentMonth:
      periodLabel = 'شهر ${_arabicMonthName(currentMonth)} $currentYear';
      trips = await ref.watch(
        monthlyTripsProvider((year: currentYear, month: currentMonth)).future,
      );
      break;
    case FinancialPeriod.previousMonth:
      periodLabel = 'شهر ${_arabicMonthName(prevMonth)} $prevYear';
      trips = await ref.watch(
        monthlyTripsProvider((year: prevYear, month: prevMonth)).future,
      );
      break;
    case FinancialPeriod.all:
      periodLabel = 'جميع الفترات';
      trips = await ref.watch(allTripsProvider.future);
      break;
  }

  // 1. Group trips by bus
  final Map<String, List<TripEntity>> tripsByBus = {};
  for (final trip in trips) {
    final key = trip.busId.isNotEmpty ? trip.busId : trip.busName;
    tripsByBus.putIfAbsent(key, () => []).add(trip);
  }

  final List<BusFinancialGroup> busGroups = [];
  double companyRevenue = 0;
  double companyExpenses = 0;

  for (final entry in tripsByBus.entries) {
    final busTrips = entry.value;
    // Sort bus trips by createdAt descending
    busTrips.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final firstTrip = busTrips.first;
    final busName = firstTrip.busName.isNotEmpty ? firstTrip.busName : 'أتوبيس غير مسمى';
    final plateNumber = firstTrip.plateNumber.isNotEmpty ? firstTrip.plateNumber : '-';

    double groupRev = 0;
    double groupExp = 0;

    for (final t in busTrips) {
      groupRev += t.revenue;
      groupExp += t.expenses;
    }

    companyRevenue += groupRev;
    companyExpenses += groupExp;

    busGroups.add(
      BusFinancialGroup(
        busId: entry.key,
        busName: busName,
        plateNumber: plateNumber,
        trips: busTrips,
        busRevenue: groupRev,
        busExpenses: groupExp,
        busNet: groupRev - groupExp,
      ),
    );
  }

  // Sort bus groups alphabetically or by revenue descending
  busGroups.sort((a, b) => b.busRevenue.compareTo(a.busRevenue));

  return CompanyFinancialSummary(
    period: period,
    periodLabel: periodLabel,
    totalTrips: trips.length,
    totalRevenue: companyRevenue,
    totalExpenses: companyExpenses,
    totalNetRevenue: companyRevenue - companyExpenses,
    busGroups: busGroups,
    allTrips: trips,
  );
});

String _arabicMonthName(int month) {
  const months = [
    'يناير',
    'فبراير',
    'مارس',
    'أبريل',
    'مايو',
    'يونيو',
    'يوليو',
    'أغسطس',
    'سبتمبر',
    'أكتوبر',
    'نوفمبر',
    'ديسمبر',
  ];
  if (month < 1 || month > 12) return '';
  return months[month - 1];
}
