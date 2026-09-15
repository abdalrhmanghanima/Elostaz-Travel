import 'package:elostaz_travel/core/extensions/extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elostaz_travel/core/utils/app_colors.dart';
import 'package:elostaz_travel/presentation/ai_assistant/model/ai_action_option.dart';
import 'package:elostaz_travel/presentation/ai_assistant/model/ai_entry_context.dart';
import 'package:elostaz_travel/presentation/ai_assistant/provider/ai_assistant_provider.dart';
import 'package:elostaz_travel/presentation/components/custom_snack_bar/custom_snack_bar.dart';
import 'package:elostaz_travel/presentation/ai_assistant/provider/speech_recognition_provider.dart';
import 'package:elostaz_travel/presentation/ai_assistant/service/ai_composer_service.dart';
import 'package:elostaz_travel/presentation/ai_assistant/service/ai_entity_resolver.dart';
import 'package:elostaz_travel/domain/factory/entity/factory_entity.dart';
import 'package:elostaz_travel/presentation/ai_assistant/widgets/ai_action_confirmation_card.dart';
import 'package:elostaz_travel/presentation/ai_assistant/widgets/ai_action_options_list.dart';
import 'package:elostaz_travel/presentation/ai_assistant/widgets/ai_chat_message.dart';
import 'package:elostaz_travel/presentation/ai_assistant/widgets/ai_entity_choice_list.dart';
import 'package:elostaz_travel/presentation/ai_assistant/widgets/ai_factory_trip_choice_list.dart';

class AiAssistantSheet extends ConsumerStatefulWidget {
  const AiAssistantSheet({
    super.key,
    this.entryContext = const AiEntryContext(),
  });

  final AiEntryContext entryContext;

  @override
  ConsumerState<AiAssistantSheet> createState() => _AiAssistantSheetState();
}

class _AiAssistantSheetState extends ConsumerState<AiAssistantSheet> {
  final TextEditingController _controller = TextEditingController();

  final FocusNode _focusNode = FocusNode();

  final ScrollController _scrollController = ScrollController();

  String _voiceBaseText = '';

