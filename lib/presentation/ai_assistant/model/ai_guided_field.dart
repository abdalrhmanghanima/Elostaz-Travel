import 'package:flutter/material.dart';

/// Field specs that drive the guided creation flows for non-trip entities
/// (bus / driver / factory). Mirrors the app's own forms.
enum AiGuidedField {
  busName('اسم الأتوبيس', icon: Icons.directions_bus_outlined, isText: true),
  plateNumber('رقم اللوحة', icon: Icons.confirmation_number_outlined, isText: true),
  vehicleType('نوع العربية',
      icon: Icons.category_outlined,
      isText: true,
      hint: 'ميكروباص - ميني باص - اتوبيس رحلات'),
  brand('الماركة',
      icon: Icons.car_repair_outlined, isText: true, hint: 'تويوتا - مرسيدس'),
  model('الموديل', icon: Icons.label_outline_rounded, isText: true, optional: true),
  manufacturingYear('سنة الصنع',
      icon: Icons.event_note_outlined, isNumeric: true, isYear: true),
  chassisNumber('رقم الشاسية', icon: Icons.qr_code_2_rounded, isText: true),
  engineNumber('رقم الموتور', icon: Icons.settings_outlined, isText: true),
  passengerCount('عدد الركاب',
      icon: Icons.event_seat_outlined, isNumeric: true),
  licenseExpiryDate('تاريخ انتهاء الترخيص',
      icon: Icons.badge_outlined, isDate: true),
  specialConditions('اشتراطات خاصة',
      icon: Icons.warning_amber_rounded,
      isText: true,
      hint: 'محظورة بيع - السيارة خالصة'),
  insuranceType('تأمين السيارة',
      icon: Icons.verified_user_outlined, isText: true, hint: 'مؤمنة - غير مؤمنة'),
  prohibitedBankName('اسم البنك المحظور',
      icon: Icons.account_balance_outlined, isText: true),
  driverName('اسم السائق', icon: Icons.person_outline_rounded, isText: true),
  driverPhone('رقم تليفون السائق',
      icon: Icons.phone_outlined, isText: true, optional: true),
  factoryName('اسم المصنع', icon: Icons.factory_outlined, isText: true),
  factoryDetails('عنوان / ملاحظات المصنع',
      icon: Icons.notes_rounded, isText: true, optional: true);

  const AiGuidedField(
    this.label, {
    required this.icon,
    this.isText = false,
    this.isNumeric = false,
    this.isYear = false,
    this.isDate = false,
    this.optional = false,
    this.hint,
  });

  final String label;
  final IconData icon;
  final bool isText;
  final bool isNumeric;
  final bool isYear;
  final bool isDate;
  final bool optional;
  final String? hint;

  static AiGuidedField? byName(String name) {
    for (final field in AiGuidedField.values) {
      if (field.name == name) return field;
    }
    return null;
  }
}