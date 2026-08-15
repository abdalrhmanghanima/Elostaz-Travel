class BusEntity {
  final String? id;
  final String busName;
  final String plateNumber;
  final String brand;
  final int modelYear;
  final String chassisNumber;
  final String engineNumber;
  final int passengerCount;
  final String vehicleType;
  final DateTime licenseExpiryDate;
  final String? licenseImageUrl;
  final String? busImageUrl;
  final String specialConditions;
  final String insuranceType;

  const BusEntity({
    required this.id,
    required this.busName,
    required this.plateNumber,
    required this.brand,
    required this.modelYear,
    required this.chassisNumber,
    required this.engineNumber,
    required this.passengerCount,
    required this.vehicleType,
    required this.licenseExpiryDate,
    this.licenseImageUrl,
    this.busImageUrl,
    required this.specialConditions,
    required this.insuranceType,
  });
}