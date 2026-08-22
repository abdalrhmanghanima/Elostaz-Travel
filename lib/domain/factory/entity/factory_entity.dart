class FactoryEntity {
  final String id;
  final String name;
  final String phone;
  final String details;
  final int tripsCount;
  final double totalRevenue;
  final DateTime createdAt;

  const FactoryEntity({
    required this.id,
    required this.name,
    this.phone = '',
    this.details = '',
    this.tripsCount = 0,
    this.totalRevenue = 0,
    required this.createdAt,
  });
}
