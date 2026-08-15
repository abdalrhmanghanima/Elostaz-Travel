class DriverEntity {
  final String id;
  final String name;
  final String phone;
  final int tripsCount;
  final double totalRevenue;

  const DriverEntity({
    required this.id,
    required this.name,
    required this.phone,
    required this.tripsCount,
    required this.totalRevenue,
  });
}