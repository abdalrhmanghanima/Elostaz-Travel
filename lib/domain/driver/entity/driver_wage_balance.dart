import 'package:elostaz_travel/domain/driver/entity/driver_wage_entry_entity.dart';
import 'package:elostaz_travel/domain/driver/entity/driver_wage_payment_entity.dart';
import 'package:elostaz_travel/domain/trip/entity/trip_entity.dart';

class DriverWagePaymentException implements Exception {
  final String message;

  const DriverWagePaymentException(this.message);

  @override
  String toString() => message;
}

class DriverWageBalance {
  final double accruedFromTrips;
  final double accruedFromEntries;
  final double totalPaid;

  const DriverWageBalance({
    required this.accruedFromTrips,
    required this.accruedFromEntries,
    required this.totalPaid,
  });

  double get totalAccrued => accruedFromTrips + accruedFromEntries;

  double get remaining {
    final value = totalAccrued - totalPaid;
    return value < 0 ? 0 : value;
  }

  static double tripWageAmount(double? driverWage) => driverWage ?? 0;

  static DriverWageBalance compute({
    required Iterable<TripEntity> trips,
    required Iterable<DriverWageEntryEntity> entries,
    required Iterable<DriverWagePaymentEntity> payments,
  }) {
    final accruedFromTrips = trips.fold<double>(
      0,
      (sum, trip) => sum + tripWageAmount(trip.driverWage),
    );
    final accruedFromEntries = entries.fold<double>(
      0,
      (sum, entry) => sum + entry.amount,
    );
    final totalPaid = payments.fold<double>(
      0,
      (sum, payment) => sum + payment.amount,
    );
    return DriverWageBalance(
      accruedFromTrips: accruedFromTrips,
      accruedFromEntries: accruedFromEntries,
      totalPaid: totalPaid,
    );
  }

  static bool canPay({
    required double amount,
    required double outstanding,
  }) {
    return amount > 0 && amount <= outstanding + 0.0001;
  }

  static String? validatePayment({
    required double amount,
    required double outstanding,
  }) {
    if (amount <= 0) {
      return 'أدخل مبلغ صحيح أكبر من صفر';
    }
    if (outstanding <= 0) {
      return 'لا يوجد أجر مستحق للتسديد';
    }
    if (amount > outstanding + 0.0001) {
      return 'لا يمكن تسديد مبلغ أكبر من المتبقي';
    }
    return null;
  }

  /// Cash-based company result: accrued wages are ignored.
  static double companyCashResult({
    required double revenue,
    required double expenses,
    required double wagesPaid,
  }) {
    return revenue - expenses - wagesPaid;
  }

  /// Delta to apply to [accruedTripWages] per driver when a trip is written.
  static Map<String, double> tripWageCounterDeltas({
    required String oldDriverId,
    required String newDriverId,
    required double? oldWage,
    required double? newWage,
    required bool isCreate,
    required bool isDelete,
  }) {
    final oldAmount = tripWageAmount(oldWage);
    final newAmount = tripWageAmount(newWage);
    final deltas = <String, double>{};

    void add(String driverId, double delta) {
      if (driverId.isEmpty || delta == 0) return;
      deltas[driverId] = (deltas[driverId] ?? 0) + delta;
    }

    if (isCreate) {
      add(newDriverId, newAmount);
      return deltas;
    }
    if (isDelete) {
      add(oldDriverId, -oldAmount);
      return deltas;
    }
    if (oldDriverId == newDriverId) {
      add(newDriverId, newAmount - oldAmount);
    } else {
      add(oldDriverId, -oldAmount);
      add(newDriverId, newAmount);
    }
    return deltas;
  }
}
