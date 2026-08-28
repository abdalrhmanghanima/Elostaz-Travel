import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elostaz_travel/domain/trip/entity/trip_entity.dart';

class TripModel extends TripEntity {
  const TripModel({
    required super.id,
    required super.driverId,
    required super.driverName,
    required super.busId,
    required super.busName,
    required super.plateNumber,
    super.details = '',
    super.revenue = 0.0,
    super.expenses = 0.0,
    super.expenseDetails,
    super.factoryId,
    super.factoryName,
    super.departureTime,
    super.type = TripType.trip,
    required super.createdAt,
    super.tripDate,
    super.isNightShift = false,
    super.expenseItems = const [],
    super.sahraDetails,
    super.sahraDriverId,
    super.sahraDriverName,
    super.sahraRevenue,
    super.sahraExpense,
    super.sahraExpenseDetails,
  });

  factory TripModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? {};

    final rawExpenses = data['expenseItems'];
    List<TripExpenseItem> items = [];
    if (rawExpenses is List) {
      items = rawExpenses
          .whereType<Map<String, dynamic>>()
          .map((item) => TripExpenseItem.fromMap(item))
          .toList();
    }

    // Resolution order for type:
    // 1. If explicit 'type' field exists, use it.
    // 2. Else if legacy isNightShift == true, use 'night_outing'.
    // 3. Otherwise, fallback to 'trip'.
    String recordType = TripType.trip;
    if (data['type'] != null && data['type'].toString().trim().isNotEmpty) {
      final rawType = data['type'].toString().trim();
      if (rawType == 'night_outing' || rawType == 'sahra') {
        recordType = TripType.nightOuting;
      } else {
        recordType = TripType.trip;
      }
    } else if (data['isNightShift'] == true) {
      recordType = TripType.nightOuting;
    }

    DateTime? parsedTripDate;
    if (data['tripDate'] is Timestamp) {
      parsedTripDate = (data['tripDate'] as Timestamp).toDate();
    } else if (data['tripDate'] is String && (data['tripDate'] as String).isNotEmpty) {
      parsedTripDate = DateTime.tryParse(data['tripDate']);
    }

    DateTime parsedCreatedAt = DateTime.now();
    if (data['createdAt'] is Timestamp) {
      parsedCreatedAt = (data['createdAt'] as Timestamp).toDate();
    } else if (data['createdAt'] is String && (data['createdAt'] as String).isNotEmpty) {
      parsedCreatedAt = DateTime.tryParse(data['createdAt']) ?? DateTime.now();
    }

    return TripModel(
      id: document.id,
      driverId: data['driverId']?.toString() ?? '',
      driverName: data['driverName']?.toString() ?? '',
      busId: data['busId']?.toString() ?? '',
      busName: data['busName']?.toString() ?? '',
      plateNumber: data['plateNumber']?.toString() ?? '',
      details: data['details']?.toString() ?? '',
      revenue: (data['revenue'] as num?)?.toDouble() ??
          double.tryParse(data['revenue']?.toString() ?? '') ??
          0.0,
      expenses: (data['expenses'] as num?)?.toDouble() ??
          double.tryParse(data['expenses']?.toString() ?? '') ??
          0.0,
      expenseDetails: data['expenseDetails']?.toString(),
      factoryId: data['factoryId'] as String?,
      factoryName: data['factoryName'] as String?,
      departureTime: data['departureTime']?.toString(),
      type: recordType,
      createdAt: parsedCreatedAt,
      tripDate: parsedTripDate,
      isNightShift: data['isNightShift'] == true || recordType == TripType.nightOuting,
      expenseItems: items,
      sahraDetails: data['sahraDetails']?.toString(),
      sahraDriverId: data['sahraDriverId']?.toString(),
      sahraDriverName: data['sahraDriverName']?.toString(),
      sahraRevenue: (data['sahraRevenue'] as num?)?.toDouble() ??
          double.tryParse(data['sahraRevenue']?.toString() ?? ''),
      sahraExpense: (data['sahraExpense'] as num?)?.toDouble() ??
          double.tryParse(data['sahraExpense']?.toString() ?? ''),
      sahraExpenseDetails: data['sahraExpenseDetails']?.toString(),
    );
  }

  factory TripModel.fromEntity(TripEntity entity) {
    return TripModel(
      id: entity.id,
      driverId: entity.driverId,
      driverName: entity.driverName,
      busId: entity.busId,
      busName: entity.busName,
      plateNumber: entity.plateNumber,
      details: entity.details,
      revenue: entity.revenue,
      expenses: entity.expenses,
      expenseDetails: entity.expenseDetails,
      factoryId: entity.factoryId,
      factoryName: entity.factoryName,
      departureTime: entity.departureTime,
      type: entity.type,
      createdAt: entity.createdAt,
      tripDate: entity.tripDate,
      isNightShift: entity.isNightShift,
      expenseItems: entity.expenseItems,
      sahraDetails: entity.sahraDetails,
      sahraDriverId: entity.sahraDriverId,
      sahraDriverName: entity.sahraDriverName,
      sahraRevenue: entity.sahraRevenue,
      sahraExpense: entity.sahraExpense,
      sahraExpenseDetails: entity.sahraExpenseDetails,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'driverId': driverId,
      'driverName': driverName,
      'busId': busId,
      'busName': busName,
      'plateNumber': plateNumber,
      'details': details,
      'revenue': revenue,
      'expenses': expenses,
      'type': type,
      'createdAt': Timestamp.fromDate(createdAt),
      if (tripDate != null) 'tripDate': Timestamp.fromDate(tripDate!),
      if (expenseDetails != null && expenseDetails!.isNotEmpty)
        'expenseDetails': expenseDetails,
      if (factoryId != null && factoryId!.isNotEmpty) 'factoryId': factoryId,
      if (factoryName != null && factoryName!.isNotEmpty)
        'factoryName': factoryName,
      if (departureTime != null && departureTime!.trim().isNotEmpty)
        'departureTime': departureTime!.trim(),
      'isNightShift': isNightShift || isNightOuting,
      if (expenseItems.isNotEmpty)
        'expenseItems': expenseItems.map((e) => e.toMap()).toList(),
      if (sahraDetails != null && sahraDetails!.isNotEmpty)
        'sahraDetails': sahraDetails,
      if (sahraDriverId != null && sahraDriverId!.isNotEmpty)
        'sahraDriverId': sahraDriverId,
      if (sahraDriverName != null && sahraDriverName!.isNotEmpty)
        'sahraDriverName': sahraDriverName,
      if (sahraRevenue != null) 'sahraRevenue': sahraRevenue,
      if (sahraExpense != null) 'sahraExpense': sahraExpense,
      if (sahraExpenseDetails != null && sahraExpenseDetails!.isNotEmpty)
        'sahraExpenseDetails': sahraExpenseDetails,
    };
  }
}