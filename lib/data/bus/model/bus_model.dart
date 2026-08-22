import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elostaz_travel/domain/bus/entity/bus_entity.dart';

class BusModel extends BusEntity {
  const BusModel({
    required super.id,
    required super.busName,
    required super.plateNumber,
    required super.brand,
    super.model = '',
    super.manufacturingYear,
    super.modelYear = 0,
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
    final data = document.data() ?? {};

    final rawMfgYear = data['manufacturingYear'];
    final rawModelYear = data['modelYear'];
    final int? mfgYear = rawMfgYear is num
        ? rawMfgYear.toInt()
        : int.tryParse(rawMfgYear?.toString() ?? '') ??
            (rawModelYear is num
                ? rawModelYear.toInt()
                : int.tryParse(rawModelYear?.toString() ?? ''));

    final int mYear = (rawModelYear is num)
        ? rawModelYear.toInt()
        : (int.tryParse(rawModelYear?.toString() ?? '') ?? mfgYear ?? 0);

    return BusModel(
      id: document.id,
      busName: data['busName'] ?? '',
      plateNumber: data['plateNumber'] ?? '',
      brand: data['brand'] ?? '',
      model: data['model']?.toString() ?? '',
      manufacturingYear: mfgYear,
      modelYear: mYear,
      chassisNumber: data['chassisNumber'] ?? '',
      engineNumber: data['engineNumber'] ?? '',
      passengerCount: data['passengerCount'] ?? 0,
      vehicleType: data['vehicleType'] ?? '',
      licenseExpiryDate: data['licenseExpiryDate'] is Timestamp
          ? (data['licenseExpiryDate'] as Timestamp).toDate()
          : DateTime.now(),
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
      'model': model,
      if (manufacturingYear != null) 'manufacturingYear': manufacturingYear,
      'modelYear': manufacturingYear ?? modelYear,
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