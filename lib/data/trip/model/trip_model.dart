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
    required super.details,
    required super.revenue,
    required super.createdAt,
    required super.expenses,
    super.expenseDetails,
    super.factoryId,
    super.factoryName,
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

    return TripModel(
      id: document.id,
      driverId: data['driverId']?.toString() ?? '',
      driverName: data['driverName']?.toString() ?? '',
      busId: data['busId']?.toString() ?? '',
      busName: data['busName']?.toString() ?? '',
      plateNumber: data['plateNumber']?.toString() ?? '',
      details: data['details']?.toString() ?? '',
      revenue: double.tryParse(
            data['revenue']?.toString() ?? '',
          ) ??
          0.0,
      expenses: (data['expenses'] as num?)?.toDouble() ??
          double.tryParse(data['expenses']?.toString() ?? '') ??
          0.0,
      expenseDetails: data['expenseDetails']?.toString(),
      factoryId: data['factoryId'] as String?,
      factoryName: data['factoryName'] as String?,
      isNightShift: data['isNightShift'] == true,
      expenseItems: items,
      sahraDetails: data['sahraDetails']?.toString(),
      sahraDriverId: data['sahraDriverId']?.toString(),
      sahraDriverName: data['sahraDriverName']?.toString(),
      sahraRevenue: (data['sahraRevenue'] as num?)?.toDouble() ??
          double.tryParse(data['sahraRevenue']?.toString() ?? ''),
      sahraExpense: (data['sahraExpense'] as num?)?.toDouble() ??
          double.tryParse(data['sahraExpense']?.toString() ?? ''),
      sahraExpenseDetails: data['sahraExpenseDetails']?.toString(),
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
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
      createdAt: entity.createdAt,
      expenses: entity.expenses,
      expenseDetails: entity.expenseDetails,
      factoryId: entity.factoryId,
      factoryName: entity.factoryName,
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
      if (expenseDetails != null && expenseDetails!.isNotEmpty)
        'expenseDetails': expenseDetails,
      if (factoryId != null && factoryId!.isNotEmpty) 'factoryId': factoryId,
      if (factoryName != null && factoryName!.isNotEmpty)
        'factoryName': factoryName,
      'isNightShift': isNightShift,
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
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}