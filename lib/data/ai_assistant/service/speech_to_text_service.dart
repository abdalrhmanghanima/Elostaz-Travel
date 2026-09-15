import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';

/// Minimal surface of the speech engine [SpeechToTextService] needs.
///
/// Kept separate from the concrete [SpeechToText] so the service can be
/// driven deterministically in tests with a fake engine.
abstract class SpeechToTextEngine {
  Future<bool> initialize({
    SpeechErrorListener? onError,
    SpeechStatusListener? onStatus,
  });

  bool get isAvailable;

  Future<void> listen({
    SpeechResultListener? onResult,
    SpeechListenOptions? listenOptions,
  });

  Future<void> stop();

  Future<void> cancel();
}

/// Default [SpeechToTextEngine] backed by the real [SpeechToText] plugin.
class SpeechToTextEngineDefault implements SpeechToTextEngine {
  SpeechToTextEngineDefault() : _speech = SpeechToText();

  final SpeechToText _speech;

  @override
  Future<bool> initialize({
    SpeechErrorListener? onError,
    SpeechStatusListener? onStatus,
  }) =>
      _speech.initialize(onError: onError, onStatus: onStatus);

  @override
  bool get isAvailable => _speech.isAvailable;

  @override
  Future<void> listen({
    SpeechResultListener? onResult,
    SpeechListenOptions? listenOptions,
  }) =>
      _speech.listen(onResult: onResult, listenOptions: listenOptions);

  @override
  Future<void> stop() => _speech.stop();

  @override
  Future<void> cancel() => _speech.cancel();
}

/// Wraps [SpeechToText] with an explicitly user-controlled "continuous"
/// listening session.
///
/// Two clearly separated states:
///
/// A) USER session — [_userIsListening]. Becomes true when the user taps the
///    microphone and only becomes false when the user taps Stop (or on a
///    permanent error / dispose). Session restarts are transparent and never
///    touch this flag.
///
/// B) PLATFORM recognition sessions — one [SpeechToText.listen] invocation at
///    a time. The Android recognizer can start/end many of these internally
///    (pause timeout, silence, transient error); they are implementation
///    details that never surface as user-level start/stop events.
///
/// [SpeechToText.listen] returns once the platform session has *started*, not
/// once it ends. A platform session genuinely ends when the plugin delivers
/// `done` — and, on Android, also `notListening` (the Dart layer can drop
/// `done` after a partial result, and some builds end a session with only
/// `notListening`). Both funnel into one controlled restart so the user
/// session survives as long as [_userIsListening]. Restart is also scheduled
/// for a failed session *start*, re-armed when a session end races the start
/// completion, and armed from a transient error when no end status follows —
/// otherwise a recognizer that silently dies mid-pause would force a manual
/// mic re-tap, which resets the accumulated transcript. Restart is never
/// triggered by partial/final results independently.
///
/// The caller receives:
///   • [onPartial]  – live interim text of the CURRENT utterance only. It is a
///                    replacement preview that keeps being refined, never an
///                    append-only log of the whole session.
///   • [onSegment]  – a COMPLETED utterance to be appended to whatever the
///                    caller is accumulating. Fired from a native final, from
///                    a mid-session utterance boundary, or from a session end /
///                    manual stop preserving the last partial.
///   • [onStopped]  – called once when listening truly ends (user stop
///                    or a permanent/unrecoverable error)
class SpeechToTextService {
  /// [engine] is injectable for tests; production code uses the real engine.
  SpeechToTextService({SpeechToTextEngine? engine})
      : _engine = engine ?? SpeechToTextEngineDefault();

  final SpeechToTextEngine _engine;
  bool _initialized = false;
  bool _disposed = false;

  /// A) USER session intent. Only the user (or a permanent error) can end it.
  bool _userIsListening = false;

  /// Generation fence. Incremented every time a new platform session starts
  /// and on manual stop, so callbacks captured for a superseded session are
  /// dropped and can never overwrite the newer transcript.
  int _sessionToken = 0;

  /// True while a platform `listen` call is in flight. Guards against ever
  /// calling [SpeechToText.listen] while another session is still active.
  bool _sessionActive = false;

  /// True once a restart has been armed. Only ONE restart can be pending at a
  /// time; every candidate event funnels into the same [_requestRestart].
  bool _restartPending = false;

