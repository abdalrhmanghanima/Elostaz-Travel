import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elostaz_travel/domain/trip/entity/trip_entity.dart';

class TripModel extends TripEntity {
  const TripModel({
    required super.id,
    required super.driverId,
    required super.driverName,
    required super.busId,
    required super.busName,
    required super.plateNumber,
    required super.details,
    required super.revenue,
    required super.createdAt,
  });

  factory TripModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> document,
      ) {
    final data = document.data() ?? {};

    return TripModel(
      id: document.id,
      driverId: data['driverId'] ?? '',
      driverName: data['driverName'] ?? '',
      busId: data['busId'] ?? '',
      busName: data['busName'] ?? '',
      plateNumber: data['plateNumber'] ?? '',
      details: data['details'] ?? '',
      revenue: double.tryParse(
        data['revenue']?.toString() ?? '',
      ) ?? 0,
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'driverId': driverId,
      'driverName': driverName,
      'busId': busId,
      'busName': busName,
      'plateNumber': plateNumber,
      'details': details,
      'revenue': revenue,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}