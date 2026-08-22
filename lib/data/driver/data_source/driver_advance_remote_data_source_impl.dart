import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elostaz_travel/data/driver/data_source/driver_advance_remote_data_source.dart';
import 'package:elostaz_travel/data/driver/model/driver_advance_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DriverAdvanceRemoteDataSourceImpl
    implements DriverAdvanceRemoteDataSource {
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;

  DriverAdvanceRemoteDataSourceImpl({
    required this.firestore,
    required this.auth,
  });

  CollectionReference<Map<String, dynamic>> _advancesCollection(
      String driverId) {
    final user = auth.currentUser;
    if (user == null) {
      throw Exception('User is not logged in');
    }

    return firestore
        .collection('users')
        .doc(user.uid)
        .collection('drivers')
        .doc(driverId)
        .collection('advances');
  }

  @override
  Future<List<DriverAdvanceModel>> getDriverAdvances(String driverId) async {
    final snapshot = await _advancesCollection(driverId)
        .orderBy('date', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => DriverAdvanceModel.fromFirestore(doc, driverId))
        .toList();
  }

  @override
  Future<void> addDriverAdvance({
    required String driverId,
    required double amount,
    required DateTime date,
    required String note,
  }) async {
    final advanceModel = DriverAdvanceModel(
      id: '',
      driverId: driverId,
      amount: amount,
      date: date,
      note: note,
      status: 'active',
      createdAt: DateTime.now(),
    );

    await _advancesCollection(driverId).add(advanceModel.toFirestore());
  }

  @override
  Future<void> markDriverAdvancePaid({
    required String driverId,
    required String advanceId,
  }) async {
    await _advancesCollection(driverId).doc(advanceId).update({
      'status': 'paid',
      'paidAt': Timestamp.fromDate(DateTime.now()),
    });
  }
}
