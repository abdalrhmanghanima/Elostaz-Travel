import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elostaz_travel/domain/driver/entity/driver_advance_entity.dart';

class DriverAdvanceModel extends DriverAdvanceEntity {
  const DriverAdvanceModel({
    required super.id,
    required super.driverId,
    required super.amount,
    required super.date,
    required super.note,
    required super.status,
    required super.createdAt,
    super.paidAt,
  });

  factory DriverAdvanceModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
    String driverId,
  ) {
    final data = document.data() ?? {};

    DateTime parsedDate = DateTime.now();
    if (data['date'] != null) {
      if (data['date'] is Timestamp) {
        parsedDate = (data['date'] as Timestamp).toDate();
      } else if (data['date'] is String) {
        parsedDate = DateTime.tryParse(data['date']) ?? DateTime.now();
      }
    }

    DateTime parsedCreatedAt = DateTime.now();
    if (data['createdAt'] != null) {
      if (data['createdAt'] is Timestamp) {
        parsedCreatedAt = (data['createdAt'] as Timestamp).toDate();
      } else if (data['createdAt'] is String) {
        parsedCreatedAt = DateTime.tryParse(data['createdAt']) ?? DateTime.now();
      }
    }

    DateTime? parsedPaidAt;
    if (data['paidAt'] != null) {
      if (data['paidAt'] is Timestamp) {
        parsedPaidAt = (data['paidAt'] as Timestamp).toDate();
      } else if (data['paidAt'] is String) {
        parsedPaidAt = DateTime.tryParse(data['paidAt']);
      }
    }

    return DriverAdvanceModel(
      id: document.id,
      driverId: data['driverId'] as String? ?? driverId,
      amount: (data['amount'] ?? 0).toDouble(),
      date: parsedDate,
      note: data['note'] as String? ?? '',
      status: data['status'] as String? ?? 'active',
      createdAt: parsedCreatedAt,
      paidAt: parsedPaidAt,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'driverId': driverId,
      'amount': amount,
      'date': Timestamp.fromDate(date),
      'note': note,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      if (paidAt != null) 'paidAt': Timestamp.fromDate(paidAt!),
    };
  }
}
