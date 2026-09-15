import 'package:elostaz_travel/domain/trip/entity/trip_entity.dart';

/// Thrown when a trip's date is in the future, which is forbidden.
class FutureTripDateException implements Exception {
  final DateTime invalidDate;

  const FutureTripDateException(this.invalidDate);
}

/// Business rule for trip dates:
/// - A trip MAY have any date in the past.
/// - A trip MAY have today's date.
/// - A trip MUST NOT have a future date.
///
/// Only the calendar date matters: the time of day is ignored, so a trip
/// scheduled later today is still allowed.
class TripDateRule {
  TripDateRule._();

  /// User-facing message shown by the AI assistant and the manual forms when a
  /// future trip date is detected.
  static const String futureDateMessage =
      'تاريخ الرحلة مينفعش يكون في المستقبل. اختار تاريخ النهارده أو تاريخ أقدم.';

  /// Date-only comparison. Returns true when [date] is today or earlier
  /// relative to [today].
  static bool isAllowed(DateTime date, {required DateTime today}) {
    final d = DateTime(date.year, date.month, date.day);
    final t = DateTime(today.year, today.month, today.day);
    return !d.isAfter(t);
  }

  /// Returns [futureDateMessage] when [date] is in the future (compared against
  /// the actual system clock), otherwise null.
  static String? errorFor(DateTime date) {
    return isAllowed(date, today: DateTime.now()) ? null : futureDateMessage;
  }

  /// Whether a [TripEntity]'s effective date (tripDate ?? createdAt) is
  /// acceptable under the rule.
  static bool isTripAllowed(TripEntity trip, {required DateTime today}) {
    return isAllowed(trip.effectiveDate, today: today);
  }
}