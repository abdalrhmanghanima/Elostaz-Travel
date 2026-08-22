// ignore_for_file: avoid_print
import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// One-time test-data seeder for Elostaz Travel.
///
/// Writes 4 drivers, 6 buses, and multiple trips (current-month + previous-month)
/// to the authenticated user's Firestore sub-collections.
///
/// A sentinel document at `users/{uid}/meta/test_seed_v1` prevents the seed from
/// running more than once – even if [seed] is called multiple times.
class TestDataSeeder {
  TestDataSeeder._();

  static const _sentinelCollection = 'meta';
  static const _sentinelDocId = 'test_seed_v1';

  /// Call this once from the UI (e.g. a hidden button during QA).
  /// Returns `true` if data was seeded, `false` if already seeded.
  static Future<bool> seed() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User must be logged in to seed data');

    final db = FirebaseFirestore.instance;
    final userDoc = db.collection('users').doc(user.uid);

    // ── guard: only seed once ─────────────────────────────────────────────
    final sentinel = await userDoc.collection(_sentinelCollection).doc(_sentinelDocId).get();
    if (sentinel.exists) {
      developer.log('TestDataSeeder: already seeded – skipping.', name: 'Seeder');
      return false;
    }

    developer.log('TestDataSeeder: starting seed…', name: 'Seeder');

    final now = DateTime.now();
    final currentYear = now.year;
    final currentMonth = now.month;

    // previous month (handles January wrap-around)
    final prevMonth = currentMonth == 1 ? 12 : currentMonth - 1;
    final prevYear = currentMonth == 1 ? currentYear - 1 : currentYear;

    // ── 1. Drivers ────────────────────────────────────────────────────────
    final driversRef = userDoc.collection('drivers');

    final driverDocs = await Future.wait([
      driversRef.add({
        'name': 'محمد أحمد العمري',
        'phone': '01011223344',
        'tripsCount': 0,
        'totalRevenue': 0.0,
      }),
      driversRef.add({
        'name': 'عبد الرحمن يوسف',
        'phone': '01122334455',
        'tripsCount': 0,
        'totalRevenue': 0.0,
      }),
      driversRef.add({
        'name': 'كريم سامي البكري',
        'phone': '01233445566',
        'tripsCount': 0,
        'totalRevenue': 0.0,
      }),
      driversRef.add({
        'name': 'طارق حسام الدين',
        'phone': '01344556677',
        'tripsCount': 0,
        'totalRevenue': 0.0,
      }),
    ]);

    final d1Id = driverDocs[0].id;
    final d2Id = driverDocs[1].id;
    final d3Id = driverDocs[2].id;
    final d4Id = driverDocs[3].id;

    developer.log('TestDataSeeder: 4 drivers added.', name: 'Seeder');

    // ── 2. Buses (license expiry relative to now) ─────────────────────────
    final busesRef = userDoc.collection('buses');

    final busesRef1 = busesRef.doc();
    final busesRef2 = busesRef.doc();
    final busesRef3 = busesRef.doc();
    final busesRef4 = busesRef.doc();
    final busesRef5 = busesRef.doc();
    final busesRef6 = busesRef.doc();

    final buses = [
      (
        ref: busesRef1,
        name: 'أتوبيس الشروق',
        plate: 'أ ب ج 1001',
        brand: 'مرسيدس',
        year: 2018,
        chassis: 'CHS-100001',
        engine: 'ENG-100001',
        passengers: 45,
        type: 'سياحي',
        expiry: now.add(const Duration(days: 7)),
        conditions: 'مكيف',
        insurance: 'شاملة',
      ),
      (
        ref: busesRef2,
        name: 'أتوبيس النيل',
        plate: 'د ه و 2002',
        brand: 'مان',
        year: 2019,
        chassis: 'CHS-100002',
        engine: 'ENG-100002',
        passengers: 50,
        type: 'سياحي',
        expiry: now.add(const Duration(days: 6)),
        conditions: 'مكيف - تلفاز',
        insurance: 'ضد الغير',
      ),
      (
        ref: busesRef3,
        name: 'أتوبيس القاهرة',
        plate: 'ز ح ط 3003',
        brand: 'فولفو',
        year: 2020,
        chassis: 'CHS-100003',
        engine: 'ENG-100003',
        passengers: 48,
        type: 'نقل عام',
        expiry: now.add(const Duration(days: 20)),
        conditions: 'بدون',
        insurance: 'شاملة',
      ),
      (
        ref: busesRef4,
        name: 'أتوبيس الإسكندرية',
        plate: 'ي ك ل 4004',
        brand: 'إيفيكو',
        year: 2021,
        chassis: 'CHS-100004',
        engine: 'ENG-100004',
        passengers: 52,
        type: 'سياحي',
        expiry: now.add(const Duration(days: 35)),
        conditions: 'مكيف - واي فاي',
        insurance: 'شاملة',
      ),
      (
        ref: busesRef5,
        name: 'أتوبيس الأقصر',
        plate: 'م ن س 5005',
        brand: 'سكانيا',
        year: 2022,
        chassis: 'CHS-100005',
        engine: 'ENG-100005',
        passengers: 44,
        type: 'رحلات',
        expiry: now.add(const Duration(days: 60)),
        conditions: 'مكيف فاخر',
        insurance: 'شاملة',
      ),
      (
        ref: busesRef6,
        name: 'أتوبيس أسوان',
        plate: 'ع غ ف 6006',
        brand: 'رينو',
        year: 2023,
        chassis: 'CHS-100006',
        engine: 'ENG-100006',
        passengers: 40,
        type: 'رحلات',
        expiry: now.add(const Duration(days: 90)),
        conditions: 'مكيف - شاشات ترفيه',
        insurance: 'ضد الغير',
      ),
    ];

