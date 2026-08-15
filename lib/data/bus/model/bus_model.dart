import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elostaz_travel/domain/bus/entity/bus_entity.dart';

class BusModel extends BusEntity {
  const BusModel({
    required super.id,
    required super.busName,
    required super.plateNumber,
    required super.brand,
    required super.modelYear,
    required super.chassisNumber,
    required super.engineNumber,
    required super.passengerCount,
    required super.vehicleType,
    required super.licenseExpiryDate,
    super.licenseImageUrl,
    super.busImageUrl,
    required super.specialConditions,
    required super.insuranceType,
  });

  factory BusModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> document,
      ) {
    final data = document.data()!;

    return BusModel(
      id: document.id,
      busName: data['busName'] ?? '',
      plateNumber: data['plateNumber'] ?? '',
      brand: data['brand'] ?? '',
      modelYear: data['modelYear'] ?? 0,
      chassisNumber: data['chassisNumber'] ?? '',
      engineNumber: data['engineNumber'] ?? '',
      passengerCount: data['passengerCount'] ?? 0,
      vehicleType: data['vehicleType'] ?? '',
      licenseExpiryDate:
      (data['licenseExpiryDate'] as Timestamp).toDate(),
      licenseImageUrl: data['licenseImageUrl'],
      busImageUrl: data['busImageUrl'],
      specialConditions: data['specialConditions'] ?? '',
      insuranceType: data['insuranceType'] ?? 'غير مؤمنة',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'busName': busName,
      'plateNumber': plateNumber,
      'brand': brand,
      'modelYear': modelYear,
      'chassisNumber': chassisNumber,
      'engineNumber': engineNumber,
      'passengerCount': passengerCount,
      'vehicleType': vehicleType,
      'licenseExpiryDate': Timestamp.fromDate(licenseExpiryDate),
      'licenseImageUrl': licenseImageUrl,
      'busImageUrl': busImageUrl,
      'specialConditions': specialConditions,
      'insuranceType': insuranceType,
    };
  }
}