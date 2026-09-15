import 'package:elostaz_travel/domain/bus/entity/bus_entity.dart';
import 'package:elostaz_travel/domain/driver/entity/driver_entity.dart';
import 'package:elostaz_travel/domain/factory/entity/factory_entity.dart';
import 'package:elostaz_travel/presentation/ai_assistant/model/ai_action_option.dart';
import 'package:elostaz_travel/presentation/ai_assistant/model/ai_guided_field.dart';
import 'package:elostaz_travel/presentation/ai_assistant/service/ai_entity_resolver.dart';

/// Guards the AI additive flows against creating entities that already exist.
///
/// Before any Add Bus/Driver/Factory is executed, [checkCreate] resolves the
/// incoming values against the CURRENT provider data using the same
/// canonicalization used by [AiEntityResolver]:
///   - A) unique existing entity        -> returns a "already exists" message
///   - B) several existing entities     -> returns an "which one?" message
///   - D) name exists with a conflict   -> returns an explaining message
///   - C) no existing entity            -> returns null (safe to create)
/// The AI never creates a duplicate and never updates/deletes anything.
class AiDuplicateChecker {
  /// Short SnackBar text shown above the AI Assistant BottomSheet when a
  /// duplicate blocks creation. [checkCreate] still owns the duplicate
  /// determination; this only maps the action to the required notification.
  static String snackMessageFor(AiActionId action) {
    return switch (action) {
      AiActionId.addBus => 'معرفتش أضيف الأتوبيس، موجود بالفعل',
      AiActionId.addDriver => 'معرفتش أضيف السواق، موجود بالفعل',
      AiActionId.addFactory => 'معرفتش أضيف المصنع، موجود بالفعل',
      _ => 'البيانات دي موجودة بالفعل',
    };
  }

  static String? checkCreate({
    required AiActionId action,
    required Map<String, String> values,
    required List<BusEntity> buses,
    required List<DriverEntity> drivers,
    required List<FactoryEntity> factories,
  }) {
    switch (action) {
      case AiActionId.addDriver:
        return _checkDriver(values, drivers);
      case AiActionId.addBus:
        return _checkBus(values, buses);
      case AiActionId.addFactory:
        return _checkFactory(values, factories);
      default:
        return null;
    }
  }

  static String? _checkDriver(
    Map<String, String> values,
    List<DriverEntity> drivers,
  ) {
    final name = values[AiGuidedField.driverName.name]?.trim() ?? '';
    if (name.isEmpty) return null;

    final nameKey = AiEntityResolver.normalizeKey(name);
    final matches = drivers
        .where((d) => AiEntityResolver.normalizeKey(d.name) == nameKey)
        .toList();
    if (matches.isEmpty) return null;

    if (matches.length > 1) {
      return 'لقيت أكتر من سايق باسم "$name" 🤔\n\n'
          'مش هقدر أحدد السايق المقصود وأضيف نسخة تانية.\n'
          'قول لي أي تفصيلة تميزه (زِه رقم التليفون) أو كله حط اسم مختلف.';
    }

    final existing = matches.first;
    final phone = values[AiGuidedField.driverPhone.name]?.trim() ?? '';
    final existingPhone = existing.phone.trim();
    if (phone.isNotEmpty &&
        existingPhone.isNotEmpty &&
        AiEntityResolver.normalizeKey(existingPhone) !=
            AiEntityResolver.normalizeKey(phone)) {
      return 'السايق "$name" موجود بالفعل لكن مسجل بتليفون مختلف '
          '($existingPhone) 🤔\n\n'
          'لو ده المقصود، بياناته محفوظة من قبل، ومش هضيف نسخة تانية '
          'ومش هعدل حاجة في بياناته.';
    }

    final labeledPhone =
        existingPhone.isNotEmpty ? existingPhone : 'مش مسجل';
    return 'السايق "$name" موجود بالفعل ✅\n\n'
        'الاسم: ${existing.name}\n'
        'التليفون: $labeledPhone\n\n'
        'فمش هضيفه تاني. لو تقصد سايق جديد خليه باسم مختلف.';
  }

  static String? _checkBus(
    Map<String, String> values,
    List<BusEntity> buses,
  ) {
    final name = values[AiGuidedField.busName.name]?.trim() ?? '';
    final plate = values[AiGuidedField.plateNumber.name]?.trim() ?? '';

    final nameKey = name.isEmpty ? null : AiEntityResolver.normalizeKey(name);
    final plateKey = plate.isEmpty ? null : AiEntityResolver.normalizeKey(plate);

    final plateMatches = plateKey == null
        ? <BusEntity>[]
        : buses
            .where((b) =>
                AiEntityResolver.normalizeKey(b.plateNumber) == plateKey)
            .toList();
    final nameMatches = nameKey == null
        ? <BusEntity>[]
        : buses
            .where((b) => AiEntityResolver.normalizeKey(b.busName) == nameKey)
            .toList();

    if (plateMatches.length > 1) {
      return 'أكتر من أتوبيس مسجل برقم العربيه "$plate" 🤔\n\n'
          'مش هقدر أحدد وأضيف نسخة تانية. شوف قايمة العربيات وميّز '
          'اللي تقصده.';
    }
    if (plateMatches.length == 1) {
      final existing = plateMatches.first;
      return 'الأتوبيس برقم العربيه "${existing.plateNumber}" '
          'موجود بالفعل ✅\n\n'
          'الاسم: ${existing.busName}\n'
          'العلامة: ${existing.brand.isNotEmpty ? existing.brand : '-'}\n\n'
          'فمش هضيفه تاني. لو تقصد عربية جديدة خليها برقم عربية مختلف.';
    }

    if (nameMatches.length > 1) {
      return 'أكتر من أتوبيس باسم "$name" 🤔\n\n'
          'مش هقدر أحدد وأضيف نسخة تانية. شوف قايمة العربيات وميّز '
          'اللي تقصده (بالرقم أو أي تفصيلة).';
    }
    if (nameMatches.length == 1) {
      final existing = nameMatches.first;
      return 'في أتوبيس باسم "${existing.busName}" موجود بالفعل ✅\n\n'
          'رقم العربيه: ${existing.plateNumber}\n'
          'العلامة: ${existing.brand.isNotEmpty ? existing.brand : '-'}\n\n'
          'فمش هضيفه تاني بنفس الاسم. لو تقصد عربية جديدة خلي اسمها مختلف.';
    }

    return null;
  }

  static String? _checkFactory(
    Map<String, String> values,
    List<FactoryEntity> factories,
  ) {
    final name = values[AiGuidedField.factoryName.name]?.trim() ?? '';
    if (name.isEmpty) return null;

    final nameKey = AiEntityResolver.normalizeKey(name);
    final matches = factories
        .where((f) => AiEntityResolver.normalizeKey(f.name) == nameKey)
        .toList();
    if (matches.isEmpty) return null;

    if (matches.length > 1) {
      return 'لقيت أكتر من مصنع بالاسم "$name" 🤔\n\n'
          'مش هقدر أحدد وأضيف نسخة تانية. شوف قايمة المصانع وميّز '
          'اللي تقصده.';
    }

    final existing = matches.first;
    final details = existing.details.trim();
    return 'المصنع "${existing.name}" موجود بالفعل ✅\n\n'
        'التفاصيل: ${details.isNotEmpty ? details : 'مش مسجلة'}\n\n'
        'فمش هضيفه تاني. لو تقصد مصنع جديد خليه باسم مختلف.';
  }
}