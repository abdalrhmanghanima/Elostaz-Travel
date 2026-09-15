import 'package:elostaz_travel/domain/ai_assistant/entity/ai_trip_draft.dart';
import 'package:elostaz_travel/presentation/ai_assistant/model/ai_action_option.dart';
import 'package:elostaz_travel/presentation/ai_assistant/model/ai_guided_field.dart';
import 'package:elostaz_travel/presentation/ai_assistant/service/ai_field_parser.dart';

/// Result of parsing a draft-edit utterance for the trip flows.
///
/// [patch] carries ONLY the fields the user asked to change; every untouched
/// field stays null so it can be merged without overwriting the current draft.
class TripEditResult {
  final AiTripDraft patch;
  final bool editedType;

  const TripEditResult({
    this.patch = const AiTripDraft(),
    this.editedType = false,
  });

  bool get hasChanges =>
      editedType ||
      (patch.busName ?? '').isNotEmpty ||
      (patch.plateNumber ?? '').isNotEmpty ||
      (patch.driverName ?? '').isNotEmpty ||
      (patch.factoryName ?? '').isNotEmpty ||
      patch.revenue != null ||
      patch.driverWage != null ||
      patch.tripDate != null ||
      (patch.departureTime ?? '').isNotEmpty ||
      (patch.details ?? '').isNotEmpty ||
      patch.expenses != null ||
      (patch.expenseDetails ?? '').isNotEmpty;
}

/// A single create-flow field edit: the field plus the raw spoken value
/// (still needs canonicalization / validation).
class CreateFieldEdit {
  final AiGuidedField field;
  final String rawValue;

  const CreateFieldEdit({required this.field, required this.rawValue});
}

class CreateEditResult {
  final List<CreateFieldEdit> edits;

  const CreateEditResult(this.edits);

  bool get hasChanges => edits.isNotEmpty;
}

/// Parses draft-edit utterances spoken while the user is reviewing a trip or a
/// bus/driver/factory creation BEFORE confirming it.
///
/// Pure, deterministic, no external services. Never touches persisted data:
/// it only produces in-memory patches that the caller merges into the draft.
class DraftEditParser {
  static const _arabicMonths = <String, int>{
    'يناير': 1,
    'فبراير': 2,
    'مارس': 3,
    'ابريل': 4,
    'مايو': 5,
    'يونيو': 6,
    'يوليو': 7,
    'اغسطس': 8,
    'سبتمبر': 9,
    'اكتوبر': 10,
    'نوفمبر': 11,
    'ديسمبر': 12,
  };

  static String _normalize(String text) {
    return AiFieldParser.digitsToLatin(
      text
          .replaceAll(RegExp(r'[\u0610-\u061A\u06D6-\u06ED]'), '')
          .replaceAll(RegExp(r'[أإآ]'), 'ا')
          .replaceAll('ؤ', 'و')
          .replaceAll('ئ', 'ي')
          .replaceAll('ة', 'ه')
          .replaceAll('ى', 'ي')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim()
          .toLowerCase(),
    );
  }

  /// Strips leading glue verbs / conjunctions and trims redundant whitespace
  /// and stray `و` characters from a captured value.
  static String _cleanValue(String v) {
    var s = v.trim();
    var prev = '';
    while (s != prev) {
      prev = s;
      s = s.replaceFirst(
        RegExp(
          r'^(?:هيبقي|يبقي|بقي|بيبقي|هيبقى|يبقى|هيكون|يكون|يتبقي|هو\s+)\s*',
        ),
        '',
      );
    }
    s = s.replaceFirst(RegExp(r'^(?:لـ|لي|ل|ب)\s*'), '');
    s = s.replaceAll(RegExp(r'\s+'), ' ').trim();
    s = s
        .replaceAll(RegExp(r'^[\sو]+'), '')
        .replaceAll(RegExp(r'[\sو]+$'), '')
        .trim();
    return s;
  }

