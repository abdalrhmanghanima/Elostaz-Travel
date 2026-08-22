import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elostaz_travel/data/driver/model/driver_advance_model.dart';
import 'package:elostaz_travel/data/driver/model/driver_model.dart';
import 'package:elostaz_travel/domain/driver/entity/driver_advance_entity.dart';
import 'package:elostaz_travel/domain/driver/entity/driver_entity.dart';
import 'package:elostaz_travel/domain/driver/repository/driver_repository.dart';
import 'package:elostaz_travel/domain/driver/use_case/update_driver_use_case.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DriverModel Document Images Tests', () {
    test('DriverModel serializes idCardImageUrl and licenseImageUrl', () {
      const driver = DriverModel(
        id: 'd_1',
        name: 'أحمد محمود',
        phone: '01012345678',
        tripsCount: 15,
        totalRevenue: 4500.0,
        idCardImageUrl: 'https://storage/id_cards/d_1.jpg',
        licenseImageUrl: 'https://storage/licenses/d_1.jpg',
      );

      final map = driver.toFirestore();

      expect(map['name'], 'أحمد محمود');
      expect(map['phone'], '01012345678');
      expect(map['tripsCount'], 15);
      expect(map['totalRevenue'], 4500.0);
      expect(map['idCardImageUrl'], 'https://storage/id_cards/d_1.jpg');
      expect(map['licenseImageUrl'], 'https://storage/licenses/d_1.jpg');
    });

    test('DriverModel without images produces clean map without null fields', () {
      const driver = DriverModel(
        id: 'd_2',
        name: 'محمد علي',
        phone: '01198765432',
        tripsCount: 5,
        totalRevenue: 1200.0,
      );

      final map = driver.toFirestore();

      expect(map['name'], 'محمد علي');
      expect(map.containsKey('idCardImageUrl'), isFalse);
      expect(map.containsKey('licenseImageUrl'), isFalse);
    });
  });

  group('DriverAdvanceModel Tests', () {
    test('DriverAdvanceModel toFirestore serializes all fields properly', () {
      final advanceDate = DateTime(2026, 8, 20, 10, 30);
      final createdAt = DateTime(2026, 8, 20, 10, 35);
      final paidAt = DateTime(2026, 8, 21, 14, 0);

      final advance = DriverAdvanceModel(
        id: 'adv_101',
        driverId: 'driver_1',
        amount: 500.0,
        date: advanceDate,
        note: 'سلفة وقود',
        status: 'paid',
        createdAt: createdAt,
        paidAt: paidAt,
      );

      final map = advance.toFirestore();

      expect(map['driverId'], 'driver_1');
      expect(map['amount'], 500.0);
      expect(map['note'], 'سلفة وقود');
      expect(map['status'], 'paid');
      expect(map['date'], isA<Timestamp>());
      expect(map['createdAt'], isA<Timestamp>());
      expect(map['paidAt'], isA<Timestamp>());
      expect(advance.isPaid, isTrue);
      expect(advance.isActive, isFalse);
    });

    test('DriverAdvanceModel handles active state without paidAt', () {
      final advance = DriverAdvanceModel(
        id: 'adv_102',
        driverId: 'driver_2',
        amount: 250.0,
        date: DateTime(2026, 8, 15),
        note: '',
        status: 'active',
        createdAt: DateTime(2026, 8, 15),
      );

      final map = advance.toFirestore();

      expect(map['status'], 'active');
      expect(map.containsKey('paidAt'), isFalse);
      expect(advance.isActive, isTrue);
      expect(advance.isPaid, isFalse);
    });
  });

  group('Driver Advances Financial Calculations Tests', () {
    test('Calculates outstanding advances total and excludes paid advances', () {
      final advances = <DriverAdvanceEntity>[
        DriverAdvanceEntity(
          id: '1',
          driverId: 'd1',
          amount: 300.0,
          date: DateTime(2026, 8, 1),
          note: 'سلفة 1',
          status: 'active',
          createdAt: DateTime(2026, 8, 1),
        ),
        DriverAdvanceEntity(
          id: '2',
          driverId: 'd1',
          amount: 200.0,
          date: DateTime(2026, 8, 5),
          note: 'سلفة 2',
          status: 'paid',
          createdAt: DateTime(2026, 8, 5),
          paidAt: DateTime(2026, 8, 10),
        ),
        DriverAdvanceEntity(
          id: '3',
          driverId: 'd1',
          amount: 450.0,
          date: DateTime(2026, 8, 12),
          note: 'سلفة 3',
          status: 'active',
          createdAt: DateTime(2026, 8, 12),
        ),
      ];

      final activeAdvances = advances.where((a) => a.isActive).toList();
      final totalOutstanding =
          activeAdvances.fold<double>(0, (acc, a) => acc + a.amount);

      expect(activeAdvances.length, 2);
      expect(totalOutstanding, 750.0);
    });

    test('When all advances are paid, total outstanding is 0', () {
      final advances = <DriverAdvanceEntity>[
        DriverAdvanceEntity(
          id: '1',
          driverId: 'd1',
          amount: 500.0,
          date: DateTime(2026, 8, 1),
          note: 'سلفة قديمة',
          status: 'paid',
          createdAt: DateTime(2026, 8, 1),
          paidAt: DateTime(2026, 8, 15),
        ),
      ];

      final activeAdvances = advances.where((a) => a.isActive).toList();
      final totalOutstanding =
          activeAdvances.fold<double>(0, (acc, a) => acc + a.amount);

      expect(activeAdvances.isEmpty, isTrue);
      expect(totalOutstanding, 0.0);
    });
  });

  group('Edit Driver & CopyWith Tests', () {
    test('DriverModel copyWith updates editable fields and preserves other fields', () {
      const original = DriverModel(
        id: 'driver_edit_1',
        name: 'أحمد سعيد',
        phone: '01011112222',
        tripsCount: 20,
        totalRevenue: 6000.0,
        idCardImageUrl: 'https://storage/id_cards/driver_edit_1.jpg',
        licenseImageUrl: 'https://storage/licenses/driver_edit_1.jpg',
      );

      final updated = original.copyWith(
        name: 'أحمد سعيد المعدل',
        phone: '01099998888',
        totalRevenue: 7500.0,
        tripsCount: 25,
      );

      expect(updated.id, 'driver_edit_1');
      expect(updated.name, 'أحمد سعيد المعدل');
      expect(updated.phone, '01099998888');
      expect(updated.totalRevenue, 7500.0);
      expect(updated.tripsCount, 25);
      expect(updated.idCardImageUrl, 'https://storage/id_cards/driver_edit_1.jpg');
      expect(updated.licenseImageUrl, 'https://storage/licenses/driver_edit_1.jpg');
    });

    test('DriverModel copyWith allows replacing document images', () {
      const original = DriverModel(
        id: 'driver_edit_2',
        name: 'كريم عادل',
        phone: '01234567890',
        tripsCount: 5,
        totalRevenue: 1500.0,
        idCardImageUrl: 'https://storage/id_cards/old.jpg',
        licenseImageUrl: 'https://storage/licenses/old.jpg',
      );

      final updated = original.copyWith(
        idCardImageUrl: 'https://storage/id_cards/new.jpg',
        licenseImageUrl: 'https://storage/licenses/new.jpg',
      );

      expect(updated.id, 'driver_edit_2');
      expect(updated.name, 'كريم عادل');
      expect(updated.idCardImageUrl, 'https://storage/id_cards/new.jpg');
      expect(updated.licenseImageUrl, 'https://storage/licenses/new.jpg');

      final map = updated.toFirestore();
      expect(map['idCardImageUrl'], 'https://storage/id_cards/new.jpg');
      expect(map['licenseImageUrl'], 'https://storage/licenses/new.jpg');
    });

    test('UpdateDriverUseCase calls repository with correct updated parameters', () async {
      final fakeRepo = _FakeDriverRepository();
      final useCase = UpdateDriverUseCase(fakeRepo);

      await useCase.call(
        id: 'd_test',
        name: 'سائق معدل',
        phone: '01000000000',
        tripsCount: 10,
        totalRevenue: 3000.0,
        idCardImageUrl: 'https://new_card.jpg',
        licenseImageUrl: 'https://new_license.jpg',
      );

      expect(fakeRepo.lastUpdatedId, 'd_test');
      expect(fakeRepo.lastUpdatedName, 'سائق معدل');
      expect(fakeRepo.lastUpdatedPhone, '01000000000');
      expect(fakeRepo.lastUpdatedTripsCount, 10);
      expect(fakeRepo.lastUpdatedRevenue, 3000.0);
      expect(fakeRepo.lastUpdatedIdCard, 'https://new_card.jpg');
      expect(fakeRepo.lastUpdatedLicense, 'https://new_license.jpg');
    });
  });
}

class _FakeDriverRepository implements DriverRepository {
  String? lastUpdatedId;
  String? lastUpdatedName;
  String? lastUpdatedPhone;
  int? lastUpdatedTripsCount;
  double? lastUpdatedRevenue;
  String? lastUpdatedIdCard;
  String? lastUpdatedLicense;

  @override
  Future<String> addDriver({
    required String name,
    required String phone,
    required int tripsCount,
    required double totalRevenue,
    String? idCardImageUrl,
    String? licenseImageUrl,
  }) async => 'new_id';

  @override
  Future<void> updateDriver({
    required String id,
    required String name,
    required String phone,
    required int tripsCount,
    required double totalRevenue,
    String? idCardImageUrl,
    String? licenseImageUrl,
  }) async {
    lastUpdatedId = id;
    lastUpdatedName = name;
    lastUpdatedPhone = phone;
    lastUpdatedTripsCount = tripsCount;
    lastUpdatedRevenue = totalRevenue;
    lastUpdatedIdCard = idCardImageUrl;
    lastUpdatedLicense = licenseImageUrl;
  }

  @override
  Future<void> deleteDriver(String driverId) async {}

  @override
  Future<List<DriverEntity>> getDrivers() async => [];
}
