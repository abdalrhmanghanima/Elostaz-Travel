import 'package:elostaz_travel/domain/ai_assistant/entity/ai_trip_draft.dart';
import 'package:elostaz_travel/domain/bus/entity/bus_entity.dart';
import 'package:elostaz_travel/domain/driver/entity/driver_entity.dart';
import 'package:elostaz_travel/domain/factory/entity/factory_entity.dart';
import 'package:elostaz_travel/domain/trip/entity/trip_entity.dart';

enum AiEntityField { bus, driver, factory }

/// Result of trying to resolve a user-described entity (by name/plate) against
/// the real entities loaded from the existing providers.
class AiEntityResolution<T> {
  final T? resolved;
  final List<T> candidates;

  const AiEntityResolution({
    this.resolved,
    this.candidates = const [],
  });

  bool get isResolved => resolved != null;
  bool get isAmbiguous => candidates.length > 1;
  bool get isNotFound => resolved == null && candidates.isEmpty;
}

/// Bridges the AI draft (human-readable names) to the real domain entities.
///
/// The AI never invents IDs: it only ever picks an entity that already exists,
/// asks the user to pick when more than one matches, and says "not found" when
/// nothing matches. Trip construction mirrors the exact mapping used by
/// [AddTripBottomSheet]/[AddFactoryTripBottomSheet].
class AiEntityResolver {
  static String _key(String value) {
    final buffer = StringBuffer();
    for (final rune in value.toLowerCase().runes) {
      final code = rune;
      if (code >= 0x0660 && code <= 0x0669) {
        buffer.writeCharCode(code - 0x0660 + 0x30);
      } else if (code >= 0x06F0 && code <= 0x06F9) {
        buffer.writeCharCode(code - 0x06F0 + 0x30);
      } else {
        buffer.writeCharCode(code);
      }
    }
    return buffer
        .toString()
        .replaceAll(RegExp(r'\s+'), '')
        .replaceAll(RegExp(r'[أإآ]'), 'ا')
        .replaceAll('ة', 'ه')
        .replaceAll('ى', 'ي');
  }

  static String normalizeKey(String value) => _key(value);

  static AiEntityResolution<BusEntity> resolveBus({
    required AiTripDraft draft,
    required List<BusEntity> buses,
  }) {
    final nameKey = draft.busName != null && draft.busName!.isNotEmpty
        ? _key(draft.busName!)
        : null;
    final plateKey = draft.plateNumber != null && draft.plateNumber!.isNotEmpty
        ? _key(draft.plateNumber!)
        : null;

    final plateSet = plateKey == null
        ? const <BusEntity>{}
        : {
            for (final bus in buses)
              if (_key(bus.plateNumber) == plateKey) bus,
          };
    if (plateSet.isNotEmpty) {
      return _toResolution(plateSet);
    }

    final nameSet = nameKey == null
        ? const <BusEntity>{}
        : {
            for (final bus in buses)
              if (_key(bus.busName) == nameKey) bus,
          };
    if (nameSet.isNotEmpty) {
      return _toResolution(nameSet);
    }

    return const AiEntityResolution();
  }

  static AiEntityResolution<DriverEntity> resolveDriver({
    required AiTripDraft draft,
    required List<DriverEntity> drivers,
  }) {
    final nameKey = draft.driverName != null && draft.driverName!.isNotEmpty
        ? _key(draft.driverName!)
        : null;
    if (nameKey == null) return const AiEntityResolution();

    final matches = <DriverEntity>{};
    for (final driver in drivers) {
      if (_key(driver.name) == nameKey) matches.add(driver);
    }

    return _toResolution(matches);
  }

  static AiEntityResolution<FactoryEntity> resolveFactory({
    required AiTripDraft draft,
    required List<FactoryEntity> factories,
  }) {
    final nameKey = draft.factoryName != null && draft.factoryName!.isNotEmpty
        ? _key(draft.factoryName!)
        : null;
    if (nameKey == null) return const AiEntityResolution();

    final matches = <FactoryEntity>{};
    for (final factory in factories) {
      if (_key(factory.name) == nameKey) matches.add(factory);
    }

    return _toResolution(matches);
  }

  static AiEntityResolution<T> _toResolution<T>(Set<T> matches) {
    if (matches.length == 1) {
      return AiEntityResolution(resolved: matches.first);
    }
    if (matches.length > 1) {
      return AiEntityResolution(candidates: matches.toList());
    }
    return const AiEntityResolution();
  }

  static bool busStillMatches(BusEntity bus, AiTripDraft draft) {
    final nameKey = draft.busName != null && draft.busName!.isNotEmpty
        ? _key(draft.busName!)
        : null;
    final plateKey = draft.plateNumber != null && draft.plateNumber!.isNotEmpty
        ? _key(draft.plateNumber!)
        : null;
    return (nameKey != null && _key(bus.busName) == nameKey) ||
        (plateKey != null && _key(bus.plateNumber) == plateKey);
  }

  static bool driverStillMatches(DriverEntity driver, AiTripDraft draft) {
    final nameKey = draft.driverName != null && draft.driverName!.isNotEmpty
        ? _key(draft.driverName!)
        : null;
    return nameKey != null && _key(driver.name) == nameKey;
  }

  static bool factoryStillMatches(FactoryEntity factory, AiTripDraft draft) {
    final nameKey = draft.factoryName != null && draft.factoryName!.isNotEmpty
        ? _key(draft.factoryName!)
        : null;
    return nameKey != null && _key(factory.name) == nameKey;
  }

  /// Keeps a resolution the user already confirmed/validated (Rule D): when the
  /// raw match is ambiguous but the stored entity still matches the current
  /// draft, the stored entity stays chosen instead of re-asking the user.
  static AiEntityResolution<T> preferStored<T>({
    required AiEntityResolution<T> raw,
    required T? stored,
    required bool Function(T stored) stillMatches,
  }) {
    if (raw.isResolved) return raw;
    if (raw.isAmbiguous && stored != null && stillMatches(stored)) {
      return AiEntityResolution(resolved: stored);
    }
    return raw;
  }

  /// Builds the exact [TripEntity] shape the existing Add Trip sheets create.
  ///
  /// Field names/references mirror `AddTripBottomSheet._AddTripBottomSheetState`
  /// onTap handler: id = '', createdAt defaults to the trip date (or now).
  static TripEntity buildTripEntity({
    required AiTripDraft draft,
    required BusEntity bus,
    required DriverEntity driver,
    FactoryEntity? factory,
  }) {
    final type = draft.type == TripType.nightOuting
        ? TripType.nightOuting
        : TripType.trip;

    return TripEntity(
      id: '',
      driverId: driver.id,
      driverName: driver.name,
      busId: bus.id ?? '',
      busName: bus.busName,
      plateNumber: bus.plateNumber,
      details: (draft.details ?? '').trim(),
      revenue: draft.revenue ?? 0.0,
      expenses: draft.expenses ?? 0.0,
      driverWage: draft.driverWage,
      expenseDetails: (draft.expenseDetails ?? '').trim().isNotEmpty
          ? draft.expenseDetails!.trim()
          : null,
      factoryId: factory?.id,
      factoryName: factory?.name,
      departureTime: draft.departureTime,
      type: type,
      tripDate: draft.tripDate,
      createdAt: draft.tripDate ?? DateTime.now(),
    );
  }
}