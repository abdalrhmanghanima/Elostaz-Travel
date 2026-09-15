import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elostaz_travel/data/ai_assistant/service/draft_edit_parser.dart';
import 'package:elostaz_travel/data/ai_assistant/service/local_trip_parser.dart';
import 'package:elostaz_travel/domain/ai_assistant/entity/ai_action_result.dart';
import 'package:elostaz_travel/domain/ai_assistant/entity/ai_chat_message_entity.dart';
import 'package:elostaz_travel/domain/ai_assistant/entity/ai_trip_draft.dart';
import 'package:elostaz_travel/domain/bus/entity/bus_entity.dart';
import 'package:elostaz_travel/domain/driver/entity/driver_entity.dart';
import 'package:elostaz_travel/domain/factory/entity/factory_entity.dart';
import 'package:elostaz_travel/domain/trip/entity/trip_entity.dart';
import 'package:elostaz_travel/domain/trip/validation/trip_date_rule.dart';
import 'package:elostaz_travel/presentation/ai_assistant/model/ai_action_option.dart';
import 'package:elostaz_travel/presentation/ai_assistant/model/ai_entry_context.dart';
import 'package:elostaz_travel/presentation/ai_assistant/model/ai_guided_field.dart';
import 'package:elostaz_travel/presentation/ai_assistant/model/ai_trip_field_spec.dart';
import 'package:elostaz_travel/presentation/ai_assistant/service/ai_duplicate_checker.dart';
import 'package:elostaz_travel/presentation/ai_assistant/service/ai_entity_resolver.dart';
import 'package:elostaz_travel/presentation/ai_assistant/service/ai_field_parser.dart';
import 'package:elostaz_travel/presentation/ai_assistant/service/ai_query_service.dart';
import 'package:elostaz_travel/presentation/ai_assistant/service/local_intent_service.dart';
import 'package:elostaz_travel/presentation/home/tabs/bus/provider/bus_provider.dart';
import 'package:elostaz_travel/presentation/home/tabs/driver/provider/driver_provider.dart';
import 'package:elostaz_travel/presentation/home/tabs/factory/provider/factory_provider.dart';
import 'package:elostaz_travel/presentation/trip/provider/paginated_trips_provider.dart';
import 'package:elostaz_travel/presentation/trip/provider/trip_provider.dart';
import 'package:elostaz_travel/presentation/home/tabs/trip/provider/trip_provider.dart'
    as home_trip;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const String forbiddenMutationMessage =
    'أقدر أضيف بيانات جديدة وأستعلم عن البيانات من هنا، '
    'لكن تعديل أو حذف أو تحديث البيانات لازم تعمله من شاشة التطبيق نفسها.';

/// Shown after a draft edit is applied. The updated values live in the
/// confirmation card rendered directly below this message.
const String tripEditedMessage = 'تمام، عدلت البيانات. راجع الرحلة بعد التعديل.';

/// An in-flight trip edit that is blocked on an ambiguous entity choice.
/// The [baseDraft] is the last valid draft; [patch] is applied only after the
/// user picks the correct entity.
class PendingDraftEdit {
  final AiTripDraft baseDraft;
  final AiTripDraft patch;
  final String? typeOverride;

  const PendingDraftEdit({
    required this.baseDraft,
    required this.patch,
    this.typeOverride,
  });
}

class AiAssistantState {
  final List<ChatMessage> messages;
  final AiTripDraft currentDraft;
  final AiActionResult? lastResult;
  final bool isProcessing;
  final AiActionId? selectedAction;
  final bool showActionList;

  final bool isConfirming;
  final BusEntity? resolvedBus;
  final DriverEntity? resolvedDriver;
  final FactoryEntity? resolvedFactory;
  final AiEntityField? pendingChoiceField;
  final List<BusEntity> busCandidates;
  final List<DriverEntity> driverCandidates;
  final List<FactoryEntity> factoryCandidates;

  final AiEntryContext entryContext;
  final String? selectedFactoryTripType;
  final bool showFactoryTripChoice;

  final bool showFactoryChoice;
  final List<FactoryEntity> factoryChoiceCandidates;

  final Map<String, String> createValues;
  final List<AiGuidedField> createPendingRequired;
  final List<AiGuidedField> createPendingOptional;
  final AiGuidedField? createActiveField;
  final bool awaitingOptionalChoice;
  final bool showGenericReview;
  final String? lastSuccessMessage;
  final String? lastDuplicateMessage;

  final bool isEditingDraft;
  final PendingDraftEdit? pendingDraftEdit;

  const AiAssistantState({
    this.messages = const [],
    this.currentDraft = const AiTripDraft(),
    this.lastResult,
    this.isProcessing = false,
    this.selectedAction,
    this.showActionList = false,
    this.isConfirming = false,
    this.resolvedBus,
    this.resolvedDriver,
    this.resolvedFactory,
    this.pendingChoiceField,
    this.busCandidates = const [],
    this.driverCandidates = const [],
    this.factoryCandidates = const [],
    this.entryContext = const AiEntryContext(),
    this.selectedFactoryTripType,
    this.showFactoryTripChoice = false,
    this.showFactoryChoice = false,
    this.factoryChoiceCandidates = const [],
    this.createValues = const {},
    this.createPendingRequired = const [],
    this.createPendingOptional = const [],
    this.createActiveField,
    this.awaitingOptionalChoice = false,
    this.showGenericReview = false,
    this.lastSuccessMessage,
    this.lastDuplicateMessage,
    this.isEditingDraft = false,
    this.pendingDraftEdit,
  });

  bool get hasCompleteDraft => currentDraft.hasAllRequiredFields;
  bool get showConfirmation =>
      lastResult?.type == AiActionType.createTrip && hasCompleteDraft;

  bool get hasResolvedRequiredEntities =>
      resolvedBus != null &&
      resolvedDriver != null &&
      (currentDraft.factoryName == null ||
          currentDraft.factoryName!.isEmpty ||
          resolvedFactory != null) &&
      pendingChoiceField == null;

  bool get showConfirmationCard =>
      showConfirmation && hasResolvedRequiredEntities;

  bool get canConfirm => showConfirmationCard && !isConfirming;

  bool get hasContextBus => entryContext.isBusContext;
  bool get hasContextFactory => entryContext.isFactoryContext;

  AiActionOption? get selectedActionOption {
    final action = selectedAction;
    if (action == null) return null;
    for (final option in availableAiActions) {
      if (option.id == action) return option;
    }
    return null;
  }

  bool get selectedActionIsQuery => selectedActionOption?.isQuery ?? false;

  bool get showCreateReviewCard =>
      showGenericReview &&
      (selectedActionOption?.isCreate ?? false) &&
      createValues.isNotEmpty;

  bool get canCreateConfirm => showCreateReviewCard && !isConfirming;

  AiAssistantState copyWith({
    List<ChatMessage>? messages,
    AiTripDraft? currentDraft,
    AiActionResult? lastResult,
    bool? isProcessing,
    bool clearLastResult = false,
    AiActionId? selectedAction,
    bool clearSelectedAction = false,
    bool? showActionList,
    bool? isConfirming,
    BusEntity? resolvedBus,
    DriverEntity? resolvedDriver,
    FactoryEntity? resolvedFactory,
    bool clearResolution = false,
    AiEntityField? pendingChoiceField,
    bool clearPending = false,
    List<BusEntity>? busCandidates,
    List<DriverEntity>? driverCandidates,
    List<FactoryEntity>? factoryCandidates,
    AiEntryContext? entryContext,
    String? selectedFactoryTripType,
    bool clearFactoryTripType = false,
    bool? showFactoryTripChoice,
    bool? showFactoryChoice,
    bool clearFactoryChoice = false,
    List<FactoryEntity>? factoryChoiceCandidates,
    Map<String, String>? createValues,
    bool clearCreateValues = false,
    List<AiGuidedField>? createPendingRequired,
    List<AiGuidedField>? createPendingOptional,
    AiGuidedField? createActiveField,
    bool clearActiveCreate = false,
    bool? awaitingOptionalChoice,
    bool? showGenericReview,
    bool clearCreate = false,
    String? lastSuccessMessage,
    bool clearLastSuccess = false,
    String? lastDuplicateMessage,
    bool clearLastDuplicate = false,
    bool? isEditingDraft,
    PendingDraftEdit? pendingDraftEdit,
    bool clearEdit = false,
  }) {
    return AiAssistantState(
      messages: messages ?? this.messages,
      currentDraft: currentDraft ?? this.currentDraft,
      lastResult: clearLastResult ? null : (lastResult ?? this.lastResult),
      isProcessing: isProcessing ?? this.isProcessing,
      isConfirming: isConfirming ?? this.isConfirming,
      selectedAction: clearSelectedAction
          ? null
          : (selectedAction ?? this.selectedAction),
      showActionList: showActionList ?? this.showActionList,
      resolvedBus: clearResolution ? null : (resolvedBus ?? this.resolvedBus),
      resolvedDriver: clearResolution
          ? null
          : (resolvedDriver ?? this.resolvedDriver),
      resolvedFactory: clearResolution
          ? null
          : (resolvedFactory ?? this.resolvedFactory),
      pendingChoiceField: clearPending
          ? null
          : (pendingChoiceField ?? this.pendingChoiceField),
      busCandidates: busCandidates ?? this.busCandidates,
      driverCandidates: driverCandidates ?? this.driverCandidates,
      factoryCandidates: factoryCandidates ?? this.factoryCandidates,
      entryContext: entryContext ?? this.entryContext,
      selectedFactoryTripType: clearFactoryTripType
          ? null
          : (selectedFactoryTripType ?? this.selectedFactoryTripType),
      showFactoryTripChoice:
          showFactoryTripChoice ?? this.showFactoryTripChoice,
      showFactoryChoice: clearFactoryChoice
          ? false
          : (showFactoryChoice ?? this.showFactoryChoice),
      factoryChoiceCandidates:
          factoryChoiceCandidates ?? this.factoryChoiceCandidates,
      createValues: (clearCreate || clearCreateValues)
          ? const {}
          : (createValues ?? this.createValues),
      createPendingRequired: (clearCreate || clearCreateValues)
          ? const []
          : (createPendingRequired ?? this.createPendingRequired),
      createPendingOptional: (clearCreate || clearCreateValues)
          ? const []
          : (createPendingOptional ?? this.createPendingOptional),
      createActiveField: (clearCreate || clearActiveCreate)
          ? null
          : (createActiveField ?? this.createActiveField),
      awaitingOptionalChoice:
          awaitingOptionalChoice ?? this.awaitingOptionalChoice,
      showGenericReview: (clearCreate || clearCreateValues)
          ? false
          : (showGenericReview ?? this.showGenericReview),
      lastSuccessMessage: (clearCreate || clearLastSuccess)
          ? null
          : (lastSuccessMessage ?? this.lastSuccessMessage),
      lastDuplicateMessage: clearLastDuplicate
          ? null
          : (lastDuplicateMessage ?? this.lastDuplicateMessage),
      isEditingDraft: clearEdit
          ? false
          : (isEditingDraft ?? this.isEditingDraft),
      pendingDraftEdit: clearEdit
          ? null
          : (pendingDraftEdit ?? this.pendingDraftEdit),
    );
  }
}

class AiAssistantNotifier extends AutoDisposeAsyncNotifier<AiAssistantState> {
  @override
  Future<AiAssistantState> build() async {
    return const AiAssistantState(
      messages: [
        ChatMessage(
          role: AiMessageRole.assistant,
          content:
              'أهلاً 👋\n'
              'أنا مساعدك الذكي في Elostaz Travel.\n'
              'تقدر تضيف بيانات جديدة (أتوبيس، سواق، مصنع، أو رحلة) '
              'وتستعلم عن البيانات.\n'
              'تحب نعمل إيه النهارده؟',
        ),
      ],
      showActionList: true,
    );
  }

  AiEntryContext _getContext() {
    final current = state.valueOrNull;
    return current?.entryContext ?? const AiEntryContext();
  }

  void initializeWithContext(AiEntryContext context) {
    final current = state.valueOrNull;
    if (current == null) return;

    state = AsyncValue.data(
      AiAssistantState(
        messages: [
          ChatMessage(
            role: AiMessageRole.assistant,
            content: _buildGreetingForContext(context),
          ),
        ],
        showActionList: true,
        entryContext: context,
      ),
    );
  }

  String _buildGreetingForContext(AiEntryContext ctx) {
    if (ctx.isBusContext) {
      return 'أهلاً 👋\n'
          'أنا مساعدك الذكي.\n'
          'أشوف الأتوبيس "${ctx.bus!.busName}".\n'
          'تحب نعمل إيه؟';
    }
    if (ctx.isFactoryContext) {
      return 'أهلاً 👋\n'
          'أنا مساعدك الذكي.\n'
          'أشوف المصنع "${ctx.factory!.name}".\n'
          'تحب نعمل إيه؟';
    }
    return 'أهلاً 👋\n'
        'أنا مساعدك الذكي في Elostaz Travel.\n'
        'تقدر تضيف بيانات جديدة وأستعلم عن البيانات.\n'
        'تحب نعمل إيه النهارده؟';
  }