  /// Best (left-most, longest-on-tie) keyword match, or null when no keyword
  /// is present in [text]. The keyword must sit at a word boundary: `^`,
  /// whitespace, or a glued `و`.
  static (String, Match)? _bestKeywordMatch(
    String text,
    List<String> keywords,
  ) {
    String? bestKey;
    Match? bestMatch;
    for (final kw in keywords) {
      final pattern = RegExp(
        '(?:^|[\\sو])${RegExp.escape(kw)}(?![\\u0600-\\u06FF0-9])',
      );
      final m = pattern.firstMatch(text);
      if (m == null) continue;
      if (bestMatch == null ||
          m.start < bestMatch.start ||
          (m.start == bestMatch.start && kw.length > (bestKey ?? '').length)) {
        bestKey = kw;
        bestMatch = m;
      }
    }
    return bestMatch == null ? null : (bestKey!, bestMatch);
  }

  /// Earliest start index of any stop keyword at/after [from], or null.
  static int? _findStop(String text, int from, List<String> stops) {
    int? best;
    for (final stop in stops) {
      final pattern = RegExp('(?:^|[\\sو])${RegExp.escape(stop)}');
      for (final match in pattern.allMatches(text)) {
        if (match.start < from) continue;
        if (best == null || match.start < best) best = match.start;
      }
    }
    return best;
  }

  /// Captures the value that follows the first matching [keywords], cut at the
  /// first [stops] keyword. Returns null when no keyword matches or nothing
  /// meaningful remains.
  static String? _capture(String text, List<String> keywords, List<String> stops) {
    final best = _bestKeywordMatch(text, keywords);
    if (best == null) return null;
    final (_, match) = best;
    final stopIndex = _findStop(text, match.end, stops);
    final end = stopIndex ?? text.length;
    final value = _cleanValue(text.substring(match.end, end));
    return value.isEmpty ? null : value;
  }

  // ── Trip stops: all field keywords with and without a glued `و` ──────────
  static const List<String> _tripStops = [
    'والايراد', 'الايراد', 'ايراد',
    'والاجر', 'الاجر', 'واجر', 'اجر',
    'والاجره', 'الاجره', 'اجره',
    'والمصروف', 'المصروف', 'ومصروف', 'مصروف',
    'ومصروفات', 'مصروفات',
    'والمصاريف', 'المصاريف', 'ومصاريف', 'مصاريف',
    'والمصرايف', 'المصرايف', 'ومصرايف', 'مصرايف',
    'وتفاصيل المصروف', 'تفاصيل المصروف',
    'والتفاصيل', 'التفاصيل',
    'والمصنع', 'المصنع',
    'والسواق', 'السواق',
    'والسايق', 'السايق',
    'والسائق', 'السائق',
    'والاتوبيس', 'الاتوبيس',
    'والاوتوبيس', 'الاوتوبيس',
    'والعربيه', 'العربيه',
    'والعربة', 'العربة',
    'واللوحه', 'اللوحه',
    'واللوحة', 'اللوحة',
    'والنمره', 'النمره', 'نمره',
    'والساعه', 'الساعه',
    'والوقت', 'الوقت',
    'واليوم', 'اليوم',
    'والنهارده', 'النهارده',
    'والنوع', 'النوع',
    'والتاريخ', 'التاريخ',
    'وغدا', 'غدا',
    'وبكره', 'بكره',
  ];

  static const List<String> _driverKeywords = [
    'السواق',
    'السايق',
    'السائق',
    'السواقه',
  ];
  static const List<String> _busKeywords = ['الاتوبيس', 'الاوتوبيس', 'العربيه'];
  static const List<String> _plateKeywords = [
    'رقم اللوحه',
    'رقم اللوحة',
    'اللوحه',
    'اللوحة',
    'النمره',
    'نمره',
    'رقم النمره',
  ];
  static const List<String> _factoryKeywords = ['المصنع', 'الشركه', 'معمل'];
  static const List<String> _revenueKeywords = ['الايراد', 'ايراد', 'السعر', 'سعر'];
  static const List<String> _wageKeywords = [
    'اجر السواق',
    'اجره السواق',
    'الاجر',
    'الاجره',
    'اجر',
    'اجره',
    'اجر السائق',
  ];
  static const List<String> _expenseKeywords = [
    'المصروف',
    'المصاريف',
    'المصرايف',
    'مصروف',
    'مصاريف',
    'مصرايف',
  ];
  static const List<String> _expenseDetailKeywords = ['تفاصيل المصروف'];
  static const List<String> _detailKeywords = ['التفاصيل', 'تفاصيل الرحله'];
  static const List<String> _typeKeywords = ['النوع', 'نوع'];

