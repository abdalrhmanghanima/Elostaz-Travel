import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elostaz_travel/domain/factory/entity/factory_entity.dart';

class FactoryModel extends FactoryEntity {
  const FactoryModel({
    required super.id,
    required super.name,
    super.phone = '',
    super.details = '',
    super.tripsCount = 0,
    super.totalRevenue = 0,
    required super.createdAt,
  });

  factory FactoryModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? {};

    return FactoryModel(
      id: document.id,
      name: data['name']?.toString() ?? '',
      phone: data['phone']?.toString() ?? '',
      details: data['details']?.toString() ?? '',
      tripsCount: (data['tripsCount'] as num?)?.toInt() ?? 0,
      totalRevenue: (data['totalRevenue'] as num?)?.toDouble() ?? 0.0,
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'phone': phone,
      'details': details,
      'tripsCount': tripsCount,
      'totalRevenue': totalRevenue,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
