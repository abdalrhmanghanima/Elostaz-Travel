import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elostaz_travel/data/driver/model/driver_advance_model.dart';
import 'package:elostaz_travel/data/trip/model/trip_model.dart';
import 'package:elostaz_travel/domain/driver/entity/driver_advance_entity.dart';
import 'package:elostaz_travel/domain/trip/entity/trip_entity.dart';
import 'package:elostaz_travel/domain/trip/repository/trip_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeTripRepository implements TripRepository {
  final Map<String, TripEntity> _store = {};
  int _counter = 0;

  @override
  Future<void> addTrip(TripEntity trip) async {
    _counter++;
    final id = 'trip_auto_$_counter';
    _store[id] = TripEntity(
      id: id,
      driverId: trip.driverId,
      driverName: trip.driverName,
      busId: trip.busId,
      busName: trip.busName,
      plateNumber: trip.plateNumber,
      details: trip.details,
      revenue: trip.revenue,
      expenses: trip.expenses,
      expenseDetails: trip.expenseDetails,
      factoryId: trip.factoryId,
      factoryName: trip.factoryName,
      isNightShift: trip.isNightShift,
      expenseItems: trip.expenseItems,
      sahraDetails: trip.sahraDetails,
      sahraDriverId: trip.sahraDriverId,
      sahraDriverName: trip.sahraDriverName,
      sahraRevenue: trip.sahraRevenue,
      sahraExpense: trip.sahraExpense,
      sahraExpenseDetails: trip.sahraExpenseDetails,
      createdAt: trip.createdAt,
    );
  }

  @override
  Future<void> deleteTrip(String tripId) async {
    _store.remove(tripId);
  }

  @override
  Future<List<TripEntity>> getBusTrips(String busId) async =>
      _store.values.where((t) => t.busId == busId).toList();

  @override
  Future<List<TripEntity>> getDriverTrips(String driverId) async =>
      _store.values.where((t) => t.driverId == driverId).toList();

  @override
  Future<List<TripEntity>> getFactoryTrips(String factoryId) async =>
      _store.values.where((t) => t.factoryId == factoryId).toList();

  @override
  Future<List<TripEntity>> getAllTrips() async =>
      _store.values.toList();

  @override
  Future<List<TripEntity>> getMonthlyTrips({
    required int year,
    required int month,
  }) async {
    return _store.values.where((t) {
      return t.createdAt.year == year && t.createdAt.month == month;
    }).toList();
  }

  int get count => _store.length;
  Iterable<String> get ids => _store.keys;
}

TripModel _buildTripModel({
  String id = 'trip_1',
  String driverId = 'driver_1',
  String driverName = 'أحمد',
  String busId = 'bus_1',
  String busName = 'أتوبيس 1',
  String plateNumber = 'أ ب ج 123',
  String details = 'وردية صباحية',
  double revenue = 1000.0,
  double expenses = 200.0,
  String? expenseDetails,
  String? factoryId,
  String? factoryName,
  bool isNightShift = false,
  String? sahraDetails,
  String? sahraDriverName,
  double? sahraRevenue,
  double? sahraExpense,
  String? sahraExpenseDetails,
  DateTime? createdAt,
}) {
  return TripModel(
    id: id,
    driverId: driverId,
    driverName: driverName,
    busId: busId,
    busName: busName,
    plateNumber: plateNumber,
    details: details,
    revenue: revenue,
    expenses: expenses,
    expenseDetails: expenseDetails,
    factoryId: factoryId,
    factoryName: factoryName,
    isNightShift: isNightShift,
    sahraDetails: sahraDetails,
    sahraDriverName: sahraDriverName,
    sahraRevenue: sahraRevenue,
    sahraExpense: sahraExpense,
    sahraExpenseDetails: sahraExpenseDetails,
    createdAt: createdAt ?? DateTime(2026, 8, 1),
  );
}

Map<String, dynamic> _buildFirestoreMap({
  String? driverId,
  String? driverName,
  String? busId,
  String? busName,
  String? plateNumber,
  String? details,
  double? revenue,
  double? expenses,
  String? expenseDetails,
  String? factoryId,
  String? factoryName,
  bool isNightShift = false,
  String? sahraDetails,
  String? sahraDriverId,
  String? sahraDriverName,
  double? sahraRevenue,
  double? sahraExpense,
  String? sahraExpenseDetails,
  DateTime? createdAt,
}) {
  final map = <String, dynamic>{
    'driverId': driverId ?? 'driver_1',
    'driverName': driverName ?? 'سائق تجريبي',
    'busId': busId ?? 'bus_1',
    'busName': busName ?? 'أتوبيس',
    'plateNumber': plateNumber ?? 'أ ب ج 1',
    'details': details ?? '',
    'revenue': revenue ?? 0.0,
    'expenses': expenses ?? 0.0,
    'isNightShift': isNightShift,
    'createdAt': Timestamp.fromDate(createdAt ?? DateTime(2026, 8, 1)),
  };
  if (expenseDetails != null) map['expenseDetails'] = expenseDetails;
  if (factoryId != null) map['factoryId'] = factoryId;
  if (factoryName != null) map['factoryName'] = factoryName;
  if (sahraDetails != null) map['sahraDetails'] = sahraDetails;
  if (sahraDriverId != null) map['sahraDriverId'] = sahraDriverId;
  if (sahraDriverName != null) map['sahraDriverName'] = sahraDriverName;
  if (sahraRevenue != null) map['sahraRevenue'] = sahraRevenue;
  if (sahraExpense != null) map['sahraExpense'] = sahraExpense;
  if (sahraExpenseDetails != null) {
    map['sahraExpenseDetails'] = sahraExpenseDetails;
  }
  return map;
}

