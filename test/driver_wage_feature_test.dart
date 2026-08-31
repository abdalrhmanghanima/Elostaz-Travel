import 'package:elostaz_travel/domain/driver/entity/driver_wage_balance.dart';
import 'package:elostaz_travel/domain/driver/entity/driver_wage_entry_entity.dart';
import 'package:elostaz_travel/domain/driver/entity/driver_wage_payment_entity.dart';
import 'package:elostaz_travel/domain/trip/entity/trip_entity.dart';
import 'package:flutter_test/flutter_test.dart';

TripEntity _makeTrip({
  String id = 't1',
  String driverId = 'd1',
  double revenue = 5000.0,
  double expenses = 500.0,
  double? driverWage,
  DateTime? createdAt,
}) {
  return TripEntity(
    id: id,
    driverId: driverId,
    driverName: 'سائق 1',
    busId: 'b1',
    busName: 'أتوبيس 1',
    plateNumber: 'أ ب ج 123',
    details: 'رحلة تجريبية',
    revenue: revenue,
    expenses: expenses,
    driverWage: driverWage,
    createdAt: createdAt ?? DateTime(2026, 8, 29),
  );
}

void main() {
  group('1. Trip Driver Wage & Net Revenue Invariance', () {
    test('Trip net is always Revenue - Expenses, unaffected by driverWage', () {
      final tripWithWage = _makeTrip(
        revenue: 5000.0,
        expenses: 500.0,
        driverWage: 300.0,
      );

      final tripWithoutWage = _makeTrip(
        revenue: 5000.0,
        expenses: 500.0,
        driverWage: null,
      );

      final netWithWage = tripWithWage.revenue - tripWithWage.expenses;
      final netWithoutWage = tripWithoutWage.revenue - tripWithoutWage.expenses;

      expect(netWithWage, 4500.0);
      expect(netWithoutWage, 4500.0);
      expect(tripWithWage.driverWage, 300.0);
      expect(tripWithoutWage.driverWage, isNull);
    });
  });

  group('2. Driver Wage Balance & Accrual Computation', () {
    test('Computes total accrued from trips + manual entries, and subtracts payments', () {
      final trips = [
        _makeTrip(id: 't1', driverWage: 300.0),
        _makeTrip(id: 't2', driverWage: 250.0),
        _makeTrip(id: 't3', driverWage: 350.0),
        _makeTrip(id: 't4', driverWage: null), // null wage ignored
      ];

      final entries = [
        DriverWageEntryEntity(
          id: 'e1',
          driverId: 'd1',
          amount: 100.0,
          date: DateTime(2026, 8, 29),
          notes: 'أجر يوم إضافي',
          createdAt: DateTime(2026, 8, 29),
        ),
      ];

      final payments = [
        DriverWagePaymentEntity(
          id: 'p1',
          driverId: 'd1',
          amount: 600.0,
          date: DateTime(2026, 8, 29),
          notes: 'تسوية جزئية',
          createdAt: DateTime(2026, 8, 29),
        ),
      ];

      final balance = DriverWageBalance.compute(
        trips: trips,
        entries: entries,
        payments: payments,
      );

      expect(balance.accruedFromTrips, 900.0);
      expect(balance.accruedFromEntries, 100.0);
      expect(balance.totalAccrued, 1000.0);
      expect(balance.totalPaid, 600.0);
      expect(balance.remaining, 400.0);
    });

    test('Zero remaining balance when full payment is made', () {
      final trips = [
        _makeTrip(id: 't1', driverWage: 300.0),
        _makeTrip(id: 't2', driverWage: 250.0),
        _makeTrip(id: 't3', driverWage: 350.0),
      ];

      final payments = [
        DriverWagePaymentEntity(
          id: 'p1',
          driverId: 'd1',
          amount: 900.0,
          date: DateTime(2026, 8, 29),
          notes: 'تسوية كاملة',
          createdAt: DateTime(2026, 8, 29),
        ),
      ];

      final balance = DriverWageBalance.compute(
        trips: trips,
        entries: const [],
        payments: payments,
      );

      expect(balance.totalAccrued, 900.0);
      expect(balance.totalPaid, 900.0);
      expect(balance.remaining, 0.0);
    });
  });

  group('3. Payment Validation', () {
    test('Validates payment successfully when amount <= outstanding', () {
      final error = DriverWageBalance.validatePayment(
        amount: 300.0,
        outstanding: 500.0,
      );
      expect(error, isNull);
    });

    test('Validates full payment when amount == outstanding', () {
      final error = DriverWageBalance.validatePayment(
        amount: 500.0,
        outstanding: 500.0,
      );
      expect(error, isNull);
    });

    test('Rejects payment when amount > outstanding', () {
      final error = DriverWageBalance.validatePayment(
        amount: 600.0,
        outstanding: 500.0,
      );
      expect(error, isNotNull);
      expect(error, contains('أكبر من المتبقي'));
    });

    test('Rejects zero or negative payment', () {
      final errorZero = DriverWageBalance.validatePayment(
        amount: 0.0,
        outstanding: 500.0,
      );
      expect(errorZero, isNotNull);

      final errorNeg = DriverWageBalance.validatePayment(
        amount: -50.0,
        outstanding: 500.0,
      );
      expect(errorNeg, isNotNull);
    });

    test('Rejects payment when outstanding balance is 0', () {
      final error = DriverWageBalance.validatePayment(
        amount: 100.0,
        outstanding: 0.0,
      );
      expect(error, isNotNull);
      expect(error, contains('لا يوجد أجر مستحق'));
    });
  });

  group('4. Company Financial Result & Cash Accounting', () {
    test('Cash result only subtracts actual wage payments, NOT accrued wages', () {
      const revenue = 10000.0;
      const expenses = 2000.0;
      const accruedWages = 1000.0;
      const actualPayments = 600.0;

      // Accrual-only scenario (before payment)
      final resultBeforePayment = DriverWageBalance.companyCashResult(
        revenue: revenue,
        expenses: expenses,
        wagesPaid: 0.0,
      );
      expect(resultBeforePayment, 8000.0); // 10,000 - 2,000

      // After 600 EGP payment
      final resultAfterPayment = DriverWageBalance.companyCashResult(
        revenue: revenue,
        expenses: expenses,
        wagesPaid: actualPayments,
      );
      expect(resultAfterPayment, 7400.0); // 10,000 - 2,000 - 600

      // Verify that accrued wages (1000) are NOT deducted
      expect(resultAfterPayment, isNot(equals(revenue - expenses - accruedWages)));
    });
  });

  group('5. Trip Wage Edit and Delete Deltas', () {
    test('Create trip wage delta is positive', () {
      final deltas = DriverWageBalance.tripWageCounterDeltas(
        oldDriverId: '',
        newDriverId: 'd1',
        oldWage: null,
        newWage: 300.0,
        isCreate: true,
        isDelete: false,
      );
      expect(deltas['d1'], 300.0);
    });

    test('Edit trip wage (300 -> 500) produces +200 delta', () {
      final deltas = DriverWageBalance.tripWageCounterDeltas(
        oldDriverId: 'd1',
        newDriverId: 'd1',
        oldWage: 300.0,
        newWage: 500.0,
        isCreate: false,
        isDelete: false,
      );
      expect(deltas['d1'], 200.0);
    });

    test('Edit trip wage (500 -> 200) produces -300 delta', () {
      final deltas = DriverWageBalance.tripWageCounterDeltas(
        oldDriverId: 'd1',
        newDriverId: 'd1',
        oldWage: 500.0,
        newWage: 200.0,
        isCreate: false,
        isDelete: false,
      );
      expect(deltas['d1'], -300.0);
    });

    test('Edit trip wage (500 -> null) produces -500 delta', () {
      final deltas = DriverWageBalance.tripWageCounterDeltas(
        oldDriverId: 'd1',
        newDriverId: 'd1',
        oldWage: 500.0,
        newWage: null,
        isCreate: false,
        isDelete: false,
      );
      expect(deltas['d1'], -500.0);
    });

    test('Delete trip wage produces negative delta', () {
      final deltas = DriverWageBalance.tripWageCounterDeltas(
        oldDriverId: 'd1',
        newDriverId: '',
        oldWage: 400.0,
        newWage: null,
        isCreate: false,
        isDelete: true,
      );
      expect(deltas['d1'], -400.0);
    });
  });
}
