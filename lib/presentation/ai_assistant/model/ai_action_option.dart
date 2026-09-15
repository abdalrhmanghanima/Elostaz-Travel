import 'package:flutter/material.dart';
import 'package:elostaz_travel/presentation/ai_assistant/model/ai_guided_field.dart';

enum AiActionId {
  addBus,
  addDriver,
  addFactory,
  addTrip,
  addFactoryTrip,
  queryTrips,
  queryBuses,
  queryDrivers,
  queryFactories,
}

enum AiActionCategory {
  add,
  query;

  String get label => switch (this) {
        AiActionCategory.add => 'إضافة',
        AiActionCategory.query => 'استعلام',
      };
}

class AiActionOption {
  final AiActionId id;
  final String title;
  final String description;
  final IconData icon;
  final AiActionCategory category;

  /// Required fields shown/collected in the guided create flow.
  final List<AiGuidedField> requiredFields;

  /// Optional fields collected with an explicit yes/no step.
  final List<AiGuidedField> optionalFields;

  const AiActionOption({
    required this.id,
    required this.title,
    this.description = '',
    required this.icon,
    this.category = AiActionCategory.add,
    this.requiredFields = const [],
    this.optionalFields = const [],
  });

  bool get isCreate => category == AiActionCategory.add;
  bool get isQuery => category == AiActionCategory.query;
}

const List<AiActionOption> availableAiActions = [
  AiActionOption(
    id: AiActionId.addTrip,
    title: 'إضافة رحلة أتوبيس',
    description: 'سجّل رحلة: الأتوبيس + السائق + بيانات اختيارية',
    icon: Icons.add_circle_outline_rounded,
    category: AiActionCategory.add,
  ),
  AiActionOption(
    id: AiActionId.addFactoryTrip,
    title: 'إضافة رحلة مصنع',
    description: 'سجّل رحلة أو سهرة لمصنع: تحدد الأتوبيس والسائق',
    icon: Icons.handshake_outlined,
    category: AiActionCategory.add,
  ),
  AiActionOption(
    id: AiActionId.addBus,
    title: 'إضافة أتوبيس',
    description: 'سجّل أتوبيس جديد ببياناته كاملة',
    icon: Icons.directions_bus_outlined,
    category: AiActionCategory.add,
    requiredFields: [
      AiGuidedField.busName,
      AiGuidedField.plateNumber,
      AiGuidedField.vehicleType,
      AiGuidedField.brand,
      AiGuidedField.manufacturingYear,
      AiGuidedField.chassisNumber,
      AiGuidedField.engineNumber,
      AiGuidedField.passengerCount,
      AiGuidedField.licenseExpiryDate,
      AiGuidedField.specialConditions,
      AiGuidedField.insuranceType,
    ],
    optionalFields: [
      AiGuidedField.model,
    ],
  ),
  AiActionOption(
    id: AiActionId.addDriver,
    title: 'إضافة سائق',
    description: 'سجّل سائق جديد باسمه ورقم تليفونه',
    icon: Icons.person_add_alt_1_rounded,
    category: AiActionCategory.add,
    requiredFields: [
      AiGuidedField.driverName,
    ],
    optionalFields: [
      AiGuidedField.driverPhone,
    ],
  ),
  AiActionOption(
    id: AiActionId.addFactory,
    title: 'إضافة مصنع',
    description: 'سجّل مصنع تعاقد جديد',
    icon: Icons.factory_outlined,
    category: AiActionCategory.add,
    requiredFields: [
      AiGuidedField.factoryName,
    ],
    optionalFields: [
      AiGuidedField.factoryDetails,
    ],
  ),
  AiActionOption(
    id: AiActionId.queryTrips,
    title: 'الاستعلام عن الرحلات',
    description: 'شوف عدد الرحلات والإيرادات والمصروفات',
    icon: Icons.receipt_long_outlined,
    category: AiActionCategory.query,
  ),
  AiActionOption(
    id: AiActionId.queryBuses,
    title: 'الاستعلام عن الأتوبيسات',
    description: 'قائمة الأتوبيسات ورحلاتها',
    icon: Icons.directions_bus_filled_rounded,
    category: AiActionCategory.query,
  ),
  AiActionOption(
    id: AiActionId.queryDrivers,
    title: 'الاستعلام عن السائقين',
    description: 'قائمة السائقين وأجورهم',
    icon: Icons.groups_outlined,
    category: AiActionCategory.query,
  ),
  AiActionOption(
    id: AiActionId.queryFactories,
    title: 'الاستعلام عن المصانع',
    description: 'قائمة المصانع وإيراداتها',
    icon: Icons.apartment_rounded,
    category: AiActionCategory.query,
  ),
];