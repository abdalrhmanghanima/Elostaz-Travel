import 'package:elostaz_travel/domain/bus/entity/bus_entity.dart';
import 'package:elostaz_travel/domain/trip/entity/trip_entity.dart';
import 'package:elostaz_travel/domain/trip/repository/trip_repository.dart';
import 'package:elostaz_travel/presentation/ai_assistant/provider/ai_assistant_provider.dart';
import 'package:elostaz_travel/presentation/home/tabs/bus/provider/bus_provider.dart';
import 'package:elostaz_travel/presentation/home/tabs/bus/provider/bus_notifier.dart';
import 'package:elostaz_travel/presentation/trip/provider/trip_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeTripRepository implements TripRepository {
  final List<TripEntity> trips;
  _FakeTripRepository(this.trips);

  bool getBusTripsCalled = false;
  String? queriedBusId;

  @override
  Future<List<TripEntity>> getBusTrips(String busId) async {
    getBusTripsCalled = true;
    queriedBusId = busId;
    return trips.where((t) => t.busId == busId).toList();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('bus-scoped trip query for رحلات العربية الخضراء', () async {
    final bus = BusEntity(
      id: 'bus_green_1',
      busName: 'الخضراء',
      plateNumber: 'ط س ر 1234',
      brand: 'مرسيدس',
      chassisNumber: 'CH123',
      engineNumber: 'EN123',
      passengerCount: 30,
      vehicleType: 'أتوبيس',
      licenseExpiryDate: DateTime(2027, 1, 1),
      specialConditions: '',
      insuranceType: 'مؤمنة',
    );

    final trip = TripEntity(
      id: 't_green_1',
      driverId: 'd1',
      driverName: 'أحمد',
      busId: 'bus_green_1',
      busName: 'العربية الخضراء',
      plateNumber: 'ط س ر 1234',
      revenue: 1500,
      expenses: 200,
      createdAt: DateTime.now(),
    );

    final fakeRepo = _FakeTripRepository([trip]);

    final container = ProviderContainer(
      overrides: [
        tripRepositoryProvider.overrideWithValue(fakeRepo),
        busProvider.overrideWith(() => _TestBusNotifier([bus])),
      ],
    );
    addTearDown(container.dispose);

    // Initial state
    await container.read(busProvider.future);
    await container.read(aiAssistantProvider.future);

    // Send query message
    await container
        .read(aiAssistantProvider.notifier)
        .processUserMessage('رحلات العربية الخضراء');

    final state = container.read(aiAssistantProvider).value!;
    final lastMessage = state.messages.last.content;
    print('DEBUG LAST MESSAGE: $lastMessage');
    print('DEBUG REPO CALLED: ${fakeRepo.getBusTripsCalled}');
    print('DEBUG QUERIED BUS ID: ${fakeRepo.queriedBusId}');
  });
}

class _TestBusNotifier extends BusNotifier {
  final List<BusEntity> _initial;
  _TestBusNotifier(this._initial);

  @override
  Future<List<BusEntity>> build() async => _initial;
}
