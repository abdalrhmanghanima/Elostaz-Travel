import 'package:elostaz_travel/domain/ai_assistant/entity/ai_action_result.dart';
import 'package:elostaz_travel/domain/ai_assistant/entity/ai_trip_draft.dart';
import 'package:elostaz_travel/domain/bus/entity/bus_entity.dart';
import 'package:elostaz_travel/domain/driver/entity/driver_entity.dart';
import 'package:elostaz_travel/domain/factory/entity/factory_entity.dart';

class _BusMatch {
  final String name;
  final String? plate;

  const _BusMatch({required this.name, this.plate});
}

class LocalTripParser {
  static const _arabicMonths = {
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

  AiActionResult parse({
    required String userMessage,
    required AiTripDraft currentDraft,
    required List<BusEntity> availableBuses,
    required List<DriverEntity> availableDrivers,
    required List<FactoryEntity> availableFactories,
  }) {
    final text = _normalize(userMessage);

    if (!_isTripRelated(
      text,
      availableBuses,
      availableDrivers,
      availableFactories,
    )) {
      return const AiActionResult(
        type: AiActionType.generalChat,
        assistantMessage:
            'أنا مساعدك الذكي في Elostaz Travel.\n'
            'قولّي عايز تعمل رحلة وهساعدك في استخراج البيانات.\n'
            'مثلاً: "عايز أعمل رحلة للأتوبيس [الاسم] والسواق [الاسم]"',
      );
    }

    final busMatch = _matchBus(text, availableBuses);
    final driverName = _matchDriver(text, availableDrivers);
    final factoryName = _matchFactory(text, availableFactories);
    final revenue = _extractRevenue(text);
    final driverWage = _extractDriverWage(text);
    final tripDate = _extractDate(text);
    final departureTime = _extractTime(text);
    final type = _extractType(text);
    final expenses = _extractExpenses(text);
    final details = _extractDetails(text);
    final expenseDetails = _extractExpenseDetails(text);

    final newDraft = AiTripDraft(
      busName: busMatch?.name,
      plateNumber: busMatch?.plate,
      driverName: driverName,
      factoryName: factoryName,
      revenue: revenue,
      driverWage: driverWage,
      tripDate: tripDate,
      departureTime: departureTime,
      type: type,
      expenses: expenses,
      details: details,
      expenseDetails: expenseDetails,
    );

    final merged = currentDraft.merge(newDraft);
    final missing = merged.missingRequiredFields;

    if (missing.isNotEmpty) {
      return AiActionResult(
        type: AiActionType.missingFields,
        assistantMessage: _buildMissingMessage(
          missing,
          merged,
          availableBuses,
          availableDrivers,
        ),
        tripDraft: merged,
        missingFields: missing,
      );
    }

    return AiActionResult(
      type: AiActionType.createTrip,
      assistantMessage: _buildSummaryMessage(merged),
      tripDraft: merged,
    );
  }

  String _normalize(String text) {
    return text
        .replaceAll(RegExp(r'[\u0610-\u061A\u06D6-\u06ED]'), '')
        .replaceAll(RegExp(r'[أإآ]'), 'ا')
        .replaceAll('ة', 'ه')
        .replaceAll('ى', 'ي')
        .toLowerCase()
        .trim();
  }

  String _normalizeDigits(String text) {
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
        .replaceAll('٩', '9')
        .replaceAll('٫', '.');
  }

  bool _isTripRelated(
    String text,
    List<BusEntity> buses,
    List<DriverEntity> drivers,
    List<FactoryEntity> factories,
  ) {
    const keywords = [
      'رحله',
      'سهره',
      'سحور',
      'اعمل',
      'عايز',
      'اتوبيس',
      'سواق',
      'مصنع',
      'يوم',
      'الساعه',
      'جنيه',
      'ايراد',
      'اجر',
      'سعر',
      'نمره',
      'مصروف',
      'مصاريف',
      'تفاصيل الرحله',
      'تفاصيل المصروف',
      'التفاصيل',
    ];

    for (final kw in keywords) {
      if (text.contains(kw)) return true;
    }

    for (final bus in buses) {
      final busName = _normalize(bus.busName);
      final plate = _normalize(bus.plateNumber);
      if ((busName.isNotEmpty && text.contains(busName)) ||
          (plate.isNotEmpty && text.contains(plate))) {
        return true;
      }
    }

    for (final driver in drivers) {
      final name = _normalize(driver.name);
      if (name.isNotEmpty && text.contains(name)) return true;
    }

    for (final factory in factories) {
      final name = _normalize(factory.name);
      if (name.isNotEmpty && text.contains(name)) return true;
    }

    if (_timeHintPattern.hasMatch(text)) return true;

    return false;
  }

  _BusMatch? _matchBus(String text, List<BusEntity> buses) {
    for (final bus in buses) {
      final plate = _normalize(bus.plateNumber);
      if (plate.isNotEmpty && text.contains(plate)) {
        return _BusMatch(name: bus.busName, plate: bus.plateNumber);
      }
    }

    for (final bus in buses) {
      final name = _normalize(bus.busName);
      if (name.isNotEmpty && text.contains(name)) {
        return _BusMatch(name: bus.busName);
      }
    }

    return null;
  }

  String? _matchDriver(String text, List<DriverEntity> drivers) {
    for (final driver in drivers) {
      final name = _normalize(driver.name);
      if (name.isNotEmpty && text.contains(name)) {
        return driver.name;
      }
    }
    return null;
  }

  String? _matchFactory(String text, List<FactoryEntity> factories) {
    for (final factory in factories) {
      final name = _normalize(factory.name);
      if (name.isNotEmpty && text.contains(name)) {
        return factory.name;
      }
    }
    return null;
  }

  double? _extractRevenue(String text) {
    final dayRef = r'(?:ال(?:يوم|نهارده|نهار)?\s+)?';
    final patterns = [
      RegExp('الايراد\\s+$dayRef(\\d+(?:[.,]\\d+)?)'),
      RegExp('ايراد\\s+$dayRef(\\d+(?:[.,]\\d+)?)'),
      RegExp('السعر\\s+$dayRef(\\d+(?:[.,]\\d+)?)'),
      RegExp('سعر\\s+$dayRef(\\d+(?:[.,]\\d+)?)'),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        return _parseNumber(match.group(1)!);
      }
    }

    final ginehMatch = RegExp(r'(\d+(?:[.,]\d+)?)\s*جنيه').firstMatch(text);
    if (ginehMatch != null) {
      final before = text.substring(0, ginehMatch.start);
      if (!before.contains(RegExp(r'اجر|اجره|الاجر|الاجره|مصروف'))) {
        return _parseNumber(ginehMatch.group(1)!);
      }
    }

    return null;
  }