  static TripEditResult parseTrip(String rawText) {
    final t = _normalize(rawText);
    if (t.isEmpty) return const TripEditResult();

    // Replacement patterns: "غير X من OLD خليه NEW", "X بدل OLD يكون NEW",
    // etc. Extract ONLY the NEW value (the OLD value is the current draft
    // context and must never be resolved as a new entity).
    final driverName =
        _extractReplacementNewValue(t, _driverKeywords) ??
        _capture(t, _driverKeywords, _tripStops);
    final busName =
        _extractReplacementNewValue(t, _busKeywords) ??
        _capture(t, _busKeywords, _tripStops);
    final plateNumber =
        _extractReplacementNewValue(t, _plateKeywords) ??
        _capture(t, _plateKeywords, _tripStops);
    final factoryName =
        _extractReplacementNewValue(t, _factoryKeywords) ??
        _capture(t, _factoryKeywords, _tripStops);

    final revenueRaw =
        _extractReplacementNewValue(t, _revenueKeywords) ??
        _capture(t, _revenueKeywords, _tripStops);
    final revenue =
        revenueRaw == null ? null : AiFieldParser.parseNumber(revenueRaw);

    final wageRaw =
        _extractReplacementNewValue(t, _wageKeywords) ??
        _capture(t, _wageKeywords, _tripStops);
    final driverWage = wageRaw == null ? null : AiFieldParser.parseNumber(wageRaw);

    final expenseRaw =
        _extractReplacementNewValue(t, _expenseKeywords) ??
        _capture(t, _expenseKeywords, _tripStops);
    final expenses =
        expenseRaw == null ? null : AiFieldParser.parseNumber(expenseRaw);

    final expenseDetails =
        _extractReplacementNewValue(t, _expenseDetailKeywords) ??
        _capture(t, _expenseDetailKeywords, _tripStops);
    final details =
        _extractReplacementNewValue(t, _detailKeywords) ??
        _capture(t, _detailKeywords, _tripStops);

    final tripDate = _extractDate(t);
    final departureTime = _extractTime(t);

    final typeEdited = _bestKeywordMatchType(t);
    final type = typeEdited
        ? (t.contains('سهره') || t.contains('سحور') || t.contains('ليل')
            ? 'night_outing'
            : (t.contains('رحله') ? 'trip' : null))
        : null;

    final patch = AiTripDraft(
      busName: busName,
      plateNumber: plateNumber,
      driverName: driverName,
      factoryName: factoryName,
      revenue: revenue,
      driverWage: driverWage,
      tripDate: tripDate,
      departureTime: departureTime,
      type: type,
      details: details,
      expenses: expenses,
      expenseDetails: expenseDetails,
    );

    return TripEditResult(patch: patch, editedType: typeEdited && type != null);
  }

  /// True when the text explicitly references the trip "type" (النوع/نوع),
  /// so "الايراد يبقى 5000" never silently flips رحلة → سهرة.
  static bool _bestKeywordMatchType(String text) {
    for (final kw in _typeKeywords) {
      if (RegExp('(?:^|[\\sو])${RegExp.escape(kw)}(?![\\u0600-\\u06FF0-9])')
          .hasMatch(text)) {
        return true;
      }
    }
    return false;
  }

