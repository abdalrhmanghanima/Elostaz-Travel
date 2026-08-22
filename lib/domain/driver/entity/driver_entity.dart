class DriverEntity {
  final String id;
  final String name;
  final String phone;
  final int tripsCount;
  final double totalRevenue;
  final String? idCardImageUrl;
  final String? licenseImageUrl;

  const DriverEntity({
    required this.id,
    required this.name,
    required this.phone,
    required this.tripsCount,
    required this.totalRevenue,
    this.idCardImageUrl,
    this.licenseImageUrl,
  });

  DriverEntity copyWith({
    String? id,
    String? name,
    String? phone,
    int? tripsCount,
    double? totalRevenue,
    String? idCardImageUrl,
    String? licenseImageUrl,
  }) {
    return DriverEntity(
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