  double? _extractDriverWage(String text) {
    final patterns = [
      RegExp(r'اجر\s+السواق\s+المستحق\s+(\d+(?:[.,]\d+)?)'),
      RegExp(r'اجره\s+السواق\s+المستحق\s+(\d+(?:[.,]\d+)?)'),
      RegExp(r'اجر\s+السائق\s+المستحق\s+(\d+(?:[.,]\d+)?)'),
      RegExp(r'اجره\s+السائق\s+المستحق\s+(\d+(?:[.,]\d+)?)'),
      RegExp(r'الاجر\s+المستحق\s+(\d+(?:[.,]\d+)?)'),
      RegExp(r'الاجره\s+المستحق\s+(\d+(?:[.,]\d+)?)'),
      RegExp(r'اجر\s+السواق\s+(\d+(?:[.,]\d+)?)'),
      RegExp(r'اجره\s+السواق\s+(\d+(?:[.,]\d+)?)'),
      RegExp(r'اجر\s+السائق\s+(\d+(?:[.,]\d+)?)'),
      RegExp(r'اجره\s+السائق\s+(\d+(?:[.,]\d+)?)'),
      RegExp(r'اجره\s+(?:اليوم\s+)?(\d+(?:[.,]\d+)?)'),
      RegExp(r'اجر\s+(?:اليوم\s+)?(\d+(?:[.,]\d+)?)'),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        return _parseNumber(match.group(1)!);
      }
    }