  /// Consecutive failed platform *starts* since the last successful one. When
  /// this reaches [_maxFailedStarts], restarts back off to [_restartBackoff]
  /// so a recognizer that repeatedly refuses to start (resource exhaustion,
  /// service churn) is not hammered in a tight loop. Any result, a `listening`
  /// status, or a user re-tap resets the streak.
  int _failedStarts = 0;

  /// Set when a session end (`done` or `notListening`) arrives while a
  /// platform session is still in its start window. The restart can't be
  /// armed then (a live listen must never be interrupted), but it MUST be
  /// re-armed the moment the start completes — otherwise an ending session
  /// would leak a "dead" recognizer and the continuation below would never be
  /// received.
  bool _sessionEndedDuringActive = false;

  Timer? _restartTimer;

  /// Short settle time before starting the next platform session, letting the
  /// recognizer finish tearing down the previous one.
  ///
  /// 150ms is empirically safe on speech_to_text 7.4.0: the Android plugin
  /// already demultiplexes status/result channel callbacks into sequential
  /// Dart events and completes its native teardown (`destroy()`/`stop()`) in
  /// its Kotlin layer BEFORE emitting the `done`/`notListening` pair that
  /// drives this restart. By the time Dart observes the session end, the
  /// underlying recognizer is free to accept a new `startListening()`, so a
  /// small settle (rather than zero) only absorbs intra-framework callback
  /// delivery jitter. Values much below 100ms risk `error_busy` on some
  /// vendor recognizers that finalize asynchronously.
  static const Duration _restartDelay = Duration(milliseconds: 150);

  /// Longer settle used once [_failedStarts] reaches [_maxFailedStarts].
  static const Duration _restartBackoff = Duration(milliseconds: 1500);

  /// Number of consecutive failed starts allowed at the fast [_restartDelay].
  static const int _maxFailedStarts = 3;

  // --- public state ----------------------------------------------------------
  bool get isAvailable => _engine.isAvailable;

  /// Tracks user intent, not the underlying platform session. Stays true
  /// across transparent restarts and only goes false on user stop or a
  /// permanent error.
  bool get isListening => _userIsListening;
  bool get isInitialized => _initialized;

  // --- callbacks set by startListening() ------------------------------------
  /// Called with interim (partial) text for the current segment.
  void Function(String text)? onPartial;

  /// Called when the platform finalises a segment; text is the completed
  /// segment — callers should *append* this to their accumulated buffer.
  void Function(String segmentText)? onSegment;

  /// Called once when listening fully stops (user stop or permanent error).
  void Function()? onStopped;

  // --- internal state --------------------------------------------------------
  /// Pending (uncommitted) text of the CURRENT utterance of the CURRENT
  /// platform session. Partials refine it; utterance boundaries, native
  /// finals, session ends and manual stop commit it exactly once.
  String _currentUtterance = '';

  // -------------------------------------------------------------------------

  Future<bool> initialize() async {
    if (_initialized) return _engine.isAvailable;
    _initialized = await _engine.initialize(
      onError: _onError,
      onStatus: _onStatus,
    );
    _debug('initialize -> $_initialized');
    return _initialized;
  }

  /// Start the user-controlled listening session. [onPartial] fires for
  /// interim words, [onSegment] for each completed utterance chunk,
  /// [onStopped] fires once when the user taps stop (or on a permanent
  /// error). Returns false only when the mic/recognizer is genuinely
  /// unavailable.
  Future<bool> startListening({
    required void Function(String text) onPartial,
    required void Function(String segmentText) onSegment,
    required void Function() onStopped,
  }) async {
    this.onPartial = onPartial;
    this.onSegment = onSegment;
    this.onStopped = onStopped;

    if (_disposed) return false;

    if (!_initialized) {
      final available = await initialize();
      if (!available) return false;
    }

    if (!_engine.isAvailable) return false;

    _debug('USER LISTEN START');
    _userIsListening = true;
    _currentUtterance = '';
    _failedStarts = 0;
    _sessionEndedDuringActive = false;
    _cancelPendingRestart();
    _startPlatformSession();
    return true;
  }

