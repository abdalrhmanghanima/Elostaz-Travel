class TripEntity {
  final String id;
  final String driverId;
  final String driverName;
  final String busId;
  final String busName;
  final String plateNumber;
  final String details;
  final double revenue;
  final DateTime createdAt;
  final double expenses;

  const TripEntity({
    required this.id,
    required this.driverId,
    required this.driverName,
    required this.busId,
    required this.busName,
    required this.plateNumber,
    required this.details,
    required this.revenue,
    required this.createdAt,
    required this.expenses,
  });
}