  static DateTime? _extractDate(String text) {
    if (text.contains('بكره') || text.contains('غدا')) {
      return DateTime.now().add(const Duration(days: 1));
    }
    if (text.contains('اليوم') || text.contains('النهارده')) {
      return DateTime.now();
    }

    final dayMonthPattern = RegExp(r'يوم\s+(\d{1,2})\s+(\S+)');
    final dayMonthMatch = dayMonthPattern.firstMatch(text);
    if (dayMonthMatch != null) {
      final result = _parseDayMonth(
        dayMonthMatch.group(1)!,
        dayMonthMatch.group(2)!,
      );
      if (result != null) return result;
    }

    final monthPattern = RegExp(r'(\d{1,2})\s+(\S+)');
    final monthMatches = monthPattern.allMatches(text);
    for (final match in monthMatches) {
      final result = _parseDayMonth(match.group(1)!, match.group(2)!);
      if (result != null) return result;
    }

    final slashPattern = RegExp(r'(\d{1,2})/(\d{1,2})(?:/(\d{4}))?');
    final slashMatch = slashPattern.firstMatch(text);
    if (slashMatch != null) {
      final day = int.tryParse(slashMatch.group(1)!);
      final month = int.tryParse(slashMatch.group(2)!);
      final yearStr = slashMatch.group(3);
      final year = yearStr != null
          ? int.tryParse(yearStr)
          : DateTime.now().year;
      if (day != null &&
          month != null &&
          year != null &&
          month >= 1 &&
          month <= 12 &&
          day >= 1 &&
          day <= 31) {
        return DateTime(year, month, day);
      }
    }

    return null;
  }

  static DateTime? _parseDayMonth(String dayStr, String monthStr) {
    final day = int.tryParse(dayStr);
    if (day == null) return null;
    final month = _arabicMonths[_normalize(monthStr)];
    if (month == null) return null;
    return DateTime(DateTime.now().year, month, day);
  }

  // ── Time extraction (mirrors LocalTripParser, canonical 24h HH:mm) ────────
  static final RegExp _time12HourAndMinutes = RegExp(
    r'(?:الساعه\s+)?(\d{1,2})\s*[:.،]\s*(\d{1,2})\s*'
    r'(الصبح|صباحا|مساءا|مساء|بالليل|ليلا|الليل|المغرب|ظهرا|الظهر|العصر|عصر|'
    r'ص(?![\u0600-\u06FF])|م(?![\u0600-\u06FF]))',
  );

  static final RegExp _time12HourOnly = RegExp(
    r'(?:الساعه\s+)?(\d{1,2})\s*'
    r'(الصبح|صباحا|مساءا|مساء|بالليل|ليلا|الليل|المغرب|ظهرا|الظهر|العصر|عصر|'
    r'ص(?![\u0600-\u06FF])|م(?![\u0600-\u06FF]))',
  );

  static final RegExp _time24HourAndMinutes = RegExp(
    r'(?:الساعه\s+)?(\d{1,2}):(\d{1,2})(?!\d)',
  );

  static final RegExp _time24HourOnly = RegExp(r'الساعه\s+(\d{1,2})(?!\d)');

  static String? _extractTime(String text) {
    final match12Minutes = _time12HourAndMinutes.firstMatch(text);
    if (match12Minutes != null) {
      final hour = int.tryParse(match12Minutes.group(1)!);
      final minute = int.tryParse(match12Minutes.group(2)!);
      if (hour != null &&
          minute != null &&
          hour >= 1 &&
          hour <= 12 &&
          minute <= 59) {
        return _formatTime(hour, minute, match12Minutes.group(3)!);
      }
    }

    final match12Hour = _time12HourOnly.firstMatch(text);
    if (match12Hour != null) {
      final hour = int.tryParse(match12Hour.group(1)!);
      if (hour != null && hour >= 1 && hour <= 12) {
        return _formatTime(hour, 0, match12Hour.group(2)!);
      }
    }

    final match24 = _time24HourAndMinutes.firstMatch(text);
    if (match24 != null) {
      final hour = int.tryParse(match24.group(1)!);
      final minute = int.tryParse(match24.group(2)!);
      if (hour != null && minute != null && hour <= 23 && minute <= 59) {
        return _formatDateTime(hour, minute);
      }
    }

    final match24Hour = _time24HourOnly.firstMatch(text);
    if (match24Hour != null) {
      final hour = int.tryParse(match24Hour.group(1)!);
      if (hour != null && hour <= 23) {
        return _formatDateTime(hour, 0);
      }
    }

    return null;
  }

