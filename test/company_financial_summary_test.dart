import 'package:elostaz_travel/domain/trip/entity/trip_entity.dart';
import 'package:flutter_test/flutter_test.dart';

// ------------------------------------------------------------------------------
// Pure-logic helpers extracted from company_financial_summary_provider.dart
// ------------------------------------------------------------------------------

class _BusGroup {
  final String busId;
  final String busName;
  final String plateNumber;
  final List<TripEntity> trips;
  final double busRevenue;
  final double busExpenses;
  final double busNet;

  _BusGroup({
    required this.busId,
    required this.busName,
    required this.plateNumber,
    required this.trips,
    required this.busRevenue,
    required this.busExpenses,
    required this.busNet,
  });
}

class _CompanySummary {
  final int totalTrips;
  final double totalRevenue;
  final double totalExpenses;
  final double totalNetRevenue;
  final List<_BusGroup> busGroups;

  _CompanySummary({
    required this.totalTrips,
    required this.totalRevenue,
    required this.totalExpenses,
    required this.totalNetRevenue,
    required this.busGroups,
  });
}

_CompanySummary _buildSummary(List<TripEntity> trips) {
  final Map<String, List<TripEntity>> tripsByBus = {};
  for (final trip in trips) {
    final key = trip.busId.isNotEmpty ? trip.busId : trip.busName;
    tripsByBus.putIfAbsent(key, () => []).add(trip);
  }

  final List<_BusGroup> busGroups = [];
  double companyRevenue = 0;
  double companyExpenses = 0;

  for (final entry in tripsByBus.entries) {
    final busTrips = List<TripEntity>.from(entry.value);
    busTrips.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final firstTrip = busTrips.first;
    final busName = firstTrip.busName.isNotEmpty ? firstTrip.busName : 'unknown';
    final plateNumber = firstTrip.plateNumber.isNotEmpty ? firstTrip.plateNumber : '-';

    double groupRev = 0;
    double groupExp = 0;
    for (final t in busTrips) {
      groupRev += t.revenue;
      groupExp += t.expenses;
    }

    companyRevenue += groupRev;
    companyExpenses += groupExp;

    busGroups.add(_BusGroup(
      busId: entry.key,
      busName: busName,
      plateNumber: plateNumber,
      trips: busTrips,
      busRevenue: groupRev,
      busExpenses: groupExp,
      busNet: groupRev - groupExp,
    ));
  }

  busGroups.sort((a, b) => b.busRevenue.compareTo(a.busRevenue));

  return _CompanySummary(
    totalTrips: trips.length,
    totalRevenue: companyRevenue,
    totalExpenses: companyExpenses,
    totalNetRevenue: companyRevenue - companyExpenses,
    busGroups: busGroups,
  );
}

List<TripEntity> _filterByMonth(List<TripEntity> all, int year, int month) {
  return all.where((t) => t.createdAt.year == year && t.createdAt.month == month).toList();
}

TripEntity _trip({
  required String id,
  required String busId,
  required String busName,
  required String plateNumber,
  required String driverId,
  required String driverName,
  required double revenue,
  required double expenses,
  required DateTime createdAt,
}) =>
    TripEntity(
      id: id,
      busId: busId,
      busName: busName,
      plateNumber: plateNumber,
      driverId: driverId,
      driverName: driverName,
      revenue: revenue,
      expenses: expenses,
      createdAt: createdAt,
      details: '',
    );

// ------------------------------------------------------------------------------
// Test data
// ------------------------------------------------------------------------------

final _now = DateTime.now();
final _curYear = _now.year;
final _curMonth = _now.month;
final _prevMonthValue = _curMonth == 1 ? 12 : _curMonth - 1;
final _prevYearValue = _curMonth == 1 ? _curYear - 1 : _curYear;

