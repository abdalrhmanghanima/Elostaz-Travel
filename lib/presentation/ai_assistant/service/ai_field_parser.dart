import 'package:elostaz_travel/presentation/ai_assistant/model/ai_guided_field.dart';

/// Parses and validates guided create-flow answers (bus/driver/factory fields).
/// Pure, free, deterministic — no external services.
class AiFieldParser {
  static const _arabicMonths = <String, int>{
    'يناير': 1,
    'فبراير': 2,
    'مارس': 3,
    'ابريل': 4,
    'أبريل': 4,
    'مايو': 5,
    'يونيو': 6,
    'يوليو': 7,
    'اغسطس': 8,
    'أغسطس': 8,
    'سبتمبر': 9,
    'اكتوبر': 10,
    'أكتوبر': 10,
    'نوفمبر': 11,
    'ديسمبر': 12,
  };

  static String digitsToLatin(String text) {
    return text
        .replaceAll('٠', '0')
        .replaceAll('١', '1')
        .replaceAll('٢', '2')
        .replaceAll('٣', '3')
        .replaceAll('٤', '4')
        .replaceAll('٥', '5')
        .replaceAll('٦', '6')
        .replaceAll('٧', '7')
        .replaceAll('٨', '8')
        .replaceAll('٩', '9');
  }

  static String _normalize(String text) {
    return digitsToLatin(
      text
          .replaceAll(RegExp(r'[\u0610-\u061A\u06D6-\u06ED]'), '')
          .replaceAll(RegExp(r'[أإآ]'), 'ا')
          .replaceAll('ؤ', 'و')
          .replaceAll('ئ', 'ي')
          .replaceAll('ة', 'ه')
          .replaceAll('ى', 'ي')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim(),
    );
  }

  static int? parseInt(String text) {
    final digits = digitsToLatin(text).replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return null;
    return int.tryParse(digits);
  }

  static double? parseNumber(String text) {
    var t = digitsToLatin(text).trim();
    t = t.replaceAll(',', '');
    final match = RegExp(r'-?\d+(\.\d+)?').firstMatch(t);
    if (match == null) return null;
    return double.tryParse(match.group(0)!);
  }

  static DateTime? parseDate(String text) {
    var t = _normalize(text);
    t = t.replaceAll(RegExp(r'[(]/[)]|[,]'), ' ');

    final slash = RegExp(r'(\d{1,2})/(\d{1,2})/(\d{2,4})').firstMatch(t);
    if (slash != null) {
      final day = int.parse(slash.group(1)!);
      final month = int.parse(slash.group(2)!);
      var year = int.parse(slash.group(3)!);
      if (year < 100) year += 2000;
      return _tryDate(year, month, day);
    }

    final slashArab = RegExp(r'(\d{1,2})-(\d{1,2})-(\d{2,4})').firstMatch(t);
    if (slashArab != null) {
      final day = int.parse(slashArab.group(1)!);
      final month = int.parse(slashArab.group(2)!);
      var year = int.parse(slashArab.group(3)!);
      if (year < 100) year += 2000;
      return _tryDate(year, month, day);
    }

    String monthName = '';
    for (final name in _arabicMonths.keys) {
      if (t.contains(name)) {
        monthName = name;
        break;
      }
    }

    final numTokens = RegExp(r'\d{1,4}')
        .allMatches(t)
        .map((m) => int.parse(m.group(0)!))
        .toList();

    if (monthName.isEmpty) return null;
    if (numTokens.isEmpty) return null;

    final month = _arabicMonths[monthName]!;
    final now = DateTime.now();
    int year = numTokens.any((n) => n > 31) ? numTokens.firstWhere((n) => n > 31) : now.year;
    final dayCandidates = numTokens.where((n) => n <= 31 && n > 0).toList();
    int day = dayCandidates.isEmpty ? 1 : dayCandidates.last;
    return _tryDate(year, month, day);
  }

  static DateTime? _tryDate(int year, int month, int day) {
    if (month < 1 || month > 12 || day < 1 || day > 31) return null;
    final dt = DateTime(year, month, day);
    if (dt.year != year || dt.month != month || dt.day != day) return null;
    return dt;
  }

