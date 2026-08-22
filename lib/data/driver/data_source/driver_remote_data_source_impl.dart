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
  Future<String> addDriver({
    required String name,
    required String phone,
    required int tripsCount,
    required double totalRevenue,
    String? idCardImageUrl,
    String? licenseImageUrl,
  }) async {
    final user = auth.currentUser;

    if (user == null) {
      throw Exception('User is not logged in');
    }

    final docData = <String, dynamic>{
      'name': name,
      'phone': phone,
      'tripsCount': tripsCount,
      'totalRevenue': totalRevenue,
    };

    if (idCardImageUrl != null) {
      docData['idCardImageUrl'] = idCardImageUrl;
    }
    if (licenseImageUrl != null) {
      docData['licenseImageUrl'] = licenseImageUrl;
    }

    final docRef = await firestore
        .collection('users')
        .doc(user.uid)
        .collection('drivers')
        .add(docData);

    return docRef.id;
  }

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
    final user = auth.currentUser;

    if (user == null) {
      throw Exception('User is not logged in');
    }

    final docData = <String, dynamic>{
      'name': name,
      'phone': phone,
      'tripsCount': tripsCount,
      'totalRevenue': totalRevenue,
    };

    if (idCardImageUrl != null) {
      docData['idCardImageUrl'] = idCardImageUrl;
    }
    if (licenseImageUrl != null) {
      docData['licenseImageUrl'] = licenseImageUrl;
    }

    await firestore
        .collection('users')
        .doc(user.uid)
        .collection('drivers')
        .doc(id)
        .update(docData);
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