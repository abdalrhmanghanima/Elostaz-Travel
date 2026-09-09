import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elostaz_travel/data/trip/data_source/trip_remote_data_source.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:elostaz_travel/data/trip/model/trip_model.dart';
import 'package:elostaz_travel/domain/trip/entity/trip_entity.dart';
import 'package:elostaz_travel/domain/trip/repository/trip_repository.dart'
    show TripListFilter;

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

      final tripWage = trip.driverWage ?? 0.0;
      transaction.update(
        driverRef,
        {
          'tripsCount': FieldValue.increment(1),
          'totalRevenue': FieldValue.increment(trip.revenue),
          if (tripWage != 0)
            'accruedTripWages': FieldValue.increment(tripWage),
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
  Future<void> updateTrip(TripModel trip) async {
    final tripRef = _trips().doc(trip.id);

    await firestore.runTransaction((transaction) async {
      final tripSnapshot = await transaction.get(tripRef);

      if (!tripSnapshot.exists) {
        throw Exception('Trip not found');
      }

      final oldData = tripSnapshot.data() ?? {};
      final oldRevenue = (oldData['revenue'] as num?)?.toDouble() ?? 0.0;
      final oldDriverId = oldData['driverId']?.toString() ?? '';
      final oldFactoryId = oldData['factoryId']?.toString();
      final oldWage = (oldData['driverWage'] as num?)?.toDouble() ?? 0.0;
      final newWage = trip.driverWage ?? 0.0;

      final revDiff = trip.revenue - oldRevenue;
      final wageDiff = newWage - oldWage;

      // Overwrite trip doc with new model
      transaction.set(tripRef, trip.toFirestore());

      // Update driver(s)
      if (oldDriverId == trip.driverId) {
        if ((revDiff != 0 || wageDiff != 0) && trip.driverId.isNotEmpty) {
          final driverRef = _drivers().doc(trip.driverId);
          transaction.update(driverRef, {
            if (revDiff != 0) 'totalRevenue': FieldValue.increment(revDiff),
            if (wageDiff != 0)
              'accruedTripWages': FieldValue.increment(wageDiff),
          });
        }
      } else {
        if (oldDriverId.isNotEmpty) {
          final oldDriverRef = _drivers().doc(oldDriverId);
          transaction.update(oldDriverRef, {
            'tripsCount': FieldValue.increment(-1),
            'totalRevenue': FieldValue.increment(-oldRevenue),
            if (oldWage != 0)
              'accruedTripWages': FieldValue.increment(-oldWage),
          });
        }
        if (trip.driverId.isNotEmpty) {
          final newDriverRef = _drivers().doc(trip.driverId);
          transaction.update(newDriverRef, {
            'tripsCount': FieldValue.increment(1),
            'totalRevenue': FieldValue.increment(trip.revenue),
            if (newWage != 0)
              'accruedTripWages': FieldValue.increment(newWage),
          });
        }
      }

      // Update factory(ies)
      if (oldFactoryId == trip.factoryId) {
        if (revDiff != 0 && trip.factoryId != null && trip.factoryId!.isNotEmpty) {
          final factoryRef = _factories().doc(trip.factoryId!);
          transaction.update(factoryRef, {
            'totalRevenue': FieldValue.increment(revDiff),
          });
        }
      } else {
        if (oldFactoryId != null && oldFactoryId.isNotEmpty) {
          final oldFactoryRef = _factories().doc(oldFactoryId);
          transaction.update(oldFactoryRef, {
            'tripsCount': FieldValue.increment(-1),
            'totalRevenue': FieldValue.increment(-oldRevenue),
          });
        }
        if (trip.factoryId != null && trip.factoryId!.isNotEmpty) {
          final newFactoryRef = _factories().doc(trip.factoryId!);
          transaction.update(newFactoryRef, {
            'tripsCount': FieldValue.increment(1),
            'totalRevenue': FieldValue.increment(trip.revenue),
          });
        }
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
      final tripWage = (tripData['driverWage'] as num?)?.toDouble() ?? 0;

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
          if (tripWage != 0)
            'accruedTripWages': FieldValue.increment(-tripWage),
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

  @override
  Future<List<TripModel>> getBusTripsLimited(String busId, int limit) async {
    try {
      final snapshot = await _trips()
          .where('busId', isEqualTo: busId)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => TripModel.fromFirestore(doc))
          .toList();
    } catch (e, stackTrace) {
      print('BUS TRIPS LIMITED ERROR: $e');
      print(stackTrace);
      rethrow;
    }
  }

  @override
  Future<List<TripModel>> getDriverTripsLimited(String driverId, int limit) async {
    try {
      final snapshot = await _trips()
          .where('driverId', isEqualTo: driverId)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => TripModel.fromFirestore(doc))
          .toList();
    } catch (e, stackTrace) {
      print('DRIVER TRIPS LIMITED ERROR: $e');
      print(stackTrace);
      rethrow;
    }
  }

  @override
  Future<List<TripModel>> getFactoryTripsLimited(String factoryId, int limit) async {
    try {
      final snapshot = await _trips()
          .where('factoryId', isEqualTo: factoryId)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => TripModel.fromFirestore(doc))
          .toList();
    } catch (e, stackTrace) {
      print('FACTORY TRIPS LIMITED ERROR: $e');
      print(stackTrace);
      rethrow;
    }
  }

  @override
  Future<PaginatedTripsResult> getBusTripsPaginated(
    String busId,
    int limit,
    DocumentSnapshot<Map<String, dynamic>>? lastDocument,
    TripListFilter filter,
  ) async {
    try {
      Query<Map<String, dynamic>> query =
          _applyFilter(_trips().where('busId', isEqualTo: busId), filter)
              .orderBy('createdAt', descending: true)
              .limit(limit);

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      final snapshot = await query.get();
      final trips = snapshot.docs
          .map((doc) => TripModel.fromFirestore(doc))
          .toList();

      final lastDoc = snapshot.docs.isNotEmpty ? snapshot.docs.last : null;
      final hasMore = snapshot.docs.length == limit;

      return PaginatedTripsResult(
        trips: trips,
        lastDocument: lastDoc,
        hasMore: hasMore,
      );
    } catch (e, stackTrace) {
      print('BUS TRIPS PAGINATED ERROR: $e');
      print(stackTrace);
      rethrow;
    }
  }

  @override
  Future<PaginatedTripsResult> getDriverTripsPaginated(
    String driverId,
    int limit,
    DocumentSnapshot<Map<String, dynamic>>? lastDocument,
    TripListFilter filter,
  ) async {
    try {
      Query<Map<String, dynamic>> query =
          _applyFilter(_trips().where('driverId', isEqualTo: driverId), filter)
              .orderBy('createdAt', descending: true)
              .limit(limit);

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      final snapshot = await query.get();
      final trips = snapshot.docs
          .map((doc) => TripModel.fromFirestore(doc))
          .toList();

      final lastDoc = snapshot.docs.isNotEmpty ? snapshot.docs.last : null;
      final hasMore = snapshot.docs.length == limit;

      return PaginatedTripsResult(
        trips: trips,
        lastDocument: lastDoc,
        hasMore: hasMore,
      );
    } catch (e, stackTrace) {
      print('DRIVER TRIPS PAGINATED ERROR: $e');
      print(stackTrace);
      rethrow;
    }
  }

  @override
  Future<PaginatedTripsResult> getFactoryTripsPaginated(
    String factoryId,
    int limit,
    DocumentSnapshot<Map<String, dynamic>>? lastDocument,
    TripListFilter filter,
  ) async {
    try {
      Query<Map<String, dynamic>> query =
          _applyFilter(_trips().where('factoryId', isEqualTo: factoryId), filter)
              .orderBy('createdAt', descending: true)
              .limit(limit);

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      final snapshot = await query.get();
      final trips = snapshot.docs
          .map((doc) => TripModel.fromFirestore(doc))
          .toList();

      final lastDoc = snapshot.docs.isNotEmpty ? snapshot.docs.last : null;
      final hasMore = snapshot.docs.length == limit;

      return PaginatedTripsResult(
        trips: trips,
        lastDocument: lastDoc,
        hasMore: hasMore,
      );
    } catch (e, stackTrace) {
      print('FACTORY TRIPS PAGINATED ERROR: $e');
      print(stackTrace);
      rethrow;
    }
  }

  /// Batch size used internally when collecting all documents for the
  /// print/report flow. This is independent of UI pagination.
  static const int _reportBatchSize = 200;

  @override
  Future<List<TripModel>> getBusTripsForReport(
    String busId,
    TripListFilter filter,
  ) {
    return _fetchAllFiltered(_trips().where('busId', isEqualTo: busId), filter);
  }

  @override
  Future<List<TripModel>> getDriverTripsForReport(
    String driverId,
    TripListFilter filter,
  ) {
    return _fetchAllFiltered(
        _trips().where('driverId', isEqualTo: driverId), filter);
  }

  @override
  Future<List<TripModel>> getFactoryTripsForReport(
    String factoryId,
    TripListFilter filter,
  ) {
    return _fetchAllFiltered(
        _trips().where('factoryId', isEqualTo: factoryId), filter);
  }

  /// Collects every document matching [base] + [filter] by repeatedly fetching
  /// [_reportBatchSize] documents and advancing with [startAfterDocument],
  /// stopping once a batch returns fewer than the batch size (no more matches).
  Future<List<TripModel>> _fetchAllFiltered(
    Query<Map<String, dynamic>> base,
    TripListFilter filter,
  ) async {
    final all = <TripModel>[];
    DocumentSnapshot<Map<String, dynamic>>? lastDocument;

    while (true) {
      Query<Map<String, dynamic>> query = _applyFilter(base, filter)
          .orderBy('createdAt', descending: true)
          .limit(_reportBatchSize);

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      final snapshot = await query.get();
      if (snapshot.docs.isEmpty) break;

      all.addAll(snapshot.docs.map((doc) => TripModel.fromFirestore(doc)));
      lastDocument = snapshot.docs.last;

      if (snapshot.docs.length < _reportBatchSize) break;
    }

    return all;
  }

  /// Applies the server-side [TripListFilter] to [query].
  ///
  /// Date filtering uses the always-present `createdAt` field (the same field
  /// used by [getMonthlyTrips]), and record-type filtering uses the stored
  /// `type` field.
  Query<Map<String, dynamic>> _applyFilter(
    Query<Map<String, dynamic>> query,
    TripListFilter filter,
  ) {
    Query<Map<String, dynamic>> result = query;

    if (filter.startDate != null) {
      result = result.where(
        'createdAt',
        isGreaterThanOrEqualTo: Timestamp.fromDate(filter.startDate!),
      );
    }
    if (filter.endDate != null) {
      result = result.where(
        'createdAt',
        isLessThan: Timestamp.fromDate(filter.endDate!),
      );
    }
    if (filter.recordType != null) {
      if (filter.recordType == TripType.nightOuting) {
        result = result.where('type', whereIn: [
          TripType.nightOuting,
          'sahra',
        ]);
      } else {
        result = result.where('type', isEqualTo: filter.recordType);
      }
    }

    return result;
  }
}