    final batch1 = db.batch();
    for (final b in buses) {
      batch1.set(b.ref, {
        'busName': b.name,
        'plateNumber': b.plate,
        'brand': b.brand,
        'model': b.brand,
        'manufacturingYear': b.year,
        'modelYear': b.year,
        'chassisNumber': b.chassis,
        'engineNumber': b.engine,
        'passengerCount': b.passengers,
        'vehicleType': b.type,
        'licenseExpiryDate': Timestamp.fromDate(b.expiry),
        'licenseImageUrl': null,
        'busImageUrl': null,
        'specialConditions': b.conditions,
        'insuranceType': b.insurance,
      });
    }
    await batch1.commit();
    developer.log('TestDataSeeder: 6 buses added.', name: 'Seeder');

    // helper – build a trip map
    Map<String, dynamic> trip({
      required String driverId,
      required String driverName,
      required String busId,
      required String busName,
      required String plateNumber,
      required String details,
      required double revenue,
      required double expenses,
      required DateTime createdAt,
    }) =>
        {
          'driverId': driverId,
          'driverName': driverName,
          'busId': busId,
          'busName': busName,
          'plateNumber': plateNumber,
          'details': details,
          'revenue': revenue,
          'expenses': expenses,
          'createdAt': Timestamp.fromDate(createdAt),
        };

    final tripsRef = userDoc.collection('trips');

    // ── 3. Current-month trips ────────────────────────────────────────────
    final batch2 = db.batch();

    // Driver 1 + Bus 1
    batch2.set(tripsRef.doc(), trip(
      driverId: d1Id, driverName: 'محمد أحمد العمري',
      busId: busesRef1.id, busName: 'أتوبيس الشروق', plateNumber: 'أ ب ج 1001',
      details: 'رحلة مدرسية من القاهرة إلى الإسكندرية',
      revenue: 3500, expenses: 800,
      createdAt: DateTime(currentYear, currentMonth, 3, 8, 0),
    ));
    batch2.set(tripsRef.doc(), trip(
      driverId: d1Id, driverName: 'محمد أحمد العمري',
      busId: busesRef1.id, busName: 'أتوبيس الشروق', plateNumber: 'أ ب ج 1001',
      details: 'رحلة سياحية إلى الأهرامات',
      revenue: 4200, expenses: 950,
      createdAt: DateTime(currentYear, currentMonth, 8, 9, 30),
    ));

    // Driver 2 + Bus 2
    batch2.set(tripsRef.doc(), trip(
      driverId: d2Id, driverName: 'عبد الرحمن يوسف',
      busId: busesRef2.id, busName: 'أتوبيس النيل', plateNumber: 'د ه و 2002',
      details: 'رحلة شركة إلى العين السخنة',
      revenue: 5000, expenses: 1200,
      createdAt: DateTime(currentYear, currentMonth, 5, 7, 0),
    ));
    batch2.set(tripsRef.doc(), trip(
      driverId: d2Id, driverName: 'عبد الرحمن يوسف',
      busId: busesRef2.id, busName: 'أتوبيس النيل', plateNumber: 'د ه و 2002',
      details: 'رحلة مدرسية إلى مدينة نصر',
      revenue: 2800, expenses: 600,
      createdAt: DateTime(currentYear, currentMonth, 12, 8, 0),
    ));

    // Driver 3 + Bus 3
    batch2.set(tripsRef.doc(), trip(
      driverId: d3Id, driverName: 'كريم سامي البكري',
      busId: busesRef3.id, busName: 'أتوبيس القاهرة', plateNumber: 'ز ح ط 3003',
      details: 'رحلة جامعية إلى المنصورة',
      revenue: 3200, expenses: 700,
      createdAt: DateTime(currentYear, currentMonth, 6, 10, 0),
    ));

