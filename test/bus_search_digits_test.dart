import 'package:elostaz_travel/domain/bus/entity/bus_entity.dart';
import 'package:elostaz_travel/presentation/home/tabs/bus/bus_tab.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final busArabicPlate = BusEntity(
    id: 'bus_1',
    busName: 'الوهاب',
    plateNumber: 'ط س ر ١٢٣٤',
    brand: 'مرسيدس',
    model: '',
    manufacturingYear: 2020,
    modelYear: 2020,
    chassisNumber: 'CH1',
    engineNumber: 'EN1',
    passengerCount: 30,
    vehicleType: 'أتوبيس',
    licenseExpiryDate: DateTime(2027, 1, 1),
    specialConditions: '',
    insuranceType: 'مؤمنة',
  );

  final busWesternPlate = BusEntity(
    id: 'bus_2',
    busName: 'النيل',
    plateNumber: 'د ه و 4567',
    brand: 'ميني باص',
    model: '',
    manufacturingYear: 2022,
    modelYear: 2022,
    chassisNumber: 'CH2',
    engineNumber: 'EN2',
    passengerCount: 14,
    vehicleType: 'ميني باص',
    licenseExpiryDate: DateTime(2028, 6, 1),
    specialConditions: '',
    insuranceType: 'غير مؤمنة',
  );

  group('normalizeBusSearchText', () {
    test('maps Arabic-Indic digits to Western digits', () {
      expect(normalizeBusSearchText('ط س ر ١٢٣٤'), 'ط س ر 1234');
      expect(normalizeBusSearchText('١٢٣'), '123');
      expect(normalizeBusSearchText('٤٥٦٧'), '4567');
    });

    test('maps Persian digits too', () {
      expect(normalizeBusSearchText('۰۱۲۳'), '0123');
    });

    test('keeps Arabic letters and existing behavior (trim + lowercase)', () {
      expect(normalizeBusSearchText('  أب ج 123 '), 'أب ج 123');
      expect(normalizeBusSearchText('ABC123'), 'abc123');
    });
  });

  group('filterBusesBySearch (digit equivalence)', () {
    test('stored "١٢٣٤" is found by query "1234"', () {
      final result =
          filterBusesBySearch([busArabicPlate, busWesternPlate], '1234');
      expect(result.map((b) => b.id), contains('bus_1'));
    });

    test('stored "4567" is found by query "٤٥٦٧"', () {
      final result =
          filterBusesBySearch([busArabicPlate, busWesternPlate], '٤٥٦٧');
      expect(result.map((b) => b.id), contains('bus_2'));
    });

    test('mixed Arabic/English plate still matches by letters', () {
      final result =
          filterBusesBySearch([busArabicPlate, busWesternPlate], 'ط س ر');
      expect(result.map((b) => b.id), contains('bus_1'));
      final mixed = filterBusesBySearch(
          [busArabicPlate, busWesternPlate], 'د ه و ١٢٣٤');
      expect(mixed, isEmpty);
    });

    test('normal Arabic name search still works', () {
      final result =
          filterBusesBySearch([busArabicPlate, busWesternPlate], 'النيل');
      expect(result.map((b) => b.id), contains('bus_2'));
    });

    test('existing behavior not regressed: empty query returns all, '
        'unknown query returns none', () {
      final all = filterBusesBySearch([busArabicPlate, busWesternPlate], '');
      expect(all, hasLength(2));
      expect(
        filterBusesBySearch([busArabicPlate, busWesternPlate], 'zzz'),
        isEmpty,
      );
    });
  });
}