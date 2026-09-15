import 'package:elostaz_travel/data/ai_assistant/service/speech_to_text_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum SpeechRecognitionStatus {
  idle,
  listening,
  processing,
  error,
}

class SpeechRecognitionState {
  final SpeechRecognitionStatus status;

  /// Segments already committed and accumulated across all transparent
  /// platform-session restarts. This is NEVER modified by an interim/preview
  /// update — a partial only ever previews on top of it.
  final String committedText;

  /// Live interim preview for the CURRENT platform segment only. Replaced on
  /// every partial callback, and empty while paused / between segments. It
  /// never replaces committed text on its own.
  final String currentSegment;

  /// Full composer preview: committed transcript + current interim segment.
  String get recognizedText =>
      SpeechRecognitionState._mergeParts(committedText, currentSegment);

  final String? errorMessage;

  const SpeechRecognitionState({
    this.status = SpeechRecognitionStatus.idle,
    this.committedText = '',
    this.currentSegment = '',
    this.errorMessage,
  });

  bool get isListening => status == SpeechRecognitionStatus.listening;
  bool get isIdle => status == SpeechRecognitionStatus.idle;
  bool get hasError => status == SpeechRecognitionStatus.error;

  SpeechRecognitionState copyWith({
    SpeechRecognitionStatus? status,
    String? committedText,
    String? currentSegment,
    String? errorMessage,
  }) {
    return SpeechRecognitionState(
      status: status ?? this.status,
      committedText: committedText ?? this.committedText,
      currentSegment: currentSegment ?? this.currentSegment,
      errorMessage: errorMessage,
    );
  }

  /// `committed + ' ' + interim`, with empty parts never clobbering the rest.
  static String _mergeParts(String committed, String interim) {
    final base = committed.trimRight();
    final segment = interim.trim();
    if (segment.isEmpty) return base;
    if (base.isEmpty) return segment;
    return '$base $segment';
  }
}

class SpeechRecognitionNotifier
    extends StateNotifier<SpeechRecognitionState> {
  final SpeechToTextService _service;

  SpeechRecognitionNotifier(this._service)
      : super(const SpeechRecognitionState());

  /// Buffer that accumulates completed segments across session restarts.
  String _accumulatedText = '';

  Future<void> startListening() async {
    _accumulatedText = '';

    state = const SpeechRecognitionState(
      status: SpeechRecognitionStatus.listening,
    );

    final started = await _service.startListening(
      onPartial: _onPartial,
      onSegment: _onSegment,
      onStopped: _onStopped,
    );

    if (!started) {
      state = const SpeechRecognitionState(
        status: SpeechRecognitionStatus.error,
        errorMessage: 'لم نتمكن من بدء التعرف على الصوت. تأكد من إذن الميكروفون.',
      );
    }
  }

  Future<void> stopListening() async {
    await _service.stopListening();
    // _onStopped will be called by the service, which will set state to idle.
  }

  Future<void> cancelListening() async {
    await _service.cancelListening();
    _accumulatedText = '';
    state = const SpeechRecognitionState();
  }

  void clearText() {
    _accumulatedText = '';
    state = state.copyWith(committedText: '', currentSegment: '');
  }

  void reset() {
    _accumulatedText = '';
    state = const SpeechRecognitionState();
  }

  // -------------------------------------------------------------------------
  // Callbacks from SpeechToTextService
  // -------------------------------------------------------------------------

  /// Called with interim partial text for the *current* segment. This is a
  /// replacement PREVIEW for the current platform segment only — never the
  /// whole conversation — so it is merged on top of the committed transcript
  /// and can never replace it. Empty partials are inert.
  void _onPartial(String partialSegment) {
    if (!state.isListening) return;
    final trimmed = partialSegment.trim();
    if (trimmed.isEmpty) return;

    // A partial that merely echoes already-committed trailing words (the
    // recognizer may replay the tail of the previous segment right after a
    // transparent restart) must never duplicate or replace committed text.
    final committed = _accumulatedText.trimRight();
    if (committed.isNotEmpty && _isAlreadyTrailing(committed, trimmed)) {
      debugPrint('[stt] partial DEDUPED (echo)');
      state = state.copyWith(
        committedText: _accumulatedText,
        currentSegment: '',
      );
      return;
    }

    final preview = mergedText(_accumulatedText, trimmed);
    debugPrint('[stt] partial -> preview len=${preview.length}');
    state = state.copyWith(
      committedText: _accumulatedText,
      currentSegment: trimmed,
    );
  }

  /// Called when a segment is finalized. Commit it into the accumulator
  /// (deduped against what we already accumulated) and clear the interim
  /// preview. The status stays `listening` — the platform session restarts
  /// automatically and MUST continue from this accumulated transcript.
  void _onSegment(String segmentText) {
    if (!state.isListening) return;
    final seg = segmentText.trim();
    if (seg.isEmpty) return;

    final current = _accumulatedText.trimRight();
    if (current.isEmpty) {
      _accumulatedText = seg;
    } else if (!_isAlreadyTrailing(current, seg)) {
      _accumulatedText = mergedText(_accumulatedText, seg);
    }
    // Keep status = listening (session will restart automatically).
    debugPrint('[stt] segment committed -> accumulated len=${_accumulatedText.length}');
    state = state.copyWith(
      committedText: _accumulatedText,
      currentSegment: '',
    );
  }

  /// True when [candidate] already equals the trailing words of [base],
  /// i.e. appending it again would duplicate the transcript.
  bool _isAlreadyTrailing(String base, String candidate) {
    final baseWords = base.split(' ');
    final candidateWords = candidate.split(' ');
    if (candidateWords.length > baseWords.length) return false;
    final tail = baseWords
        .sublist(baseWords.length - candidateWords.length)
        .join(' ');
    return tail == candidate;
  }

  /// Called when listening truly ends (user stop or fatal error). The full
  /// accumulated transcript is exposed to the composer one last time, then
  /// the buffer is cleared for a future session.
  void _onStopped() {
    if (!mounted) return;
    debugPrint('[stt] STOPPED -> idle, final len=${_accumulatedText.length}');
    state = SpeechRecognitionState(
      status: SpeechRecognitionStatus.idle,
      committedText: _accumulatedText,
    );
    _accumulatedText = '';
  }

  // -------------------------------------------------------------------------

  /// Combines an accumulated base transcript with a new (partial or final)
  /// segment, inserting a space separator when needed. An empty segment
  /// leaves the base untouched; an empty base takes the segment as-is.
  String mergedText(String base, String segment) {
    final trimmedBase = base.trimRight();
    final trimmedSegment = segment.trim();
    if (trimmedSegment.isEmpty) return trimmedBase;
    if (trimmedBase.isEmpty) return trimmedSegment;
    return '$trimmedBase $trimmedSegment';
  }
}

final speechToTextServiceProvider = Provider<SpeechToTextService>((ref) {
  final service = SpeechToTextService();
  ref.onDispose(() => service.dispose());
  return service;
});

final speechRecognitionProvider =
    StateNotifierProvider<SpeechRecognitionNotifier, SpeechRecognitionState>(
  (ref) {
    final service = ref.read(speechToTextServiceProvider);
    return SpeechRecognitionNotifier(service);
  },
);
