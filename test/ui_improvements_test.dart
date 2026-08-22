import 'package:elostaz_travel/core/utils/app_colors.dart';
import 'package:elostaz_travel/core/utils/app_date_picker.dart';
import 'package:elostaz_travel/domain/driver/entity/driver_advance_entity.dart';
import 'package:elostaz_travel/domain/trip/entity/trip_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppDateFormatter Tests', () {
    test('AppDateFormatter.format formats single digit day and month as DD/MM/YYYY', () {
      final date = DateTime(2026, 3, 5);
      expect(AppDateFormatter.format(date), '05/03/2026');
    });

    test('AppDateFormatter.format formats double digit day and month as DD/MM/YYYY', () {
      final date = DateTime(2026, 12, 25);
      expect(AppDateFormatter.format(date), '25/12/2026');
    });

    test('AppDateFormatter.format handles leap day correctly', () {
      final date = DateTime(2028, 2, 29);
      expect(AppDateFormatter.format(date), '29/02/2028');
    });
  });

  group('Sahra Color & Styling Tests', () {
    test('AppColors.lightGreen and AppColors.green are valid green colors', () {
      expect(AppColors.lightGreen, isA<Color>());
      expect(AppColors.green, isA<Color>());
      expect(AppColors.lightGreen.value, 0xFFE6F4EA);
      expect(AppColors.green.value, 0xFF2E7D32);
    });
  });

  group('Trip & Advance Entities Integration for Reports', () {
    test('TripEntity with expense details and Sahra retains separate financial values', () {
      final trip = TripEntity(
        id: 'trip_1',
        busId: 'bus_1',
        driverId: 'driver_1',
        driverName: 'أحمد محمود',
        busName: 'باص 1',
        plateNumber: 'أ ب ج 123',
        details: 'وردية صباحية',
        revenue: 1500.0,
        expenses: 300.0,
        expenseDetails: 'سولار وبنزين',
        factoryId: 'factory_1',
        factoryName: 'مصنع الأمل',
        isNightShift: true,
        sahraDetails: 'سهرة إضافية من 10م',
        sahraDriverId: 'driver_2',
        sahraDriverName: 'سيد علي',
        sahraRevenue: 800.0,
        sahraExpense: 150.0,
        sahraExpenseDetails: 'كارتة ومصروف',
        createdAt: DateTime(2026, 8, 21),
      );

      expect(trip.hasSahra, isTrue);
      expect(trip.revenue, 1500.0);
      expect(trip.expenses, 300.0);
      expect(trip.expenseDetails, 'سولار وبنزين');
      expect(trip.sahraRevenue, 800.0);
      expect(trip.sahraExpense, 150.0);
      expect(trip.sahraExpenseDetails, 'كارتة ومصروف');
      expect(trip.factoryName, 'مصنع الأمل');
    });

    test('Advances can be filtered cleanly into active vs paid for driver report', () {
      final advances = [
        DriverAdvanceEntity(
          id: 'adv_1',
          driverId: 'd1',
          amount: 500,
          date: DateTime(2026, 8, 10),
          note: 'سلفة طارئة',
          status: 'active',
          createdAt: DateTime(2026, 8, 10),
        ),
        DriverAdvanceEntity(
          id: 'adv_2',
          driverId: 'd1',
          amount: 300,
          date: DateTime(2026, 8, 15),
          note: 'سلفة تصليح',
          status: 'paid',
          paidAt: DateTime(2026, 8, 20),
          createdAt: DateTime(2026, 8, 15),
        ),
        DriverAdvanceEntity(
          id: 'adv_3',
          driverId: 'd1',
          amount: 200,
          date: DateTime(2026, 8, 18),
          note: '',
          status: 'active',
          createdAt: DateTime(2026, 8, 18),
        ),
      ];

      final active = advances.where((a) => a.isActive).toList();
      final paid = advances.where((a) => a.isPaid).toList();

      expect(active.length, 2);
      expect(paid.length, 1);

      final totalOutstanding = active.fold<double>(0, (sum, a) => sum + a.amount);
      final totalPaid = paid.fold<double>(0, (sum, a) => sum + a.amount);

      expect(totalOutstanding, 700.0);
      expect(totalPaid, 300.0);
      expect(paid.first.paidAt, isNotNull);
    });
  });
}
