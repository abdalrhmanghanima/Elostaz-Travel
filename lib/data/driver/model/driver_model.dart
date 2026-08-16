import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elostaz_travel/domain/driver/entity/driver_entity.dart';

class DriverModel extends DriverEntity {
  const DriverModel({
    required super.id,
    required super.name,
    required super.phone,
    required super.tripsCount,
    required super.totalRevenue,
  });

  factory DriverModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> document,
      ) {
    final data = document.data() ?? {};

    return DriverModel(
      id: document.id,
      name: data['name'] ?? '',
      phone: data['phone'] ?? '',
      tripsCount: (data['tripsCount'] ?? 0) as int,
      totalRevenue:
      (data['totalRevenue'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'phone': phone,
      'tripsCount': tripsCount,
      'totalRevenue': totalRevenue,
    };
  }
}