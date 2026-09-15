import 'package:elostaz_travel/domain/bus/entity/bus_entity.dart';
import 'package:elostaz_travel/domain/driver/entity/driver_entity.dart';
import 'package:elostaz_travel/domain/factory/entity/factory_entity.dart';
import 'package:elostaz_travel/domain/trip/entity/trip_entity.dart';
import 'package:elostaz_travel/presentation/ai_assistant/model/ai_action_option.dart';
import 'package:elostaz_travel/presentation/ai_assistant/service/ai_field_parser.dart';
import 'package:elostaz_travel/presentation/ai_assistant/service/local_intent_service.dart';

class AiPeriod {
  final DateTime start;
  final DateTime end;
  final String label;

  const AiPeriod({
    required this.start,
    required this.end,
    required this.label,
  });

  bool contains(DateTime date) =>
      !date.isBefore(start) && date.isBefore(end);
}

/// Resolves chronological periods from Arabic text (اليوم، الأسبوع ده،
/// الشهر اللي فات، من..لـ...) using the app's effective trip date
/// (tripDate ?? createdAt) so reports match the in-app monthly report rule.
class AiPeriodParser {
  static DateTime _startOfDay(DateTime d) => DateTime(d.year, d.month, d.day);

  static AiPeriod? resolve(String text, {DateTime? now}) {
    final t = LocalIntentService.normalize(text);
    final reference = now ?? DateTime.now();
    final today = _startOfDay(reference);

    if (t.contains('امبارح') || t.contains('امس ') || t == 'امس') {
      final start = today.subtract(const Duration(days: 1));
      return AiPeriod(start: start, end: today, label: 'أمس');
    }
    if (t.contains('النهارده') || t.contains('اليوم')) {
      return AiPeriod(start: today, end: today.add(const Duration(days: 1)), label: 'اليوم');
    }
    if (t.contains('بكره') ||
        (t.contains('غدا') && !t.contains('طبقا')) ||
        (t.contains('غد') && !t.contains('من بعد'))) {
      final start = today.add(const Duration(days: 1));
      return AiPeriod(
          start: start, end: start.add(const Duration(days: 1)), label: 'بكرة');
    }

    final weekStart = today.subtract(Duration(days: today.weekday - 1));
    if (t.contains('الاسبوع اللي فات')) {
      final end = weekStart;
      return AiPeriod(
          start: end.subtract(const Duration(days: 7)),
          end: end,
          label: 'الأسبوع اللي فات');
    }
    if (t.contains('الاسبوع ده') ||
        t.contains('هذا الاسبوع') ||
        t.contains('اسابيع')) {
      return AiPeriod(
          start: weekStart,
          end: weekStart.add(const Duration(days: 7)),
          label: 'الأسبوع ده');
    }

    final thisMonthStart = DateTime(today.year, today.month);
    if (t.contains('الشهر اللي فات')) {
      final end = thisMonthStart;
      final start = DateTime(today.year, today.month - 1);
      return AiPeriod(start: start, end: end, label: 'الشهر اللي فات');
    }
    if (t.contains('الشهر ده') || t.contains('هذا الشهر')) {
      final start = thisMonthStart;
      final end = DateTime(start.year, start.month + 1);
      return AiPeriod(start: start, end: end, label: 'الشهر ده');
    }
    if (t.contains('الشهر الحالي') ||
        t.contains('الفتره دي') ||
        t.contains('الفترة دي')) {
      final start = thisMonthStart;
      final end = DateTime(start.year, start.month + 1);
      final label =
          t.contains('الفتره دي') || t.contains('الفترة دي') ? 'الفترة دي' : 'الشهر ده';
      return AiPeriod(start: start, end: end, label: label);
    }

    final rangeMatch = RegExp(
      r'من\s+(.+?)\s+(الي|لـ|الى)\s+(.+)',
    ).firstMatch(t);
    if (rangeMatch != null) {
      final from =
          AiFieldParser.parseDate(LocalIntentService.normalize(rangeMatch.group(1)!));
      final to =
          AiFieldParser.parseDate(LocalIntentService.normalize(rangeMatch.group(3)!));
      if (from != null && to != null) {
        final start = _startOfDay(from);
        final end = _startOfDay(to).add(const Duration(days: 1));
        return AiPeriod(
          start: start,
          end: end,
          label: 'من ${_monthName(from.day, from.month, from.year)} لـ '
              '${_monthName(to.day, to.month, to.year)}',
        );
      }
    }

    final monthName = _findMonthName(t);
    if (monthName != null) {
      final year = _extractYear(t, reference.year);
      final start = DateTime(year, monthName);
      final end = DateTime(year, monthName + 1);
      return AiPeriod(
          start: start, end: end, label: 'شهر ${_monthLabel(monthName)}');
    }

    final concrete = AiFieldParser.parseDate(text);
    if (concrete != null) {
      final start = _startOfDay(concrete);
      return AiPeriod(
          start: start,
          end: start.add(const Duration(days: 1)),
          label: _monthName(concrete.day, concrete.month, concrete.year));
    }

    return null;
  }

