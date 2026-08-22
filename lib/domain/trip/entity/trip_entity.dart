class TripExpenseItem {
  final String title;
  final double amount;

  const TripExpenseItem({
    required this.title,
    required this.amount,
  });

  factory TripExpenseItem.fromMap(Map<String, dynamic> map) {
    return TripExpenseItem(
      title: map['title']?.toString() ?? '',
      amount: (map['amount'] as num?)?.toDouble() ??
          double.tryParse(map['amount']?.toString() ?? '') ??
          0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'amount': amount,
    };
  }
}

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
  final String? expenseDetails;
  final String? factoryId;
  final String? factoryName;
  final bool isNightShift;
  final List<TripExpenseItem> expenseItems;

  // Dedicated optional Night Shift ("سهرة") fields
  final String? sahraDetails;
  final String? sahraDriverId;
  final String? sahraDriverName;
  final double? sahraRevenue;
  final double? sahraExpense;
  final String? sahraExpenseDetails;

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
    this.expenseDetails,
    this.factoryId,
    this.factoryName,
    this.isNightShift = false,
    this.expenseItems = const [],
    this.sahraDetails,
    this.sahraDriverId,
    this.sahraDriverName,
    this.sahraRevenue,
    this.sahraExpense,
    this.sahraExpenseDetails,
  });

  bool get hasSahra =>
      isNightShift ||
      (sahraDetails != null && sahraDetails!.trim().isNotEmpty) ||
      (sahraDriverName != null && sahraDriverName!.trim().isNotEmpty) ||
      (sahraRevenue != null && sahraRevenue! > 0) ||
      (sahraExpense != null && sahraExpense! > 0);
}