  /// Permanently ends the active listening session (manual stop).
  ///
  /// Order matters: the USER session is marked inactive FIRST so the package
  /// callbacks emitted during shutdown can never restart recognition; the
  /// pending restart timer is cancelled; the session token is invalidated;
  /// then any trailing interim words are committed and the recognizer
  /// stopped. No callback after this point may restart.
  Future<void> stopListening() async {
    _debug('USER LISTEN STOP');
    _userIsListening = false;
    _cancelPendingRestart();
    _sessionEndedDuringActive = false;
    _sessionToken++;
    _commitCurrentUtterance('USER LISTEN STOP -> committing current utterance');
    try {
      await _engine.stop();
    } on Exception {
      // Best effort; the platform session is going away regardless.
    }
    onStopped?.call();
    _clear();
  }

  /// Discards the session without committing trailing text.
  Future<void> cancelListening() async {
    _debug('USER LISTEN CANCEL');
    _userIsListening = false;
    _cancelPendingRestart();
    _sessionEndedDuringActive = false;
    _sessionToken++;
    try {
      await _engine.cancel();
    } on Exception {
      // Best effort.
    }
    onStopped?.call();
    _clear();
  }

  void dispose() {
    _disposed = true;
    _userIsListening = false;
    _cancelPendingRestart();
    _sessionEndedDuringActive = false;
    _sessionToken++;
    _sessionActive = false;
    _clear();
    _engine.cancel();
  }

  // -------------------------------------------------------------------------
  // Private helpers
  // -------------------------------------------------------------------------

  void _clear() {
    onPartial = null;
    onSegment = null;
    onStopped = null;
    _currentUtterance = '';
  }

  /// Starts exactly ONE platform recognition session. This is the only place
  /// [SpeechToText.listen] is ever invoked.
  ///
  /// The awaited future resolves as soon as the session *starts*, so on a
  /// normal completion we deliberately do NOT schedule anything — an alive
  /// session will deliver its own `done` status when it genuinely ends. Only
  /// a failure to start (exception) schedules the single restart.
  Future<void> _startPlatformSession() async {
    if (_disposed || !_userIsListening || _sessionActive) return;
    if (!_engine.isAvailable) return;

    _sessionActive = true;
    final token = ++_sessionToken;
    _currentUtterance = '';
    _debug('PLATFORM SESSION START token=$token');

    var startedOk = false;
    try {
      await _engine.listen(
        onResult: (r) => _handleResult(token, r),
        listenOptions: SpeechListenOptions(
          localeId: 'ar_EG',
          // Upper bound only; the platform may end sessions sooner, in which
          // case we transparently restart below — the user's session is not
          // affected by the internal timeout.
          listenFor: const Duration(seconds: 120),
          // Length of tolerated silence inside one platform session. On
          // speech_to_text 7.4.0 this value is forwarded to Android natively
          // via EXTRA_SPEECH_INPUT_COMPLETE_SILENCE_LENGTH_MILLIS, so it
          // genuinely widens the recognizer's pause window and defers the
          // platform session end (and the associated handoff gap). Long pauses
          // still end the session (and we restart); short pauses between
          // utterances keep the session open.
          pauseFor: const Duration(seconds: 10),
          cancelOnError: false, // transient errors handled in _onError
          partialResults: true,
        ),
      );
      startedOk = true;
      _debug('PLATFORM SESSION END token=$token userListening=$_userIsListening');
    } on Exception catch (e) {
      _debug('PLATFORM SESSION START FAILED: $e');
    }

    _sessionActive = false;
    if (_disposed || !_userIsListening) return;

    // A session that started resets the failure streak; one that failed to
    // start increments it so repeated failures back off.
    if (startedOk) {
      _failedStarts = 0;
    } else {
      _failedStarts++;
    }

    // A session end (`done`/`notListening`) that arrived while the START was
    // still in flight must not be lost: if it is, this platform session
    // already ended and would otherwise leave a permanently dead recognizer
    // until the user taps again.
    if (_sessionEndedDuringActive) {
      _sessionEndedDuringActive = false;
      _requestRestart();
    } else if (!startedOk) {
      // The future completing does NOT mean the recognition session ended —
      // only the start attempt finished. If it failed to start, schedule the
      // single retry; if it started, its end status will drive the restart.
      _requestRestart();
    }
  }