  Future<void> processUserMessage(String text) async {
    if (text.trim().isEmpty) return;

    final currentState = state.valueOrNull ?? const AiAssistantState();
    if (currentState.isProcessing || currentState.isConfirming) return;

    final userMessage = ChatMessage(
      role: AiMessageRole.user,
      content: text.trim(),
      timestamp: DateTime.now(),
    );

    state = AsyncValue.data(
      currentState.copyWith(
        messages: [...currentState.messages, userMessage],
        isProcessing: true,
      ),
    );

    final normalized = LocalIntentService.normalize(text.trim());

    final buses = ref.read(busProvider).valueOrNull ?? [];
    final drivers = ref.read(driversProvider).valueOrNull ?? [];
    final factories = ref.read(factoriesProvider).valueOrNull ?? [];

    if (LocalIntentService.isShowOptionsRequest(normalized)) {
      _finalize(
        extraMessages: [
          ChatMessage(
            role: AiMessageRole.assistant,
            content:
                'تقدر تعمل معايا النهارده الآتي 👇\n'
                'اختار أي واحدة أو قولها بصوتك.',
            timestamp: DateTime.now(),
          ),
        ],
        clearLastResult: true,
        clearSelectedAction: true,
        showActionList: true,
        clearResolution: true,
        clearPending: true,
        clearFactoryTripType: true,
        showFactoryTripChoice: false,
        showFactoryChoice: false,
        clearCreate: true,
        clearEdit: true,
      );
      return;
    }

    if (LocalIntentService.isHelpRequest(normalized)) {
      _finalize(
        extraMessages: const [
          ChatMessage(
            role: AiMessageRole.assistant,
            content: 'تقدر تعمل معايا النهارده الآتي 👇',
          ),
        ],
        clearLastResult: true,
        clearSelectedAction: true,
        showActionList: true,
        clearResolution: true,
        clearPending: true,
        clearFactoryTripType: true,
        showFactoryTripChoice: false,
        showFactoryChoice: false,
        clearCreate: true,
        clearEdit: true,
      );
      return;
    }

    if (LocalIntentService.isIntentChange(normalized)) {
      _finalize(
        extraMessages: const [
          ChatMessage(
            role: AiMessageRole.assistant,
            content: 'تمام، مفهوم 👍\nتحب تعمل إيه تاني؟\nاختار من تحت 👇',
          ),
        ],
        clearLastResult: true,
        clearSelectedAction: true,
        showActionList: true,
        clearPending: true,
        clearFactoryTripType: true,
        showFactoryTripChoice: false,
        showFactoryChoice: false,
        clearCreate: true,
        clearEdit: true,
      );
      return;
    }

    if (currentState.isEditingDraft) {
      _handleDraftEditText(text.trim(), normalized);
      return;
    }

    if (LocalIntentService.isForbiddenMutation(normalized)) {
      _finalize(
        extraMessages: [
          ChatMessage(
            role: AiMessageRole.assistant,
            content: forbiddenMutationMessage,
            timestamp: DateTime.now(),
          ),
        ],
        clearLastResult: true,
        clearSelectedAction: true,
        showActionList: true,
        clearPending: true,
        clearFactoryTripType: true,
        showFactoryTripChoice: false,
        showFactoryChoice: false,
        clearCreate: true,
        clearEdit: true,
      );
      return;
    }

    final ctx = currentState.entryContext;

    if (currentState.showFactoryChoice) {
      _handleFactoryChoiceText(normalized);
      return;
    }

    if (currentState.createActiveField != null &&
        !currentState.showGenericReview) {
      _handleCreateFlowAnswer(text.trim(), normalized);
      return;
    }

    final containsTripData = LocalIntentService.containsTripData(
      normalized,
      busNames: buses.map((b) => b.busName).toList(),
      plates: buses.map((b) => b.plateNumber).toList(),
      driverNames: drivers.map((d) => d.name).toList(),
      factoryNames: factories.map((f) => f.name).toList(),
    );

    final addAction = LocalIntentService.detectAddAction(normalized);
    if (addAction == AiActionId.addFactoryTrip) {
      _startAddFactoryTripFlow(userText: normalized);
      return;
    }
    if (addAction == AiActionId.addBus ||
        addAction == AiActionId.addDriver ||
        addAction == AiActionId.addFactory) {
      _startCreateFlow(addAction!, userText: text.trim());
      return;
    }
    if (addAction == AiActionId.addTrip && !containsTripData) {
      _handleAddTripIntent(ctx);
      return;
    }

    if ((currentState.selectedAction == AiActionId.addFactoryTrip ||
            currentState.selectedAction == AiActionId.addTrip) &&
        currentState.showFactoryTripChoice) {
      final tripType = LocalIntentService.detectFactoryTripType(normalized);
      if (tripType != null) {
        _applyFactoryTripType(tripType, userText: text.trim());
        return;
      }
      _finalize(
        extraMessages: [
          ChatMessage(
            role: AiMessageRole.assistant,
            content:
                'عايز أسجل أنهي نوع؟ 👇\n'
                'قول: "رحلة" أو "سهرة".',
            timestamp: DateTime.now(),
          ),
        ],
      );
      return;
    }

    if (LocalIntentService.isAddTripIntent(
      normalized,
      containsTripData: containsTripData,
    )) {
      _handleAddTripIntent(ctx);
      return;
    }

    if (_isThanks(normalized) && currentState.selectedActionIsQuery) {
      _finalize(
        extraMessages: [
          ChatMessage(
            role: AiMessageRole.assistant,
            content: 'العفو! 😊\nتحب تعمل إيه تاني؟\nاختار من تحت 👇',
            timestamp: DateTime.now(),
          ),
        ],
        clearSelectedAction: true,
        showActionList: true,
      );
      return;
    }

    final isTripCreation =
        (currentState.selectedAction == AiActionId.addTrip &&
            containsTripData) ||
        addAction == AiActionId.addTrip ||
        (addAction == null &&
            LocalIntentService.shouldTreatAsTripCreation(
              normalized,
              busNames: buses.map((b) => b.busName).toList(),
              plates: buses.map((b) => b.plateNumber).toList(),
              driverNames: drivers.map((d) => d.name).toList(),
              factoryNames: factories.map((f) => f.name).toList(),
            ));

    if (!isTripCreation &&
        (currentState.selectedActionIsQuery ||
            LocalIntentService.detectQueryAction(normalized) != null)) {
      final queryAction =
          currentState.selectedAction ??
          LocalIntentService.detectQueryAction(normalized)!;
      await _handleQueryAction(
        queryAction,
        text.trim(),
        alreadyProcessing: true,
      );
      return;
    }

    if (currentState.selectedAction == AiActionId.addTrip || containsTripData) {
      try {
        final result = LocalTripParser().parse(
          userMessage: text.trim(),
          currentDraft: _applyContextToDraft(currentState.currentDraft),
          availableBuses: buses,
          availableDrivers: drivers,
          availableFactories: factories,
        );

        final assistantMessage = ChatMessage(
          role: AiMessageRole.assistant,
          content: result.assistantMessage,
          timestamp: DateTime.now(),
        );

        final newDraft = result.tripDraft != null
            ? _applyContextToDraft(
                currentState.currentDraft.merge(result.tripDraft!),
              )
            : currentState.currentDraft;

        if (result.type != AiActionType.generalChat) {
          _handleTripEngagement(
            draft: newDraft,
            result: result,
            assistantMessage: assistantMessage,
          );
        } else {
          _finalize(extraMessages: [assistantMessage]);
        }
      } catch (e) {
        _finalize(
          extraMessages: const [
            ChatMessage(
              role: AiMessageRole.assistant,
              content: 'حدث خطأ. الرجاء المحاولة مرة أخرى.',
            ),
          ],
        );
      }
      return;
    }

    _finalize(
      extraMessages: const [
        ChatMessage(
          role: AiMessageRole.assistant,
          content:
              'أنا مساعدك الذكي في Elostaz Travel.\n'
              'قولّي عايز تضيف إيه أو تستعلم عن إيه:\n'
              'مثلاً: "عايز أعمل رحلة للأتوبيس [الاسم] والسواق [الاسم]"، '
              '"عايز أضيف أتوبيس"، أو "قايمة الرحلات"',
        ),
      ],
    );
  }

  bool _isThanks(String normalized) {
    return normalized.startsWith('شكرا') ||
        normalized == 'تمام' ||
        normalized == 'هلو' ||
        normalized == 'سلام' ||
        normalized == 'متشكر' ||
        normalized == 'ازيك';
  }

  bool _isDeclineAnswer(String normalized) {
    final t = normalized;
    if (t.isEmpty) return false;
    const words = [
      'لا',
      'لأ',
      'لاا',
      'للا',
      'مش عايز',
      'سيبها',
      'مش محتاج',
      'مش لازم',
      'سيب',
      'كفايه',
      'كفيه',
    ];
    return words.contains(t) ||
        t.startsWith('لا ') ||
        t.startsWith('مش عايز') ||
        t.startsWith('سيبها');
  }

  void _handleAddTripIntent(AiEntryContext ctx) {
    if (ctx.isFactoryContext && ctx.factory != null) {
      _finalize(
        extraMessages: [
          ChatMessage(
            role: AiMessageRole.assistant,
            content:
                'تمام 👍\n'
                'المصنع "${ctx.factory!.name}" محدد بالفعل.\n'
                'عايز تسجل أنهي نوع؟',
            timestamp: DateTime.now(),
          ),
        ],
        clearLastResult: true,
        selectedAction: AiActionId.addTrip,
        showActionList: false,
        showFactoryTripChoice: true,
        clearEdit: true,
      );
      return;
    }

    _handleAddTripAction();
  }

  void selectAction(AiActionId actionId) {
    final current = state.valueOrNull;
    if (current != null && (current.isProcessing || current.isConfirming)) {
      return;
    }

    switch (actionId) {
      case AiActionId.addBus:
      case AiActionId.addDriver:
      case AiActionId.addFactory:
        _startCreateFlow(actionId);
        return;
      case AiActionId.addFactoryTrip:
        _startAddFactoryTripFlow();
        return;
      case AiActionId.addTrip:
        _selectAddTripAction();
        return;
      case AiActionId.queryTrips:
      case AiActionId.queryBuses:
      case AiActionId.queryDrivers:
      case AiActionId.queryFactories:
        if (current != null) {
          state = AsyncValue.data(current.copyWith(showActionList: false));
        }
        unawaited(_handleQueryAction(actionId, ''));
        return;
    }
  }

  void _selectAddTripAction() {
    final ctx = _getContext();

    if (ctx.isFactoryContext && ctx.factory != null) {
      _finalize(
        extraMessages: [
          ChatMessage(
            role: AiMessageRole.assistant,
            content:
                'تمام 👍\n'
                'المصنع "${ctx.factory!.name}" محدد بالفعل.\n'
                'عايز تسجل أنهي نوع؟',
            timestamp: DateTime.now(),
          ),
        ],
        clearLastResult: true,
        selectedAction: AiActionId.addTrip,
        showActionList: false,
        showFactoryTripChoice: true,
        clearEdit: true,
      );
      return;
    }

    _handleAddTripAction();
  }

  void _handleAddTripAction() {
    _finalize(
      extraMessages: [
        ChatMessage(
          role: AiMessageRole.assistant,
          content: _buildTripChecklistMessage(),
          timestamp: DateTime.now(),
        ),
      ],
      clearLastResult: true,
      selectedAction: AiActionId.addTrip,
      showActionList: false,
      showFactoryTripChoice: false,
    );
  }

  /// Enters draft-edit mode (from the [تعديل] button on a confirmation card).
  /// Keeps the confirmation card visible so the user can either speak a change
  /// or hit تأكيد/إلغاء directly.
  void enterDraftEditMode() {
    final current = state.valueOrNull ?? const AiAssistantState();
    if (current.isProcessing || current.isConfirming) return;
    final showsTrip = current.showConfirmationCard;
    final showsCreate = current.showCreateReviewCard;
    if (!showsTrip && !showsCreate) return;

    final hint = showsCreate
        ? 'تمام، قولّي أيه اللي عايز تعدله.\n'
            'مثلاً: "غير الاسم يبقى ..." أو "رقم التليفون يبقى ..."'
        : 'تمام، قولّي أيه اللي عايز تعدله في الرحلة.\n'
            'مثلاً: "غير السواق من احمد محمد خليه عبدالرحمن محمد" أو '
            '"الايراد يبقى 5000" أو "النوع يبقى سهرة"';

    state = AsyncValue.data(
      current.copyWith(
        messages: [
          ...current.messages,
          ChatMessage(
            role: AiMessageRole.assistant,
            content: hint,
            timestamp: DateTime.now(),
          ),
        ],
        isEditingDraft: true,
        isConfirming: false,
      ),
    );
    // The confirmation card renders below the messages list, so the edit hint
    // and the card stay visible together; the sheet's ListView listener
    // auto-scrolls on each appended message so the latest result and the
    // updated card remain in view.
  }

  /// Routes a message received while `isEditingDraft` is true. Runs BEFORE the
  /// forbidden-mutation guard so spoken "غير .." is allowed for draft edits.
  void _handleDraftEditText(String rawText, String normalized) {
    final current = state.valueOrNull ?? const AiAssistantState();
    final action = current.selectedAction;
    final isCreateEdit = action == AiActionId.addBus ||
        action == AiActionId.addDriver ||
        action == AiActionId.addFactory;
    if (isCreateEdit) {
      _handleCreateDraftEdit(rawText);
    } else {
      _handleTripDraftEdit(rawText);
    }
  }

