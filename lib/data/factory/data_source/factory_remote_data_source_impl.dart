import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elostaz_travel/data/factory/data_source/factory_remote_data_source.dart';
import 'package:elostaz_travel/data/factory/model/factory_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FactoryRemoteDataSourceImpl implements FactoryRemoteDataSource {
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;

  FactoryRemoteDataSourceImpl({
    required this.firestore,
    required this.auth,
  });

  CollectionReference<Map<String, dynamic>> _factories() {
    final user = auth.currentUser;

    if (user == null) {
      throw Exception('User is not logged in');
    }

    return firestore
        .collection('users')
        .doc(user.uid)
        .collection('factories');
  }

  @override
  Future<List<FactoryModel>> getFactories() async {
    final user = auth.currentUser;

    if (user == null) {
      throw Exception('User is not logged in');
    }

    final snapshot = await _factories()
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs
        .map((document) => FactoryModel.fromFirestore(document))
        .toList();
  }

  @override
  Future<void> addFactory({
    required String name,
    required String phone,
    required String details,
    required int tripsCount,
    required double totalRevenue,
  }) async {
    final user = auth.currentUser;

    if (user == null) {
      throw Exception('User is not logged in');
    }

    await _factories().add({
      'name': name,
      'phone': phone,
      'details': details,
      'tripsCount': tripsCount,
      'totalRevenue': totalRevenue,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> updateFactory(FactoryModel factory) async {
    final user = auth.currentUser;

    if (user == null) {
      throw Exception('User is not logged in');
    }

    await _factories().doc(factory.id).update({
      'name': factory.name,
      'phone': factory.phone,
      'details': factory.details,
    });
  }

  @override
  Future<void> deleteFactory(String factoryId) async {
    final user = auth.currentUser;

    if (user == null) {
      throw Exception('User is not logged in');
    }

    await _factories().doc(factoryId).delete();
  }
}
