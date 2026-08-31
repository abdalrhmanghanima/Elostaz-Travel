import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elostaz_travel/data/driver/data_source/driver_wage_remote_data_source.dart';
import 'package:elostaz_travel/data/driver/model/driver_wage_entry_model.dart';
import 'package:elostaz_travel/data/driver/model/driver_wage_payment_model.dart';
import 'package:elostaz_travel/domain/driver/entity/driver_wage_balance.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DriverWageRemoteDataSourceImpl implements DriverWageRemoteDataSource {
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;

  DriverWageRemoteDataSourceImpl({
    required this.firestore,
    required this.auth,
  });

  String get _uid {
    final user = auth.currentUser;
    if (user == null) {
      throw Exception('User is not logged in');
    }
    return user.uid;
  }

  CollectionReference<Map<String, dynamic>> _drivers() {
    return firestore.collection('users').doc(_uid).collection('drivers');
  }

  CollectionReference<Map<String, dynamic>> _trips() {
    return firestore.collection('users').doc(_uid).collection('trips');
  }

  CollectionReference<Map<String, dynamic>> _entries(String driverId) {
    return _drivers().doc(driverId).collection('wageEntries');
  }

  CollectionReference<Map<String, dynamic>> _payments(String driverId) {
    return _drivers().doc(driverId).collection('wagePayments');
  }

  @override
  Future<List<DriverWageEntryModel>> getDriverWageEntries(
    String driverId,
  ) async {
    final snapshot =
        await _entries(driverId).orderBy('date', descending: true).get();
    return snapshot.docs
        .map((doc) => DriverWageEntryModel.fromFirestore(doc, driverId))
        .toList();
  }

  @override
  Future<List<DriverWagePaymentModel>> getDriverWagePayments(
    String driverId,
  ) async {
    final snapshot =
        await _payments(driverId).orderBy('date', descending: true).get();
    return snapshot.docs
        .map((doc) => DriverWagePaymentModel.fromFirestore(doc, driverId))
        .toList();
  }

  @override
  Future<List<DriverWageEntryModel>> getAllWageEntries() async {
    final driversSnap = await _drivers().get();
    final all = <DriverWageEntryModel>[];
    for (final driver in driversSnap.docs) {
      all.addAll(await getDriverWageEntries(driver.id));
    }
    return all;
  }

  @override
  Future<List<DriverWagePaymentModel>> getAllWagePayments() async {
    final driversSnap = await _drivers().get();
    final all = <DriverWagePaymentModel>[];
    for (final driver in driversSnap.docs) {
      all.addAll(await getDriverWagePayments(driver.id));
    }
    return all;
  }

  Future<double> _sumTripWages(String driverId) async {
    final snapshot =
        await _trips().where('driverId', isEqualTo: driverId).get();
    var total = 0.0;
    for (final doc in snapshot.docs) {
      final wage = (doc.data()['driverWage'] as num?)?.toDouble();
      total += DriverWageBalance.tripWageAmount(wage);
    }
    return total;
  }

  @override
  Future<void> addDriverWageEntry({
    required String driverId,
    required double amount,
    required DateTime date,
    required String notes,
  }) async {
    if (amount <= 0) {
      throw const DriverWagePaymentException('أدخل مبلغ صحيح أكبر من صفر');
    }

    final driverRef = _drivers().doc(driverId);
    final entryRef = _entries(driverId).doc();
    final entry = DriverWageEntryModel(
      id: entryRef.id,
      driverId: driverId,
      amount: amount,
      date: date,
      notes: notes,
      createdAt: DateTime.now(),
    );

    await firestore.runTransaction((transaction) async {
      final driverSnap = await transaction.get(driverRef);
      if (!driverSnap.exists) {
        throw Exception('Driver not found');
      }

      transaction.set(entryRef, entry.toFirestore());
      transaction.update(driverRef, {
        'accruedManualWages': FieldValue.increment(amount),
      });
    });
  }

  @override
  Future<void> addDriverWagePayment({
    required String driverId,
    required double amount,
    required DateTime date,
    required String notes,
  }) async {
    if (amount <= 0) {
      throw const DriverWagePaymentException('أدخل مبلغ صحيح أكبر من صفر');
    }

    final tripWages = await _sumTripWages(driverId);
    final entries = await getDriverWageEntries(driverId);
    final payments = await getDriverWagePayments(driverId);
    final manualWages = entries.fold<double>(0, (sum, e) => sum + e.amount);
    final alreadyPaid = payments.fold<double>(0, (sum, p) => sum + p.amount);
    final truthOutstanding = tripWages + manualWages - alreadyPaid;

    final driverRef = _drivers().doc(driverId);
    final paymentRef = _payments(driverId).doc();
    final payment = DriverWagePaymentModel(
      id: paymentRef.id,
      driverId: driverId,
      amount: amount,
      date: date,
      notes: notes,
      createdAt: DateTime.now(),
    );

    await firestore.runTransaction((transaction) async {
      final driverSnap = await transaction.get(driverRef);
      if (!driverSnap.exists) {
        throw Exception('Driver not found');
      }

      final data = driverSnap.data() ?? {};
      final accruedTrip =
          (data['accruedTripWages'] as num?)?.toDouble();
      final accruedManual =
          (data['accruedManualWages'] as num?)?.toDouble();
      final totalPaid = (data['totalWagePaid'] as num?)?.toDouble();
      final countersMissing =
          accruedTrip == null && accruedManual == null && totalPaid == null;

      final counterOutstanding =
          (accruedTrip ?? 0) + (accruedManual ?? 0) - (totalPaid ?? 0);

      // Prefer source-of-truth remaining when counters are missing or stale
      // (trips created before denormalized wage fields existed).
      final outstanding = countersMissing ||
              (counterOutstanding + 0.001 < truthOutstanding)
          ? truthOutstanding
          : counterOutstanding;

      final error = DriverWageBalance.validatePayment(
        amount: amount,
        outstanding: outstanding,
      );
      if (error != null) {
        throw DriverWagePaymentException(error);
      }

      transaction.set(paymentRef, payment.toFirestore());

      if (countersMissing ||
          (accruedTrip ?? 0) + 0.001 < tripWages ||
          (accruedManual ?? 0) + 0.001 < manualWages) {
        transaction.update(driverRef, {
          'accruedTripWages': tripWages,
          'accruedManualWages': manualWages,
          'totalWagePaid': alreadyPaid + amount,
        });
      } else {
        transaction.update(driverRef, {
          'totalWagePaid': FieldValue.increment(amount),
        });
      }
    });
  }
}