    return null;
  }

  double? _extractExpenses(String text) {
    final patterns = [
      RegExp(r'مصروف\s+الرحله\s+(\d+(?:[.,]\d+)?)'),
      RegExp(r'مصروفات\s+الرحله\s+(\d+(?:[.,]\d+)?)'),
      RegExp(r'مصاريف\s+الرحله\s+(\d+(?:[.,]\d+)?)'),
      RegExp(r'مصرايف\s+الرحله\s+(\d+(?:[.,]\d+)?)'),
      RegExp(r'مصروفات\s+(\d+(?:[.,]\d+)?)'),
      RegExp(r'المصروف\s+(\d+(?:[.,]\d+)?)'),
      RegExp(r'المصاريف\s+(\d+(?:[.,]\d+)?)'),
      RegExp(r'المصرايف\s+(\d+(?:[.,]\d+)?)'),
      RegExp(r'مصروف\s+(\d+(?:[.,]\d+)?)'),
      RegExp(r'مصاريف\s+(\d+(?:[.,]\d+)?)'),
      RegExp(r'مصرايف\s+(\d+(?:[.,]\d+)?)'),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        return _parseNumber(match.group(1)!);
      }
    }

    return null;
  }

  /// Field-start words that terminate a captured free-text section
  /// (details / expense details). `و`-glued variants are handled by
  /// [_findStop]; both plain and `ال`-prefixed forms are listed because the
  /// boundary regex only sees one separator character.
  static const _detailStops = [
    'والايراد',
    'الايراد',
    'ايراد',
    'والاجر',
    'الاجر',
    'الاجره',
    'اجر',
    'اجره',
    'ومصروف',
    'المصروف',
    'مصروف',
    'مصروفات',
    'ومصاريف',
    'المصاريف',
    'مصاريف',
    'ومصرايف',
    'المصرايف',
    'مصرايف',
    'وتفاصيل المصروف',
    'تفاصيل المصروف',
    'والمصنع',
    'المصنع',
    'والساعه',
    'الساعه',
    'والوقت',
    'الوقت',
    'واليوم',
    'اليوم',
    'وغدا',
    'غدا',
    'وبكره',
    'بكره',
    'والنوع',
    'النوع',
    'والسهره',
    'السهره',
  ];

  String? _extractDetails(String text) {
    for (final marker in ['تفاصيل الرحله', 'التفاصيل']) {
      final value = _extractAfterMarker(text, marker, _detailStops);
      if (value != null) return value;
    }
    return null;
  }

  String? _extractExpenseDetails(String text) {
    return _extractAfterMarker(text, 'تفاصيل المصروف', _detailStops);
  }

  /// Captures everything after [marker] until the first stop keyword
  /// (or end of text). Returns null when empty.
  String? _extractAfterMarker(String text, String marker, List<String> stops) {
    final match = RegExp(RegExp.escape(marker)).firstMatch(text);
    if (match == null) return null;

    final from = match.end;
    final stopIndex = _findStop(text, from, stops);
    final end = stopIndex ?? text.length;
    final value = text.substring(from, end).trim();
    return value.isEmpty ? null : value;
  }

  /// Earliest start index of any stop keyword at/after [from].
  /// The keyword must sit at a word-like boundary: a preceding separator
  /// (`و` or whitespace) or the very start of the string.
  int? _findStop(String text, int from, List<String> stops) {
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

  DateTime? _extractDate(String text) {
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
      final day = int.tryParse(_normalizeDigits(slashMatch.group(1)!));
      final month = int.tryParse(_normalizeDigits(slashMatch.group(2)!));
      final yearStr = slashMatch.group(3);
      final year = yearStr != null
          ? int.tryParse(_normalizeDigits(yearStr))
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

  DateTime? _parseDayMonth(String dayStr, String monthStr) {
    final day = int.tryParse(_normalizeDigits(dayStr));
    if (day == null) return null;

    final normalizedMonth = _normalize(monthStr);
    final month = _arabicMonths[normalizedMonth];
    if (month == null) return null;

    return DateTime(DateTime.now().year, month, day);
  }

  /// Matches `H:mm` (or `H.mm`) directly followed by an Arabic time word.
  static final RegExp _time12HourAndMinutes = RegExp(
    r'(?:الساعه\s+)?(\d{1,2})\s*[:.،]\s*(\d{1,2})\s*'
    r'(الصبح|صباحا|مساءا|مساء|بالليل|ليلا|الليل|المغرب|ظهرا|الظهر|العصر|عصر|'
    r'ص(?![\u0600-\u06FF])|م(?![\u0600-\u06FF]))',
  );

  /// Matches an hour directly followed by an Arabic time word (<12h + period).
  static final RegExp _time12HourOnly = RegExp(
    r'(?:الساعه\s+)?(\d{1,2})\s*'
    r'(الصبح|صباحا|مساءا|مساء|بالليل|ليلا|الليل|المغرب|ظهرا|الظهر|العصر|عصر|'
    r'ص(?![\u0600-\u06FF])|م(?![\u0600-\u06FF]))',
  );

  /// Matches an explicit 24-hour `H:mm`.
  static final RegExp _time24HourAndMinutes = RegExp(
    r'(?:الساعه\s+)?(\d{1,2}):(\d{1,2})(?!\d)',
  );

  /// Matches a bare hour after `الساعة` (treated as 24-hour).
  static final RegExp _time24HourOnly = RegExp(r'الساعه\s+(\d{1,2})(?!\d)');

  /// A number + Arabic time word (or a colon time) is itself a trip hint.
  static final RegExp _timeHintPattern = RegExp(
    r'(\d{1,2}:\d{1,2})|'
    r'(\d{1,2})\s*'
    r'(الصبح|صباحا|مساءا|مساء|بالليل|ليلا|الليل|المغرب|ظهرا|الظهر|العصر|عصر|'
    r'ص(?![\u0600-\u06FF])|م(?![\u0600-\u06FF]))',
  );

  /// Extracts the trip time and normalizes it to canonical 24-hour `HH:mm`.
  ///
  /// 12-hour inputs with an Arabic period (صباحا/مساء/م/...) are converted to
  /// 24-hour; explicit 24-hour inputs (`الساعة 17:00`) are kept as-is; `12`
  /// behaves per the period (12 مساء -> 12:00, 12 صباحا -> 00:00).
  String? _extractTime(String text) {
    final t = _normalizeDigits(text);

    final match12Minutes = _time12HourAndMinutes.firstMatch(t);
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

    final match12Hour = _time12HourOnly.firstMatch(t);
    if (match12Hour != null) {
      final hour = int.tryParse(match12Hour.group(1)!);
      if (hour != null && hour >= 1 && hour <= 12) {
        return _formatTime(hour, 0, match12Hour.group(2)!);
      }
    }

    final match24 = _time24HourAndMinutes.firstMatch(t);
    if (match24 != null) {
      final hour = int.tryParse(match24.group(1)!);
      final minute = int.tryParse(match24.group(2)!);
      if (hour != null && minute != null && hour <= 23 && minute <= 59) {
        return _formatDateTime(hour, minute);
      }
    }

    final match24Hour = _time24HourOnly.firstMatch(t);
    if (match24Hour != null) {
      final hour = int.tryParse(match24Hour.group(1)!);
      if (hour != null && hour <= 23) {
        return _formatDateTime(hour, 0);
      }
    }

    return null;
  }

  /// Converts a 12-hour hour/minute/period into canonical `HH:mm`.
  String _formatTime(int hour, int minute, String period) {
    final isAm = period == 'ص' || period == 'صباحا' || period == 'الصبح';
    final hour24 = isAm
        ? (hour == 12 ? 0 : hour)
        : (hour == 12 ? 12 : hour + 12);
    return _formatDateTime(hour24, minute);
  }

  String _formatDateTime(int hour, int minute) {
    final hh = hour.toString().padLeft(2, '0');
    final mm = minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  String? _extractType(String text) {
    if (text.contains('سهره') ||
        text.contains('سحور') ||
        text.contains('ليل')) {
      return 'night_outing';
    }
    if (text.contains('رحله')) {
      return 'trip';
    }
    return null;
  }

  double? _parseNumber(String text) {
    final normalized = _normalizeDigits(text.replaceAll(',', ''));
    return double.tryParse(normalized);
  }

  String _buildMissingMessage(
    List<String> missing,
    AiTripDraft draft,
    List<BusEntity> buses,
    List<DriverEntity> drivers,
  ) {
    final buffer = StringBuffer();

    final captured = <String>[];
    if (draft.busName != null) {
      captured.add('الأتوبيس ${draft.busName}');
    }
    if (draft.driverName != null) {
      captured.add('السواق ${draft.driverName}');
    }
    if (draft.revenue != null) {
      captured.add('الايراد ${draft.revenue!.toInt()} جنيه');
    }
    if (draft.driverWage != null) {
      captured.add('أجر السواق ${draft.driverWage!.toInt()}');
    }
    if (draft.factoryName != null) {
      captured.add('المصنع ${draft.factoryName}');
    }
    if (draft.details != null && draft.details!.isNotEmpty) {
      captured.add('التفاصيل "${draft.details}"');
    }
    if (draft.expenses != null) {
      captured.add('مصروف الرحلة ${draft.expenses!.toInt()} جنيه');
    }
    if (draft.expenseDetails != null && draft.expenseDetails!.isNotEmpty) {
      captured.add('تفاصيل المصروف "${draft.expenseDetails}"');
    }
    if (captured.isNotEmpty) {
      buffer.write('تمام، فهمت إنك عايز رحلة ');
      buffer.write(captured.join(' و'));
      buffer.write('. ');
    }

    if (missing.contains('الأتوبيس')) {
      buffer.write('محتاج أعرف الأتوبيس.');
      if (buses.isNotEmpty) {
        buffer.write(
          ' عندك الأتوبيسات دي: ${buses.map((b) => b.busName).join("، ")}',
        );
      }
      buffer.write('\n');
    }

    if (missing.contains('السواق')) {
      buffer.write('محتاج أعرف السواق.');
      if (drivers.isNotEmpty) {
        buffer.write(
          ' السواقين المتاحين: ${drivers.map((d) => d.name).join("، ")}',
        );
      }
    }

    return buffer.toString();
  }

  String _buildSummaryMessage(AiTripDraft draft) {
    final buffer = StringBuffer('تمام! راجع البيانات دي:\n\n');

    buffer.write('الأتوبيس: ${draft.busName}');
    if (draft.plateNumber != null) {
      buffer.write(' (${draft.plateNumber})');
    }
    buffer.write('\n');

    buffer.write('السواق: ${draft.driverName}\n');

    if (draft.factoryName != null) {
      buffer.write('المصنع: ${draft.factoryName}\n');
    }

    if (draft.tripDate != null) {
      buffer.write('التاريخ: ${_formatDate(draft.tripDate!)}\n');
    }

    if (draft.departureTime != null) {
      buffer.write('الوقت: ${draft.departureTime}\n');
    }

    if (draft.revenue != null) {
      buffer.write('الايراد: ${draft.revenue!.toInt()} جنيه\n');
    }

    if (draft.driverWage != null) {
      buffer.write('أجر السواق المستحق: ${draft.driverWage!.toInt()} جنيه\n');
    }

    if (draft.details != null && draft.details!.isNotEmpty) {
      buffer.write('التفاصيل: ${draft.details}\n');
    }

    if (draft.expenses != null) {
      buffer.write('مصروف الرحلة: ${draft.expenses!.toInt()} جنيه\n');
    }

    if (draft.expenseDetails != null && draft.expenseDetails!.isNotEmpty) {
      buffer.write('تفاصيل المصروف: ${draft.expenseDetails}\n');
    }

    buffer.write('النوع: ${draft.type == 'night_outing' ? 'سهرة' : 'رحلة'}\n');

    buffer.write('\nعندك تعديل ولا ننفذه؟');

    return buffer.toString();
  }

  String _formatDate(DateTime date) {
    const months = [
      '',
      'يناير',
      'فبراير',
      'مارس',
      'أبريل',
      'مايو',
      'يونيو',
      'يوليو',
      'أغسطس',
      'سبتمبر',
      'أكتوبر',
      'نوفمبر',
      'ديسمبر',
    ];
    return '${date.day} ${months[date.month]} ${date.year}';
  }
}