  /// Applies a trip draft edit: parses the change into a patch, merges it into
  /// the current draft, re-resolves entities and re-shows the confirmation
  /// (or defers to an ambiguous-entity choice / not-found message).
  void _handleTripDraftEdit(String rawText) {
    final current = state.valueOrNull ?? const AiAssistantState();
    final ctx = current.entryContext;
    final result = DraftEditParser.parseTrip(rawText);

    if (!result.hasChanges) {
      _finalize(
        extraMessages: [
          ChatMessage(
            role: AiMessageRole.assistant,
            content: 'قولّي الحقل اللي عايز تعدله.\n'
                'مثلاً: "غير السواق يبقى أحمد" أو "الايراد يبقى 5000".',
            timestamp: DateTime.now(),
          ),
        ],
      );
      return;
    }

    final p = result.patch;
    final filtered = AiTripDraft(
      busName: ctx.isBusContext ? null : p.busName,
      plateNumber: ctx.isBusContext ? null : p.plateNumber,
      driverName: p.driverName,
      factoryName: ctx.isFactoryContext ? null : p.factoryName,
      revenue: p.revenue,
      driverWage: p.driverWage,
      tripDate: p.tripDate,
      departureTime: p.departureTime,
      type: p.type,
      details: p.details,
      expenses: p.expenses,
      expenseDetails: p.expenseDetails,
    );

    var merged = current.currentDraft.merge(filtered);
    if (result.editedType && p.type != null) {
      merged = merged.copyWith(type: p.type);
    }
    _finishTripEdit(current, merged, filtered, result.editedType ? p.type : null);
  }

  /// Shared finalization for a merged trip edit: resolves entities, reports
  /// not-found/ambiguous — or applies the change and re-shows confirmation.
  void _finishTripEdit(
    AiAssistantState current,
    AiTripDraft merged,
    AiTripDraft changed,
    String? typeOverride,
  ) {
    final ctx = current.entryContext;
    final buses = ref.read(busProvider).valueOrNull ?? const [];
    final drivers = ref.read(driversProvider).valueOrNull ?? const [];
    final factories = ref.read(factoriesProvider).valueOrNull ?? const [];
    final now = DateTime.now();

    AiEntityResolution<BusEntity> busRes;
    if (ctx.isBusContext && ctx.bus != null) {
      busRes = AiEntityResolution<BusEntity>(resolved: ctx.bus);
    } else {
      busRes = AiEntityResolver.preferStored(
        raw: AiEntityResolver.resolveBus(draft: merged, buses: buses),
        stored: current.resolvedBus,
        stillMatches: (bus) => AiEntityResolver.busStillMatches(bus, merged),
      );
    }

    final driverRes = AiEntityResolver.preferStored(
      raw: AiEntityResolver.resolveDriver(draft: merged, drivers: drivers),
      stored: current.resolvedDriver,
      stillMatches: (driver) =>
          AiEntityResolver.driverStillMatches(driver, merged),
    );

    AiEntityResolution<FactoryEntity> factoryRes;
    if (ctx.isFactoryContext && ctx.factory != null) {
      factoryRes = AiEntityResolution<FactoryEntity>(resolved: ctx.factory);
    } else {
      factoryRes = AiEntityResolver.preferStored(
        raw: AiEntityResolver.resolveFactory(
          draft: merged,
          factories: factories,
        ),
        stored: current.resolvedFactory,
        stillMatches: (factory) =>
            AiEntityResolver.factoryStillMatches(factory, merged),
      );
    }

    final hasFactory =
        merged.factoryName != null && merged.factoryName!.isNotEmpty;

    if (!ctx.isBusContext && changed.busName != null && busRes.isNotFound) {
      _finalize(
        extraMessages: [
          ChatMessage(
            role: AiMessageRole.assistant,
            content:
                'مش لاقي أتوبيس باسم "${changed.busName}". اختار أتوبيس موجود عندك.',
            timestamp: now,
          ),
        ],
      );
      return;
    }
    if (!ctx.isBusContext && changed.plateNumber != null && busRes.isNotFound) {
      _finalize(
        extraMessages: [
          ChatMessage(
            role: AiMessageRole.assistant,
            content:
                'مش لاقي أتوبيس بالنمرة "${changed.plateNumber}". '
                'اختار أتوبيس موجود عندك.',
            timestamp: now,
          ),
        ],
      );
      return;
    }
    if (changed.driverName != null && driverRes.isNotFound) {
      _finalize(
        extraMessages: [
          ChatMessage(
            role: AiMessageRole.assistant,
            content:
                'مش لاقي سواق باسم "${changed.driverName}". اختار سواق موجود عندك.',
            timestamp: now,
          ),
        ],
      );
      return;
    }
    if (hasFactory &&
        !ctx.isFactoryContext &&
        changed.factoryName != null &&
        factoryRes.isNotFound) {
      _finalize(
        extraMessages: [
          ChatMessage(
            role: AiMessageRole.assistant,
            content:
                'مش لاقي مصنع باسم "${changed.factoryName}". اختار مصنع موجود عندك.',
            timestamp: now,
          ),
        ],
      );
      return;
    }

    AiEntityField? pending;
    if (busRes.isAmbiguous) {
      pending = AiEntityField.bus;
    } else if (driverRes.isAmbiguous) {
      pending = AiEntityField.driver;
    } else if (hasFactory && factoryRes.isAmbiguous) {
      pending = AiEntityField.factory;
    }

    if (pending != null) {
      final label = switch (pending) {
        AiEntityField.bus => 'أتوبيس',
        AiEntityField.driver => 'سواق',
        AiEntityField.factory => 'مصنع',
      };
      state = AsyncValue.data(
        AiAssistantState(
          messages: [
            ...current.messages,
            ChatMessage(
              role: AiMessageRole.assistant,
              content: 'لقيت أكتر من $label مطابق. اختار واحد منهم 👇',
              timestamp: now,
            ),
          ],
          currentDraft: current.currentDraft,
          lastResult: current.lastResult,
          isProcessing: false,
          isConfirming: false,
          isEditingDraft: true,
          selectedAction: current.selectedAction,
          showActionList: false,
          resolvedBus: current.resolvedBus,
          resolvedDriver: current.resolvedDriver,
          resolvedFactory: current.resolvedFactory,
          pendingChoiceField: pending,
          busCandidates: busRes.candidates,
          driverCandidates: driverRes.candidates,
          factoryCandidates: factoryRes.candidates,
          entryContext: ctx,
          selectedFactoryTripType: typeOverride ?? current.selectedFactoryTripType,
          pendingDraftEdit: PendingDraftEdit(
            baseDraft: current.currentDraft,
            patch: changed,
            typeOverride: typeOverride,
          ),
        ),
      );
      return;
    }

    var finalDraft = merged;
    if (busRes.resolved != null && !ctx.isBusContext) {
      finalDraft = finalDraft.copyWith(
        busName: busRes.resolved!.busName,
        plateNumber: busRes.resolved!.plateNumber,
      );
    }
    if (driverRes.resolved != null) {
      finalDraft = finalDraft.copyWith(driverName: driverRes.resolved!.name);
    }
    if (factoryRes.resolved != null && !ctx.isFactoryContext) {
      finalDraft = finalDraft.copyWith(factoryName: factoryRes.resolved!.name);
    }
    finalDraft = _applyContextToDraft(finalDraft);
    if (typeOverride != null) {
      finalDraft = finalDraft.copyWith(type: typeOverride);
    }

    final editsMessage = ChatMessage(
      role: AiMessageRole.assistant,
      content: tripEditedMessage,
      timestamp: now,
    );

    state = AsyncValue.data(
      AiAssistantState(
        messages: [...current.messages, editsMessage],
        currentDraft: finalDraft,
        lastResult: AiActionResult(
          type: AiActionType.createTrip,
          assistantMessage: '',
          tripDraft: finalDraft,
        ),
        isProcessing: false,
        isConfirming: false,
        isEditingDraft: true,
        selectedAction: current.selectedAction,
        showActionList: false,
        resolvedBus: busRes.resolved ?? current.resolvedBus,
        resolvedDriver: driverRes.resolved ?? current.resolvedDriver,
        resolvedFactory: factoryRes.resolved ?? current.resolvedFactory,
        pendingChoiceField: null,
        entryContext: ctx,
        selectedFactoryTripType: typeOverride ?? current.selectedFactoryTripType,
      ),
    );
  }

  /// Applies a create-flow (bus/driver/factory) draft edit to `createValues`
  /// and re-shows the review card. Invalid values ask the user to re-state
  /// them; `محظورة بيع` prompts for the prohibited bank name.
  void _handleCreateDraftEdit(String rawText) {
    final current = state.valueOrNull ?? const AiAssistantState();
    final action = current.selectedAction;
    if (action == null) return;
    final now = DateTime.now();
    final result = DraftEditParser.parseCreate(rawText, action);

    if (!result.hasChanges) {
      _finalize(
        extraMessages: [
          ChatMessage(
            role: AiMessageRole.assistant,
            content: 'قولّي الحقل اللي عايز تعدله.\n'
                'مثلاً: "غير الاسم يبقى ..." أو "رقم التليفون يبقى ..."',
            timestamp: now,
          ),
        ],
      );
      return;
    }

    final values = Map<String, String>.of(current.createValues);
    final errors = <String>[];
    for (final edit in result.edits) {
      final error = AiFieldParser.validate(edit.field, edit.rawValue);
      if (error != null) {
        errors.add('• ${edit.field.label}: $error');
      }
    }

    if (errors.isNotEmpty) {
      _finalize(
        extraMessages: [
          ChatMessage(
            role: AiMessageRole.assistant,
            content:
                'البيانات دي فيها مشكلة:\n${errors.join('\n')}\n\n'
                'صحح القيمة واقولهالي تاني.',
            timestamp: now,
          ),
        ],
      );
      return;
    }

    final changedLines = <String>[];
    for (final edit in result.edits) {
      final value = AiFieldParser.canonicalize(edit.field, edit.rawValue);
      values[edit.field.name] = value;
      changedLines.add('• ${edit.field.label} = $value ✓');
    }

    final messages = [
      ...current.messages,
      ChatMessage(
        role: AiMessageRole.assistant,
        content: 'تمام، عدلت:\n${changedLines.join('\n')}',
        timestamp: now,
      ),
    ];

    final isProhibitedSaleEdit =
        values[AiGuidedField.specialConditions.name] == 'محظورة بيع' &&
            !values.containsKey(AiGuidedField.prohibitedBankName.name);

    if (isProhibitedSaleEdit) {
      state = AsyncValue.data(
        current.copyWith(
          messages: [
            ...messages,
            ChatMessage(
              role: AiMessageRole.assistant,
              content:
                  'البيع محظور والمفروض تختار بنك محظور البيع عنده. قولّي اسم البنك؟',
              timestamp: now,
            ),
          ],
          createValues: values,
          createPendingRequired: const [],
          createPendingOptional: const [],
          createActiveField: AiGuidedField.prohibitedBankName,
          awaitingOptionalChoice: false,
          showGenericReview: false,
          isEditingDraft: false,
          isProcessing: false,
        ),
      );
      return;
    }

    state = AsyncValue.data(
      current.copyWith(
        messages: [
          ...messages,
          ChatMessage(
            role: AiMessageRole.assistant,
            content: 'تمام، راجع البيانات واضغط "تأكيد وتنفيذ" 👇',
            timestamp: now,
          ),
        ],
        createValues: values,
        createPendingRequired: const [],
        createPendingOptional: const [],
        createActiveField: null,
        awaitingOptionalChoice: false,
        showGenericReview: true,
        isEditingDraft: true,
        isProcessing: false,
      ),
    );
  }

  /// Starts the guided flow for adding a bus/driver/factory:
  /// collects required fields one question at a time, then optional fields
  /// (with an explicit yes/no), then shows the review/confirm card.
  /// For the Add Driver flow, [userText] may already carry driver fields
  /// (name / phone), which are pre-filled and skipped in the questions.
  void _startCreateFlow(AiActionId actionId, {String userText = ''}) {
    final currentState = state.valueOrNull ?? const AiAssistantState();
    final option = availableAiActions.firstWhere((o) => o.id == actionId);

    final Map<String, String> prefill;
    if (actionId == AiActionId.addDriver && userText.trim().isNotEmpty) {
      prefill = AiFieldParser.extractDriverPrefill(userText);
    } else if (actionId == AiActionId.addFactory &&
        userText.trim().isNotEmpty) {
      prefill = AiFieldParser.extractFactoryPrefill(userText);
    } else {
      prefill = const <String, String>{};
    }

    final values = Map<String, String>.of(prefill);

    final required = List<AiGuidedField>.of(option.requiredFields)
      ..removeWhere((f) => prefill.containsKey(f.name));
    final optional = List<AiGuidedField>.of(option.optionalFields)
      ..removeWhere((f) => prefill.containsKey(f.name));

    final buf = StringBuffer('تمام، هنضيف: ${option.title} 👍');
    if (prefill.isNotEmpty) {
      buf.writeln('\n\nحفظت من كلامك:');
      for (final f in [...option.requiredFields, ...option.optionalFields]) {
        final value = prefill[f.name];
        if (value != null && value.isNotEmpty) {
          buf.writeln('\n• ${f.label}: $value ✓');
        }
      }
    }
    if (required.isNotEmpty) {
      buf.writeln('\n\nالبيانات المطلوبة:');
      for (final f in required) {
        buf.writeln('\n• ${f.label}');
      }
    }
    if (optional.isNotEmpty) {
      buf.writeln('\n\nوالبيانات دي اختيارية (مش إجباري):');
      for (final f in optional) {
        buf.writeln('\n• ${f.label}');
      }
    }

    AiGuidedField? first;
    var firstIsOptional = false;
    if (required.isNotEmpty) {
      first = required.removeAt(0);
    } else if (optional.isNotEmpty) {
      first = optional.removeAt(0);
      firstIsOptional = true;
    }

    if (first != null) {
      buf.writeln(
        '\n\n${firstIsOptional ? 'تحب تضيف ${first.label}؟\n(اكتب القيمة أو "لا" لو مش ضروري)' : 'يلا نبدأ: ${first.label}؟'}',
      );
    }

    final messages = [
      ...currentState.messages,
      ChatMessage(
        role: AiMessageRole.assistant,
        content: buf.toString(),
        timestamp: DateTime.now(),
      ),
    ];

    if (first == null) {
      messages.add(
        ChatMessage(
          role: AiMessageRole.assistant,
          content: 'تمام، راجع البيانات واضغط "تأكيد وتنفيذ" 👇',
          timestamp: DateTime.now(),
        ),
      );
    }

    state = AsyncValue.data(
      AiAssistantState(
        messages: messages,
        currentDraft: const AiTripDraft(),
        lastResult: null,
        isProcessing: false,
        isConfirming: false,
        selectedAction: actionId,
        showActionList: false,
        entryContext: currentState.entryContext,
        createValues: values,
        createPendingRequired: required,
        createPendingOptional: optional,
        createActiveField: first,
        awaitingOptionalChoice: firstIsOptional,
        showGenericReview: first == null,
      ),
    );
  }