  void _handleResult(int token, SpeechRecognitionResult result) {
    // Ignore stale results delivered for a superseded platform session.
    if (_disposed || !_userIsListening || token != _sessionToken) return;

    // Any live result proves the recognizer is working: clear the failure
    // streak so the next silence restart uses the fast delay.
    _failedStarts = 0;

    final segText = result.recognizedWords.trim();

    if (result.finalResult) {
      _debug('onResult FINAL len=${segText.length} "$segText"');
      // Native recognition finalized the current utterance: commit it exactly
      // once and clear the pending utterance, so the following
      // notListening/done session-end commit is a no-op — nothing is
      // duplicated (Req 5). If the final arrived EMPTY (silence / no-match /
      // timeout), the trailing partial is the only evidence we have; commit
      // that instead of discarding the speaker's words.
      final finalText = segText.isEmpty ? _currentUtterance.trim() : segText;
      _currentUtterance = '';
      if (finalText.isNotEmpty) {
        _debug('FINAL -> committed utterance len=${finalText.length}');
        onSegment?.call(finalText);
      }
      return;
    }

    // Empty partials (silence gaps in the recognition stream) are inert: they
    // must never wipe committed text or the pending utterance (Req 9).
    if (segText.isEmpty) {
      _debug('onResult PARTIAL len=0 "" (empty -> inert)');
      return;
    }

    // Within ONE native platform session, partial results are successive
    // revisions of the CURRENT utterance, not independent append-only
    // segments (Req 2):
    //   "اسم" -> "اسم الاتوبيس" -> "اسم الاتوبيس الوهاب"
    // is a SINGLE utterance that just keeps being refined; concatenating the
    // three would duplicate text. Only when the incoming partial is NOT an
    // extension of the pending one (it lost the prefix, shrank, or is a
    // genuinely fresh phrase) did the recognizer reset to a NEW utterance:
    //   "اسم الاتوبيس الوهاب" -> "اسم السواق" -> "اسم السواق احمد"
    // The previous utterance is then committed BEFORE being replaced, so no
    // spoken words are ever dropped mid-session (Req 3).
    final prev = _currentUtterance;
    if (!_isUtteranceExtension(prev, segText)) {
      _commitCurrentUtterance('partial boundary -> committed utterance');
    }
    if (_currentUtterance != segText) {
      _currentUtterance = segText;
      _debug(
          'partial -> currentUtterance len=${_currentUtterance.length} '
          '"$_currentUtterance"');
      onPartial?.call(_currentUtterance);
    }
  }

  /// True when [text] is a refinement of the pending [prev] utterance:
  /// identical, or a strict extension that still begins with it. Anything
  /// that dropped or shortened the prefix (a reset, a shrink, or a genuinely
  /// new utterance) is NOT an extension and therefore starts a new utterance.
  bool _isUtteranceExtension(String prev, String text) {
    if (prev.isEmpty) return false;
    if (text == prev) return true;
    if (text.length < prev.length) return false;
    return text.startsWith(prev);
  }

  /// One platform recognition session genuinely ended — confirmed by either
  /// the `done` status, Android's `notListening`, or a transient error
  /// (whichever arrives first).
  ///
  /// The COMPLETE pending utterance is preserved and committed exactly once
  /// (never just the last partial), the USER session stays alive, and the
  /// single controlled restart is central — the transcript keeps growing
  /// across session boundaries (Req 6/7).
  void _handleSessionEnd() {
    _commitCurrentUtterance('SESSION END -> committing current utterance');

    // Invalidate the finished session's generation NOW. Any stray callback
    // still in flight (a late partial delivered after 'notListening', a result
    // racing the end) is dropped by _handleResult and can never rewrite the
    // committed transcript during the restart window (Req 10).
    _sessionToken++;

    if (_sessionActive) {
      // The session is still in its start window; we can't interrupt a live
      // listen. But the session IS over: remember the end so the restart is
      // re-armed once the start completes instead of being lost.
      _sessionEndedDuringActive = true;
      return;
    }
    _requestRestart();
  }

  void _onStatus(String status) {
    if (_disposed) return;
    _debug(
        'PLATFORM STATUS "$status" token=$_sessionToken userListening=$_userIsListening');
    if (!_userIsListening) return;

    if (status == 'listening') {
      // The platform session is live; a successful start clears the failure
      // streak so ordinary silence restarts always use the fast delay.
      _failedStarts = 0;
      return;
    }

    // 'done' and — on Android — 'notListening' both mean a platform
    // recognition session fully ended (after a final result, pause timeout,
    // transient error, or stop). Either one funnels into the single
    // [_handleSessionEnd] so the trailing interim is committed and exactly one
    // restart is armed; the restart gate deduplicates the status that arrives
    // second. 'listening'/'notListening' alone never end the user session.
    if (status == 'done' || status == 'notListening') {
      // Ignore teardown noise delivered before any platform session started.
      if (_sessionToken == 0) return;
      _handleSessionEnd();
    }
  }