  static int? _findMonthName(String t) {
    const months = <String, int>{
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
    for (final entry in months.entries) {
      if (t.contains(entry.key)) return entry.value;
    }
    return null;
  }

  static int _extractYear(String t, int fallback) {
    final digits = AiFieldParser.digitsToLatin(t)
        .splitMapJoin(RegExp(r'\d{2,4}'), onMatch: (m) => ' ${m.group(0)} ', onNonMatch: (s) => ' ');
    final years = RegExp(r'\d{4}')
        .allMatches(digits)
        .map((m) => int.parse(m.group(0)!))
        .where((y) => y >= 1900 && y <= 2100)
        .toList();
    if (years.isNotEmpty) return years.last;
    final yy = RegExp(r'\d{2}').firstMatch(digits);
    if (yy != null) {
      final v = int.parse(yy.group(0)!);
      if (v >= 0 && v <= 99) return v + 2000;
    }
    return fallback;
  }

  static String _monthLabel(int month) {
    const arabicNames = [
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
    return arabicNames[month];
  }

  static String _monthName(int day, int month, int year) {
    return '$day ${_monthLabel(month)} $year';
  }
}

class AiQueryScope {
  final String? entityKind;
  final String? entityId;
  final String? entityName;

  const AiQueryScope({this.entityKind, this.entityId, this.entityName});
}

class AiQueryService {
  static DateTime effectiveDate(TripEntity trip) =>
      trip.tripDate ?? trip.createdAt;

  /// True when the text is a plain "how many / count" question (عندك كام سواق).
  /// Never returns true for trip-oriented phrases like "كم رحلة" because those
  /// are detected earlier as queryTrips before reaching this helper.
  static bool isCountQuery(String text) {
    final t = LocalIntentService.normalize(text);
    if (t.contains('عدد')) return true;
    return RegExp(r'(^|\s)(كم|كام|اد ايه|قد ايه)(\s|$)').hasMatch(t);
  }

  /// Finds ALL buses/drivers/factories whose name/plate actually appears in the
  /// message. More than one match means the entity is ambiguous — the caller
  /// must ask the user to choose instead of guessing.
  static List<AiQueryScope> resolveScopeCandidates(String text, {
    required List<BusEntity> buses,
    required List<DriverEntity> drivers,
    required List<FactoryEntity> factories,
  }) {
    final t = LocalIntentService.normalize(text);
    final result = <AiQueryScope>[];

    for (final d in drivers) {
      final n = LocalIntentService.normalize(d.name);
      if (n.isNotEmpty && t.contains(n)) {
        result.add(AiQueryScope(
          entityKind: 'driver',
          entityId: d.id,
          entityName: d.name,
        ));
      }
    }
    for (final b in buses) {
      final matchPlateOnly = result.isEmpty;
      final n = LocalIntentService.normalize(b.busName);
      final p = LocalIntentService.normalize(b.plateNumber);
      if (n.isNotEmpty && t.contains(n)) {
        result.add(AiQueryScope(
          entityKind: 'bus',
          entityId: b.id,
          entityName: b.busName,
        ));
      } else if (matchPlateOnly && p.isNotEmpty && t.contains(p)) {
        result.add(AiQueryScope(
          entityKind: 'bus',
          entityId: b.id,
          entityName: b.busName,
        ));
      }
    }
    for (final f in factories) {
      final n = LocalIntentService.normalize(f.name);
      if (n.isNotEmpty && t.contains(n)) {
        result.add(AiQueryScope(
          entityKind: 'factory',
          entityId: f.id,
          entityName: f.name,
        ));
      }
    }

    return result;
  }

  /// Finds a bus/driver/factory whose name appears in the message.
  /// Returns the first match — call [resolveScopeCandidates] when you need to
  /// detect ambiguity instead of guessing.
  static AiQueryScope resolveScope(String text, {
    required List<BusEntity> buses,
    required List<DriverEntity> drivers,
    required List<FactoryEntity> factories,
  }) {
    final candidates = resolveScopeCandidates(
      text,
      buses: buses,
      drivers: drivers,
      factories: factories,
    );
    if (candidates.isEmpty) return const AiQueryScope();
    return candidates.first;
  }

  /// Words that can legally follow an entity marker without naming a specific
  /// entity (generic queries like "أجر السواق خلال الفترة").
  static const Set<String> _syntaxTokens = {
    'خلال',
    'الفتره',
    'الفترة',
    'الشهر',
    'الاسبوع',
    'اليوم',
    'النهارده',
    'امبارح',
    'المستحق',
    'كم',
    'كام',
    'عدد',
    'في',
    'فيه',
    'عندي',
    'عندك',
    'عنديها',
    'لسه',
    'اللي',
    'ده',
    'دي',
    'دلوقتي',
    'انا',
    'بعد',
    'قبل',
    'من',
    'الي',
    'الى',
    'لـ',
    'عن',
    'علي',
    'اكل',
    'اكثر',
  };

  static const Set<String> _busMarkers = {
    'العربيه',
    'العربية',
    'العربه',
    'العربة',
    'الاتوبيس',
    'الاوتوبيس',
    'عربيه',
    'عربية',
    'عربه',
    'عربة',
    'اتوبيس',
    'اوتوبيس',
  };

  static const Set<String> _driverMarkers = {
    'السواق',
    'السايق',
    'السائق',
    'سواق',
    'سايق',
    'سائق',
  };

  static const Set<String> _factoryMarkers = {
    'المصنع',
    'الشركه',
    'الشركة',
    'شركه',
    'شركة',
    'مصنع',
  };

  /// True when the text clearly names one specific entity (singular marker
  /// followed by a real-looking token), as opposed to a generic category
  /// question ("كم عدد السواقين", "أجر السواق خلال الفترة").
  static bool isEntityReferenced(String text) {
    final tokens =
        LocalIntentService.normalize(text).split(RegExp(r'\s+'));
    final markers = <String>{
      ..._busMarkers,
      ..._driverMarkers,
      ..._factoryMarkers,
    };
    for (var i = 0; i < tokens.length - 1; i++) {
      if (!markers.contains(tokens[i])) continue;
      final following = tokens[i + 1];
      if (following.isEmpty || _syntaxTokens.contains(following)) continue;
      return true;
    }
    return false;
  }

  /// Arabic message shown when a query referenced a specific bus/driver/factory
  /// that does not exist in the user's current data.
  static String entityNotFoundMessage(AiActionId actionId) {
    final subject = switch (actionId) {
      AiActionId.queryBuses => 'أتوبيس',
      AiActionId.queryDrivers => 'سواق',
      AiActionId.queryFactories => 'مصنع',
      _ => 'كيان',
    };
    return 'مش لاقي $subject بالاسم/الرقم ده في بياناتك الحالية.\n'
        'إتأكد إنك كتبت الاسم صح، أو اسأل عن القايمة الكاملة.';
  }

  /// Arabic message shown when a query matched MORE than one existing entity.
  /// The assistant NEVER guesses — it asks the user to pick by typing the
  /// exact full name.
  static String ambiguousEntityMessage(List<AiQueryScope> candidates) {
    final names = candidates.map((c) => c.entityName ?? '').where((n) => n.isNotEmpty);
    final list = names.toSet().toList();
    if (list.isEmpty) return 'لقيت أكتر من واحد مطابق. اكتب الاسم كامل من فضلك.';
    return 'لقيت أكتر من واحد مطابق: ${list.join('، ')}\n'
        'اكتب الاسم بالكامل من القايمة دي عشان أجاوبك صح.';
  }

  static List<TripEntity> applyFilters(
    List<TripEntity> trips, {
    AiQueryScope? scope,
    AiPeriod? period,
  }) {
    var result = trips;
    if (period != null) {
      result =
          result.where((t) => period.contains(effectiveDate(t))).toList();
    }
    if (scope != null && scope.entityId != null && scope.entityKind != null) {
      result = result.where((t) {
        switch (scope.entityKind) {
          case 'bus':
            return t.busId == scope.entityId || t.busName == scope.entityName;
          case 'driver':
            return t.driverId == scope.entityId;
          case 'factory':
            return t.factoryId == scope.entityId ||
                (t.factoryName != null && t.factoryName == scope.entityName);
          default:
            return true;
        }
      }).toList();
    }
    return result;
  }

  static String answerTrips({
    required List<TripEntity> trips,
    required List<BusEntity> buses,
    required List<DriverEntity> drivers,
    required List<FactoryEntity> factories,
    AiQueryScope? scope,
    AiPeriod? period,
  }) {
    final filtered = applyFilters(trips, scope: scope, period: period);
    final nightCount = filtered.where((t) => t.isNightOuting).length;
    final tripCount = filtered.length - nightCount;

    double revenue = 0;
    double expenses = 0;
    double wages = 0;
    for (final t in filtered) {
      revenue += t.revenue;
      expenses += t.expenses;
      wages += t.driverWage ?? 0;
    }

    final scopeLabel = scope?.entityName ??
        switch (scope?.entityKind) {
          'bus' => 'الأتوبيس',
          'driver' => 'السائق',
          'factory' => 'المصنع',
          _ => 'كل الجهات',
        };

    if (scope != null &&
        (scope.entityId ?? '').isNotEmpty &&
        scope.entityName != null) {
      final buf = StringBuffer();
      final periodLabel = period?.label ?? 'كل الفترات';
      final total = filtered.length;
      final word = total == 1 ? 'رحلة' : 'رحلات';
      buf.writeln(switch (scope.entityKind) {
        'bus' => 'العربية "$scopeLabel" عملت $total $word خلال $periodLabel.',
        'driver' => 'السواق "$scopeLabel" عمل $total $word خلال $periodLabel.',
        'factory' => 'المصنع "$scopeLabel" عنده $total $word خلال $periodLabel.',
        _ => '',
      });
      buf.writeln('');
      buf.writeln('عدد الرحلات: $tripCount رحلة');
      buf.writeln('عدد السهرات: $nightCount سهرة');
      buf.writeln('الإجمالي: $total عملية');
      buf.writeln('💰 الإيراد الكلي: ${_fmt(revenue)} جنيه');
      buf.writeln('💸 المصروفات: ${_fmt(expenses)} جنيه');
      buf.writeln('📈 الصافي: ${_fmt(revenue - expenses)} جنيه');
      return buf.toString();
    }

    final buf = StringBuffer('📊 تقرير الرحلات\n\n');
    buf.writeln('النطاق: $scopeLabel');
    buf.writeln('الفترة: ${period?.label ?? 'كل الفترات'}');
    buf.writeln('');
    buf.writeln('عدد الرحلات: $tripCount رحلة');
    buf.writeln('عدد السهرات: $nightCount سهرة');
    buf.writeln('الإجمالي: ${filtered.length} عملية');
    buf.writeln('');
    buf.writeln('💰 الإيراد الكلي: ${_fmt(revenue)} جنيه');
    buf.writeln('💸 المصروفات: ${_fmt(expenses)} جنيه');
    buf.writeln('📈 الصافي: ${_fmt(revenue - expenses)} جنيه');
    buf.writeln('💵 أجور السائقين المستحقة: ${_fmt(wages)} جنيه');
    return buf.toString();
  }

  /// Answers a scoped driver-wage question ("أجر السواق X المستحق الشهر ده كام؟")
  /// using ONLY the real stored `trip.driverWage` values of the driver's trips
  /// within [period]. No wage is invented or derived from other fields.
  static String answerDriverWage({
    required String driverName,
    required List<TripEntity> trips,
    AiPeriod? period,
  }) {
    final filtered = period == null
        ? trips
        : trips.where((t) => period.contains(effectiveDate(t))).toList();

    final total = filtered.length;
    final nightCount = filtered.where((t) => t.isNightOuting).length;
    final tripCount = total - nightCount;

    var wage = 0.0;
    for (final t in filtered) {
      wage += t.driverWage ?? 0;
    }

    final periodLabel = period?.label ?? 'كل الفترات';
    final buf = StringBuffer('👨‍✈️ أجر السواق "$driverName"\n\n');
    buf.writeln('الفترة: $periodLabel');
    buf.writeln('');
    buf.writeln('💵 الأجر المستحق (من الرحلات المسجلة): ${_fmt(wage)} جنيه');
    buf.writeln('عدد الرحلات: $tripCount');
    buf.writeln('عدد السهرات: $nightCount');
    buf.writeln('إجمالي العمليات: $total');
    return buf.toString();
  }

  static String answerBusesCount(List<BusEntity> buses) {
    if (buses.isEmpty) {
      return 'مفيش أتوبيسات مسجلة لسه. اضغط "إضافة أتوبيس" ونسجّل أول أتوبيس 😉';
    }
    final n = buses.length;
    return n == 1
        ? 'عندك أتوبيس واحد مسجل حالياً.'
        : 'عندك $n أتوبيسات مسجلين حالياً.';
  }

  static String answerBuses({
    required List<BusEntity> buses,
    List<TripEntity>? trips,
    AiPeriod? period,
  }) {
    if (buses.isEmpty) {
      return 'مفيش أتوبيسات مسجلة لسه. اضغط "إضافة أتوبيس" ونسجّل أول أتوبيس 😉';
    }

    final buf = StringBuffer('🚌 الأتوبيسات\n');
    buf.writeln('الفترة: ${period?.label ?? 'كل الفترات'}');
    buf.writeln('');

    if (trips == null) {
      for (final b in buses) {
        buf.writeln('• ${b.busName} (${b.plateNumber})');
      }
      if (period != null) {
        buf.writeln('');
        buf.writeln(
            'مقدرتش أجيب تفاصيل رحلات الأتوبيسات في الفترة دي حالياً، '
            'جرب بعد شوية.');
      }
      return buf.toString();
    }

    final filtered = period == null
        ? trips
        : trips.where((t) => period.contains(effectiveDate(t))).toList();

    for (final b in buses) {
      final busTrips = filtered.where((t) => t.busId == b.id).toList();
      final revenue =
          busTrips.fold<double>(0, (sum, t) => sum + t.revenue);
      buf.writeln('• ${b.busName} (${b.plateNumber})');
      buf.writeln(
          '   ${busTrips.length} رحلة، إيراد ${_fmt(revenue)} جنيه');
    }
    return buf.toString();
  }

  static String answerDriversCount(List<DriverEntity> drivers) {
    if (drivers.isEmpty) {
      return 'مفيش سواقين مسجلين لسه. اضغط "إضافة سائق" ونسجّل أول سائق 😉';
    }
    final n = drivers.length;
    return n == 1
        ? 'عندك سواق واحد مسجل حالياً.'
        : 'عندك $n سواق مسجلين حالياً.';
  }

  static String answerDrivers({
    required List<DriverEntity> drivers,
    List<TripEntity>? trips,
    AiPeriod? period,
  }) {
    if (drivers.isEmpty) {
      return 'مفيش سواقين مسجلين لسه. اضغط "إضافة سائق" ونسجّل أول سائق 😉';
    }

    final buf = StringBuffer('👨‍✈️ السائقين\n');
    buf.writeln('الفترة: ${period?.label ?? 'كل الفترات'}');
    buf.writeln('');

    if (trips == null) {
      for (final d in drivers) {
        buf.writeln(
            '• ${d.name}${d.phone.isNotEmpty ? ' (${d.phone})' : ''}');
        buf.writeln(
            '   الرحلات الكلية: ${d.tripsCount}، إيراد ${_fmt(d.totalRevenue)} جنيه');
      }
      if (period != null) {
        buf.writeln('');
        buf.writeln(
            'مقدرتش أجيب تفاصيل رحلات السواقين في الفترة دي حالياً، '
            'جرب بعد شوية.');
      }
      return buf.toString();
    }

    final filtered = period == null
        ? trips
        : trips.where((t) => period.contains(effectiveDate(t))).toList();

    for (final d in drivers) {
      final driverTrips =
          filtered.where((t) => t.driverId == d.id).toList();
      final wages = driverTrips.fold<double>(
          0, (sum, t) => sum + (t.driverWage ?? 0));
      buf.writeln(
          '• ${d.name}${d.phone.isNotEmpty ? ' (${d.phone})' : ''}');
      buf.writeln(
          '   الرحلات: ${d.tripsCount}، إيراد ${_fmt(d.totalRevenue)} جنيه');
      buf.writeln(
          '   الأجر المستحق في الفترة: ${_fmt(wages)} جنيه');
    }
    return buf.toString();
  }

  static String answerFactoriesCount(List<FactoryEntity> factories) {
    if (factories.isEmpty) {
      return 'مفيش مصانع مسجلة لسه. اضغط "إضافة مصنع" ونسجّل أول مصنع 😉';
    }
    final n = factories.length;
    return n == 1
        ? 'عندك مصنع واحد مسجل حالياً.'
        : 'عندك $n مصانع مسجلة حالياً.';
  }

  static String answerTripsCount({
    required List<DriverEntity> drivers,
  }) {
    final totalTrips =
        drivers.fold<int>(0, (sum, d) => sum + d.tripsCount);
    if (totalTrips == 0) {
      return 'مفيش رحلات مسجلة لسه. اضغط "إضافة رحلة" ونسجّل أول رحلة 😉';
    }
    return totalTrips == 1
        ? 'عندك رحلة واحدة مسجلة حالياً.'
        : 'عندك $totalTrips رحلة مسجلة حالياً.';
  }

  static String answerFactories({
    required List<FactoryEntity> factories,
    List<TripEntity>? trips,
    AiPeriod? period,
  }) {
    if (factories.isEmpty) {
      return 'مفيش مصانع مسجلة لسه. اضغط "إضافة مصنع" ونسجّل أول مصنع 😉';
    }

    final buf = StringBuffer('🏭 المصانع\n');
    buf.writeln('الفترة: ${period?.label ?? 'كل الفترات'}');
    buf.writeln('');

    if (trips == null) {
      for (final f in factories) {
        buf.writeln('• ${f.name}');
        buf.writeln(
            '   الرحلات الكلية: ${f.tripsCount}، إيراد ${_fmt(f.totalRevenue)} جنيه');
      }
      if (period != null) {
        buf.writeln('');
        buf.writeln(
            'مقدرتش أجيب تفاصيل الرحلات في الفترة دي حالياً، '
            'جرب بعد شوية.');
      }
      return buf.toString();
    }

    final filtered = period == null
        ? trips
        : trips.where((t) => period.contains(effectiveDate(t))).toList();

    for (final f in factories) {
      final factoryTrips =
          filtered.where((t) => t.factoryId == f.id).toList();
      final revenue = factoryTrips.fold<double>(
          0, (sum, t) => sum + t.revenue);
      buf.writeln('• ${f.name}');
      buf.writeln(
          '   الرحلات الكلية: ${f.tripsCount}، إيراد ${_fmt(f.totalRevenue)} جنيه');
      if (period != null) {
        buf.writeln(
            '   إيراد ${period.label}: ${_fmt(revenue)} جنيه');
      }
    }
    return buf.toString();
  }

  static String _fmt(double v) {
    return v.toStringAsFixed(v == v.roundToDouble() ? 0 : 1);
  }
}