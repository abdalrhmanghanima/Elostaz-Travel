class AiTripFieldSpec {
  final String key;
  final String label;
  final bool isRequired;

  const AiTripFieldSpec({
    required this.key,
    required this.label,
    this.isRequired = false,
  });
}

/// Field lists derived from the existing trip creation flow
/// (AddTripBottomSheet / AddFactoryTripBottomSheet).
/// The app only validates bus + driver as required; all money/date/time
/// fields are labelled (اختياري) and never block saving.
class AiTripFieldCatalog {
  static const List<AiTripFieldSpec> requiredFields = [
    AiTripFieldSpec(key: 'bus', label: '🚌 الأتوبيس', isRequired: true),
    AiTripFieldSpec(key: 'driver', label: '👨‍✈️ السائق', isRequired: true),
  ];

  static const List<AiTripFieldSpec> optionalFields = [
    AiTripFieldSpec(key: 'factory', label: '🏭 المصنع'),
    AiTripFieldSpec(key: 'date', label: '📅 تاريخ الرحلة'),
    AiTripFieldSpec(key: 'time', label: '🕐 وقت الرحلة'),
    AiTripFieldSpec(key: 'revenue', label: '💰 الإيراد'),
    AiTripFieldSpec(key: 'driverWage', label: '💵 أجر السائق'),
    AiTripFieldSpec(key: 'details', label: '📝 تفاصيل الرحلة'),
    AiTripFieldSpec(key: 'expenses', label: '💸 مصروف الرحلة'),
    AiTripFieldSpec(key: 'expenseDetails', label: '📋 تفاصيل المصروف'),
  ];
}