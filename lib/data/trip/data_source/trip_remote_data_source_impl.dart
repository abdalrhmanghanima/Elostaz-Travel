import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elostaz_travel/data/trip/data_source/trip_remote_data_source.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:elostaz_travel/data/trip/model/trip_model.dart';

class TripRemoteDataSourceImpl implements TripRemoteDataSource {
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;

  TripRemoteDataSourceImpl({
    required this.firestore,
    required this.auth,
  });

  CollectionReference<Map<String, dynamic>> _trips() {
    final user = auth.currentUser;

    if (user == null) {
      throw Exception('User is not logged in');
    }

    return firestore
        .collection('users')
        .doc(user.uid)
        .collection('trips');
  }

  @override
  Future<void> addTrip(TripModel trip) async {
    await _trips().add(trip.toFirestore());
  }

  @override
  Future<void> deleteTrip(String tripId) async {
    await _trips().doc(tripId).delete();
  }

  @override
  Future<List<TripModel>> getBusTrips(String busId) async {
    try {
      print('BUS TRIPS - busId: $busId');

      final snapshot = await _trips()
          .where('busId', isEqualTo: busId)
          .orderBy('createdAt', descending: true)
          .get();

      print('BUS TRIPS - count: ${snapshot.docs.length}');

      return snapshot.docs
          .map((doc) => TripModel.fromFirestore(doc))
          .toList();
    } catch (e, stackTrace) {
      print('BUS TRIPS ERROR: $e');
      print(stackTrace);
      rethrow;
    }
  }

  @override
  Future<List<TripModel>> getDriverTrips(String driverId) async {
    try {
      print('DRIVER TRIPS - driverId: $driverId');

      final snapshot = await _trips()
          .where('driverId', isEqualTo: driverId)
          .orderBy('createdAt', descending: true)
          .get();

      print('DRIVER TRIPS - count: ${snapshot.docs.length}');

      return snapshot.docs
          .map((doc) => TripModel.fromFirestore(doc))
          .toList();
    } catch (e, stackTrace) {
      print('DRIVER TRIPS ERROR: $e');
      print(stackTrace);
      rethrow;
    }
  }
}