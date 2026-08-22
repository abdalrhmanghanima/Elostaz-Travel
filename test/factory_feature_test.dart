import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elostaz_travel/data/factory/model/factory_model.dart';
import 'package:elostaz_travel/data/trip/model/trip_model.dart';
import 'package:elostaz_travel/domain/factory/entity/factory_entity.dart';
import 'package:elostaz_travel/domain/trip/entity/trip_entity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Factories Feature Unit Tests', () {
    test('FactoryModel toFirestore produces expected map', () {
      final now = DateTime(2026, 8, 20, 10, 30);
      final factory = FactoryModel(
        id: 'fac_123',
        name: 'مصنع الأمل للغزل والنسيج',
        phone: '01012345678',
        details: 'شفت أول 8 ص وشفت ثاني 4 م',
        tripsCount: 15,
        totalRevenue: 45000.0,
        createdAt: now,
      );

      final map = factory.toFirestore();

      expect(map['name'], 'مصنع الأمل للغزل والنسيج');
      expect(map['phone'], '01012345678');
      expect(map['details'], 'شفت أول 8 ص وشفت ثاني 4 م');
      expect(map['tripsCount'], 15);
      expect(map['totalRevenue'], 45000.0);
      expect(map['createdAt'], isA<Timestamp>());
    });

    test('FactoryEntity preserves ID and updates fields when edited', () {
      final createdAt = DateTime(2026, 8, 10);
      final originalFactory = FactoryEntity(
        id: 'fac_999',
        name: 'مصنع الشرق',
        phone: '01111111111',
        details: 'شفت مسائي',
        tripsCount: 10,
        totalRevenue: 30000,
        createdAt: createdAt,
      );

      final updatedFactory = FactoryEntity(
        id: originalFactory.id,
        name: 'مصنع الشرق الحديث',
        phone: '01222222222',
        details: 'شفت صباحي ومسائي وسهرات',
        tripsCount: originalFactory.tripsCount,
        totalRevenue: originalFactory.totalRevenue,
        createdAt: originalFactory.createdAt,
      );

      expect(updatedFactory.id, 'fac_999');
      expect(updatedFactory.name, 'مصنع الشرق الحديث');
      expect(updatedFactory.phone, '01222222222');
      expect(updatedFactory.details, 'شفت صباحي ومسائي وسهرات');
      expect(updatedFactory.tripsCount, 10);
      expect(updatedFactory.totalRevenue, 30000);
      expect(updatedFactory.createdAt, createdAt);
    });

    test('TripEntity with Factory, Sahra (Night Shift), and Expense Details initializes properly', () {
      final now = DateTime(2026, 8, 20);
      final trip = TripEntity(
        id: 'trip_1',
        driverId: 'drv_1',
        driverName: 'محمد أحمد',
        busId: 'bus_1',
        busName: 'أتوبيس 101',
        plateNumber: 'أ ب ج 1234',
        details: 'وردية صباحية',
        revenue: 2500,
        expenses: 450,
        expenseDetails: 'سولار وطريق',
        createdAt: now,
        factoryId: 'fac_123',
        factoryName: 'مصنع الأمل',
        isNightShift: true,
        sahraDetails: 'سهرة إضافية من 8م إلى 4ص',
        sahraDriverId: 'drv_2',
        sahraDriverName: 'سيد محمود',
        sahraRevenue: 1200,
        sahraExpense: 200,
        sahraExpenseDetails: 'سولار سهرة',
      );

      expect(trip.factoryId, 'fac_123');
      expect(trip.factoryName, 'مصنع الأمل');
      expect(trip.isNightShift, isTrue);
      expect(trip.hasSahra, isTrue);
      expect(trip.expenseDetails, 'سولار وطريق');
      expect(trip.sahraDetails, 'سهرة إضافية من 8م إلى 4ص');
      expect(trip.sahraDriverId, 'drv_2');
      expect(trip.sahraDriverName, 'سيد محمود');
      expect(trip.sahraRevenue, 1200);
      expect(trip.sahraExpense, 200);
      expect(trip.sahraExpenseDetails, 'سولار سهرة');
    });

    test('TripModel toFirestore serializes factory, normal expenses, and sahra correctly', () {
      final now = DateTime(2026, 8, 20);
      final tripModel = TripModel(
        id: 'trip_1',
        driverId: 'drv_1',
        driverName: 'علي حسن',
        busId: 'bus_1',
        busName: 'أتوبيس النصر',
        plateNumber: 'س ص ع 5678',
        details: 'شفت مسائي',
        revenue: 3000,
        expenses: 500,
        expenseDetails: 'سولار وصيانة',
        createdAt: now,
        factoryId: 'fac_abc',
        factoryName: 'مصنع الحديد والصلب',
        isNightShift: true,
        sahraDetails: 'سهرة نقل عمال',
        sahraDriverId: 'drv_3',
        sahraDriverName: 'كريم عادل',
        sahraRevenue: 1500,
        sahraExpense: 300,
        sahraExpenseDetails: 'طريق وأكل',
      );

      final map = tripModel.toFirestore();

      expect(map['factoryId'], 'fac_abc');
      expect(map['factoryName'], 'مصنع الحديد والصلب');
      expect(map['isNightShift'], isTrue);
      expect(map['expenseDetails'], 'سولار وصيانة');
      expect(map['sahraDetails'], 'سهرة نقل عمال');
      expect(map['sahraDriverId'], 'drv_3');
      expect(map['sahraDriverName'], 'كريم عادل');
      expect(map['sahraRevenue'], 1500);
      expect(map['sahraExpense'], 300);
      expect(map['sahraExpenseDetails'], 'طريق وأكل');
    });

    test('TripModel gracefully handles non-factory and legacy trip structures without sahra', () {
      final now = DateTime(2026, 8, 20);
      final legacyTrip = TripModel(
        id: 'trip_legacy',
        driverId: 'drv_2',
        driverName: 'محمود',
        busId: 'bus_2',
        busName: 'أتوبيس 202',
        plateNumber: 'ط ر ق 999',
        details: 'رحلة سياحية',
        revenue: 5000,
        expenses: 800,
        createdAt: now,
      );

      final map = legacyTrip.toFirestore();

      expect(map.containsKey('factoryId'), isFalse);
      expect(map.containsKey('factoryName'), isFalse);
      expect(map['isNightShift'], isFalse);
      expect(map.containsKey('expenseDetails'), isFalse);
      expect(map.containsKey('sahraDetails'), isFalse);
      expect(map.containsKey('sahraDriverId'), isFalse);
      expect(map.containsKey('sahraDriverName'), isFalse);
      expect(map.containsKey('sahraRevenue'), isFalse);
      expect(map.containsKey('sahraExpense'), isFalse);
      expect(legacyTrip.hasSahra, isFalse);
    });
  });
}