  void _handleCreateFlowAnswer(String rawText, String normalized) {
    final currentState = state.valueOrNull ?? const AiAssistantState();
    final field = currentState.createActiveField;
    if (field == null) return;

    if (LocalIntentService.isHelpRequest(normalized)) {
      _finalize(
        extraMessages: const [
          ChatMessage(
            role: AiMessageRole.assistant,
            content: 'تقدر تعمل معايا النهارده الآتي 👇',
          ),
        ],
        clearLastResult: true,
        clearSelectedAction: true,
        showActionList: true,
        clearPending: true,
        clearFactoryTripType: true,
        showFactoryTripChoice: false,
        showFactoryChoice: false,
        clearCreate: true,
        clearEdit: true,
      );
      return;
    }
    if (LocalIntentService.isIntentChange(normalized)) {
      _finalize(
        extraMessages: const [
          ChatMessage(
            role: AiMessageRole.assistant,
            content: 'تمام، مفهوم 👍\nتحب تعمل إيه تاني؟\nاختار من تحت 👇',
          ),
        ],
        clearLastResult: true,
        clearSelectedAction: true,
        showActionList: true,
        clearPending: true,
        clearFactoryTripType: true,
        showFactoryTripChoice: false,
        showFactoryChoice: false,
        clearCreate: true,
        clearEdit: true,
      );
      return;
    }
    if (LocalIntentService.isForbiddenMutation(normalized)) {
      _finalize(
        extraMessages: [
          ChatMessage(
            role: AiMessageRole.assistant,
            content: forbiddenMutationMessage,
            timestamp: DateTime.now(),
          ),
        ],
        clearLastResult: true,
        clearSelectedAction: true,
        showActionList: true,
        clearPending: true,
        clearFactoryTripType: true,
        showFactoryTripChoice: false,
        showFactoryChoice: false,
        clearCreate: true,
        clearEdit: true,
      );
      return;
    }
    final queryAction = LocalIntentService.detectQueryAction(normalized);
    if (queryAction != null) {
      unawaited(
        _handleQueryAction(queryAction, rawText, alreadyProcessing: true),
      );
      return;
    }

    final isOptionalAsk = currentState.awaitingOptionalChoice;

    if (isOptionalAsk && _isDeclineAnswer(normalized)) {
      _advanceCreateFlow(
        currentState,
        updatedValues: currentState.createValues,
        declinedField: field,
      );
      return;
    }
    if (!isOptionalAsk && _isDeclineAnswer(normalized)) {
      _finalize(
        extraMessages: [
          ChatMessage(
            role: AiMessageRole.assistant,
            content: 'تمام، بس ${field.label} مطلوب فعلًا. قولّها لي؟',
            timestamp: DateTime.now(),
          ),
        ],
      );
      return;
    }

    if (currentState.selectedAction == AiActionId.addDriver) {
      _handleDriverCreateAnswer(currentState, field, rawText);
      return;
    }

    if (currentState.selectedAction == AiActionId.addFactory) {
      _handleFactoryCreateAnswer(currentState, field, rawText);
      return;
    }

    final error = AiFieldParser.validate(field, rawText);
    if (error != null) {
      _finalize(
        extraMessages: [
          ChatMessage(
            role: AiMessageRole.assistant,
            content: '$error\n\n${field.label}؟',
            timestamp: DateTime.now(),
          ),
        ],
      );
      return;
    }

    final value = AiFieldParser.canonicalize(field, rawText);
    final values = Map<String, String>.of(currentState.createValues);
    values[field.name] = value;
    if (field == AiGuidedField.specialConditions && value != 'محظورة بيع') {
      values.remove(AiGuidedField.prohibitedBankName.name);
    }

    _advanceCreateFlow(currentState, updatedValues: values);
  }

  /// Add Driver answer handling: accepts plain and multi-field answers
  /// ("اسمه X ورقم تليفونه Y"), applies spoken corrections of already
  /// entered values, and only advances when the active field is genuinely
  /// answered.
  void _handleDriverCreateAnswer(
    AiAssistantState currentState,
    AiGuidedField field,
    String rawText,
  ) {
    final absorbed = Map<String, String>.of(currentState.createValues);

    final nameCorrection = AiFieldParser.extractDriverNameFromAnswer(rawText);
    if (nameCorrection != null && nameCorrection.isNotEmpty) {
      absorbed[AiGuidedField.driverName.name] = nameCorrection;
    } else if (field == AiGuidedField.driverName) {
      final name = AiFieldParser.extractDriverPrefill(
        rawText,
      )[AiGuidedField.driverName.name];
      if (name != null && name.isNotEmpty) {
        absorbed[AiGuidedField.driverName.name] = name;
      }
    }

    final phone = AiFieldParser.phoneFromText(rawText);
    if (phone != null) {
      absorbed[AiGuidedField.driverPhone.name] = phone;
    }

    final activeHasValue = field == AiGuidedField.driverName
        ? absorbed.containsKey(AiGuidedField.driverName.name)
        : absorbed.containsKey(AiGuidedField.driverPhone.name);

    if (!activeHasValue) {
      if (field == AiGuidedField.driverName) {
        _finalize(
          extraMessages: [
            ChatMessage(
              role: AiMessageRole.assistant,
              content: 'قولّي ${field.label}؟ (مثال: "اسمه محمد علي")',
              timestamp: DateTime.now(),
            ),
          ],
        );
        return;
      }
      if (_sameCreateValues(absorbed, currentState.createValues)) {
        final error = AiFieldParser.validate(field, rawText);
        if (error != null) {
          _finalize(
            extraMessages: [
              ChatMessage(
                role: AiMessageRole.assistant,
                content: '$error\n\n${field.label}؟',
                timestamp: DateTime.now(),
              ),
            ],
          );
          return;
        }
      }
      _advanceCreateFlow(currentState, updatedValues: absorbed);
      return;
    }

    _advanceCreateFlow(currentState, updatedValues: absorbed);
  }

  /// Add Factory answer handling: accepts plain and multi-field answers
  /// ("اسمه X وعنوانه Y"), applies spoken corrections of already entered
  /// values, and only advances when the active field is genuinely answered.
  void _handleFactoryCreateAnswer(
    AiAssistantState currentState,
    AiGuidedField field,
    String rawText,
  ) {
    final absorbed = Map<String, String>.of(currentState.createValues);

    final name = AiFieldParser.extractFactoryNameFromAnswer(rawText);
    if (name != null && name.isNotEmpty) {
      absorbed[AiGuidedField.factoryName.name] = name;
    }

    final details = AiFieldParser.extractFactoryDetailsFromAnswer(rawText);
    if (details != null && details.isNotEmpty) {
      absorbed[AiGuidedField.factoryDetails.name] = details;
    }

    if (field == AiGuidedField.factoryName &&
        !absorbed.containsKey(AiGuidedField.factoryName.name)) {
      final asName = AiFieldParser.extractFactoryPrefill(
        rawText,
      )[AiGuidedField.factoryName.name];
      if (asName != null && asName.isNotEmpty) {
        absorbed[AiGuidedField.factoryName.name] = asName;
      }
    } else if (field == AiGuidedField.factoryDetails &&
        !absorbed.containsKey(AiGuidedField.factoryDetails.name) &&
        !AiFieldParser.hasFactoryNameLabel(rawText)) {
      final stripped = AiFieldParser.stripLeadingLabels(rawText);
      if (stripped.isNotEmpty) {
        absorbed[AiGuidedField.factoryDetails.name] = stripped;
      }
    }

    final activeHasValue = field == AiGuidedField.factoryName
        ? absorbed.containsKey(AiGuidedField.factoryName.name)
        : absorbed.containsKey(AiGuidedField.factoryDetails.name);

    if (!activeHasValue) {
      if (field == AiGuidedField.factoryName) {
        _finalize(
          extraMessages: [
            ChatMessage(
              role: AiMessageRole.assistant,
              content: 'قولّي اسم المصنع؟ (مثال: "اسمه مصنع النور")',
              timestamp: DateTime.now(),
            ),
          ],
        );
        return;
      }
      if (_sameCreateValues(absorbed, currentState.createValues)) {
        final error = AiFieldParser.validate(field, rawText);
        if (error != null) {
          _finalize(
            extraMessages: [
              ChatMessage(
                role: AiMessageRole.assistant,
                content: '$error\n\n${field.label}؟',
                timestamp: DateTime.now(),
              ),
            ],
          );
          return;
        }
      }
      _advanceCreateFlow(currentState, updatedValues: absorbed);
      return;
    }

    _advanceCreateFlow(currentState, updatedValues: absorbed);
  }

  bool _sameCreateValues(Map<String, String> a, Map<String, String> b) {
    if (a.length != b.length) return false;
    for (final entry in b.entries) {
      if (a[entry.key] != entry.value) return false;
    }
    return true;
  }

  void _advanceCreateFlow(
    AiAssistantState currentState, {
    required Map<String, String> updatedValues,
    AiGuidedField? declinedField,
  }) {
    final values = updatedValues;
    final justSet = currentState.createActiveField;
    var pendingRequired = List<AiGuidedField>.of(
      currentState.createPendingRequired,
    );
    var pendingOptional = List<AiGuidedField>.of(
      currentState.createPendingOptional,
    );

    if (declinedField != null) {
      pendingRequired.removeWhere((f) => f == declinedField);
      pendingOptional.removeWhere((f) => f == declinedField);
    }

    if (justSet != null &&
        justSet == AiGuidedField.specialConditions &&
        values[justSet.name] == 'محظورة بيع' &&
        !pendingRequired.contains(AiGuidedField.prohibitedBankName)) {
      pendingRequired.insert(0, AiGuidedField.prohibitedBankName);
    }

    pendingRequired.removeWhere((f) => values.containsKey(f.name));
    pendingOptional.removeWhere((f) => values.containsKey(f.name));

    AiGuidedField? next;
    var nextIsOptional = false;
    if (pendingRequired.isNotEmpty) {
      next = pendingRequired.removeAt(0);
    } else if (pendingOptional.isNotEmpty) {
      next = pendingOptional.removeAt(0);
      nextIsOptional = true;
    }

    final messages = [...currentState.messages];
    final changedNames = _changedCreateFieldNames(
      currentState.createValues,
      values,
    );
    if (changedNames.isNotEmpty) {
      final lines = changedNames
          .map(
            (name) =>
                '■ ${(AiGuidedField.byName(name)?.label ?? name)} = ${values[name]} ✓',
          )
          .join('\n');
      messages.add(
        ChatMessage(
          role: AiMessageRole.assistant,
          content: 'تمام، حطيت إيه معايا:\n$lines',
          timestamp: DateTime.now(),
        ),
      );
    }

    AiAssistantState nextState;
    if (next == null) {
      messages.add(
        ChatMessage(
          role: AiMessageRole.assistant,
          content: 'تمام، راجع البيانات واضغط "تأكيد وتنفيذ" 👇',
          timestamp: DateTime.now(),
        ),
      );
      nextState = AiAssistantState(
        messages: messages,
        currentDraft: const AiTripDraft(),
        lastResult: null,
        isProcessing: false,
        isConfirming: false,
        selectedAction: currentState.selectedAction,
        showActionList: false,
        entryContext: currentState.entryContext,
        createValues: values,
        createPendingRequired: const [],
        createPendingOptional: const [],
        createActiveField: null,
        awaitingOptionalChoice: false,
        showGenericReview: true,
      );
    } else {
      final question = nextIsOptional
          ? 'تحب تضيف ${next.label}؟\n(اكتب القيمة أو "لا" لو مش ضروري)'
          : '${next.label}؟';
      messages.add(
        ChatMessage(
          role: AiMessageRole.assistant,
          content: question,
          timestamp: DateTime.now(),
        ),
      );
      nextState = AiAssistantState(
        messages: messages,
        currentDraft: const AiTripDraft(),
        lastResult: null,
        isProcessing: false,
        isConfirming: false,
        selectedAction: currentState.selectedAction,
        showActionList: false,
        entryContext: currentState.entryContext,
        createValues: values,
        createPendingRequired: pendingRequired,
        createPendingOptional: pendingOptional,
        createActiveField: next,
        awaitingOptionalChoice: nextIsOptional,
        showGenericReview: false,
      );
    }

    state = AsyncValue.data(nextState);
  }

