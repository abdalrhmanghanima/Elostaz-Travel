import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elostaz_travel/domain/driver/entity/driver_entity.dart';

class DriverModel extends DriverEntity {
  const DriverModel({
    required super.id,
    required super.name,
    required super.phone,
    required super.tripsCount,
    required super.totalRevenue,
    super.idCardImageUrl,
    super.licenseImageUrl,
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
      totalRevenue: (data['totalRevenue'] ?? 0).toDouble(),
      idCardImageUrl: data['idCardImageUrl'] as String?,
      licenseImageUrl: data['licenseImageUrl'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    final map = <String, dynamic>{
      'name': name,
      'phone': phone,
      'tripsCount': tripsCount,
      'totalRevenue': totalRevenue,
    };

    if (idCardImageUrl != null) {
      map['idCardImageUrl'] = idCardImageUrl;
    }
    if (licenseImageUrl != null) {
      map['licenseImageUrl'] = licenseImageUrl;
    }

    return map;
  }

  @override
  DriverModel copyWith({
    String? id,
    String? name,
    String? phone,
    int? tripsCount,
    double? totalRevenue,
    String? idCardImageUrl,
    String? licenseImageUrl,
  }) {
    return DriverModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      tripsCount: tripsCount ?? this.tripsCount,
      totalRevenue: totalRevenue ?? this.totalRevenue,
      idCardImageUrl: idCardImageUrl ?? this.idCardImageUrl,
      licenseImageUrl: licenseImageUrl ?? this.licenseImageUrl,
    );
  }
}