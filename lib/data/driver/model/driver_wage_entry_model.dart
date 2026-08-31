import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elostaz_travel/domain/driver/entity/driver_wage_entry_entity.dart';

class DriverWageEntryModel extends DriverWageEntryEntity {
  const DriverWageEntryModel({
    required super.id,
    required super.driverId,
    required super.amount,
    required super.date,
    required super.notes,
    required super.createdAt,
  });

  factory DriverWageEntryModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
    String driverId,
  ) {
    final data = document.data() ?? {};

    return DriverWageEntryModel(
      id: document.id,
      driverId: data['driverId'] as String? ?? driverId,
      amount: (data['amount'] as num?)?.toDouble() ?? 0,
      date: _parseDate(data['date']),
      notes: data['notes'] as String? ?? data['note'] as String? ?? '',
      createdAt: _parseDate(data['createdAt']),
    );
  }

  factory DriverWageEntryModel.fromEntity(DriverWageEntryEntity entity) {
    return DriverWageEntryModel(
      id: entity.id,
      driverId: entity.driverId,
      amount: entity.amount,
      date: entity.date,
      notes: entity.notes,
      createdAt: entity.createdAt,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'driverId': driverId,
      'amount': amount,
      'date': Timestamp.fromDate(date),
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  static DateTime _parseDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }
}