  /// Names of create values added or changed in this turn, ordered as the
  /// action's fields appear (required first, then optional).
  List<String> _changedCreateFieldNames(
    Map<String, String> before,
    Map<String, String> after,
  ) {
    final changed = <String>[];
    for (final entry in after.entries) {
      if (!before.containsKey(entry.key) || before[entry.key] != entry.value) {
        changed.add(entry.key);
      }
    }
    final action = state.valueOrNull?.selectedAction;
    if (action == null) return changed;
    final option = availableAiActions.firstWhere(
      (o) => o.id == action,
      orElse: () => availableAiActions.first,
    );
    final ordered = [
      ...option.requiredFields.map((f) => f.name),
      ...option.optionalFields.map((f) => f.name),
    ];
    changed.sort((a, b) {
      final ia = ordered.indexOf(a);
      final ib = ordered.indexOf(b);
      if (ia == -1 && ib == -1) return 0;
      if (ia == -1) return 1;
      if (ib == -1) return -1;
      return ia.compareTo(ib);
    });
    return changed;
  }

  Future<void> executeCreate() async {
    final currentState = state.valueOrNull ?? const AiAssistantState();
    if (!currentState.showGenericReview || currentState.isConfirming) return;

    final action = currentState.selectedAction;
    if (action == null) return;

    final values = currentState.createValues;

    final duplicateMessage = AiDuplicateChecker.checkCreate(
      action: action,
      values: values,
      buses: ref.read(busProvider).valueOrNull ?? [],
      drivers: ref.read(driversProvider).valueOrNull ?? [],
      factories: ref.read(factoriesProvider).valueOrNull ?? [],
    );
    if (duplicateMessage != null) {
      state = AsyncValue.data(
        currentState.copyWith(
          clearLastResult: true,
          clearSelectedAction: true,
          showActionList: true,
          clearResolution: true,
          clearPending: true,
          clearFactoryTripType: true,
          showFactoryTripChoice: false,
          showFactoryChoice: false,
          clearCreate: true,
          clearEdit: true,
          lastDuplicateMessage: AiDuplicateChecker.snackMessageFor(action),
        ),
      );
      return;
    }

    final now = DateTime.now();
    state = AsyncValue.data(
      currentState.copyWith(
        messages: [
          ...currentState.messages,
          ChatMessage(
            role: AiMessageRole.assistant,
            content: 'جاري حفظ البيانات...',
            timestamp: now,
          ),
        ],
        isConfirming: true,
      ),
    );

    bool success = false;
    switch (action) {
      case AiActionId.addBus:
        success = await _executeAddBus(values);
        break;
      case AiActionId.addDriver:
        success = await _executeAddDriver(values);
        break;
      case AiActionId.addFactory:
        success = await _executeAddFactory(values);
        break;
      default:
        break;
    }

    final afterState = state.valueOrNull;
    if (afterState == null) return;

    if (success) {
      _completeCreateSuccess(afterState, action, values);
    } else {
      state = AsyncValue.data(
        afterState.copyWith(
          messages: [
            ...afterState.messages,
            ChatMessage(
              role: AiMessageRole.assistant,
              content:
                  'حصلت مشكلة أثناء الحفظ. البيانات لسه محفوظة، '
                  'تقدر تجرب تاني من الزرار.',
              timestamp: DateTime.now(),
            ),
          ],
          isProcessing: false,
          isConfirming: false,
        ),
      );
    }
  }

  Future<bool> _executeAddBus(Map<String, String> values) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    final licenseRaw = values[AiGuidedField.licenseExpiryDate.name] ?? '';
    final licenseDate = AiFieldParser.parseDate(licenseRaw);
    if (licenseDate == null) return false;

    final busId = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('buses')
        .doc()
        .id;

    final bus = BusEntity(
      id: busId,
      busName: values[AiGuidedField.busName.name] ?? '',
      plateNumber: values[AiGuidedField.plateNumber.name] ?? '',
      brand: values[AiGuidedField.brand.name] ?? '',
      model: values[AiGuidedField.model.name] ?? '',
      manufacturingYear: AiFieldParser.parseInt(
        values[AiGuidedField.manufacturingYear.name] ?? '',
      ),
      modelYear:
          AiFieldParser.parseInt(
            values[AiGuidedField.manufacturingYear.name] ?? '',
          ) ??
          0,
      chassisNumber: values[AiGuidedField.chassisNumber.name] ?? '',
      engineNumber: values[AiGuidedField.engineNumber.name] ?? '',
      passengerCount:
          AiFieldParser.parseInt(
            values[AiGuidedField.passengerCount.name] ?? '',
          ) ??
          0,
      vehicleType: values[AiGuidedField.vehicleType.name] ?? '',
      licenseExpiryDate: licenseDate,
      licenseImageUrl: null,
      busImageUrl: null,
      specialConditions:
          values[AiGuidedField.specialConditions.name] ?? 'السيارة خالصة',
      prohibitedBankName:
          values[AiGuidedField.prohibitedBankName.name]?.isNotEmpty == true
          ? values[AiGuidedField.prohibitedBankName.name]
          : null,
      insuranceType: values[AiGuidedField.insuranceType.name] ?? 'غير مؤمنة',
    );

