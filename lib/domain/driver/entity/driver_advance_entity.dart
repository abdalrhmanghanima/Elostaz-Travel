class DriverAdvanceEntity {
  final String id;
  final String driverId;
  final double amount;
  final DateTime date;
  final String note;
  final String status; // 'active' (مستحقة) or 'paid' (تم السداد)
  final DateTime createdAt;
  final DateTime? paidAt;

  const DriverAdvanceEntity({
    required this.id,
    required this.driverId,
    required this.amount,
    required this.date,
    required this.note,
    required this.status,
    required this.createdAt,
    this.paidAt,
  });

  bool get isPaid => status == 'paid';
  bool get isActive => status == 'active';
}
