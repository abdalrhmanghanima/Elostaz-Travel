class DriverWageEntryEntity {
  final String id;
  final String driverId;
  final double amount;
  final DateTime date;
  final String notes;
  final DateTime createdAt;

  const DriverWageEntryEntity({
    required this.id,
    required this.driverId,
    required this.amount,
    required this.date,
    required this.notes,
    required this.createdAt,
  });
}
