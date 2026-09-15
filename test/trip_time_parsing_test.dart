import 'package:elostaz_travel/data/ai_assistant/service/local_trip_parser.dart';
import 'package:elostaz_travel/data/trip/model/trip_model.dart';
import 'package:elostaz_travel/domain/ai_assistant/entity/ai_trip_draft.dart';
import 'package:elostaz_travel/domain/bus/entity/bus_entity.dart';
import 'package:elostaz_travel/domain/driver/entity/driver_entity.dart';
import 'package:elostaz_travel/presentation/ai_assistant/service/ai_entity_resolver.dart';
import 'package:flutter_test/flutter_test.dart';

const _current = AiTripDraft(busName: 'الوهاب', driverName: 'أحمد');

void main() {
  final parser = LocalTripParser();

  String? parseTime(String text, [AiTripDraft? current]) {
    final result = parser.parse(
      userMessage: text,
      currentDraft: current ?? _current,
      availableBuses: const [],
      availableDrivers: const [],
      availableFactories: const [],
    );
    return result.tripDraft?.departureTime;
  }

  group('Trip time extraction — Arabic 12-hour and 24-hour inputs', () {
    test('A: "الساعة 5 مساء" => 17:00', () {
      expect(parseTime('وقت الرحله الساعه 5 مساء'), '17:00');
    });

    test('A2: "الساعة 5 م" => 17:00', () {
      expect(parseTime('وقت الرحله الساعه 5 م'), '17:00');
    });

    test('A3: "5 مساء" (bare, active draft) => 17:00', () {
      expect(parseTime('5 مساء'), '17:00');
    });

    test('A4: "5:00 مساء" => 17:00', () {
      expect(parseTime('وقت الرحله الساعه 5:00 مساء'), '17:00');
    });

    test('A5: "5:00 مساء" bare => 17:00', () {
      expect(parseTime('5:00 مساء'), '17:00');
    });

    test('B: "الساعة 5 صباحا" => 05:00', () {
      expect(parseTime('وقت الرحله الساعه 5 صباحا'), '05:00');
    });

    test('B2: "5 صباحا" => 05:00', () {
      expect(parseTime('وقت الرحله الساعه 5 ص'), '05:00');
    });

    test('C: "الساعة 12 مساء" => 12:00 (12 PM)', () {
      expect(parseTime('وقت الرحله الساعه 12 مساء'), '12:00');
    });

    test('D: "الساعة 12 صباحا" => 00:00 (12 AM)', () {
      expect(parseTime('وقت الرحله الساعه 12 صباحا'), '00:00');
    });

    test('E: "الساعة 17:00" => 17:00', () {
      expect(parseTime('وقت الرحله الساعه 17:00'), '17:00');
    });

    test('E2: "الساعة 23:45" => 23:45', () {
      expect(parseTime('وقت الرحله الساعه 23:45'), '23:45');
    });

    test('F: "الساعة 5:30 مساء" => 17:30', () {
      expect(parseTime('وقت الرحله الساعه 5:30 مساء'), '17:30');
    });

    test('F2: "الساعة 7:15 صباحا" => 07:15', () {
      expect(parseTime('وقت الرحله الساعه 7:15 صباحا'), '07:15');
    });

    test('the midnight-corruption format 5:00 did not become 0:00', () {
      expect(parseTime('وقت الرحله الساعه 5:00 مساء'), isNot('0:00 م'));
      expect(parseTime('وقت الرحله الساعه 12:00 مساء'), '12:00');
      expect(parseTime('وقت الرحله الساعه 12:00 صباحا'), '00:00');
    });
  });

  group('G: Draft -> TripEntity conversion preserves the time', () {
    final bus = BusEntity(
      id: 'bus_1',
      busName: 'الوهاب',
      plateNumber: 'أ ب ج 123',
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

    final driver = const DriverEntity(
      id: 'driver_1',
      name: 'أحمد',
      phone: '01',
      tripsCount: 0,
      totalRevenue: 0,
    );

    test(
      '5 PM parsed from text survives draft -> TripEntity (17:00, not 0)',
      () {
        final parsed = parseTime('وقت الرحله الساعه 5 مساء');
        expect(parsed, '17:00');

        final draft = AiTripDraft(
          busName: 'الوهاب',
          driverName: 'أحمد',
          departureTime: parsed,
        );

        final trip = AiEntityResolver.buildTripEntity(
          draft: draft,
          bus: bus,
          driver: driver,
        );

        expect(trip.departureTime, '17:00');
        expect(trip.departureTime, isNot('0'));
        expect(trip.departureTime, isNot('0:00 م'));
      },
    );

    test('noon and midnight survive draft -> TripEntity', () {
      final noon = AiEntityResolver.buildTripEntity(
        draft: const AiTripDraft(
          busName: 'الوهاب',
          driverName: 'أحمد',
          departureTime: '12:00',
        ),
        bus: bus,
        driver: driver,
      );
      expect(noon.departureTime, '12:00');

      final midnight = AiEntityResolver.buildTripEntity(
        draft: const AiTripDraft(
          busName: 'الوهاب',
          driverName: 'أحمد',
          departureTime: '00:00',
        ),
        bus: bus,
        driver: driver,
      );
      expect(midnight.departureTime, '00:00');
    });
  });

  group('H: Firestore serialization round-trip preserves the time', () {
    final bus = BusEntity(
      id: 'bus_1',
      busName: 'الوهاب',
      plateNumber: 'أ ب ج 123',
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
    final driver = const DriverEntity(
      id: 'driver_1',
      name: 'أحمد',
      phone: '01',
      tripsCount: 0,
      totalRevenue: 0,
    );

    test('17:00 survives TripEntity -> TripModel -> Firestore map -> load', () {
      final trip = AiEntityResolver.buildTripEntity(
        draft: const AiTripDraft(
          busName: 'الوهاب',
          driverName: 'أحمد',
          departureTime: '17:00',
        ),
        bus: bus,
        driver: driver,
      );

      final model = TripModel.fromEntity(trip);
      final map = model.toFirestore();

      expect(map['departureTime'], '17:00');

      final loaded = map['departureTime']?.toString();
      expect(loaded, '17:00');
      expect(loaded, isNot('0'));

      final roundTripped = TripModel.fromEntity(
        AiEntityResolver.buildTripEntity(
          draft: AiTripDraft(
            busName: 'الوهاب',
            driverName: 'أحمد',
            departureTime: loaded,
          ),
          bus: bus,
          driver: driver,
        ),
      );
      expect(roundTripped.toFirestore()['departureTime'], '17:00');
    });
  });
}
