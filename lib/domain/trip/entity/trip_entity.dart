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

class TripType {
  static const String trip = 'trip';
  static const String nightOuting = 'night_outing';
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
  final double expenses;
  final double? driverWage;
  final String? expenseDetails;
  final String? factoryId;
  final String? factoryName;
  final String? departureTime;
  final String type; // 'trip' or 'night_outing'
  final DateTime createdAt;
  final DateTime? tripDate; // Optional user-selected operational date

  // Legacy fields for backward compatibility
  final bool isNightShift;
  final List<TripExpenseItem> expenseItems;
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
    this.details = '',
    this.revenue = 0.0,
    this.expenses = 0.0,
    this.driverWage,
    this.expenseDetails,
    this.factoryId,
    this.factoryName,
    this.departureTime,
    this.type = TripType.trip,
    required this.createdAt,
    this.tripDate,
    this.isNightShift = false,
    this.expenseItems = const [],
    this.sahraDetails,
    this.sahraDriverId,
    this.sahraDriverName,
    this.sahraRevenue,
    this.sahraExpense,
    this.sahraExpenseDetails,
  });

  /// Primary source of truth for record classification
  bool get isNightOuting =>
      type == TripType.nightOuting ||
      type == 'sahra' ||
      isNightShift ||
      hasLegacySahra;

  bool get isTrip => !isNightOuting;

  String get typeLabel => isNightOuting ? 'سهرة' : 'رحلة';

  double get netRevenue => revenue - expenses;

  /// Returns the effective date (user-entered tripDate if available, else createdAt).
  DateTime get effectiveDate => tripDate ?? createdAt;

  /// Whether a specific trip date was explicitly chosen by the user.
  bool get hasExplicitDate => tripDate != null;

  bool get hasLegacySahra =>
      (sahraDetails != null && sahraDetails!.trim().isNotEmpty) ||
      (sahraDriverName != null && sahraDriverName!.trim().isNotEmpty) ||
      (sahraRevenue != null && sahraRevenue! > 0) ||
      (sahraExpense != null && sahraExpense! > 0);

  bool get hasSahra => isNightOuting || hasLegacySahra;

  TripEntity copyWith({
    String? id,
    String? driverId,
    String? driverName,
    String? busId,
    String? busName,
    String? plateNumber,
    String? details,
    double? revenue,
    double? expenses,
    double? driverWage,
    bool clearDriverWage = false,
    String? expenseDetails,
    String? factoryId,
    String? factoryName,
    String? departureTime,
    String? type,
    DateTime? createdAt,
    DateTime? tripDate,
    bool? isNightShift,
    List<TripExpenseItem>? expenseItems,
    String? sahraDetails,
    String? sahraDriverId,
    String? sahraDriverName,
    double? sahraRevenue,
    double? sahraExpense,
    String? sahraExpenseDetails,
  }) {
    return TripEntity(
      id: id ?? this.id,
      driverId: driverId ?? this.driverId,
      driverName: driverName ?? this.driverName,
      busId: busId ?? this.busId,
      busName: busName ?? this.busName,
      plateNumber: plateNumber ?? this.plateNumber,
      details: details ?? this.details,
      revenue: revenue ?? this.revenue,
      expenses: expenses ?? this.expenses,
      driverWage: clearDriverWage ? null : (driverWage ?? this.driverWage),
      expenseDetails: expenseDetails ?? this.expenseDetails,
      factoryId: factoryId ?? this.factoryId,
      factoryName: factoryName ?? this.factoryName,
      departureTime: departureTime ?? this.departureTime,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      tripDate: tripDate ?? this.tripDate,
      isNightShift: isNightShift ?? this.isNightShift,
      expenseItems: expenseItems ?? this.expenseItems,
      sahraDetails: sahraDetails ?? this.sahraDetails,
      sahraDriverId: sahraDriverId ?? this.sahraDriverId,
      sahraDriverName: sahraDriverName ?? this.sahraDriverName,
      sahraRevenue: sahraRevenue ?? this.sahraRevenue,
      sahraExpense: sahraExpense ?? this.sahraExpense,
      sahraExpenseDetails: sahraExpenseDetails ?? this.sahraExpenseDetails,
    );
  }
}