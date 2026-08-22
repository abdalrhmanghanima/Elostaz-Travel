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

  CollectionReference<Map<String, dynamic>> _drivers() {
    final user = auth.currentUser;

    if (user == null) {
      throw Exception('User is not logged in');
    }

    return firestore
        .collection('users')
        .doc(user.uid)
        .collection('drivers');
  }

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
  Future<void> addTrip(TripModel trip) async {
    final tripRef = _trips().doc();
    final driverRef = _drivers().doc(trip.driverId);
    final DocumentReference<Map<String, dynamic>>? factoryRef =
        (trip.factoryId != null && trip.factoryId!.isNotEmpty)
            ? _factories().doc(trip.factoryId)
            : null;

    await firestore.runTransaction((transaction) async {
      final driverSnapshot = await transaction.get(driverRef);

      if (!driverSnapshot.exists) {
        throw Exception('Driver not found');
      }

      DocumentSnapshot<Map<String, dynamic>>? factorySnapshot;
      if (factoryRef != null) {
        factorySnapshot = await transaction.get(factoryRef);
      }

      transaction.set(
        tripRef,
        trip.toFirestore(),
      );

      transaction.update(
        driverRef,
        {
          'tripsCount': FieldValue.increment(1),
          'totalRevenue': FieldValue.increment(trip.revenue),
        },
      );

      if (factoryRef != null &&
          factorySnapshot != null &&
          factorySnapshot.exists) {
        transaction.update(
          factoryRef,
          {
            'tripsCount': FieldValue.increment(1),
            'totalRevenue': FieldValue.increment(trip.revenue),
          },
        );
      }
    });
  }

  @override
  Future<void> deleteTrip(String tripId) async {
    final tripRef = _trips().doc(tripId);

    await firestore.runTransaction((transaction) async {
      final tripSnapshot = await transaction.get(tripRef);

      if (!tripSnapshot.exists) {
        throw Exception('Trip not found');
      }

      final tripData = tripSnapshot.data() ?? {};

      final driverId = tripData['driverId'] as String?;
      final factoryId = tripData['factoryId'] as String?;
      final revenue = (tripData['revenue'] as num?)?.toDouble() ?? 0;

      if (driverId == null || driverId.isEmpty) {
        throw Exception('Driver ID not found in trip');
      }

      final driverRef = _drivers().doc(driverId);
      final driverSnapshot = await transaction.get(driverRef);

      if (!driverSnapshot.exists) {
        throw Exception('Driver not found');
      }

      DocumentReference<Map<String, dynamic>>? factoryRef;
      DocumentSnapshot<Map<String, dynamic>>? factorySnapshot;
      if (factoryId != null && factoryId.isNotEmpty) {
        factoryRef = _factories().doc(factoryId);
        factorySnapshot = await transaction.get(factoryRef);
      }

      transaction.delete(tripRef);

      transaction.update(
        driverRef,
        {
          'tripsCount': FieldValue.increment(-1),
          'totalRevenue': FieldValue.increment(-revenue),
        },
      );

      if (factoryRef != null &&
          factorySnapshot != null &&
          factorySnapshot.exists) {
        transaction.update(
          factoryRef,
          {
            'tripsCount': FieldValue.increment(-1),
            'totalRevenue': FieldValue.increment(-revenue),
          },
        );
      }
    });
  }

  @override
  Future<List<TripModel>> getBusTrips(String busId) async {
    try {
      final snapshot = await _trips()
          .where('busId', isEqualTo: busId)
          .orderBy('createdAt', descending: true)
          .get();

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
      final snapshot = await _trips()
          .where(
            'driverId',
            isEqualTo: driverId,
          )
          .orderBy(
            'createdAt',
            descending: true,
          )
          .get();

      return snapshot.docs
          .map(
            (doc) => TripModel.fromFirestore(doc),
          )
          .toList();
    } catch (e, stackTrace) {
      print('GET DRIVER TRIPS ERROR: $e');
      print(stackTrace);
      rethrow;
    }
  }

  @override
  Future<List<TripModel>> getFactoryTrips(String factoryId) async {
    try {
      final snapshot = await _trips()
          .where('factoryId', isEqualTo: factoryId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => TripModel.fromFirestore(doc))
          .toList();
    } catch (e, stackTrace) {
      print('GET FACTORY TRIPS ERROR: $e');
      print(stackTrace);
      // If composite index is pending, fallback to query by factoryId and sort in memory
      try {
        final fallbackSnapshot = await _trips()
            .where('factoryId', isEqualTo: factoryId)
            .get();

        final trips = fallbackSnapshot.docs
            .map((doc) => TripModel.fromFirestore(doc))
            .toList();
        trips.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return trips;
      } catch (_) {
        rethrow;
      }
    }
  }

  @override
  Future<List<TripModel>> getAllTrips() async {
    try {
      final snapshot = await _trips()
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) => TripModel.fromFirestore(doc)).toList();
    } catch (e, stackTrace) {
      print('GET ALL TRIPS ERROR: $e');
      print(stackTrace);
      rethrow;
    }
  }

  @override
  Future<List<TripModel>> getMonthlyTrips({
    required int year,
    required int month,
  }) async {
    try {
      final start = DateTime(year, month, 1);
      final end = DateTime(year, month + 1, 1);

      final snapshot = await _trips()
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('createdAt', isLessThan: Timestamp.fromDate(end))
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) => TripModel.fromFirestore(doc)).toList();
    } catch (e, stackTrace) {
      print('GET MONTHLY TRIPS ERROR: $e');
      print(stackTrace);
      rethrow;
    }
  }
}