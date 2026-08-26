class BusEntity {
  final String? id;
  final String busName;
  final String plateNumber;
  final String brand;
  final String model;
  final int? manufacturingYear;
  final int modelYear;
  final String chassisNumber;
  final String engineNumber;
  final int passengerCount;
  final String vehicleType;
  final DateTime licenseExpiryDate;
  final String? licenseImageUrl;
  final String? busImageUrl;
  final String specialConditions;
  final String? prohibitedBankName;
  final String insuranceType;

  const BusEntity({
    required this.id,
    required this.busName,
    required this.plateNumber,
    required this.brand,
    this.model = '',
    this.manufacturingYear,
    this.modelYear = 0,
    required this.chassisNumber,
    required this.engineNumber,
    required this.passengerCount,
    required this.vehicleType,
    required this.licenseExpiryDate,
    this.licenseImageUrl,
    this.busImageUrl,
    required this.specialConditions,
    this.prohibitedBankName,
    required this.insuranceType,
  });

  BusEntity copyWith({
    String? id,
    String? busName,
    String? plateNumber,
    String? brand,
    String? model,
    int? manufacturingYear,
    int? modelYear,
    String? chassisNumber,
    String? engineNumber,
    int? passengerCount,
    String? vehicleType,
    DateTime? licenseExpiryDate,
    String? licenseImageUrl,
    String? busImageUrl,
    String? specialConditions,
    String? prohibitedBankName,
    String? insuranceType,
  }) {
    return BusEntity(
      id: id ?? this.id,
      busName: busName ?? this.busName,
      plateNumber: plateNumber ?? this.plateNumber,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      manufacturingYear: manufacturingYear ?? this.manufacturingYear,
      modelYear: modelYear ?? this.modelYear,
      chassisNumber: chassisNumber ?? this.chassisNumber,
      engineNumber: engineNumber ?? this.engineNumber,
      passengerCount: passengerCount ?? this.passengerCount,
      vehicleType: vehicleType ?? this.vehicleType,
      licenseExpiryDate: licenseExpiryDate ?? this.licenseExpiryDate,
      licenseImageUrl: licenseImageUrl ?? this.licenseImageUrl,
      busImageUrl: busImageUrl ?? this.busImageUrl,
      specialConditions: specialConditions ?? this.specialConditions,
      prohibitedBankName: prohibitedBankName ?? this.prohibitedBankName,
      insuranceType: insuranceType ?? this.insuranceType,
    );
  }
}