final List<TripEntity> _allTrips = [
  // Current-month trips
  _trip(id: 't1', busId: 'bus1', busName: '???????? ?????', plateNumber: '? ? ? 100', driverId: 'd1', driverName: '???', revenue: 5000, expenses: 800, createdAt: DateTime(_curYear, _curMonth, 2)),
  _trip(id: 't2', busId: 'bus1', busName: '???????? ?????', plateNumber: '? ? ? 100', driverId: 'd1', driverName: '???', revenue: 4500, expenses: 1200, createdAt: DateTime(_curYear, _curMonth, 8)),
  _trip(id: 't3', busId: 'bus2', busName: '???????? ??????', plateNumber: '? ? ? 200', driverId: 'd2', driverName: '???', revenue: 3800, expenses: 950, createdAt: DateTime(_curYear, _curMonth, 5)),
  _trip(id: 't4', busId: 'bus2', busName: '???????? ??????', plateNumber: '? ? ? 200', driverId: 'd2', driverName: '???', revenue: 4200, expenses: 750, createdAt: DateTime(_curYear, _curMonth, 12)),
  _trip(id: 't5', busId: 'bus3', busName: '???????? ??????', plateNumber: '? ? ? 300', driverId: 'd3', driverName: '???', revenue: 5500, expenses: 1100, createdAt: DateTime(_curYear, _curMonth, 7)),
  _trip(id: 't6', busId: 'bus4', busName: '???????? ??????', plateNumber: '? ? ? 400', driverId: 'd4', driverName: '????', revenue: 3700, expenses: 600, createdAt: DateTime(_curYear, _curMonth, 10)),
  _trip(id: 't7', busId: 'bus4', busName: '???????? ??????', plateNumber: '? ? ? 400', driverId: 'd4', driverName: '????', revenue: 3000, expenses: 1500, createdAt: DateTime(_curYear, _curMonth, 15)),
  // Previous-month trips
  _trip(id: 't8', busId: 'bus1', busName: '???????? ?????', plateNumber: '? ? ? 100', driverId: 'd1', driverName: '???', revenue: 6000, expenses: 1200, createdAt: DateTime(_prevYearValue, _prevMonthValue, 5)),
  _trip(id: 't9', busId: 'bus2', busName: '???????? ??????', plateNumber: '? ? ? 200', driverId: 'd2', driverName: '???', revenue: 4500, expenses: 900, createdAt: DateTime(_prevYearValue, _prevMonthValue, 5)),
  _trip(id: 't10', busId: 'bus3', busName: '???????? ??????', plateNumber: '? ? ? 300', driverId: 'd3', driverName: '???', revenue: 5200, expenses: 800, createdAt: DateTime(_prevYearValue, _prevMonthValue, 5)),
];

