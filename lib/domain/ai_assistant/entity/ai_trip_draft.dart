class AiTripDraft {
  final String? busName;
  final String? plateNumber;
  final String? driverName;
  final String? factoryName;
  final double? revenue;
  final double? driverWage;
  final DateTime? tripDate;
  final String? departureTime;
  final String? type;
  final String? details;
  final double? expenses;
  final String? expenseDetails;

  const AiTripDraft({
    this.busName,
    this.plateNumber,
    this.driverName,
    this.factoryName,
    this.revenue,
    this.driverWage,
    this.tripDate,
    this.departureTime,
    this.type,
    this.details,
    this.expenses,
    this.expenseDetails,
  });

  AiTripDraft copyWith({
    String? busName,
    String? plateNumber,
    String? driverName,
    String? factoryName,
    double? revenue,
    double? driverWage,
    DateTime? tripDate,
    String? departureTime,
    String? type,
    String? details,
    double? expenses,
    String? expenseDetails,
  }) {
    return AiTripDraft(
      busName: busName ?? this.busName,
      plateNumber: plateNumber ?? this.plateNumber,
      driverName: driverName ?? this.driverName,
      factoryName: factoryName ?? this.factoryName,
      revenue: revenue ?? this.revenue,
      driverWage: driverWage ?? this.driverWage,
      tripDate: tripDate ?? this.tripDate,
      departureTime: departureTime ?? this.departureTime,
      type: type ?? this.type,
      details: details ?? this.details,
      expenses: expenses ?? this.expenses,
      expenseDetails: expenseDetails ?? this.expenseDetails,
    );
  }

  AiTripDraft merge(AiTripDraft other) {
    return AiTripDraft(
      busName: other.busName ?? busName,
      plateNumber: other.plateNumber ?? plateNumber,
      driverName: other.driverName ?? driverName,
      factoryName: other.factoryName ?? factoryName,
      revenue: other.revenue ?? revenue,
      driverWage: other.driverWage ?? driverWage,
      tripDate: other.tripDate ?? tripDate,
      departureTime: other.departureTime ?? departureTime,
      type: other.type ?? type,
      details: other.details ?? details,
      expenses: other.expenses ?? expenses,
      expenseDetails: other.expenseDetails ?? expenseDetails,
    );
  }

  List<String> get missingRequiredFields {
    final missing = <String>[];
    if (busName == null || busName!.isEmpty) missing.add('الأتوبيس');
    if (driverName == null || driverName!.isEmpty) missing.add('السواق');
    return missing;
  }

  List<String> get missingOptionalFields {
    final missing = <String>[];
    if (revenue == null) missing.add('الإيراد');
    if (driverWage == null) missing.add('أجر السواق');
    if (tripDate == null) missing.add('تاريخ الرحلة');
    if (departureTime == null || departureTime!.isEmpty) {
      missing.add('وقت المغادرة');
    }
    return missing;
  }

  bool get hasAllRequiredFields => missingRequiredFields.isEmpty;

  bool get isEmpty =>
      busName == null &&
      plateNumber == null &&
      driverName == null &&
      factoryName == null &&
      revenue == null &&
      driverWage == null &&
      tripDate == null &&
      departureTime == null &&
      (details == null || details!.isEmpty) &&
      expenses == null &&
      (expenseDetails == null || expenseDetails!.isEmpty);
}
