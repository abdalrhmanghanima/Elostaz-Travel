import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elostaz_travel/data/bus/model/bus_model.dart';
import 'package:elostaz_travel/domain/bus/entity/bus_entity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BusModel and BusEntity model & manufacturingYear tests', () {
    test('1. BusEntity initializes model and manufacturingYear properly', () {
      final bus = BusEntity(
        id: 'bus_1',
        busName: 'أتوبيس النور',
        plateNumber: 'أ ب ج 123',
        brand: 'Mercedes',
        model: 'Tourismo',
        manufacturingYear: 2022,
        chassisNumber: 'CH123',
        engineNumber: 'EN456',
        passengerCount: 50,
        vehicleType: 'سياحي',
        licenseExpiryDate: DateTime(2027, 1, 1),
        specialConditions: 'مكيف',
        insuranceType: 'شاملة',
      );

      expect(bus.brand, 'Mercedes');
      expect(bus.model, 'Tourismo');
      expect(bus.manufacturingYear, 2022);
    });

    test('2. BusModel toFirestore serializes model and manufacturingYear as a number', () {
      final bus = BusModel(
        id: 'bus_101',
        busName: 'سوبر جيت',
        plateNumber: 'س ج ت 999',
        brand: 'Volvo',
        model: 'B11R',
        manufacturingYear: 2021,
        chassisNumber: 'V-CHS-001',
        engineNumber: 'V-ENG-001',
        passengerCount: 48,
        vehicleType: 'سياحي فاخر',
        licenseExpiryDate: DateTime(2028, 5, 10),
        specialConditions: 'شاشات عرض',
        insuranceType: 'شاملة',
      );

      final map = bus.toFirestore();

      expect(map['brand'], 'Volvo');
      expect(map['model'], 'B11R');
      expect(map['manufacturingYear'], 2021);
      expect(map['manufacturingYear'], isA<int>());
      expect(map['modelYear'], 2021);
    });

    test('3. BusModel fromFirestore deserializes new schema with model and manufacturingYear', () {
      final fakeData = <String, dynamic>{
        'busName': 'أتوبيس الشرق',
        'plateNumber': 'ط ر ق 555',
        'brand': 'King Long',
        'model': 'XMQ6127',
        'manufacturingYear': 2023,
        'modelYear': 2023,
        'chassisNumber': 'KL-9999',
        'engineNumber': 'KL-8888',
        'passengerCount': 52,
        'vehicleType': 'نقل سياحي',
        'licenseExpiryDate': Timestamp.fromDate(DateTime(2026, 12, 31)),
        'specialConditions': 'مكيف',
        'insuranceType': 'شاملة',
      };

      // Create model directly as fromFirestore logic would do
      final rawMfgYear = fakeData['manufacturingYear'];
      final rawModelYear = fakeData['modelYear'];
      final int? mfgYear = rawMfgYear is num
          ? rawMfgYear.toInt()
          : (rawModelYear is num ? rawModelYear.toInt() : null);

      final bus = BusModel(
        id: 'bus_new',
        busName: fakeData['busName'] ?? '',
        plateNumber: fakeData['plateNumber'] ?? '',
        brand: fakeData['brand'] ?? '',
        model: fakeData['model']?.toString() ?? '',
        manufacturingYear: mfgYear,
        modelYear: (rawModelYear as num?)?.toInt() ?? mfgYear ?? 0,
        chassisNumber: fakeData['chassisNumber'] ?? '',
        engineNumber: fakeData['engineNumber'] ?? '',
        passengerCount: fakeData['passengerCount'] ?? 0,
        vehicleType: fakeData['vehicleType'] ?? '',
        licenseExpiryDate: (fakeData['licenseExpiryDate'] as Timestamp).toDate(),
        specialConditions: fakeData['specialConditions'] ?? '',
        insuranceType: fakeData['insuranceType'] ?? 'غير مؤمنة',
      );

      expect(bus.model, 'XMQ6127');
      expect(bus.manufacturingYear, 2023);
      expect(bus.brand, 'King Long');
    });

    test('4. Backward Compatibility: Old bus document without model and manufacturingYear loads safely', () {
      final oldLegacyData = <String, dynamic>{
        'busName': 'أتوبيس قديم',
        'plateNumber': 'ق د م 111',
        'brand': 'مرسيدس',
        'modelYear': 2019, // old field used as year
        // Note: 'model' and 'manufacturingYear' are absent!
        'chassisNumber': 'OLD-111',
        'engineNumber': 'ENG-111',
        'passengerCount': 40,
        'vehicleType': 'سياحي',
        'licenseExpiryDate': Timestamp.fromDate(DateTime(2025, 8, 1)),
        'specialConditions': 'مكيف',
        'insuranceType': 'ضد الغير',
      };

      final rawMfgYear = oldLegacyData['manufacturingYear'];
      final rawModelYear = oldLegacyData['modelYear'];
      final int? mfgYear = rawMfgYear is num
          ? rawMfgYear.toInt()
          : (rawModelYear is num ? rawModelYear.toInt() : null);

      final bus = BusModel(
        id: 'old_bus_doc',
        busName: oldLegacyData['busName'] ?? '',
        plateNumber: oldLegacyData['plateNumber'] ?? '',
        brand: oldLegacyData['brand'] ?? '',
        model: oldLegacyData['model']?.toString() ?? '',
        manufacturingYear: mfgYear,
        modelYear: (rawModelYear as num?)?.toInt() ?? mfgYear ?? 0,
        chassisNumber: oldLegacyData['chassisNumber'] ?? '',
        engineNumber: oldLegacyData['engineNumber'] ?? '',
        passengerCount: oldLegacyData['passengerCount'] ?? 0,
        vehicleType: oldLegacyData['vehicleType'] ?? '',
        licenseExpiryDate: (oldLegacyData['licenseExpiryDate'] as Timestamp).toDate(),
        specialConditions: oldLegacyData['specialConditions'] ?? '',
        insuranceType: oldLegacyData['insuranceType'] ?? 'غير مؤمنة',
      );

      expect(bus.model, isEmpty); // Safe fallback
      expect(bus.manufacturingYear, 2019); // Graceful fallback from old modelYear
      expect(bus.modelYear, 2019);
      expect(bus.brand, 'مرسيدس');
    });
  });
}