  /// Per the Android plugin, a transient error ends the platform session: the
  /// recognizer tears down and a `notListening`/`done` pair follows (which is
  /// why the package marks these errors `permanent: true` — in this plugin
  /// that flag means "session-ending", not "unrecoverable"). So a transient
  /// error is treated as a session end immediately: the trailing interim is
  /// committed and the single restart armed, even on builds that forget the
  /// trailing status. A `done`/`notListening` that still arrives after is
  /// deduplicated by the restart gate.
  void _onError(dynamic error) {
    if (_disposed || !_userIsListening) return;

    final msg = error is SpeechRecognitionError
        ? error.errorMsg.toLowerCase()
        : error.toString().toLowerCase();
    _debug('onError "$msg"');

    // Only genuinely permanent problems (permission, unsupported language,
    // recognizer unavailable) end the USER session. Everything else — no-match,
    // no-speech, network blips, client/busy/server disconnects, timeouts —
    // is expected during a long listening session and is handled as a
    // transparent platform session end.
    if (_isPermanentError(msg)) {
      _fail();
      return;
    }

    _handleSessionEnd();
  }

  /// Errors that no amount of restarting can fix.
  bool _isPermanentError(String msg) {
    return msg.contains('permission') ||
        msg.contains('insufficient') ||
        msg.contains('not_available') ||
        msg.contains('not available') ||
        msg.contains('unavailable') ||
        msg.contains('language_not_supported') ||
        msg.contains('language not supported');
  }

  /// THE single controlled restart mechanism.
  ///
  /// All restart candidates (a `done`/`notListening` session end, a failed
  /// session start, and Android's post-error teardown) funnel into this one
  /// method. It refuses to arm while a restart is already pending or a
  /// platform session is still in flight — so at most one platform session
  /// ever exists, and competing callbacks can never start a loop. Once armed,
  /// a live session is never interrupted: if one is running by the time the
  /// timer fires, the fire is skipped and that session's own end status
  /// re-arms the restart. Repeated failed *starts* back off so a flaky
  /// recognizer isn't hammered, while a successful session keeps restarts
  /// fast.
  void _requestRestart() {
    if (!_userIsListening || _disposed) return;
    if (_restartPending || _sessionActive) return;

    _restartPending = true;
    final delay =
        _failedStarts >= _maxFailedStarts ? _restartBackoff : _restartDelay;
    _debug('AUTO RESTART REQUEST token=$_sessionToken delay=${delay.inMilliseconds}ms');
    _restartTimer = Timer(delay, () {
      _restartPending = false;
      _restartTimer = null;
      if (_disposed || !_userIsListening) return;
      if (_sessionActive) {
        // A session is already in flight; its end status will re-arm the restart.
        _debug('AUTO RESTART SKIPPED (session active)');
        return;
      }
      _debug('AUTO RESTART EXECUTED');
      _startPlatformSession();
    });
  }

  void _cancelPendingRestart() {
    if (_restartPending || _restartTimer != null) {
      _debug('AUTO RESTART CANCELLED');
    }
    _restartPending = false;
    _restartTimer?.cancel();
    _restartTimer = null;
  }

  /// Makes the pending utterance a committed segment exactly once, so a
  /// session end, a manual stop, an utterance boundary or a permanent error
  /// never silently discards what the user already said. Clears the pending
  /// utterance so a later commit of the same words is a no-op.
  void _commitCurrentUtterance([String? reason]) {
    final utterance = _currentUtterance.trim();
    _currentUtterance = '';
    if (utterance.isEmpty || onSegment == null) return;
    _debug('${reason ?? 'commit'} len=${utterance.length} "$utterance"');
    onSegment!.call(utterance);
  }

  void _fail() {
    _debug('PERMANENT ERROR -> SESSION FAILED');
    _cancelPendingRestart();
    _userIsListening = false;
    _sessionToken++;
    _sessionActive = false;
    _commitCurrentUtterance('PERMANENT ERROR -> committing current utterance');
    onStopped?.call();
    _clear();
  }

  void _debug(String message) {
    debugPrint('[stt] $message');
  }
}