    await ref.read(busProvider.notifier).addBus(bus: bus);
    return !ref.read(busProvider).hasError;
  }

  Future<bool> _executeAddDriver(Map<String, String> values) async {
    final createdId = await ref
        .read(driversProvider.notifier)
        .addDriver(
          name: values[AiGuidedField.driverName.name] ?? '',
          phone: values[AiGuidedField.driverPhone.name] ?? '',
          totalRevenue: 0,
          tripsCount: 0,
        );
    return createdId != null;
  }

  Future<bool> _executeAddFactory(Map<String, String> values) async {
    return ref
        .read(factoriesProvider.notifier)
        .addFactory(
          name: values[AiGuidedField.factoryName.name] ?? '',
          phone: '',
          details: values[AiGuidedField.factoryDetails.name] ?? '',
          totalRevenue: 0,
          tripsCount: 0,
        );
  }

  void _completeCreateSuccess(
    AiAssistantState confirmingState,
    AiActionId action,
    Map<String, String> values,
  ) {
    final option = availableAiActions.firstWhere((o) => o.id == action);
    final entityName = switch (action) {
      AiActionId.addBus => 'الأتوبيس',
      AiActionId.addDriver => 'السائق',
      AiActionId.addFactory => 'المصنع',
      _ => '',
    };

    final buf = StringBuffer('✅ تم إضافة $entityName بنجاح\n\n');
    final ordered = [...option.requiredFields, ...option.optionalFields];
    for (final f in ordered) {
      final value = values[f.name];
      if (value != null && value.isNotEmpty) {
        buf.writeln('• ${f.label}: $value');
      }
    }
    for (final entry in values.entries) {
      if (entry.value.isNotEmpty && !ordered.any((f) => f.name == entry.key)) {
        final label = AiGuidedField.byName(entry.key)?.label ?? entry.key;
        buf.writeln('• $label: ${entry.value}');
      }
    }

    state = AsyncValue.data(
      AiAssistantState(
        messages: [
          ...confirmingState.messages,
          ChatMessage(
            role: AiMessageRole.assistant,
            content: buf.toString(),
            timestamp: DateTime.now(),
          ),
        ],
        currentDraft: const AiTripDraft(),
        lastResult: null,
        isProcessing: false,
        isConfirming: false,
        selectedAction: null,
        showActionList: true,
        entryContext: confirmingState.entryContext,
        lastSuccessMessage: '✅ تم إضافة $entityName بنجاح',
      ),
    );

    switch (action) {
      case AiActionId.addBus:
        ref.invalidate(busProvider);
        break;
      case AiActionId.addDriver:
        ref.invalidate(driversProvider);
        break;
      case AiActionId.addFactory:
        ref.invalidate(factoriesProvider);
        break;
      default:
        break;
    }
  }

  /// Starts the "add factory trip" action: chooses the factory, then the trip
  /// type (رحلة/سهرة), then reuses the normal trip data flow.
  void _startAddFactoryTripFlow({String userText = ''}) {
    final currentState = state.valueOrNull ?? const AiAssistantState();
    final factories = ref.read(factoriesProvider).valueOrNull ?? const [];

    if (factories.isEmpty) {
      _finalize(
        extraMessages: [
          ChatMessage(
            role: AiMessageRole.assistant,
            content:
                'مفيش مصانع مسجلة لسه.\n'
                'سجّل مصنع الأول من "إضافة مصنع" وبعدها نضيف رحلة المصنع.',
            timestamp: DateTime.now(),
          ),
        ],
        clearLastResult: true,
        selectedAction: AiActionId.addFactoryTrip,
        showActionList: true,
        showFactoryChoice: false,
        clearCreate: true,
      );
      return;
    }

    AiTripDraft extraDraft = const AiTripDraft();

    if (userText.isNotEmpty) {
      final matches = _matchFactories(userText, factories);
      if (matches.length == 1) {
        final detectedType = LocalIntentService.detectFactoryTripType(userText);
        if (detectedType != null) {
          _applyFactoryTripType(
            detectedType,
            userText: userText,
            factoryOverride: matches.first,
          );
          return;
        }
        _setTripFactory(matches.first, userText: userText);
        return;
      }
      if (matches.length > 1) {
        final buses = ref.read(busProvider).valueOrNull ?? [];
        final drivers = ref.read(driversProvider).valueOrNull ?? [];
        final parsed = LocalTripParser().parse(
          userMessage: userText,
          currentDraft: const AiTripDraft(),
          availableBuses: buses,
          availableDrivers: drivers,
          availableFactories: factories,
        );
        final extraDraft = parsed.tripDraft ?? const AiTripDraft();

        final message = ChatMessage(
          role: AiMessageRole.assistant,
          content: 'لقيت أكتر من مصنع مطابق. اختار واحد منهم 👇',
          timestamp: DateTime.now(),
        );
        state = AsyncValue.data(
          AiAssistantState(
            messages: [...currentState.messages, message],
            currentDraft: extraDraft,
            lastResult: null,
            isProcessing: false,
            isConfirming: false,
            selectedAction: AiActionId.addFactoryTrip,
            showActionList: false,
            showFactoryChoice: true,
            factoryChoiceCandidates: matches,
            entryContext: currentState.entryContext,
          ),
        );
        return;
      }
      if (matches.isEmpty) {
        final buses = ref.read(busProvider).valueOrNull ?? [];
        final drivers = ref.read(driversProvider).valueOrNull ?? [];
        final parsed = LocalTripParser().parse(
          userMessage: userText,
          currentDraft: const AiTripDraft(),
          availableBuses: buses,
          availableDrivers: drivers,
          availableFactories: factories,
        );
        extraDraft = parsed.tripDraft ?? const AiTripDraft();
      }
    }

    final message = ChatMessage(
      role: AiMessageRole.assistant,
      content: 'اختار المصنع اللي هتسجل الرحلة/السهرة له 👇',
      timestamp: DateTime.now(),
    );
    state = AsyncValue.data(
      AiAssistantState(
        messages: [...currentState.messages, message],
        currentDraft: extraDraft,
        lastResult: null,
        isProcessing: false,
        isConfirming: false,
        selectedAction: AiActionId.addFactoryTrip,
        showActionList: false,
        showFactoryChoice: true,
        factoryChoiceCandidates: factories,
        entryContext: currentState.entryContext,
      ),
    );
  }

  List<FactoryEntity> _matchFactories(
    String normalizedText,
    List<FactoryEntity> factories,
  ) {
    return factories.where((f) {
      final n = LocalIntentService.normalize(f.name);
      return n.isNotEmpty &&
          (normalizedText.contains(n) || n.contains(normalizedText));
    }).toList();
  }

  void _handleFactoryChoiceText(String normalized) {
    final currentState = state.valueOrNull ?? const AiAssistantState();
    final factories = currentState.factoryChoiceCandidates.isNotEmpty
        ? currentState.factoryChoiceCandidates
        : (ref.read(factoriesProvider).valueOrNull ?? const <FactoryEntity>[]);

    final matches = _matchFactories(normalized, factories);
    if (matches.isEmpty) {
      _finalize(
        extraMessages: [
          ChatMessage(
            role: AiMessageRole.assistant,
            content: 'مفيش مصنع بالاسم ده.\nاختار واحد من القايمة 👇',
            timestamp: DateTime.now(),
          ),
        ],
      );
      return;
    }
    if (matches.length > 1) {
      state = AsyncValue.data(
        currentState.copyWith(
          messages: [
            ...currentState.messages,
            ChatMessage(
              role: AiMessageRole.assistant,
              content: 'لقيت أكتر من مصنع مطابق. اختار واحد منهم 👇',
              timestamp: DateTime.now(),
            ),
          ],
          factoryChoiceCandidates: matches,
        ),
      );
      return;
    }
    _setTripFactory(matches.first, userText: normalized);
  }

  void chooseTripFactory(String entityId) {
    final currentState = state.valueOrNull ?? const AiAssistantState();
    if (!currentState.showFactoryChoice || currentState.isConfirming) return;
    final factory = _findFactoryById(
      currentState.factoryChoiceCandidates,
      entityId,
    );
    if (factory == null) return;
    _setTripFactory(factory);
  }

  void _setTripFactory(FactoryEntity factory, {String userText = ''}) {
    final currentState = state.valueOrNull ?? const AiAssistantState();

    final cameFromChoice =
        currentState.showFactoryChoice ||
        currentState.factoryChoiceCandidates.isNotEmpty;

    AiTripDraft parsedExtra = const AiTripDraft();
    if (userText.isNotEmpty) {
      final buses = ref.read(busProvider).valueOrNull ?? [];
      final drivers = ref.read(driversProvider).valueOrNull ?? [];
      final allFactories = ref.read(factoriesProvider).valueOrNull ?? [];
      final parsed = LocalTripParser().parse(
        userMessage: userText,
        currentDraft: const AiTripDraft(),
        availableBuses: buses,
        availableDrivers: drivers,
        availableFactories: allFactories,
      );
      parsedExtra = parsed.tripDraft ?? const AiTripDraft();
    }

    final base = cameFromChoice
        ? currentState.currentDraft.merge(parsedExtra)
        : parsedExtra;
    final draft = base.copyWith(factoryName: factory.name);

    final message = ChatMessage(
      role: AiMessageRole.assistant,
      content:
          'تمام، المصنع "${factory.name}" محدد ✓\n'
          'عايز تسجل أنهي نوع؟',
      timestamp: DateTime.now(),
    );

    state = AsyncValue.data(
      AiAssistantState(
        messages: [...currentState.messages, message],
        currentDraft: draft,
        lastResult: null,
        isProcessing: false,
        isConfirming: false,
        selectedAction: AiActionId.addFactoryTrip,
        showActionList: false,
        resolvedFactory: factory,
        entryContext: currentState.entryContext,
        showFactoryChoice: false,
        factoryChoiceCandidates: const [],
        showFactoryTripChoice: true,
      ),
    );
  }

  void _applyFactoryTripType(
    String tripType, {
    String userText = '',
    FactoryEntity? factoryOverride,
  }) {
    final currentState = state.valueOrNull ?? const AiAssistantState();
    final ctx = currentState.entryContext;
    final factory =
        factoryOverride ??
        currentState.resolvedFactory ??
        (ctx.isFactoryContext ? ctx.factory : null);

    final buses = ref.read(busProvider).valueOrNull ?? [];
    final drivers = ref.read(driversProvider).valueOrNull ?? [];
    final allFactories = ref.read(factoriesProvider).valueOrNull ?? [];

    AiTripDraft parsedExtra = const AiTripDraft();
    if (userText.isNotEmpty) {
      final parsed = LocalTripParser().parse(
        userMessage: userText,
        currentDraft: const AiTripDraft(),
        availableBuses: buses,
        availableDrivers: drivers,
        availableFactories: allFactories,
      );
      parsedExtra = parsed.tripDraft ?? const AiTripDraft();
    }

    final base = factoryOverride != null
        ? parsedExtra
        : currentState.currentDraft.merge(parsedExtra);
    var draft = base.copyWith(type: tripType, factoryName: factory?.name);

    BusEntity? resolvedBus = currentState.resolvedBus;
    DriverEntity? resolvedDriver = currentState.resolvedDriver;

    if (ctx.isBusContext && ctx.bus != null) {
      draft = draft.copyWith(
        busName: ctx.bus!.busName,
        plateNumber: ctx.bus!.plateNumber,
      );
      resolvedBus = ctx.bus;
    }

    final typeLabel = tripType == TripType.nightOuting ? 'سهرة' : 'رحلة';
    final merged = _applyContextToDraft(draft);
    final missing = merged.missingRequiredFields;

    if (missing.isEmpty) {
      final result = AiActionResult(
        type: AiActionType.createTrip,
        assistantMessage: '',
        tripDraft: merged,
      );
      final assistantMessage = ChatMessage(
        role: AiMessageRole.assistant,
        content: _buildTripReviewMessage(merged),
        timestamp: DateTime.now(),
      );
      _handleTripEngagement(
        draft: merged,
        result: result,
        assistantMessage: assistantMessage,
      );
      return;
    }

    final message = ChatMessage(
      role: AiMessageRole.assistant,
      content: [
        'تمام 👍',
        'هنسجل $typeLabel',
        if (factory != null) 'للمصنع "${factory.name}"',
        '',
        _buildTripChecklistMessageWithDraft(draft, tripType: tripType),
      ].join('\n'),
      timestamp: DateTime.now(),
    );

    state = AsyncValue.data(
      AiAssistantState(
        messages: [...currentState.messages, message],
        currentDraft: draft,
        lastResult: null,
        isProcessing: false,
        isConfirming: false,
        selectedAction: AiActionId.addTrip,
        showActionList: false,
        resolvedBus: resolvedBus,
        resolvedDriver: resolvedDriver,
        resolvedFactory: factory,
        entryContext: currentState.entryContext,
        selectedFactoryTripType: tripType,
        showFactoryTripChoice: false,
      ),
    );
  }

  void selectFactoryTripType(String tripType) {
    _applyFactoryTripType(tripType);
  }

  String _buildTripReviewMessage(AiTripDraft draft) {
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

    buffer.write(
      'النوع: ${draft.type == TripType.nightOuting ? 'سهرة' : 'رحلة'}\n',
    );

    buffer.write('\nعندك تعديل ولا ننفذه؟');

    return buffer.toString();
  }

  Future<void> _handleQueryAction(
    AiActionId actionId,
    String text, {
    bool alreadyProcessing = false,
  }) async {
    final currentState = state.valueOrNull ?? const AiAssistantState();
    if (!alreadyProcessing && currentState.isProcessing) return;
    final now = DateTime.now();
    state = AsyncValue.data(currentState.copyWith(isProcessing: true));
    if (state.valueOrNull == null) return;

    final buses = ref.read(busProvider).valueOrNull ?? const [];
    final drivers = ref.read(driversProvider).valueOrNull ?? const [];
    final factories = ref.read(factoriesProvider).valueOrNull ?? const [];

    final period = AiPeriodParser.resolve(text);

    AiQueryScope? scope;
    String? earlyAnswer;
    if (actionId == AiActionId.queryTrips ||
        actionId == AiActionId.queryDrivers) {
      final candidates = AiQueryService.resolveScopeCandidates(
        text,
        buses: buses,
        drivers: drivers,
        factories: factories,
      );
      if (AiQueryService.isEntityReferenced(text)) {
        if (candidates.isEmpty) {
          earlyAnswer = AiQueryService.entityNotFoundMessage(actionId);
        } else if (candidates.length > 1) {
          earlyAnswer = AiQueryService.ambiguousEntityMessage(candidates);
        } else {
          scope = candidates.first;
        }
      } else if (candidates.isNotEmpty) {
        scope = candidates.first;
      }
    }

    final wageIntent = LocalIntentService.normalize(text).contains('اجر');
    final hasScopedEntity =
        scope != null && scope.entityId != null && scope.entityId!.isNotEmpty;
    final scopedCount =
        hasScopedEntity ||
        (wageIntent && actionId == AiActionId.queryDrivers && scope == null);
    final effectiveCount =
        text.isEmpty || (AiQueryService.isCountQuery(text) && !scopedCount);

    final isTripCountGlobal =
        actionId == AiActionId.queryTrips &&
        effectiveCount &&
        scope == null &&
        period == null;
    final needsTrips = isTripCountGlobal
        ? false
        : (actionId == AiActionId.queryTrips ||
              hasScopedEntity ||
              !effectiveCount);

    List<TripEntity> allTrips = const [];
    if (earlyAnswer == null && needsTrips) {
      try {
        if (scope != null &&
            scope.entityId != null &&
            scope.entityId!.isNotEmpty) {
          switch (scope.entityKind) {
            case 'bus':
              allTrips = await ref.read(
                busTripsProvider(scope.entityId!).future,
              );
              break;
            case 'driver':
              allTrips = await ref.read(
                driverTripsProvider(scope.entityId!).future,
              );
              break;
            case 'factory':
              allTrips = await ref.read(
                factoryTripsProvider(scope.entityId!).future,
              );
              break;
            default:
              allTrips = await ref.read(home_trip.allTripsProvider.future);
          }
        } else {
          allTrips = await ref.read(home_trip.allTripsProvider.future);
        }
      } catch (_) {
        final after = state.valueOrNull;
        if (after == null) return;
        state = AsyncValue.data(
          after.copyWith(
            messages: [
              ...after.messages,
              ChatMessage(
                role: AiMessageRole.assistant,
                content:
                    'معرفتش أجيب بيانات الرحلات من السيرفر حالياً.\nجرب بعد شوية.',
                timestamp: DateTime.now(),
              ),
            ],
            isProcessing: false,
          ),
        );
        return;
      }
    }

    final answer =
        earlyAnswer ??
        (switch (actionId) {
          AiActionId.queryTrips =>
            isTripCountGlobal
                ? AiQueryService.answerTripsCount(drivers: drivers)
                : AiQueryService.answerTrips(
                    trips: allTrips,
                    buses: buses,
                    drivers: drivers,
                    factories: factories,
                    scope: scope,
                    period: period,
                  ),
          AiActionId.queryBuses =>
            effectiveCount
                ? AiQueryService.answerBusesCount(buses)
                : AiQueryService.answerBuses(
                    buses: buses,
                    trips: allTrips,
                    period: period,
                  ),
          AiActionId.queryDrivers =>
            hasScopedEntity
                ? (wageIntent
                      ? AiQueryService.answerDriverWage(
                          driverName: scope.entityName ?? '',
                          trips: allTrips,
                          period: period,
                        )
                      : AiQueryService.answerTrips(
                          trips: allTrips,
                          buses: buses,
                          drivers: drivers,
                          factories: factories,
                          scope: scope,
                          period: period,
                        ))
                : effectiveCount
                ? AiQueryService.answerDriversCount(drivers)
                : AiQueryService.answerDrivers(
                    drivers: drivers,
                    trips: allTrips,
                    period: period,
                  ),
          AiActionId.queryFactories =>
            effectiveCount
                ? AiQueryService.answerFactoriesCount(factories)
                : AiQueryService.answerFactories(
                    factories: factories,
                    trips: allTrips,
                    period: period,
                  ),
          _ => '',
        });

    final after = state.valueOrNull;
    if (after == null) return;

    state = AsyncValue.data(
      after.copyWith(
        messages: [
          ...after.messages,
          ChatMessage(
            role: AiMessageRole.assistant,
            content: answer,
            timestamp: now,
          ),
        ],
        isProcessing: false,
      ),
    );
  }

  /// Injects the entry context entities (bus/factory) into the draft so the
  /// required-field checks and execution bridge never lose context-provided
  /// values, while still letting the user override them explicitly.
  AiTripDraft _applyContextToDraft(AiTripDraft draft) {
    final ctx = _getContext();
    var updated = draft;

    if (ctx.isBusContext && ctx.bus != null) {
      updated = updated.copyWith(
        busName: ctx.bus!.busName,
        plateNumber: ctx.bus!.plateNumber,
      );
    }

    if (ctx.isFactoryContext && ctx.factory != null) {
      updated = updated.copyWith(factoryName: ctx.factory!.name);
    }

    final tripType = state.valueOrNull?.selectedFactoryTripType;
    if (tripType != null && tripType.isNotEmpty) {
      updated = updated.copyWith(type: tripType);
    }

    return updated;
  }

  void _handleTripEngagement({
    required AiTripDraft draft,
    required AiActionResult result,
    required ChatMessage assistantMessage,
  }) {
    final currentState = state.valueOrNull ?? const AiAssistantState();
    final ctx = currentState.entryContext;

    final buses = ref.read(busProvider).valueOrNull ?? const [];
    final drivers = ref.read(driversProvider).valueOrNull ?? const [];
    final factories = ref.read(factoriesProvider).valueOrNull ?? const [];

    AiEntityResolution<BusEntity> busRes;
    if (ctx.isBusContext && ctx.bus != null) {
      busRes = AiEntityResolution(resolved: ctx.bus);
    } else {
      busRes = AiEntityResolver.preferStored(
        raw: AiEntityResolver.resolveBus(draft: draft, buses: buses),
        stored: currentState.resolvedBus,
        stillMatches: (storedBus) =>
            AiEntityResolver.busStillMatches(storedBus, draft),
      );
    }

    var driverRes = AiEntityResolver.preferStored(
      raw: AiEntityResolver.resolveDriver(draft: draft, drivers: drivers),
      stored: currentState.resolvedDriver,
      stillMatches: (storedDriver) =>
          AiEntityResolver.driverStillMatches(storedDriver, draft),
    );

    AiEntityResolution<FactoryEntity> factoryRes;
    if (ctx.isFactoryContext && ctx.factory != null) {
      factoryRes = AiEntityResolution(resolved: ctx.factory);
    } else {
      factoryRes = AiEntityResolver.preferStored(
        raw: AiEntityResolver.resolveFactory(
          draft: draft,
          factories: factories,
        ),
        stored: currentState.resolvedFactory,
        stillMatches: (storedFactory) =>
            AiEntityResolver.factoryStillMatches(storedFactory, draft),
      );
    }

    final hasFactory =
        draft.factoryName != null && draft.factoryName!.isNotEmpty;

    AiEntityField? pending;
    if (busRes.isAmbiguous) {
      pending = AiEntityField.bus;
    } else if (driverRes.isAmbiguous) {
      pending = AiEntityField.driver;
    } else if (hasFactory && factoryRes.isAmbiguous) {
      pending = AiEntityField.factory;
    }

    final extra = <ChatMessage>[assistantMessage];
    final now = DateTime.now();

    if (!ctx.isBusContext && draft.busName != null && busRes.isNotFound) {
      extra.add(
        ChatMessage(
          role: AiMessageRole.assistant,
          content:
              'مش لاقي أتوبيس باسم "${draft.busName}" أو بالنمرة اللي قلتها. '
              'اختار أتوبيس موجود عندك.',
          timestamp: now,
        ),
      );
    }
    if (draft.driverName != null && driverRes.isNotFound) {
      extra.add(
        ChatMessage(
          role: AiMessageRole.assistant,
          content:
              'مش لاقي سواق باسم "${draft.driverName}". '
              'اختار سواق موجود عندك.',
          timestamp: now,
        ),
      );
    }
    if (!ctx.isFactoryContext && hasFactory && factoryRes.isNotFound) {
      extra.add(
        ChatMessage(
          role: AiMessageRole.assistant,
          content:
              'مش لاقي مصنع باسم "${draft.factoryName}". '
              'اختار مصنع موجود عندك أو سيب المصنع.',
          timestamp: now,
        ),
      );
    }

    if (pending != null) {
      final label = switch (pending) {
        AiEntityField.bus => 'أتوبيس',
        AiEntityField.driver => 'سواق',
        AiEntityField.factory => 'مصنع',
      };
      extra.add(
        ChatMessage(
          role: AiMessageRole.assistant,
          content: 'لقيت أكتر من $label مطابق. اختار واحد منهم 👇',
          timestamp: now,
        ),
      );
    }

    state = AsyncValue.data(
      AiAssistantState(
        messages: [...currentState.messages, ...extra],
        currentDraft: draft,
        lastResult: result,
        isProcessing: false,
        isConfirming: false,
        selectedAction: AiActionId.addTrip,
        showActionList: false,
        resolvedBus: busRes.resolved,
        resolvedDriver: driverRes.resolved,
        resolvedFactory: factoryRes.resolved,
        pendingChoiceField: pending,
        busCandidates: busRes.candidates,
        driverCandidates: driverRes.candidates,
        factoryCandidates: factoryRes.candidates,
        entryContext: currentState.entryContext,
        selectedFactoryTripType: currentState.selectedFactoryTripType,
      ),
    );
  }

  void chooseEntity(AiEntityField field, String entityId) {
    final currentState = state.valueOrNull ?? const AiAssistantState();
    if (currentState.pendingChoiceField != field || currentState.isConfirming) {
      return;
    }

    final pendingEdit = currentState.pendingDraftEdit;
    if (pendingEdit != null && currentState.isEditingDraft) {
      _applyChosenEntityEdit(currentState, field, entityId, pendingEdit);
      return;
    }

    final draft = currentState.currentDraft;
    final buses = ref.read(busProvider).valueOrNull ?? const [];
    final drivers = ref.read(driversProvider).valueOrNull ?? const [];
    final factories = ref.read(factoriesProvider).valueOrNull ?? const [];
    final ctx = currentState.entryContext;

    AiEntityResolution<BusEntity> busRes;
    if (ctx.isBusContext && ctx.bus != null) {
      busRes = AiEntityResolution(resolved: ctx.bus);
    } else {
      busRes = AiEntityResolver.preferStored(
        raw: AiEntityResolver.resolveBus(draft: draft, buses: buses),
        stored: currentState.resolvedBus,
        stillMatches: (storedBus) =>
            AiEntityResolver.busStillMatches(storedBus, draft),
      );
    }

    var driverRes = AiEntityResolver.preferStored(
      raw: AiEntityResolver.resolveDriver(draft: draft, drivers: drivers),
      stored: currentState.resolvedDriver,
      stillMatches: (storedDriver) =>
          AiEntityResolver.driverStillMatches(storedDriver, draft),
    );

    AiEntityResolution<FactoryEntity> factoryRes;
    if (ctx.isFactoryContext && ctx.factory != null) {
      factoryRes = AiEntityResolution(resolved: ctx.factory);
    } else {
      factoryRes = AiEntityResolver.preferStored(
        raw: AiEntityResolver.resolveFactory(
          draft: draft,
          factories: factories,
        ),
        stored: currentState.resolvedFactory,
        stillMatches: (storedFactory) =>
            AiEntityResolver.factoryStillMatches(storedFactory, draft),
      );
    }

    if (field == AiEntityField.bus && !ctx.isBusContext) {
      final chosen = _findBusById(currentState.busCandidates, entityId);
      if (chosen == null) return;
      busRes = AiEntityResolution<BusEntity>(resolved: chosen);
    } else if (field == AiEntityField.driver) {
      final chosen = _findDriverById(currentState.driverCandidates, entityId);
      if (chosen == null) return;
      driverRes = AiEntityResolution<DriverEntity>(resolved: chosen);
    } else if (field == AiEntityField.factory && !ctx.isFactoryContext) {
      final chosen = _findFactoryById(currentState.factoryCandidates, entityId);
      if (chosen == null) return;
      factoryRes = AiEntityResolution<FactoryEntity>(resolved: chosen);
    }

    final hasFactory =
        draft.factoryName != null && draft.factoryName!.isNotEmpty;

    AiEntityField? pending;
    if (busRes.isAmbiguous) {
      pending = AiEntityField.bus;
    } else if (driverRes.isAmbiguous) {
      pending = AiEntityField.driver;
    } else if (hasFactory && factoryRes.isAmbiguous) {
      pending = AiEntityField.factory;
    }

    final extra = <ChatMessage>[];
    final now = DateTime.now();

    if (pending == null) {
      final chosenLabel = switch (field) {
        AiEntityField.bus => busRes.resolved?.busName ?? '',
        AiEntityField.driver => driverRes.resolved?.name ?? '',
        AiEntityField.factory => factoryRes.resolved?.name ?? '',
      };
      extra.add(
        ChatMessage(
          role: AiMessageRole.assistant,
          content: 'تمام، اتبقنيت على الـ$chosenLabel ✅',
          timestamp: now,
        ),
      );
    } else {
      final label = switch (pending) {
        AiEntityField.bus => 'أتوبيس',
        AiEntityField.driver => 'سواق',
        AiEntityField.factory => 'مصنع',
      };
      extra.add(
        ChatMessage(
          role: AiMessageRole.assistant,
          content: 'لقيت أكتر من $label مطابق. اختار واحد منهم 👇',
          timestamp: now,
        ),
      );
    }

    state = AsyncValue.data(
      AiAssistantState(
        messages: [...currentState.messages, ...extra],
        currentDraft: draft,
        lastResult: currentState.lastResult,
        isProcessing: false,
        isConfirming: false,
        selectedAction: currentState.selectedAction,
        showActionList: false,
        resolvedBus: busRes.resolved,
        resolvedDriver: driverRes.resolved,
        resolvedFactory: factoryRes.resolved,
        pendingChoiceField: pending,
        busCandidates: busRes.candidates,
        driverCandidates: driverRes.candidates,
        factoryCandidates: factoryRes.candidates,
        entryContext: currentState.entryContext,
        selectedFactoryTripType: currentState.selectedFactoryTripType,
      ),
    );
  }

  /// Applies an entity choice made while editing a trip draft: pins the chosen
  /// entity's names onto the merged draft, then reuses the shared trip-edit
  /// finalization (re-resolution, not-found/ambiguous handling, success).
  void _applyChosenEntityEdit(
    AiAssistantState current,
    AiEntityField field,
    String entityId,
    PendingDraftEdit pending,
  ) {
    final ctx = current.entryContext;
    final now = DateTime.now();
    var merged = pending.baseDraft.merge(pending.patch);
    String? confirmLabel;

    if (field == AiEntityField.bus && !ctx.isBusContext) {
      final chosen = _findBusById(current.busCandidates, entityId);
      if (chosen == null) return;
      merged = merged.copyWith(
        busName: chosen.busName,
        plateNumber: chosen.plateNumber,
      );
      confirmLabel = chosen.busName;
    } else if (field == AiEntityField.driver) {
      final chosen = _findDriverById(current.driverCandidates, entityId);
      if (chosen == null) return;
      merged = merged.copyWith(driverName: chosen.name);
      confirmLabel = chosen.name;
    } else if (field == AiEntityField.factory && !ctx.isFactoryContext) {
      final chosen = _findFactoryById(current.factoryCandidates, entityId);
      if (chosen == null) return;
      merged = merged.copyWith(factoryName: chosen.name);
      confirmLabel = chosen.name;
    }

    final extraMessages = confirmLabel == null
        ? const <ChatMessage>[]
        : [
            ChatMessage(
              role: AiMessageRole.assistant,
              content: 'تمام، اتبقنيت على الـ$confirmLabel ✅',
              timestamp: now,
            ),
          ];

    _finishTripEdit(
      current.copyWith(
        messages: [...current.messages, ...extraMessages],
        currentDraft: pending.baseDraft,
        resolvedBus: field == AiEntityField.bus && !ctx.isBusContext
            ? (_findBusById(current.busCandidates, entityId) ??
                current.resolvedBus)
            : current.resolvedBus,
        resolvedDriver: field == AiEntityField.driver
            ? (_findDriverById(current.driverCandidates, entityId) ??
                current.resolvedDriver)
            : current.resolvedDriver,
        resolvedFactory: field == AiEntityField.factory && !ctx.isFactoryContext
            ? (_findFactoryById(current.factoryCandidates, entityId) ??
                current.resolvedFactory)
            : current.resolvedFactory,
      ),
      merged,
      pending.patch,
      pending.typeOverride,
    );
  }

  Future<void> executeTrip() async {
    final currentState = state.valueOrNull ?? const AiAssistantState();
    if (currentState.isConfirming) return;

    final draft = _applyContextToDraft(currentState.currentDraft);

    final missing = draft.missingRequiredFields;
    if (missing.isNotEmpty) {
      _finalize(
        extraMessages: [
          ChatMessage(
            role: AiMessageRole.assistant,
            content: 'لسه محتاج أعرف: ${missing.join('، ')}',
            timestamp: DateTime.now(),
          ),
        ],
      );
      return;
    }

    // A trip may never be dated in the future. When the user states a future
    // date we do NOT create the trip, we do NOT silently shift it to today,
    // and we keep the draft intact so they can pick another date.
    final statedDate = draft.tripDate;
    if (statedDate != null &&
        !TripDateRule.isAllowed(statedDate, today: DateTime.now())) {
      _finalize(
        extraMessages: [
          ChatMessage(
            role: AiMessageRole.assistant,
            content: TripDateRule.futureDateMessage,
            timestamp: DateTime.now(),
          ),
        ],
      );
      return;
    }

    final buses = ref.read(busProvider).valueOrNull ?? const [];
    final drivers = ref.read(driversProvider).valueOrNull ?? const [];
    final factories = ref.read(factoriesProvider).valueOrNull ?? const [];
    final ctx = currentState.entryContext;

    AiEntityResolution<BusEntity> busRes;
    if (ctx.isBusContext && ctx.bus != null) {
      busRes = AiEntityResolution(resolved: ctx.bus);
    } else {
      busRes = AiEntityResolver.preferStored(
        raw: AiEntityResolver.resolveBus(draft: draft, buses: buses),
        stored: currentState.resolvedBus,
        stillMatches: (storedBus) =>
            AiEntityResolver.busStillMatches(storedBus, draft),
      );
    }

    var driverRes = AiEntityResolver.preferStored(
      raw: AiEntityResolver.resolveDriver(draft: draft, drivers: drivers),
      stored: currentState.resolvedDriver,
      stillMatches: (storedDriver) =>
          AiEntityResolver.driverStillMatches(storedDriver, draft),
    );

    AiEntityResolution<FactoryEntity> factoryRes;
    if (ctx.isFactoryContext && ctx.factory != null) {
      factoryRes = AiEntityResolution(resolved: ctx.factory);
    } else {
      factoryRes = AiEntityResolver.preferStored(
        raw: AiEntityResolver.resolveFactory(
          draft: draft,
          factories: factories,
        ),
        stored: currentState.resolvedFactory,
        stillMatches: (storedFactory) =>
            AiEntityResolver.factoryStillMatches(storedFactory, draft),
      );
    }

    final hasFactory =
        draft.factoryName != null && draft.factoryName!.isNotEmpty;

    final now = DateTime.now();

    if (busRes.isAmbiguous) {
      _setPendingResolve(
        currentState,
        draft,
        AiEntityField.bus,
        busRes.candidates,
      );
      return;
    }
    if (busRes.isNotFound && draft.busName != null) {
      _finalize(
        extraMessages: [
          ChatMessage(
            role: AiMessageRole.assistant,
            content:
                'مش لاقي أتوبيس باسم "${draft.busName}". اختار أتوبيس موجود عندك.',
            timestamp: now,
          ),
        ],
      );
      return;
    }
    if (driverRes.isAmbiguous) {
      _setPendingResolve(
        currentState,
        draft,
        AiEntityField.driver,
        driverRes.candidates,
      );
      return;
    }
    if (driverRes.isNotFound && draft.driverName != null) {
      _finalize(
        extraMessages: [
          ChatMessage(
            role: AiMessageRole.assistant,
            content:
                'مش لاقي سواق باسم "${draft.driverName}". اختار سواق موجود عندك.',
            timestamp: now,
          ),
        ],
      );
      return;
    }
    if (hasFactory && factoryRes.isAmbiguous) {
      _setPendingResolve(
        currentState,
        draft,
        AiEntityField.factory,
        factoryRes.candidates,
      );
      return;
    }
    if (hasFactory && factoryRes.isNotFound) {
      _finalize(
        extraMessages: [
          ChatMessage(
            role: AiMessageRole.assistant,
            content:
                'مش لاقي مصنع باسم "${draft.factoryName}". '
                'اختار مصنع موجود عندك أو سيب المصنع.',
            timestamp: now,
          ),
        ],
      );
      return;
    }

    final bus = busRes.resolved;
    final driver = driverRes.resolved;
    if (bus == null || driver == null) return;

    final factory = factoryRes.resolved;

    final trip = AiEntityResolver.buildTripEntity(
      draft: draft,
      bus: bus,
      driver: driver,
      factory: factory,
    );

    final confirmingState = AiAssistantState(
      messages: [
        ...currentState.messages,
        ChatMessage(
          role: AiMessageRole.assistant,
          content: 'جاري إضافة الرحلة...',
          timestamp: now,
        ),
      ],
      currentDraft: draft,
      lastResult: currentState.lastResult,
      isProcessing: false,
      isConfirming: true,
      selectedAction: currentState.selectedAction,
      showActionList: false,
      resolvedBus: bus,
      resolvedDriver: driver,
      resolvedFactory: factory,
      pendingChoiceField: null,
      entryContext: currentState.entryContext,
      selectedFactoryTripType: currentState.selectedFactoryTripType,
    );

    state = AsyncValue.data(confirmingState);

    final success = await ref.read(tripProvider.notifier).addTrip(trip);

    final afterState = state.valueOrNull;
    if (afterState == null) return;

    if (success) {
      _completeSuccess(afterState, draft, bus, driver, factory);
    } else {
      state = AsyncValue.data(
        AiAssistantState(
          messages: [
            ...afterState.messages,
            ChatMessage(
              role: AiMessageRole.assistant,
              content:
                  'حصلت مشكلة وأنا بحاول أضيف الرحلة. '
                  'البيانات لسه محفوظة، ممكن نحاول تاني.',
              timestamp: DateTime.now(),
            ),
          ],
          currentDraft: draft,
          lastResult: afterState.lastResult,
          isProcessing: false,
          isConfirming: false,
          selectedAction: afterState.selectedAction,
          showActionList: false,
          resolvedBus: bus,
          resolvedDriver: driver,
          resolvedFactory: factory,
          pendingChoiceField: null,
          entryContext: afterState.entryContext,
          selectedFactoryTripType: afterState.selectedFactoryTripType,
        ),
      );
    }
  }

  void _setPendingResolve(
    AiAssistantState currentState,
    AiTripDraft draft,
    AiEntityField field,
    List<dynamic> candidates,
  ) {
    state = AsyncValue.data(
      currentState.copyWith(
        messages: [
          ...currentState.messages,
          ChatMessage(
            role: AiMessageRole.assistant,
            content: 'لقيت أكتر من مطابق. اختار واحد منهم 👇',
            timestamp: DateTime.now(),
          ),
        ],
        pendingChoiceField: field,
        busCandidates: field == AiEntityField.bus
            ? candidates.cast<BusEntity>()
            : const [],
        driverCandidates: field == AiEntityField.driver
            ? candidates.cast<DriverEntity>()
            : const [],
        factoryCandidates: field == AiEntityField.factory
            ? candidates.cast<FactoryEntity>()
            : const [],
        isConfirming: false,
        entryContext: currentState.entryContext,
        selectedFactoryTripType: currentState.selectedFactoryTripType,
      ),
    );
  }

  void _completeSuccess(
    AiAssistantState confirmingState,
    AiTripDraft draft,
    BusEntity bus,
    DriverEntity driver,
    FactoryEntity? factory,
  ) {
    final type = draft.type == TripType.nightOuting ? 'سهرة' : 'رحلة';
    final summary = StringBuffer('تم إضافة الرحلة بنجاح ✅\n\n');
    summary.write('النوع: $type\n');
    summary.write('الأتوبيس: ${bus.busName} (${bus.plateNumber})\n');
    summary.write('السواق: ${driver.name}\n');
    if (factory != null) summary.write('المصنع: ${factory.name}\n');
    if (draft.tripDate != null) {
      summary.write('التاريخ: ${_formatDate(draft.tripDate!)}\n');
    }
    if (draft.departureTime != null && draft.departureTime!.isNotEmpty) {
      summary.write('الوقت: ${draft.departureTime}\n');
    }
    if (draft.revenue != null) {
      summary.write('الايراد: ${draft.revenue!.toInt()} جنيه\n');
    }
    if (draft.driverWage != null) {
      summary.write('أجر السواق: ${draft.driverWage!.toInt()} جنيه\n');
    }
    if (draft.details != null && draft.details!.isNotEmpty) {
      summary.write('التفاصيل: ${draft.details}\n');
    }
    if (draft.expenses != null) {
      summary.write('مصروف الرحلة: ${draft.expenses!.toInt()} جنيه\n');
    }
    if (draft.expenseDetails != null && draft.expenseDetails!.isNotEmpty) {
      summary.write('تفاصيل المصروف: ${draft.expenseDetails}\n');
    }

    state = AsyncValue.data(
      AiAssistantState(
        messages: [
          ...confirmingState.messages,
          ChatMessage(
            role: AiMessageRole.assistant,
            content: summary.toString(),
            timestamp: DateTime.now(),
          ),
        ],
        currentDraft: const AiTripDraft(),
        lastResult: null,
        isProcessing: false,
        isConfirming: false,
        selectedAction: null,
        showActionList: true,
        entryContext: confirmingState.entryContext,
        lastSuccessMessage: 'تم إضافة الرحلة بنجاح ✅',
      ),
    );

    ref.invalidate(busTripsProvider(bus.id ?? ''));
    ref.invalidate(busTripsLimitedProvider(bus.id ?? ''));
    ref.invalidate(
      busPaginatedTripsProvider(PaginatedTripsRequest(entityId: bus.id ?? '')),
    );
    ref.invalidate(driverTripsProvider(driver.id));
    ref.invalidate(driverTripsLimitedProvider(driver.id));
    ref.invalidate(
      driverPaginatedTripsProvider(PaginatedTripsRequest(entityId: driver.id)),
    );
    if (factory != null) {
      ref.invalidate(factoryTripsProvider(factory.id));
      ref.invalidate(factoryTripsLimitedProvider(factory.id));
      ref.invalidate(
        factoryPaginatedTripsProvider(
          PaginatedTripsRequest(entityId: factory.id),
        ),
      );
      ref.invalidate(factoriesProvider);
    }
    ref.invalidate(driversProvider);
    ref.invalidate(busProvider);
  }

  void clearLastResult() {
    final currentState = state.valueOrNull;
    if (currentState != null) {
      state = AsyncValue.data(currentState.copyWith(clearLastResult: true));
    }
  }

  void consumeLastSuccess() {
    final currentState = state.valueOrNull;
    if (currentState == null || currentState.lastSuccessMessage == null) return;
    state = AsyncValue.data(currentState.copyWith(clearLastSuccess: true));
  }

  void consumeLastDuplicate() {
    final currentState = state.valueOrNull;
    if (currentState == null || currentState.lastDuplicateMessage == null) {
      return;
    }
    state = AsyncValue.data(currentState.copyWith(clearLastDuplicate: true));
  }

  void restartCreateFlow() {
    final currentState = state.valueOrNull;
    final action = currentState?.selectedAction ?? AiActionId.addBus;
    _startCreateFlow(action);
  }

  void cancelAction() {
    final currentState = state.valueOrNull ?? const AiAssistantState();
    if (currentState.isConfirming) return;

    final message = ChatMessage(
      role: AiMessageRole.assistant,
      content:
          'تمام، اتلغى الطلب واتشالت البيانات.\n'
          'لو عايز تبدأ تاني، اختار من القايمة تحت 👇',
      timestamp: DateTime.now(),
    );

    state = AsyncValue.data(
      AiAssistantState(
        messages: [...currentState.messages, message],
        currentDraft: const AiTripDraft(),
        lastResult: null,
        isProcessing: false,
        isConfirming: false,
        selectedAction: null,
        showActionList: true,
        entryContext: currentState.entryContext,
      ),
    );
  }

  void _finalize({
    List<ChatMessage> extraMessages = const [],
    AiTripDraft? currentDraft,
    AiActionResult? lastResult,
    bool clearLastResult = false,
    AiActionId? selectedAction,
    bool clearSelectedAction = false,
    bool? showActionList,
    bool clearResolution = false,
    bool clearPending = false,
    bool clearFactoryTripType = false,
    bool? showFactoryTripChoice,
    bool? showFactoryChoice,
    bool clearCreate = false,
    bool clearEdit = false,
  }) {
    final currentState = state.valueOrNull ?? const AiAssistantState();

    state = AsyncValue.data(
      currentState.copyWith(
        messages: [...currentState.messages, ...extraMessages],
        currentDraft: currentDraft,
        lastResult: clearLastResult
            ? null
            : (lastResult ?? currentState.lastResult),
        isProcessing: false,
        isConfirming: false,
        selectedAction: clearSelectedAction
            ? null
            : (selectedAction ?? currentState.selectedAction),
        showActionList: showActionList ?? currentState.showActionList,
        clearResolution: clearResolution,
        clearPending: clearPending,
        clearFactoryTripType: clearFactoryTripType,
        showFactoryTripChoice: showFactoryTripChoice,
        showFactoryChoice: showFactoryChoice,
        clearCreate: clearCreate,
        clearEdit: clearEdit,
      ),
    );
  }

  String _buildTripChecklistMessage() {
    final ctx = _getContext();
    final draft = state.valueOrNull?.currentDraft ?? const AiTripDraft();
    return _buildTripChecklistMessageWithDraft(draft, ctx: ctx);
  }

  String _buildTripChecklistMessageWithDraft(
    AiTripDraft draft, {
    AiEntryContext? ctx,
    String? tripType,
  }) {
    final context = ctx ?? _getContext();

    final requiredFields = <AiTripFieldSpec>[];
    final optionalFields = <AiTripFieldSpec>[];

    bool busKnown = context.isBusContext;
    bool driverKnown = false;
    bool factoryKnown = context.isFactoryContext;
    bool tripTypeKnown =
        (context.isFactoryContext &&
            state.valueOrNull?.selectedFactoryTripType != null) ||
        tripType != null;

    if (draft.busName != null && draft.busName!.isNotEmpty) busKnown = true;
    if (draft.driverName != null && draft.driverName!.isNotEmpty) {
      driverKnown = true;
    }
    if (draft.factoryName != null && draft.factoryName!.isNotEmpty) {
      factoryKnown = true;
    }
    if (draft.type != null && draft.type!.isNotEmpty) tripTypeKnown = true;

    for (final f in AiTripFieldCatalog.requiredFields) {
      if (f.key == 'bus' && busKnown) continue;
      if (f.key == 'driver' && driverKnown) continue;
      requiredFields.add(f);
    }

    for (final f in AiTripFieldCatalog.optionalFields) {
      if (f.key == 'factory' && factoryKnown) continue;
      optionalFields.add(f);
    }

    final lines = <String>['تمام 👍'];

    if (context.isBusContext && context.bus != null) {
      lines.add('الأتوبيس: ${context.bus!.busName} ✓');
    }
    if (context.isFactoryContext && context.factory != null) {
      lines.add('المصنع: ${context.factory!.name} ✓');
    }

    if (tripTypeKnown) {
      final type =
          tripType ?? state.valueOrNull?.selectedFactoryTripType ?? draft.type;
      final typeLabel = type == TripType.nightOuting ? 'سهرة' : 'رحلة';
      lines.add('النوع: $typeLabel ✓');
    }

    lines.add('');

    if (requiredFields.isNotEmpty) {
      lines.add('البيانات المطلوبة:');
      lines.addAll(requiredFields.map((f) => f.label));
    } else {
      lines.add('كل البيانات المطلوبة موجودة ✅');
    }

    if (optionalFields.isNotEmpty) {
      lines.add('\nوالبيانات الاختيارية لو حابب تضيفها:');
      lines.addAll(optionalFields.map((f) => f.label));
    }

    lines.add('\nممكن تقولهم كلهم مرة واحدة أو تبعتهم واحدة واحدة.');

    return lines.join('\n');
  }

  void resetDraft() {
    final currentState = state.valueOrNull;
    if (currentState != null) {
      state = AsyncValue.data(
        currentState.copyWith(
          currentDraft: const AiTripDraft(),
          clearLastResult: true,
          clearSelectedAction: true,
          clearResolution: true,
          clearPending: true,
          clearFactoryTripType: true,
          isConfirming: false,
          showActionList: true,
          showFactoryTripChoice: false,
          showFactoryChoice: false,
          clearCreate: true,
          clearEdit: true,
        ),
      );
    }
  }

  void reset() {
    state = const AsyncValue.data(
      AiAssistantState(
        messages: [
          ChatMessage(
            role: AiMessageRole.assistant,
            content:
                'أهلاً 👋\n'
                'أنا مساعدك الذكي في Elostaz Travel.\n'
                'تحب نعمل إيه النهارده؟',
          ),
        ],
        showActionList: true,
      ),
    );
  }

  BusEntity? _findBusById(List<BusEntity> candidates, String id) {
    for (final bus in candidates) {
      if (bus.id == id) return bus;
    }
    return null;
  }

  DriverEntity? _findDriverById(List<DriverEntity> candidates, String id) {
    for (final driver in candidates) {
      if (driver.id == id) return driver;
    }
    return null;
  }

  FactoryEntity? _findFactoryById(List<FactoryEntity> candidates, String id) {
    for (final factory in candidates) {
      if (factory.id == id) return factory;
    }
    return null;
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

final aiAssistantProvider =
    AsyncNotifierProvider.autoDispose<AiAssistantNotifier, AiAssistantState>(
      AiAssistantNotifier.new,
    );