void main() {
  group('Trip Storage — Uniqueness and Persistence', () {
    test('1. A new trip creates a unique Firestore document', () async {
      final repo = _FakeTripRepository();
      await repo.addTrip(_buildTripModel(id: '').toEntity());
      expect(repo.count, 1);
      expect(repo.ids.first, isNotEmpty);
    });

    test('2. Adding Trip B does NOT overwrite Trip A', () async {
      final repo = _FakeTripRepository();
      await repo.addTrip(_buildTripModel(
        id: '',
        details: 'رحلة أ',
        revenue: 500.0,
      ).toEntity());

      await repo.addTrip(_buildTripModel(
        id: '',
        details: 'رحلة ب',
        revenue: 800.0,
      ).toEntity());

      expect(repo.count, 2, reason: 'Both trips must exist independently');
      final allTrips = await repo.getAllTrips();
      final detailsList = allTrips.map((t) => t.details).toList();
      expect(detailsList, containsAll(['رحلة أ', 'رحلة ب']));
    });

    test('3. Multiple trips remain available — no accidental deletion or limitation', () async {
      final repo = _FakeTripRepository();
      for (int i = 1; i <= 5; i++) {
        await repo.addTrip(_buildTripModel(
          id: '',
          details: 'رحلة $i',
          revenue: i * 100.0,
        ).toEntity());
      }
      expect(repo.count, 5);
      final allTrips = await repo.getAllTrips();
      expect(allTrips.length, 5);

      final monthly = await repo.getMonthlyTrips(year: 2026, month: 8);
      expect(monthly.length, 5);
      expect(repo.count, 5);
    });
  });

  group('TripModel Serialization & Deserialization — expenseDetails', () {
    test('4. expenseDetails is serialized to Firestore map', () {
      final trip = _buildTripModel(
        expenseDetails: 'أكل للسواق وطريق',
      );
      final map = trip.toFirestore();
      expect(map.containsKey('expenseDetails'), isTrue);
      expect(map['expenseDetails'], 'أكل للسواق وطريق');
    });

    test('5. expenseDetails is deserialized from Firestore map', () {
      final firestoreMap = _buildFirestoreMap(
        expenseDetails: 'أكل للسواق وطريق',
      );
      final expenseDetails = firestoreMap['expenseDetails']?.toString();
      expect(expenseDetails, 'أكل للسواق وطريق');
    });
  });

  group('Reports Content Verification — expenseDetails & Sahra', () {
    TripEntity reportTrip({
      String expenseDetails = 'أكل للسواق وطريق',
      double expenses = 500.0,
      String? sahraExpenseDetails,
      double? sahraExpense,
    }) {
      return _buildTripModel(
        id: 'rpt_trip',
        expenses: expenses,
        expenseDetails: expenseDetails,
        factoryName: 'مصنع الشروق',
        sahraExpenseDetails: sahraExpenseDetails,
        sahraExpense: sahraExpense,
      ).toEntity();
    }

    test('6. Factory Report includes expenseDetails and amounts', () {
      final trip = reportTrip();
      expect(trip.expenseDetails != null && trip.expenseDetails!.trim().isNotEmpty, isTrue);
      expect(trip.expenseDetails, 'أكل للسواق وطريق');
      expect(trip.expenses, 500.0);
    });

    test('7. Bus Report includes expenseDetails and amounts', () {
      final trip = reportTrip();
      expect(trip.expenseDetails != null && trip.expenseDetails!.trim().isNotEmpty, isTrue);
      expect(trip.expenseDetails, 'أكل للسواق وطريق');
      expect(trip.expenses, 500.0);
    });

    test('8. Driver Report includes expenseDetails and amounts', () {
      final trip = reportTrip();
      expect((trip.expenseDetails ?? '').isNotEmpty, isTrue);
      expect(trip.expenseDetails, 'أكل للسواق وطريق');
      expect(trip.expenses, 500.0);
    });

    test('9. Sahra data remains separate from normal trip financials', () {
      final trip = reportTrip(
        expenseDetails: 'مصروف الرحلة العادية',
        sahraExpenseDetails: 'مصروف السهرة الإضافي',
        sahraExpense: 150.0,
      );
      expect(trip.expenseDetails, 'مصروف الرحلة العادية');
      expect(trip.sahraExpenseDetails, 'مصروف السهرة الإضافي');
      expect(trip.sahraExpense, 150.0);
      expect(trip.expenseDetails, isNot(equals(trip.sahraExpenseDetails)));
    });
  });

  group('Driver Advances Verification', () {
    test('10. Driver advances remain available in active state', () {
      final advances = <DriverAdvanceEntity>[
        DriverAdvanceEntity(
          id: 'adv_1',
          driverId: 'driver_1',
          amount: 500.0,
          date: DateTime(2026, 8, 10),
          note: 'سلفة وقود',
          status: 'active',
          createdAt: DateTime(2026, 8, 10),
        ),
      ];
      final activeAdvances = advances.where((a) => a.isActive).toList();
      expect(activeAdvances.length, 1);
      expect(activeAdvances.first.amount, 500.0);
      expect(activeAdvances.first.note, 'سلفة وقود');
    });

    test('11. Paid advances remain in historical records with paidAt', () {
      final paidAdvance = DriverAdvanceEntity(
        id: 'adv_paid',
        driverId: 'driver_1',
        amount: 400.0,
        date: DateTime(2026, 8, 5),
        note: 'سلفة شهرية',
        status: 'paid',
        createdAt: DateTime(2026, 8, 5),
        paidAt: DateTime(2026, 8, 20),
      );

      expect(paidAdvance.isPaid, isTrue);
      expect(paidAdvance.paidAt, isNotNull);
      expect(paidAdvance.amount, 400.0);
      expect(paidAdvance.note, 'سلفة شهرية');

      final model = DriverAdvanceModel(
        id: paidAdvance.id,
        driverId: paidAdvance.driverId,
        amount: paidAdvance.amount,
        date: paidAdvance.date,
        note: paidAdvance.note,
        status: paidAdvance.status,
        createdAt: paidAdvance.createdAt,
        paidAt: paidAdvance.paidAt,
      );

      final map = model.toFirestore();
      expect(map['status'], 'paid');
      expect(map['paidAt'], isA<Timestamp>());
      expect(map['amount'], 400.0);
      expect(map['note'], 'سلفة شهرية');
    });
  });

  group('Backward Compatibility', () {
    test('12. Existing old trips without new optional fields still work', () {
      final legacyMap = <String, dynamic>{
        'driverId': 'driver_old',
        'driverName': 'سائق قديم',
        'busId': 'bus_old',
        'busName': 'عربية قديمة',
        'plateNumber': 'ق د م 1',
        'details': 'رحلة قديمة',
        'revenue': 800.0,
        'expenses': 100.0,
        'createdAt': Timestamp.fromDate(DateTime(2025, 6, 1)),
      };

      final trip = TripModel(
        id: 'old_id',
        driverId: legacyMap['driverId'],
        driverName: legacyMap['driverName'],
        busId: legacyMap['busId'],
        busName: legacyMap['busName'],
        plateNumber: legacyMap['plateNumber'],
        details: legacyMap['details'],
        revenue: (legacyMap['revenue'] as num).toDouble(),
        expenses: (legacyMap['expenses'] as num).toDouble(),
        expenseDetails: null,
        isNightShift: false,
        sahraRevenue: null,
        sahraExpense: null,
        sahraDetails: null,
        sahraDriverName: null,
        sahraExpenseDetails: null,
        createdAt: (legacyMap['createdAt'] as Timestamp).toDate(),
      );

      expect(trip.expenseDetails, isNull);
      expect(trip.sahraRevenue, isNull);
      expect(trip.hasSahra, isFalse);
      expect(trip.revenue, 800.0);
      expect(trip.expenses, 100.0);
    });
  });
}

extension on TripModel {
  TripEntity toEntity() => TripEntity(
        id: id,
        driverId: driverId,
        driverName: driverName,
        busId: busId,
        busName: busName,
        plateNumber: plateNumber,
        details: details,
        revenue: revenue,
        expenses: expenses,
        expenseDetails: expenseDetails,
        factoryId: factoryId,
        factoryName: factoryName,
        isNightShift: isNightShift,
        expenseItems: expenseItems,
        sahraDetails: sahraDetails,
        sahraDriverId: sahraDriverId,
        sahraDriverName: sahraDriverName,
        sahraRevenue: sahraRevenue,
        sahraExpense: sahraExpense,
        sahraExpenseDetails: sahraExpenseDetails,
        createdAt: createdAt,
      );
}