  bool _ignoreVoiceUpdates = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (widget.entryContext.isBusContext ||
          widget.entryContext.isFactoryContext) {
        ref
            .read(aiAssistantProvider.notifier)
            .initializeWithContext(widget.entryContext);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _toggleListening() {
    final speechState = ref.read(speechRecognitionProvider);

    if (speechState.isListening) {
      ref.read(speechRecognitionProvider.notifier).stopListening();
      _focusNode.unfocus();
    } else {
      _voiceBaseText = _controller.text;
      _ignoreVoiceUpdates = false;
      ref.read(speechRecognitionProvider.notifier).startListening();
      _focusNode.unfocus();
    }
  }

  void _applyVoiceInterim(String committedText, String currentSegment) {
    if (_ignoreVoiceUpdates) return;
    _controller.text = _composeVoice(committedText, currentSegment);
    _controller.selection = TextSelection.collapsed(
      offset: _controller.text.length,
    );
  }

  void _applyVoiceFinal(String committedText) {
    if (_ignoreVoiceUpdates) return;
    _controller.text = _composeVoice(committedText, '');
    _controller.selection = TextSelection.collapsed(
      offset: _controller.text.length,
    );
    _voiceBaseText = '';
    _scrollToBottom();
  }

  // Compose composer text as: (pre-existing typed text) + (committed voice
  // transcript) + (current interim segment). The interim segment on its own is
  // never the whole composer text, and an empty interim (pause) leaves the
  // committed/base text untouched instead of clearing it.
  String _composeVoice(String committedText, String currentSegment) {
    final withBase = AiComposerService.mergeVoiceSegment(
      _voiceBaseText,
      committedText,
    );
    return AiComposerService.mergeVoiceSegment(withBase, currentSegment);
  }

  void _applyVoiceError() {
    _controller.text = _voiceBaseText;
    _controller.selection = TextSelection.collapsed(
      offset: _controller.text.length,
    );
    _voiceBaseText = '';
  }

  void _confirmAction() {
    ref.read(aiAssistantProvider.notifier).executeTrip();
  }

  void _confirmCreateAction() {
    ref.read(aiAssistantProvider.notifier).executeCreate();
  }

  void _editAction() {
    ref.read(aiAssistantProvider.notifier).enterDraftEditMode();
  }

  void _cancelAction() {
    ref.read(aiAssistantProvider.notifier).cancelAction();
  }

  void _sendMessage() {
    final speechState = ref.read(speechRecognitionProvider);
    var stoppedListening = false;
    if (speechState.isListening) {
      ref.read(speechRecognitionProvider.notifier).stopListening();
      stoppedListening = true;
    }

    final aiState = ref.read(aiAssistantProvider).valueOrNull;
    if ((aiState?.isProcessing ?? false) || (aiState?.isConfirming ?? false)) {
      return;
    }

    final text = _controller.text.trim();
    if (text.isEmpty) return;

    if (stoppedListening) {
      _ignoreVoiceUpdates = true;
    }
    _voiceBaseText = '';
    _controller.clear();
    ref.read(aiAssistantProvider.notifier).processUserMessage(text);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottomNow();
    });
    // The confirmation cards are laid out in the rebuild that follows the
    // state change (one frame after the listener runs), so re-check a few
    // times and auto-scroll to the final content instead of stopping above
    // the card.
    for (final delay in const [150, 300, 450]) {
      Future<void>.delayed(Duration(milliseconds: delay), () {
        if (!mounted) return;
        _scrollToBottomNow();
      });
    }
  }

  void _scrollToBottomNow() {
    if (!_scrollController.hasClients) return;
    final target = _scrollController.position.maxScrollExtent;
    if (_scrollController.offset >= target) return;
    _scrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final screenHeight = MediaQuery.of(context).size.height;
    final aboveSheetHeight = screenHeight * 0.88 + bottomInset;

    final speechState = ref.watch(speechRecognitionProvider);
    final aiAsync = ref.watch(aiAssistantProvider);

    ref.listen<SpeechRecognitionState>(speechRecognitionProvider, (
      previous,
      next,
    ) {
      if (next.hasError && next.errorMessage != null) {
        _applyVoiceError();
        CustomSnackBar.show(
          context,
          message: next.errorMessage!,
          success: false,
          aboveBottomSheetHeight: aboveSheetHeight,
        );
      }

      if (next.status == SpeechRecognitionStatus.listening) {
        _applyVoiceInterim(next.committedText, next.currentSegment);
      }

      if (previous?.status != SpeechRecognitionStatus.idle &&
          next.status == SpeechRecognitionStatus.idle) {
        _applyVoiceFinal(next.committedText);
      }
    });

    ref.listen<AsyncValue<AiAssistantState>>(aiAssistantProvider, (
      previous,
      next,
    ) {
      final successMessage = next.valueOrNull?.lastSuccessMessage;
      if (successMessage != null && successMessage.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          CustomSnackBar.show(
            context,
            message: successMessage,
            success: true,
            aboveBottomSheetHeight: aboveSheetHeight,
          );
          ref.read(aiAssistantProvider.notifier).consumeLastSuccess();
        });
      }
      final duplicateMessage = next.valueOrNull?.lastDuplicateMessage;
      if (duplicateMessage != null && duplicateMessage.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          CustomSnackBar.show(
            context,
            message: duplicateMessage,
            success: false,
            aboveBottomSheetHeight: aboveSheetHeight,
          );
          ref.read(aiAssistantProvider.notifier).consumeLastDuplicate();
        });
      }
      final prevMessages = previous?.valueOrNull?.messages.length ?? 0;
      final nextMessages = next.valueOrNull?.messages.length ?? 0;
      if (prevMessages != nextMessages && prevMessages > 0) {
        _scrollToBottom();
      }
    });

    final aiState = aiAsync.valueOrNull;
    final messages = aiState?.messages ?? const [];
    final isProcessing = aiState?.isProcessing ?? false;
    final isConfirming = aiState?.isConfirming ?? false;
    final showConfirmationCard = aiState?.showConfirmationCard ?? false;
    final canConfirm = aiState?.canConfirm ?? false;
    final showCreateReviewCard = aiState?.showCreateReviewCard ?? false;
    final canCreateConfirm = aiState?.canCreateConfirm ?? false;
    final showActionList = aiState?.showActionList ?? false;
    final pendingChoiceField = aiState?.pendingChoiceField;
    final showFactoryChoice = aiState?.showFactoryChoice ?? false;
    final factoryChoiceCandidates =
        aiState?.factoryChoiceCandidates ?? const <FactoryEntity>[];
    final showFactoryTripChoice = aiState?.showFactoryTripChoice ?? false;
    final entryContext = aiState?.entryContext ?? widget.entryContext;
    final resolvedFactoryName =
        aiState?.resolvedFactory?.name ?? entryContext.factory?.name;
    final currentDraft = aiState?.currentDraft;

    return Scaffold(
      backgroundColor: Colors.transparent,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => Navigator.of(context).pop(),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: AnimatedPadding(
              duration: const Duration(milliseconds: 200),
              padding: EdgeInsets.only(bottom: bottomInset),
              child: Container(
                height: screenHeight * 0.88,
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(28.r),
                  ),
                ),
                child: Column(
                  children: [
                    _buildHeader(),

                    Expanded(
                      child: ListView(
                        controller: _scrollController,
                        padding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 14.h,
                        ),
                        children: [
                          for (final msg in messages)
                            AiChatMessage(
                              message: msg.content,
                              isUser: msg.isUser,
                            ),

                          if (isProcessing)
                            Padding(
                              padding: EdgeInsets.symmetric(vertical: 8.h),
                              child: Row(
                                textDirection: TextDirection.rtl,
                                children: [
                                  SizedBox(
                                    width: 16.w,
                                    height: 16.w,
                                    child: const CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                  SizedBox(width: 8.w),
                                  Text(
                                    'بفكر...',
                                    style: TextStyle(
                                      fontSize: 13.sp,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          if (pendingChoiceField != null)
                            _buildEntityChoiceList(aiState!),

                          if (showFactoryChoice &&
                              factoryChoiceCandidates.isNotEmpty)
                            AiEntityChoiceList(
                              question:
                                  'اختار المصنع اللي هتسجل الرحلة/السهرة له:',
                              options: factoryChoiceCandidates
                                  .map(
                                    (f) => AiEntityChoiceItem(
                                      id: f.id,
                                      title: f.name,
                                      subtitle: f.phone.isNotEmpty
                                          ? f.phone
                                          : null,
                                      icon: Icons.factory_outlined,
                                    ),
                                  )
                                  .toList(),
                              onSelect: (factoryId) {
                                ref
                                    .read(aiAssistantProvider.notifier)
                                    .chooseTripFactory(factoryId);
                                _scrollToBottom();
                              },
                            ),

                          if (showFactoryTripChoice &&
                              resolvedFactoryName != null &&
                              resolvedFactoryName.isNotEmpty)
                            AiFactoryTripChoiceList(
                              factoryName: resolvedFactoryName,
                              onSelect: (tripType) {
                                ref
                                    .read(aiAssistantProvider.notifier)
                                    .selectFactoryTripType(tripType);
                                _scrollToBottom();
                              },
                            ),

                          if (showConfirmationCard && currentDraft != null)
                            AiActionConfirmationCard(
                              onConfirm: _confirmAction,
                              onEdit: _editAction,
                              onCancel: _cancelAction,
                              isConfirming: isConfirming,
                              canConfirm: canConfirm,
                              draft: currentDraft,
                            ),

                          if (showCreateReviewCard &&
                              aiState?.selectedAction != null)
                            AiCreateConfirmationCard(
                              action: aiState!.selectedAction!,
                              values: aiState.createValues,
                              onConfirm: _confirmCreateAction,
                              onEdit: _editAction,
                              onCancel: _cancelAction,
                              isConfirming: isConfirming,
                              canConfirm: canCreateConfirm,
                            ),

                          if (showActionList)
                            AiActionOptionsList(
                              options: availableAiActions,
                              onSelect: (option) => ref
                                  .read(aiAssistantProvider.notifier)
                                  .selectAction(option.id),
                            ),
                        ],
                      ),
                    ),

                    _buildInput(
                      speechState,
                      isProcessing: isProcessing,
                      isConfirming: isConfirming,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.only(
        left: 16.w,
        right: 16.w,
        top: 14.h,
        bottom: 14.h,
      ),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 42.w,
            height: 5.h,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(20.r),
            ),
          ),

          SizedBox(height: 15.h),

          Row(
            textDirection: TextDirection.rtl,
            children: [
              Container(
                width: 42.w,
                height: 42.w,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.auto_awesome_rounded,
                  color: AppColors.white,
                  size: 22.w,
                ),
              ),

              SizedBox(width: 10.w),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'مساعدك الذكي',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w800,
                        color: AppColors.black,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      'مساعد Elostaz Travel',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),

              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEntityChoiceList(AiAssistantState state) {
    final field = state.pendingChoiceField!;
    final (question, options) = switch (field) {
      AiEntityField.bus => (
        'لقيت أكتر من أتوبيس مطابق. اختار واحد منهم:',
        state.busCandidates
            .map(
              (b) => AiEntityChoiceItem(
                id: b.id ?? '',
                title: b.busName,
                subtitle: b.plateNumber,
                icon: Icons.directions_bus_outlined,
              ),
            )
            .toList(),
      ),
      AiEntityField.driver => (
        'لقيت أكتر من سواق مطابق. اختار واحد منهم:',
        state.driverCandidates
            .map(
              (d) => AiEntityChoiceItem(
                id: d.id,
                title: d.name,
                icon: Icons.person_outline_rounded,
              ),
            )
            .toList(),
      ),
      AiEntityField.factory => (
        'لقيت أكتر من مصنع مطابق. اختار واحد منهم:',
        state.factoryCandidates
            .map(
              (f) => AiEntityChoiceItem(
                id: f.id,
                title: f.name,
                icon: Icons.factory_outlined,
              ),
            )
            .toList(),
      ),
    };

    return AiEntityChoiceList(
      question: question,
      options: options,
      onSelect: (entityId) {
        ref.read(aiAssistantProvider.notifier).chooseEntity(field, entityId);
        _scrollToBottom();
      },
    );
  }

  Widget _buildInput(
    SpeechRecognitionState speechState, {
    required bool isProcessing,
    required bool isConfirming,
  }) {
    final busy = isProcessing || isConfirming;
    return Container(
      padding: EdgeInsets.only(
        left: 12.w,
        right: 12.w,
        top: 10.h,
        bottom: 12.h,
      ),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          textDirection: TextDirection.rtl,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            GestureDetector(
              onTap: _toggleListening,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 48.w,
                height: 48.w,
                decoration: BoxDecoration(
                  color: speechState.isListening
                      ? Colors.red
                      : AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  speechState.isListening
                      ? Icons.stop_rounded
                      : Icons.mic_rounded,
                  color: AppColors.white,
                  size: 24.w,
                ),
              ),
            ),

            SizedBox(width: 8.w),

            Expanded(
              child: Container(
                constraints: BoxConstraints(minHeight: 48.h, maxHeight: 120.h),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F6F8),
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  enabled: true,
                  maxLines: 4,
                  minLines: 1,
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.right,
                  onSubmitted: (_) => _sendMessage(),
                  decoration: InputDecoration(
                    hintText: 'قولّي عايز تعمل إيه...',
                    hintTextDirection: TextDirection.rtl,
                    hintStyle: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 14.sp,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 15.w,
                      vertical: 13.h,
                    ),
                  ),
                ),
              ),
            ),

            SizedBox(width: 8.w),

            GestureDetector(
              onTap: busy ? null : _sendMessage,
              child: Container(
                width: 48.w,
                height: 48.w,
                decoration: BoxDecoration(
                  color: busy ? Colors.grey : AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.arrow_upward_rounded,
                  color: AppColors.white,
                  size: 23.w,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