  static final List<RegExp> _leadingLabelPatterns = [
    RegExp(r'^(?:و\s*)?اسمه\s+'),
    RegExp(r'^(?:و\s*)?اسمو\s+'),
    RegExp(r'^(?:و\s*)?اسمها\s+'),
    RegExp(r'^(?:و\s*)?اسمي\s+'),
    RegExp(r'^(?:و\s*)?الاسم\s+'),
    RegExp(
        r'^(?:و\s*)?اسم\s+(?:ال)?(?:اتوبيس|اوتوبيس|عربيه|عربه|سواق|سايق|سائق|مصنع|شركه)?\s+'),
    RegExp(r'^(?:و\s*)?رقم\s+تليفونه\s+'),
    RegExp(r'^(?:و\s*)?رقم\s+تليفونها\s+'),
    RegExp(r'^(?:و\s*)?رقم\s+تليفوني\s+'),
    RegExp(r'^(?:و\s*)?رقم\s+تلفونه\s+'),
    RegExp(r'^(?:و\s*)?رقم\s+تلفون\s+'),
    RegExp(r'^(?:و\s*)?رقم\s+التلفون\s+'),
    RegExp(r'^(?:و\s*)?رقم\s+الهاتف\s+'),
    RegExp(r'^(?:و\s*)?رقم\s+موبايله\s+'),
    RegExp(r'^(?:و\s*)?رقم\s+تليفون\s+'),
    RegExp(r'^(?:و\s*)?رقم\s+التليفون\s+'),
    RegExp(r'^(?:و\s*)?رقم\s+الموبايل\s+'),
    RegExp(r'^(?:و\s*)?رقم\s+اللوحه\s+'),
    RegExp(r'^(?:و\s*)?رقم\s+اللوحة\s+'),
    RegExp(r'^(?:و\s*)?رقم\s+العربيه\s+'),
    RegExp(r'^(?:و\s*)?نمره\s+العربيه\s+'),
    RegExp(r'^(?:و\s*)?نمرة\s+العربية\s+'),
    RegExp(r'^(?:و\s*)?تليفونه\s+'),
    RegExp(r'^(?:و\s*)?تليفوني\s+'),
    RegExp(r'^(?:و\s*)?تلفونه\s+'),
    RegExp(r'^(?:و\s*)?تلفون\s+'),
    RegExp(r'^(?:و\s*)?موبايله\s+'),
    RegExp(r'^(?:و\s*)?الموبايل\s+'),
    RegExp(r'^(?:و\s*)?الماركه\s+'),
    RegExp(r'^(?:و\s*)?الموديل\s+'),
    RegExp(r'^(?:و\s*)?سنه\s+الصنع\s+'),
    RegExp(r'^(?:و\s*)?عدد\s+الركاب\s+'),
    RegExp(r'^(?:و\s*)?نوع\s+العربيه\s+'),
    RegExp(r'^(?:و\s*)?نوع\s+العربية\s+'),
    RegExp(r'^(?:و\s*)?رقم\s+الشاسيه\s+'),
    RegExp(r'^(?:و\s*)?رقم\s+الشاسية\s+'),
    RegExp(r'^(?:و\s*)?رقم\s+الموتور\s+'),
    RegExp(r'^(?:و\s*)?الشروط\s+'),
    RegExp(r'^(?:و\s*)?التامين\s+'),
    RegExp(r'^(?:و\s*)?عنوان\s+'),
    RegExp(r'^(?:و\s*)?تفاصيل\s+'),
    RegExp(r'^(?:و\s*)?ملاحظات\s+'),
  ];

  /// Drops a leading spoken field label from free-form answers, e.g.
  /// "ورقم تليفونه 200..." → "200...". Only strips the first label; the
  /// caller keeps collecting remaining fields one at a time.
  static String stripLeadingLabels(String raw) {
    final trimmed = raw.trim();
    for (final pattern in _leadingLabelPatterns) {
      final match = pattern.firstMatch(trimmed);
      if (match != null) {
        return trimmed.substring(match.end).trim();
      }
    }
    return trimmed;
  }

