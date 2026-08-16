import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elostaz_travel/data/driver/data_source/driver_remote_data_source.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:elostaz_travel/data/driver/model/driver_model.dart';
class DriverRemoteDataSourceImpl implements DriverRemoteDataSource {
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;

  DriverRemoteDataSourceImpl({
    required this.firestore,
    required this.auth,
  });

  @override
  Future<List<DriverModel>> getDrivers() async {
    final user = auth.currentUser;

    if (user == null) {
      throw Exception('User is not logged in');
    }

    final snapshot = await firestore
        .collection('users')
        .doc(user.uid)
        .collection('drivers')
        .get();

    return snapshot.docs
        .map((document) => DriverModel.fromFirestore(document))
        .toList();
  }
  @override
  Future<void> addDriver({
    required String name,
    required String phone,
    required int tripsCount,
    required double totalRevenue,
  }) async {
    final user = auth.currentUser;

    if (user == null) {
      throw Exception('User is not logged in');
    }

    await firestore
        .collection('users')
        .doc(user.uid)
        .collection('drivers')
        .add({
      'name': name,
      'phone': phone,
      'tripsCount': tripsCount,
      'totalRevenue': totalRevenue,
    });
  }
  @override
  Future<void> deleteDriver(String driverId) async {
    final user = auth.currentUser;

    if (user == null) {
      throw Exception('User is not logged in');
    }

    await firestore
        .collection('users')
        .doc(user.uid)
        .collection('drivers')
        .doc(driverId)
        .delete();
  }
}