    // Driver 4 + Bus 4
    batch2.set(tripsRef.doc(), trip(
      driverId: d4Id, driverName: 'طارق حسام الدين',
      busId: busesRef4.id, busName: 'أتوبيس الإسكندرية', plateNumber: 'ي ك ل 4004',
      details: 'رحلة نقل موظفين',
      revenue: 2500, expenses: 550,
      createdAt: DateTime(currentYear, currentMonth, 10, 6, 30),
    ));
    batch2.set(tripsRef.doc(), trip(
      driverId: d4Id, driverName: 'طارق حسام الدين',
      busId: busesRef5.id, busName: 'أتوبيس الأقصر', plateNumber: 'م ن س 5005',
      details: 'رحلة سياحية إلى الأقصر',
      revenue: 8500, expenses: 2100,
      createdAt: DateTime(currentYear, currentMonth, 14, 8, 0),
    ));

    await batch2.commit();
    developer.log('TestDataSeeder: current-month trips added.', name: 'Seeder');

    // ── 4. Previous-month trips ───────────────────────────────────────────
    final batch3 = db.batch();

    batch3.set(tripsRef.doc(), trip(
      driverId: d1Id, driverName: 'محمد أحمد العمري',
      busId: busesRef1.id, busName: 'أتوبيس الشروق', plateNumber: 'أ ب ج 1001',
      details: 'رحلة الشهر الماضي - رحلة 1',
      revenue: 3000, expenses: 700,
      createdAt: DateTime(prevYear, prevMonth, 5, 8, 0),
    ));
    batch3.set(tripsRef.doc(), trip(
      driverId: d2Id, driverName: 'عبد الرحمن يوسف',
      busId: busesRef2.id, busName: 'أتوبيس النيل', plateNumber: 'د ه و 2002',
      details: 'رحلة الشهر الماضي - رحلة 2',
      revenue: 4500, expenses: 1100,
      createdAt: DateTime(prevYear, prevMonth, 12, 9, 0),
    ));
    batch3.set(tripsRef.doc(), trip(
      driverId: d3Id, driverName: 'كريم سامي البكري',
      busId: busesRef3.id, busName: 'أتوبيس القاهرة', plateNumber: 'ز ح ط 3003',
      details: 'رحلة الشهر الماضي - رحلة 3',
      revenue: 2700, expenses: 600,
      createdAt: DateTime(prevYear, prevMonth, 18, 10, 0),
    ));
    batch3.set(tripsRef.doc(), trip(
      driverId: d4Id, driverName: 'طارق حسام الدين',
      busId: busesRef6.id, busName: 'أتوبيس أسوان', plateNumber: 'ع غ ف 6006',
      details: 'رحلة الشهر الماضي - رحلة 4',
      revenue: 6000, expenses: 1500,
      createdAt: DateTime(prevYear, prevMonth, 25, 7, 0),
    ));

    await batch3.commit();
    developer.log('TestDataSeeder: previous-month trips added.', name: 'Seeder');

    // ── 5. Update driver stats to match trips ─────────────────────────────
    // Current-month revenue per driver:
    //   d1: 3500 + 4200 = 7700   trips: 2 (current) + 1 (prev) = 3
    //   d2: 5000 + 2800 = 7800   trips: 2 + 1 = 3
    //   d3: 3200               trips: 1 + 1 = 2
    //   d4: 2500 + 8500 = 11000  trips: 2 + 1 = 3
    final batchDrivers = db.batch();
    batchDrivers.update(driversRef.doc(d1Id), {
      'tripsCount': 3,
      'totalRevenue': 3500 + 4200 + 3000,
    });
    batchDrivers.update(driversRef.doc(d2Id), {
      'tripsCount': 3,
      'totalRevenue': 5000 + 2800 + 4500,
    });
    batchDrivers.update(driversRef.doc(d3Id), {
      'tripsCount': 2,
      'totalRevenue': 3200 + 2700,
    });
    batchDrivers.update(driversRef.doc(d4Id), {
      'tripsCount': 3,
      'totalRevenue': 2500 + 8500 + 6000,
    });
    await batchDrivers.commit();
    developer.log('TestDataSeeder: driver stats updated.', name: 'Seeder');

    // ── 6. Write sentinel ──────────────────────────────────────────────────
    await userDoc.collection(_sentinelCollection).doc(_sentinelDocId).set({
      'seededAt': FieldValue.serverTimestamp(),
      'version': 1,
    });

    developer.log('TestDataSeeder: done.', name: 'Seeder');
    return true;
  }
}