void main() {
  group('Trip Net Calculation', () {
    test('trip net positive', () {
      final t = _allTrips[0];
      expect(t.revenue - t.expenses, equals(4200.0));
    });

    test('trip net negative (loss)', () {
      final t = _trip(id: 'loss', busId: 'b', busName: 'bus', plateNumber: 'p', driverId: 'd', driverName: 'n', revenue: 1000, expenses: 1500, createdAt: DateTime.now());
      expect(t.revenue - t.expenses, equals(-500.0));
    });

    test('trip net zero', () {
      final t = _trip(id: 'zero', busId: 'b', busName: 'bus', plateNumber: 'p', driverId: 'd', driverName: 'n', revenue: 2000, expenses: 2000, createdAt: DateTime.now());
      expect(t.revenue - t.expenses, equals(0.0));
    });
  });

  group('Current Month Filter', () {
    late List<TripEntity> trips;
    setUp(() => trips = _filterByMonth(_allTrips, _curYear, _curMonth));

    test('returns 7 trips', () => expect(trips.length, equals(7)));
    test('all trips in current month', () {
      for (final t in trips) {
        expect(t.createdAt.month, equals(_curMonth));
        expect(t.createdAt.year, equals(_curYear));
      }
    });
    test('prev-month trips excluded', () {
      final ids = trips.map((t) => t.id).toSet();
      expect(ids.contains('t8'), isFalse);
      expect(ids.contains('t9'), isFalse);
      expect(ids.contains('t10'), isFalse);
    });
  });

  group('Previous Month Filter', () {
    late List<TripEntity> trips;
    setUp(() => trips = _filterByMonth(_allTrips, _prevYearValue, _prevMonthValue));

    test('returns 3 trips', () => expect(trips.length, equals(3)));
    test('all trips in previous month', () {
      for (final t in trips) {
        expect(t.createdAt.month, equals(_prevMonthValue));
      }
    });
    test('current-month trips excluded', () {
      final ids = trips.map((t) => t.id).toSet();
      expect(ids.contains('t1'), isFalse);
    });
  });

  group('All Trips Filter', () {
    test('includes all 10 trips', () => expect(_allTrips.length, equals(10)));
  });

  group('Company Totals (current month)', () {
    late _CompanySummary summary;
    setUp(() {
      final trips = _filterByMonth(_allTrips, _curYear, _curMonth);
      summary = _buildSummary(trips);
    });

    test('total trips = 7', () => expect(summary.totalTrips, equals(7)));
    test('total revenue = 29700', () => expect(summary.totalRevenue, equals(29700.0)));
    test('total expenses = 6900', () => expect(summary.totalExpenses, equals(6900.0)));
    test('total net = 22800', () => expect(summary.totalNetRevenue, equals(22800.0)));
    test('net = revenue - expenses', () => expect(summary.totalNetRevenue, equals(summary.totalRevenue - summary.totalExpenses)));
  });

  group('Bus Grouping', () {
    late _CompanySummary summary;
    setUp(() {
      final trips = _filterByMonth(_allTrips, _curYear, _curMonth);
      summary = _buildSummary(trips);
    });

    test('4 bus groups', () => expect(summary.busGroups.length, equals(4)));
    test('groups sorted descending by revenue', () {
      final revs = summary.busGroups.map((g) => g.busRevenue).toList();
      for (int i = 0; i < revs.length - 1; i++) {
        expect(revs[i] >= revs[i + 1], isTrue);
      }
    });
    test('all 4 bus names present', () {
      final names = summary.busGroups.map((g) => g.busName).toSet();
      expect(names.contains('???????? ?????'), isTrue);
      expect(names.contains('???????? ??????'), isTrue);
      expect(names.contains('???????? ??????'), isTrue);
      expect(names.contains('???????? ??????'), isTrue);
    });
  });

  group('Bus Subtotals', () {
    late _CompanySummary summary;
    setUp(() {
      final trips = _filterByMonth(_allTrips, _curYear, _curMonth);
      summary = _buildSummary(trips);
    });

    test('bus1: revenue=9500, expenses=2000, net=7500', () {
      final g = summary.busGroups.firstWhere((g) => g.busId == 'bus1');
      expect(g.busRevenue, equals(9500.0));
      expect(g.busExpenses, equals(2000.0));
      expect(g.busNet, equals(7500.0));
    });

    test('bus2: revenue=8000, expenses=1700, net=6300', () {
      final g = summary.busGroups.firstWhere((g) => g.busId == 'bus2');
      expect(g.busRevenue, equals(8000.0));
      expect(g.busExpenses, equals(1700.0));
      expect(g.busNet, equals(6300.0));
    });

    test('bus3: revenue=5500, expenses=1100, net=4400', () {
      final g = summary.busGroups.firstWhere((g) => g.busId == 'bus3');
      expect(g.busRevenue, equals(5500.0));
      expect(g.busExpenses, equals(1100.0));
      expect(g.busNet, equals(4400.0));
    });

    test('bus4: revenue=6700, expenses=2100, net=4600', () {
      final g = summary.busGroups.firstWhere((g) => g.busId == 'bus4');
      expect(g.busRevenue, equals(6700.0));
      expect(g.busExpenses, equals(2100.0));
      expect(g.busNet, equals(4600.0));
    });

    test('bus subtotals sum to company totals', () {
      final sumRev = summary.busGroups.fold(0.0, (s, g) => s + g.busRevenue);
      final sumExp = summary.busGroups.fold(0.0, (s, g) => s + g.busExpenses);
      final sumNet = summary.busGroups.fold(0.0, (s, g) => s + g.busNet);
      expect(sumRev, equals(summary.totalRevenue));
      expect(sumExp, equals(summary.totalExpenses));
      expect(sumNet, closeTo(summary.totalNetRevenue, 0.001));
    });

    test('each bus net = revenue - expenses', () {
      for (final g in summary.busGroups) {
        expect(g.busNet, closeTo(g.busRevenue - g.busExpenses, 0.001));
      }
    });
  });

  group('Empty Period', () {
    test('no trips for future month returns all zeros', () {
      final trips = _filterByMonth(_allTrips, 2099, 1);
      final summary = _buildSummary(trips);
      expect(summary.totalTrips, equals(0));
      expect(summary.totalRevenue, equals(0.0));
      expect(summary.totalExpenses, equals(0.0));
      expect(summary.totalNetRevenue, equals(0.0));
      expect(summary.busGroups, isEmpty);
    });
  });
}