  static String _formatTime(int hour, int minute, String period) {
    final isAm = period == 'ص' || period == 'صباحا' || period == 'الصبح';
    final hour24 = isAm
        ? (hour == 12 ? 0 : hour)
        : (hour == 12 ? 12 : hour + 12);
    return _formatDateTime(hour24, minute);
  }

  static String _formatDateTime(int hour, int minute) {
    return '${hour.toString().padLeft(2, '0')}:'
        '${minute.toString().padLeft(2, '0')}';
  }

  // ── Natural-language replacement patterns ─────────────────────────────────
  // Detects patterns like:
  //   "غير X من OLD خليه NEW"
  //   "غير X من OLD يبقى NEW"
  //   "غير X بدل OLD يكون NEW"
  //   "غير X بدل OLD يبقى NEW"
  //   "خلي X NEW بدل OLD"
  //   "X يبقى NEW بدل OLD"
  //   "بدل X OLD بـ NEW"
  // These patterns carry OLD as context (the current draft value) and NEW as
  // the replacement to resolve against the provider entities.

  static final _replacementFromPattern = RegExp(
    r'(?:من|بدل)\s+(.+?)\s+(?:خليه|خليها|يبق[يى]|يكون)\s+(.+)',
  );

  /// Trims a raw replacement value at the first field stop keyword so a
  /// following clause ("والاتوبيس ..") never leaks into the extracted NEW value.
  static String? _cleanReplacementValue(String raw) {
    final stopIndex = _findStop(raw, 0, _tripStops);
    final cut = stopIndex != null ? raw.substring(0, stopIndex) : raw;
    final value = _cleanValue(cut);
    return value.isEmpty ? null : value;
  }

  /// For a given field keyword, extract only the NEW value from a replacement
  /// pattern in [text]. Returns null if no replacement pattern is found for
  /// this keyword.
  static String? _extractReplacementNewValue(
    String text,
    List<String> fieldKeywords,
  ) {
    // Pattern 1: keyword + من OLD خليه/يبقى/يكون NEW
    for (final kw in fieldKeywords) {
      final pattern = RegExp(
        '(?:^|[\\sو])${RegExp.escape(kw)}\\s+${_replacementFromPattern.pattern}',
      );
      final m = pattern.firstMatch(text);
      if (m != null) {
        final newValue = _cleanReplacementValue(m.group(2)!);
        if (newValue != null) return newValue;
      }
    }

    // Pattern 2: خلي keyword NEW بدل OLD
    for (final kw in fieldKeywords) {
      final pattern = RegExp(
        r'(?:^|[\sو])خلي\s+' + RegExp.escape(kw) + r'\s+(.+?)\s+بدل\s+(.+)',
      );
      final m = pattern.firstMatch(text);
      if (m != null) {
        final newValue = _cleanReplacementValue(m.group(1)!);
        if (newValue != null) return newValue;
      }
    }

    // Pattern 3: keyword يبقى NEW بدل OLD
    for (final kw in fieldKeywords) {
      final pattern = RegExp(
        '(?:^|[\\sو])${RegExp.escape(kw)}\\s+يبق[يى]\\s+(.+?)\\s+بدل\\s+(.+)',
      );
      final m = pattern.firstMatch(text);
      if (m != null) {
        final newValue = _cleanReplacementValue(m.group(1)!);
        if (newValue != null) return newValue;
      }
    }

    // Pattern 4: بدل keyword OLD بـ NEW  /  بدل keyword OLD يكون/يبقى NEW
    for (final kw in fieldKeywords) {
      // بدل keyword OLD بـ/في/على NEW
      final pattern1 = RegExp(
        '(?:^|[\\sو])بدل\\s+${RegExp.escape(kw)}\\s+(.+?)\\s+(?:بـ|في|على)\\s+(.+)',
      );
      final m1 = pattern1.firstMatch(text);
      if (m1 != null) {
        final newValue = _cleanReplacementValue(m1.group(2)!);
        if (newValue != null) return newValue;
      }

      // بدل keyword OLD يكون/يبقى NEW
      final pattern2 = RegExp(
        '(?:^|[\\sو])بدل\\s+${RegExp.escape(kw)}\\s+(.+?)\\s+(?:يكون|يبقى|يبقي)\\s+(.+)',
      );
      final m2 = pattern2.firstMatch(text);
      if (m2 != null) {
        final newValue = _cleanReplacementValue(m2.group(2)!);
        if (newValue != null) return newValue;
      }
    }

    return null;
  }