  /// Regex matching a driver-name label ("اسمه ..", "اسم السواق ..", ...).
  /// Works on normalized text.
  static final RegExp _nameLabel = RegExp(
    r'(?:اسم\s+(?:ال)?(?:سواق|سايق|سائق|قايق)?\s+|اسمه\s+|اسمو\s+|الاسم\s+)',
  );

  /// Keyword that terminates a captured name (a spoken phone label with its
  /// optional leading "و" or "رقم").
  static final RegExp _phoneLabelStop = RegExp(
    r'(?:و\s*)?(?:رقم\s+)?(?:ال)?(?:تليفون|تلفون|موبايل|هاتف)[هاي]?',
  );

  static String _cleanName(String s) {
    return s
        .replaceAll(RegExp(r'^[\sو]+'), '')
        .replaceAll(RegExp(r'[\sو]+$'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// Longest digit run in [normalized], used to isolate a spoken phone
  /// number embedded in a sentence.
  static String? _extractPhone(String normalized) {
    final runs = RegExp(r'\d{2,15}')
        .allMatches(normalized)
        .map((m) => m.group(0)!)
        .toList();
    if (runs.isEmpty) return null;
    runs.sort((a, b) => b.length.compareTo(a.length));
    return runs.first;
  }

  static String? _extractDriverName(String normalized, String? phone) {
    var tail = normalized;
    if (phone != null && phone.length >= 2) {
      tail = tail.replaceAll(phone, ' ');
    }

    final label = _nameLabel.firstMatch(tail);
    if (label != null) {
      var name = tail.substring(label.end);
      final stop = _phoneLabelStop.firstMatch(name);
      if (stop != null) name = name.substring(0, stop.start);
      name = _cleanName(name);
      if (name.isNotEmpty) return name;
    }

    // Fallback: strip intent/entity words and keep the rest as the name.
    var rest = tail;
    rest = rest.replaceAll(
      RegExp(r'\b(?:ال)?(?:عايز|عايزه?|حابب|محتاج|اضيف|اسجل|سجل|اعمل)\b'),
      ' ',
    );
    rest = rest.replaceAll(
      RegExp(r'\b(?:ال)?(?:سواق|سايق|سائق|قايق|سواقين)\b'),
      ' ',
    );
    rest = rest.replaceAll(RegExp(r'\bجديد\b'), ' ');
    final stop = _phoneLabelStop.firstMatch(rest);
    if (stop != null) rest = rest.substring(0, stop.start);
    rest = _cleanName(rest);
    return rest.isEmpty ? null : rest;
  }

  /// Pre-fills the Add Driver flow from a first message such as
  /// "عايز أضيف سواق اسمه عبدالرحمن محمد ورقم تليفونه 20043961010".
  /// Returns only values that could be separated from their spoken labels.
  static Map<String, String> extractDriverPrefill(String raw) {
    final t = raw.trim();
    if (t.isEmpty) return const {};
    final normalized = _normalize(t);

    final values = <String, String>{};

    final phone = _extractPhone(normalized);
    if (phone != null && phone.length >= 6) {
      values[AiGuidedField.driverPhone.name] = phone;
    }

    final name = _extractDriverName(normalized, phone);
    if (name != null && name.length >= 2) {
      values[AiGuidedField.driverName.name] = name;
    }

    return values;
  }

  /// Returns a driver name only when the answer explicitly carries a name
  /// label ("اسمه ..", "اسم السواق .."). Used to apply a name correction
  /// while another driver field is being asked.
  static String? extractDriverNameFromAnswer(String raw) {
    final label = _nameLabel.firstMatch(_normalize(raw));
    if (label == null) return null;
    var name = _normalize(raw).substring(label.end);
    final stop = _phoneLabelStop.firstMatch(name);
    if (stop != null) name = name.substring(0, stop.start);
    name = _cleanName(name);
    return name.isEmpty ? null : name;
  }

  /// Extracts the digit-only phone embedded in [raw], or null.
  static String? phoneFromText(String raw) {
    final phone = _extractPhone(_normalize(raw));
    if (phone == null || phone.length < 6) return null;
    return phone;
  }

  /// Regex matching a factory-name label ("اسمه ..", "اسم المصنع ..", ...).
  /// Matched against the raw (unnormalized) text so captured names keep the
  /// user's original spelling (hamza, taa marbuta, ...).
  static final RegExp _factoryNameLabel = RegExp(
    r'(?:و\s*)?(?:اسم\s+(?:ال)?(?:مصنع|شرك(?:ه|ة))?\s+|'
    r'اسمه\s+|اسمو\s+|اسمها\s+|الاسم\s+)',
  );

  /// Keyword that terminates a captured factory name (a spoken details /
  /// address label with its optional leading "و").
  static final RegExp _factoryNameStop = RegExp(
    r'(?:و\s*)?(?:عنوان|تفاصيل المصنع|تفاصيل|ملاحظات|تليفون|تلفون|موبايل|هاتف)',
  );

  /// Labels introducing the optional factory details ("وعنوانه ..",
  /// "تفاصيل المصنع ..", "ملاحظات ..").
  static final List<RegExp> _factoryDetailsLabels = [
    RegExp(r'(?:و\s*)?(?:عنوانه|عنوانها|عنوان المصنع|العنوان)\s+'),
    RegExp(r'(?:و\s*)?(?:تفاصيل المصنع|تفاصيل)\s+'),
    RegExp(r'(?:و\s*)?(?:ملاحظات المصنع|ملاحظات)\s+'),
  ];

  /// Leading intent/entity wrapper of an opening message, e.g.
  /// "عايز أضيف مصنع " or "اسجل مصنع جديد " or bare "مصنع ".
  static final RegExp _factoryOpenPattern = RegExp(
    r'^(?:'
    r'(?:عايز|عايزه|نفسي|حابب|محتاج)\s+'
    r'(?:[أاإ]?ضيف|اسجل|سجل|اعمل)\s+)?'
    r'(?:مصنع|شرك(?:ه|ة)|معمل)\s*'
    r'(?:جديد|جديده|جديدة)?\s*',
  );

  static String? _extractFactoryName(String raw) {
    final head = raw.trim();

    final label = _factoryNameLabel.firstMatch(head);
    if (label != null) {
      var name = head.substring(label.end);
      final stop = _factoryNameStop.firstMatch(name);
      if (stop != null) name = name.substring(0, stop.start);
      name = _cleanName(name);
      if (name.isNotEmpty) return name;
    }

    final rest = head.replaceFirst(_factoryOpenPattern, '');
    var name = rest;
    final stop = _factoryNameStop.firstMatch(name);
    if (stop != null) name = name.substring(0, stop.start);
    name = _cleanName(name);
    return name.isEmpty ? null : name;
  }

  static String? _extractFactoryDetails(String raw) {
    for (final pattern in _factoryDetailsLabels) {
      final match = pattern.firstMatch(raw);
      if (match == null) continue;
      final value = _cleanName(raw.substring(match.end));
      if (value.isNotEmpty) return value;
    }
    return null;
  }

  /// Pre-fills the Add Factory flow from a first message such as
  /// "عايز أضيف مصنع اسمه المصرية للإنشاءات".
  /// Returns only values that could be separated from their spoken labels.
  static Map<String, String> extractFactoryPrefill(String raw) {
    final t = raw.trim();
    if (t.isEmpty) return const {};

    final values = <String, String>{};

    final name = _extractFactoryName(t);
    if (name != null && name.length >= 2) {
      values[AiGuidedField.factoryName.name] = name;
    }

    final details = _extractFactoryDetails(t);
    if (details != null && details.isNotEmpty) {
      values[AiGuidedField.factoryDetails.name] = details;
    }

    return values;
  }

  /// Returns a factory name only when the answer explicitly carries a name
  /// label ("اسمه ..", "اسم المصنع .."). Used to apply a factory-name
  /// correction while another factory field is being asked.
  static String? extractFactoryNameFromAnswer(String raw) {
    final label = _factoryNameLabel.firstMatch(raw.trim());
    if (label == null) return null;
    var name = raw.trim().substring(label.end);
    final stop = _factoryNameStop.firstMatch(name);
    if (stop != null) name = name.substring(0, stop.start);
    name = _cleanName(name);
    return name.isEmpty ? null : name;
  }

  /// True when [raw] carries an explicit factory-name label, so a plain
  /// follow-up answer on the details field is not mistaken for a name.
  static bool hasFactoryNameLabel(String raw) {
    return _factoryNameLabel.hasMatch(raw.trim());
  }

  /// Returns a factory-details value only when the answer explicitly carries
  /// a details label ("عنوانه ..", "تفاصيل المصنع ..", ...).
  static String? extractFactoryDetailsFromAnswer(String raw) {
    return _extractFactoryDetails(raw);
  }

  static String canonicalize(AiGuidedField field, String raw) {
    switch (field) {
      case AiGuidedField.manufacturingYear:
        return '${parseInt(raw) ?? 0}';
      case AiGuidedField.passengerCount:
        return '${parseInt(raw) ?? 0}';
      case AiGuidedField.licenseExpiryDate:
        final date = parseDate(raw);
        return date == null
            ? raw.trim()
            : '${date.day.toString().padLeft(2, '0')}/'
                '${date.month.toString().padLeft(2, '0')}/${date.year}';
      case AiGuidedField.specialConditions:
        final t = _normalize(raw);
        if (t.contains('محظور')) return 'محظورة بيع';
        if (t.contains('خالص') || t.contains('مخلص')) return 'السيارة خالصة';
        return raw.trim();
      case AiGuidedField.insuranceType:
        final t = _normalize(raw);
        if (t.startsWith('غير') || t.contains('منوش') || t.contains('منيش')) {
          return 'غير مؤمنة';
        }
        if (t.contains('مومن')) return 'مؤمنة';
        return raw.trim();
      case AiGuidedField.driverPhone:
        final digits = digitsToLatin(raw).replaceAll(RegExp(r'[^0-9]'), '');
        return digits.isEmpty ? raw.trim() : digits;
      default:
        return stripLeadingLabels(raw);
    }
  }

  /// Returns an Arabic validation error message, or null when [raw] is valid.
  static String? validate(AiGuidedField field, String raw) {
    final v = raw.trim();
    if (v.isEmpty) return '${field.label} مطلوب';

    switch (field) {
      case AiGuidedField.manufacturingYear:
        final year = parseInt(v);
        if (year == null || year < 1900 || year > DateTime.now().year + 1) {
          return 'من فضلك أدخل سنة صنع صحيحة';
        }
        return null;
      case AiGuidedField.passengerCount:
        final count = parseInt(v);
        if (count == null || count <= 0) {
          return 'أدخل عدد ركاب صحيح أكبر من صفر';
        }
        return null;
      case AiGuidedField.licenseExpiryDate:
        final date = parseDate(v);
        if (date == null) {
          return 'أدخل التاريخ بصيغة DD/MM/YYYY (مثال: 15/12/2025)';
        }
        return null;
      case AiGuidedField.specialConditions:
        final t = _normalize(v);
        if (!t.contains('محظور') && !(t.contains('خالص') || t.contains('مخلص'))) {
          return 'اختر: محظورة بيع أو السيارة خالصة';
        }
        return null;
      case AiGuidedField.insuranceType:
        final t = _normalize(v);
        if (!(t.contains('مومن') ||
            t.startsWith('غير') ||
            t.contains('منوش') ||
            t.contains('منيش'))) {
          return 'اختر: مؤمنة أو غير مؤمنة';
        }
        return null;
      case AiGuidedField.driverPhone:
        final digits = digitsToLatin(v).replaceAll(RegExp(r'[^0-9]'), '');
        if (digits.length < 6 || digits.length > 15) {
          return 'ادخل رقم تليفون صحيح (مثال: 01012345678)';
        }
        return null;
      default:
        return null;
    }
  }
}