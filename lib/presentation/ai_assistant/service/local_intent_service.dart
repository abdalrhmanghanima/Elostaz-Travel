import 'package:elostaz_travel/presentation/ai_assistant/model/ai_action_option.dart';

class LocalIntentService {
  static String normalize(String text) {
    return text
        .replaceAll(RegExp(r'[\u0610-\u061A\u06D6-\u06ED]'), '')
        .replaceAll(RegExp(r'[أإآ]'), 'ا')
        .replaceAll('ؤ', 'و')
        .replaceAll('ئ', 'ي')
        .replaceAll('ة', 'ه')
        .replaceAll('ى', 'ي')
        .replaceAll(RegExp(r'[؟?]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .toLowerCase()
        .trim();
  }

  static bool isHelpRequest(String text) {
    final t = normalize(text);
    return t.contains('اعمل ايه') ||
        t.contains('تعمل ايه') ||
        t.contains('تقدر تعمل') ||
        t.contains('ايه اللي') ||
        t.contains('تعمله') ||
        t.contains('بتعمل ايه');
  }

  /// Detects requests to re-shown the action catalog ("اظهرلي الخيارات",
  /// "وريني الاكشنز", "show options", "what can you do"). Checked BEFORE
  /// query/create detection so it can never be swallowed by an add/query.
  static bool isShowOptionsRequest(String text) {
    final t = normalize(text);
    if (t.isEmpty) return false;
    return _hasAny(t, const [
      'وريني الخيارات',
      'اريني الخيارات',
      'اظهرلي الخيارات',
      'اظهر لي الخيارات',
      'عايز الخيارات',
      'عايز اشوف الخيارات',
      'اعرض الخيارات',
      'هاتلي الخيارات',
      'وريني الاكشنز',
      'اظهر الاكشنز',
      'اظهرلي الاكشنز',
      'وريني الاوامر',
      'اظهر الاوامر',
      'الخيارات المتاحه',
      'الخيارات',
      'الاكشنز',
      'الاكشن',
      'الاوامر',
      'show options',
      'show the options',
      'show me options',
      'show me the options',
      'show actions',
      'show the actions',
      'what can you do',
      'what are my options',
      'options list',
      'action list',
    ]);
  }

  static bool isIntentChange(String text) {
    final t = normalize(text);
    return t.contains('سيب الرحله') ||
        t.contains('سيبها') ||
        t.contains('حاجه تانيه') ||
        t.contains('غير راي') ||
        t.contains('لغي الرحله');
  }

  /// Editing or deleting is intentionally off-limits for the AI assistant.
  /// It only creates new data and answers read-only queries.
  static bool isForbiddenMutation(String text) {
    final t = normalize(text);
    return RegExp(
            r'عدل|تعديل|حذف|امسح|امحي|اشيل|شيل|غير|حور|حدث|update|delete|edit')
        .hasMatch(t);
  }

  static bool _hasAny(String t, List<String> phrases) {
    for (final p in phrases) {
      if (t.contains(p)) return true;
    }
    return false;
  }

  /// Maps free text to the specific "add" action the user wants, before any
  /// generic add-trip detection can swallow entity-related phrases.
  static AiActionId? detectAddAction(String text) {
    final t = normalize(text);

    if (_hasAny(t, [
      'اضيف رحله لمصنع',
      'اسجل سهره لمصنع',
      'اضيف سهره لمصنع',
      'رحله مصنع',
      'سهره مصنع',
      'رحله للمصنع',
      'سهره للمصنع',
      'رحله في مصنع',
      'سهره في مصنع',
      'اضيف رحله في مصنع',
      'اسجل رحله في مصنع',
      'سجل رحله في مصنع',
      'ضيف رحله في مصنع',
      'ضيف سهره في مصنع',
      'اضيف سهره في مصنع',
      'اسجل سهره في مصنع',
      'سجل سهره في مصنع',
    ])) {
      return AiActionId.addFactoryTrip;
    }

    if (_hasAny(t, [
      'اضيف رحله',
      'اسجل رحله',
      'سجل رحله',
      'رحله جديده',
      'اضيف رحله اتوبيس',
      'رحله اتوبيس',
      'سجل مشوار',
      'اضيف مشوار',
      'مشوار جديد',
      'اعمل رحله',
      'ضيف رحله',
      'ضيف لي رحله',
      'ضيفلي رحله',
      'اضيف سهره',
      'اسجل سهره',
      'سجل سهره',
      'اعمل سهره',
      'ضيف سهره',
      'ضيف لي سهره',
      'ضيفلي سهره',
      'اعمل مشوار',
      'ضيف مشوار',
      'ضيفلي مشوار',
    ])) {
      return AiActionId.addTrip;
    }

    final hasTripNoun = _hasAny(t, const ['رحله', 'سهره', 'سحور', 'مشوار']);
    const busTypeWords = [
      'ميكروباص',
      'ميكروبص',
      'ميني باص',
      'باص',
      'اتوبيس',
      'اوتوبيس',
      'عربه',
      'عربيه',
    ];
    if (hasTripNoun && _hasAny(t, busTypeWords)) {
      return AiActionId.addTrip;
    }

    if (_hasAny(t, [
      'اضيف عربه',
      'اضيف عربيه',
      'اضيف اوتوبيس',
      'اضيف اتوبيس',
      'اسجل عربه',
      'اسجل عربيه',
      'اسجل اتوبيس',
      'اسجل اوتوبيس',
      'سجل عربه',
      'سجل عربيه',
      'عربيه جديده',
      'عربة جديده',
      'اوتوبيس جديد',
      'اتوبيس جديد',
      'اضيف ميكروباص',
      'اضيف ميكروبص',
      'ميكروباص جديد',
      'ميكروباص',
      'اضيف ميني باص',
      'ميني باص',
      'اضيف باص',
      'باص جديد',
    ])) {
      return AiActionId.addBus;
    }

    if (_hasAny(t, [
      'اضيف سواق',
      'اسجل سواق',
      'سواق جديد',
      'سايق جديد',
      'سائق جديد',
      'اضيف سايق',
      'اضيف سائق',
      'سجل سواق',
      'سجل سائق',
      'سجل سايق',
    ])) {
      return AiActionId.addDriver;
    }

    if (_hasAny(t, [
      'اضيف مصنع',
      'اسجل مصنع',
      'مصنع جديد',
      'اضيف شركه',
      'سجل مصنع',
    ])) {
      return AiActionId.addFactory;
    }

    return null;
  }

  /// Maps free text to a read-only query action.
  static AiActionId? detectQueryAction(String text) {
    final t = normalize(text);

    if (_hasAny(t, [
      'عدد الرحلات',
      'عدد رحلات',
      'اعرف الرحلات',
      'عندك رحلات',
      'اجمالي الرحلات',
      'وريني الرحلات',
      'شوف الرحلات',
      'رحلات انهارده',
      'رحلات اليوم',
      'الرحلات',
      'اجمالي ايراد',
      'اجمالي ايرادات',
      'اجمالي الايرادات',
      'ايراد العربيه',
      'ايرادات',
      'ايراد',
      'الايرادات',
      'اجمالي العائد',
      'العائد الشهري',
      'اجمالي الصافي',
      'كم رحله',
      'كام رحله',
      'عمل كام رحله',
      'عملت كام رحله',
      'عدد اللي عمله',
      'ايام شغال',
      'ايام شغل',
      'الايام الشغله',
      'استعلام عن الرحلات',
      'تقرير الرحلات',
      'رحلات',
    ])) {
      return AiActionId.queryTrips;
    }

    if (_hasAny(t, [
      'عدد العربيات',
      'اعرف العربيات',
      'عندك عربيات',
      'قايمه العربيات',
      'وريني العربيات',
      'شوف العربيات',
      'عدد الاتوبيسات',
      'اتوبيسات',
      'الاتوبيسات',
      'اي عربيه',
      'اي اتوبيس',
      'اي عربه',
      'كم عربيه',
      'كام عربيه',
      'كم عربي',
      'كام عربي',
      'كم اتوبيس',
      'كام اتوبيس',
      'كم اوتوبيس',
      'كام اوتوبيس',
      'استعلام عن الاتوبيسات',
    ])) {
      return AiActionId.queryBuses;
    }

    if (_hasAny(t, [
      'عدد السواقين',
      'اعرف السواقين',
      'قايمه السواقين',
      'اجور السواقين',
      'رواتب السواقين',
      'اجر السواق',
      'اجره السواق',
      'الاجر المستحق',
      'الاجره المستحقة',
      'السواقين',
      'رواتبهم',
      'اجورهم',
      'كم سواق',
      'كام سواق',
      'كم سائق',
      'كام سائق',
      'عدد سواق',
      'عدد سائق',
      'استعلام عن السائقين',
    ])) {
      return AiActionId.queryDrivers;
    }

    if (_hasAny(t, [
      'عدد المصانع',
      'اعرف المصانع',
      'قايمه المصانع',
      'وريني المصانع',
      'كم مصنع',
      'كام مصنع',
      'عدد مصنع',
      'مصانع',
      'المصانع',
      'استعلام عن المصانع',
    ])) {
      return AiActionId.queryFactories;
    }

    return null;
  }

  static bool isAddTripIntent(String text, {required bool containsTripData}) {
    final t = normalize(text);
    const phrases = [
      'اضيف رحله',
      'اضيفه',
      'اسجل رحله',
      'ابدا رحله',
      'ابدا اضافه',
      'عايز اضيف',
      'عايز اسجل',
      'اعمل رحله',
      'تعمل رحله',
      'تعملي رحله',
    ];

    var matched = false;
    for (final phrase in phrases) {
      if (RegExp(phrase).hasMatch(t)) {
        matched = true;
        break;
      }
    }

    return matched && !containsTripData;
  }

  static bool containsTripData(
    String text, {
    required List<String> busNames,
    required List<String> plates,
    required List<String> driverNames,
    required List<String> factoryNames,
  }) {
    final t = normalize(text);

    if (RegExp(r'\d').hasMatch(t)) return true;

    for (final name in busNames) {
      if (name.isNotEmpty && t.contains(normalize(name))) return true;
    }
    for (final plate in plates) {
      if (plate.isNotEmpty && t.contains(normalize(plate))) return true;
    }
    for (final name in driverNames) {
      if (name.isNotEmpty && t.contains(normalize(name))) return true;
    }
    for (final name in factoryNames) {
      if (name.isNotEmpty && t.contains(normalize(name))) return true;
    }

    const keywords = ['ايراد', 'اجر', 'جنيه', 'سعر', 'الساعه', 'يوم', 'نمره'];
    for (final keyword in keywords) {
      if (t.contains(keyword)) return true;
    }

    return false;
  }

  /// Suggests whether free text is really a trip-creation message (bus or
  /// factory) even though no explicit "add" phrase was detected. Prevents the
  /// read-only query handler from swallowing verbless, data-heavy answers
  /// (e.g. "الاخضر والسواق احمد والايراد 2000").
  static bool shouldTreatAsTripCreation(
    String text, {
    required List<String> busNames,
    required List<String> plates,
    required List<String> driverNames,
    required List<String> factoryNames,
  }) {
    final t = normalize(text);
    if (t.isEmpty) return false;

    const queryMarkers = [
      'عدد',
      'كم',
      'كام',
      'اجمالي',
      'قايمه',
      'قائمة',
      'كميه',
      'استعلام',
      'تقرير',
      'رحلات',
      'الرحلات',
      'ايرادات',
      'الايرادات',
    ];
    if (_hasAny(t, queryMarkers)) return false;

    final hasTripNoun = _hasAny(t, const ['رحله', 'سهره', 'سحور', 'مشوار']);

    if (hasTripNoun &&
        _containsAnyEntityName(
          t,
          busNames: busNames,
          plates: plates,
          driverNames: driverNames,
          factoryNames: factoryNames,
        )) {
      return true;
    }

    const creationVerbs = [
      'اضيف',
      'اسجل',
      'سجل',
      'اعمل',
      'ضيف رحله',
      'ضيف سهره',
      'ضيف مشوار',
      'ابدا رحله',
      'ابدا سهره',
      'ابدا مشوار',
    ];
    return _hasAny(t, creationVerbs) &&
        (hasTripNoun ||
            _containsAnyEntityName(
              t,
              busNames: busNames,
              plates: plates,
              driverNames: driverNames,
              factoryNames: factoryNames,
            ));
  }

  static bool _containsAnyEntityName(
    String t, {
    required List<String> busNames,
    required List<String> plates,
    required List<String> driverNames,
    required List<String> factoryNames,
  }) {
    for (final name in busNames) {
      if (name.isNotEmpty && t.contains(normalize(name))) return true;
    }
    for (final plate in plates) {
      if (plate.isNotEmpty && t.contains(normalize(plate))) return true;
    }
    for (final name in driverNames) {
      if (name.isNotEmpty && t.contains(normalize(name))) return true;
    }
    for (final name in factoryNames) {
      if (name.isNotEmpty && t.contains(normalize(name))) return true;
    }
    return false;
  }

  /// Detects whether the user is selecting a factory trip type (رحلة or سهرة).
  /// Returns the TripType constant or null if no match.
  static String? detectFactoryTripType(String text) {
    final t = normalize(text);

    if (t.contains('سهره') ||
        t.contains('سحور') ||
        t.contains('ليل') ||
        t.contains('ليلا') ||
        t.contains('بالليل')) {
      return 'night_outing';
    }

    if (t.contains('رحله') ||
        t.contains('رحلة') ||
        t.contains('ضيف رحله') ||
        t.contains('اضيف رحله') ||
        t.contains('صبح') ||
        t.contains('صباح') ||
        t.contains('ورديه')) {
      return 'trip';
    }

    if (t == '1' || t == 'احدى' || t == 'الاولي' || t == 'الاولى') {
      return 'trip';
    }
    if (t == '2' || t == 'اتنين' || t == 'تانيه' || t == 'ثانيه' || t == 'الثانيه') {
      return 'night_outing';
    }

    return null;
  }
}