  // ── Create-flow field keywords (scoped per action) ────────────────────────
  static const Map<String, List<String>> _createFieldKeywords = {
    'busName': [
      'اسم الاتوبيس',
      'اسم الاوتوبيس',
      'اسم العربيه',
      'اسم العربه',
      'الاسم',
    ],
    'plateNumber': [
      'رقم اللوحه',
      'رقم اللوحة',
      'اللوحه',
      'اللوحة',
      'النمره',
      'نمره',
      'رقم العربيه',
      'رقم العربه',
    ],
    'vehicleType': ['نوع العربيه', 'نوع العربية', 'نوع الاتوبيس'],
    'brand': ['الماركه', 'الماركة'],
    'model': ['الموديل', 'موديل'],
    'manufacturingYear': ['سنه الصنع', 'سنة الصنع', 'سنه العربيه', 'سنه'],
    'chassisNumber': ['الشاسيه', 'الشاسية', 'رقم الشاسيه', 'رقم الشاسية'],
    'engineNumber': ['الموتور', 'رقم الموتور'],
    'passengerCount': ['عدد الركاب', 'الركاب'],
    'licenseExpiryDate': ['انتهاء الترخيص', 'الترخيص', 'تاريخ الترخيص'],
    'specialConditions': ['الاشتراطات', 'اشتراطات', 'الاشتراط', 'الشروط'],
    'insuranceType': ['التامين', 'التأمين', 'تامين', 'تأمين'],
    'prohibitedBankName': ['البنك المحظور', 'اسم البنك', 'البنك'],
    'driverName': [
      'اسم السواق',
      'اسم السايق',
      'اسم السائق',
      'اسمه',
      'اسمو',
      'الاسم',
      'اسم',
    ],
    'driverPhone': [
      'رقم التليفون',
      'رقم التلفون',
      'التليفون',
      'التلفون',
      'الموبايل',
      'تليفون',
      'تلفون',
      'الهاتف',
    ],
    'factoryName': [
      'اسم المصنع',
      'اسم الشركه',
      'اسم الشركة',
      'اسمه',
      'اسمو',
      'الاسم',
      'اسم',
    ],
    'factoryDetails': [
      'عنوان المصنع',
      'تفاصيل المصنع',
      'العنوان',
      'تفاصيل',
      'ملاحظات',
    ],
  };

  static CreateEditResult parseCreate(String rawText, AiActionId action) {
    final t = _normalize(rawText);
    if (t.isEmpty) return const CreateEditResult([]);

    final option = availableAiActions.firstWhere((o) => o.id == action);
    final fields = <AiGuidedField>[
      ...option.requiredFields,
      ...option.optionalFields,
    ];
    if (action == AiActionId.addBus) {
      fields.add(AiGuidedField.prohibitedBankName);
    }

    final allKeywords = <String>{};
    for (final f in fields) {
      allKeywords.addAll(_createFieldKeywords[f.name] ?? const []);
    }
    final stops = <String>{
      ...allKeywords,
      for (final kw in allKeywords) 'و$kw',
      'والايراد', 'الايراد',
      'والتاريخ', 'التاريخ',
      'والساعه', 'الساعه',
      'واليوم', 'اليوم',
      'والنوع', 'النوع',
    };

    final edits = <CreateFieldEdit>[];
    for (final f in fields) {
      final keywords = _createFieldKeywords[f.name] ?? const [];
      if (keywords.isEmpty) continue;
      final value = _capture(t, keywords, stops.toList());
      if (value == null) continue;
      edits.add(CreateFieldEdit(field: f, rawValue: value));
    }
    return CreateEditResult(edits);
  }
}