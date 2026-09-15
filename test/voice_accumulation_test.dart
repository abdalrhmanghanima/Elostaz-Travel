import 'dart:async';

import 'package:elostaz_travel/data/ai_assistant/service/speech_to_text_service.dart';
import 'package:elostaz_travel/presentation/ai_assistant/provider/speech_recognition_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// Fakes the speech engine so the whole
/// SpeechToTextService -> SpeechRecognitionNotifier chain can be driven
/// with the exact callback order Android emits.
///
/// The real plugin's `listen()` future resolves only when the platform
/// session has actually STARTED (a few hundred ms after the call). This fake
/// mirrors that via a gate completed by [startSession].
class FakeSpeechToTextEngine implements SpeechToTextEngine {
  void Function(SpeechRecognitionError)? capturedError;
  void Function(String)? capturedStatus;
  void Function(SpeechRecognitionResult)? capturedResult;
  int listenCount = 0;
  bool available = true;
  Completer<void>? _startGate;

  @override
  bool get isAvailable => available;

  @override
  Future<bool> initialize({
    SpeechErrorListener? onError,
    SpeechStatusListener? onStatus,
  }) async {
    capturedError = onError;
    capturedStatus = onStatus;
    return true;
  }

  @override
  Future<void> listen({
    SpeechResultListener? onResult,
    SpeechListenOptions? listenOptions,
  }) async {
    listenCount++;
    capturedResult = onResult;
    _startGate = Completer<void>();
    await _startGate!.future;
  }

  @override
  Future<void> stop() async {}

  @override
  Future<void> cancel() async {}

  void startSession() => _startGate?.complete();

  void partial(String text) => capturedResult?.call(SpeechRecognitionResult.init(
        [SpeechRecognitionWords(text, null, 1.0)],
        ResultType.partial,
      ));

  void final_(String text) => capturedResult?.call(SpeechRecognitionResult.init(
        [SpeechRecognitionWords(text, null, 1.0)],
        ResultType.finalResult,
      ));

  void status(String status) => capturedStatus?.call(status);

  void error_(String msg) =>
      capturedError?.call(SpeechRecognitionError(msg, true));
}

void main() {
  late FakeSpeechToTextEngine fake;
  late SpeechToTextService service;
  late SpeechRecognitionNotifier provider;

  Future<void> pumpRestart() =>
      Future<void>.delayed(const Duration(milliseconds: 450));

  /// Models the platform session start confirmation: the engine's listen()
  /// future completes, the service records the session as active, then the
  /// real 'listening' status arrives.
  Future<void> startRecognizer() async {
    fake.startSession();
    await Future<void>.delayed(const Duration(milliseconds: 5));
    fake.status('listening');
  }

  setUp(() {
    fake = FakeSpeechToTextEngine();
    service = SpeechToTextService(engine: fake);
    provider = SpeechRecognitionNotifier(service);
  });

  tearDown(() {
    provider.dispose();
    service.dispose();
  });

  test('final-with-text then pause then restart then continuation appends', () async {
    await provider.startListening();
    await startRecognizer();

    // user speaks: partials, then pause, android finalizes the utterance
    fake.partial('أنا');
    fake.partial('أنا عايز');
    fake.final_('أنا عايز أضيف رحلة');
    fake.status('notListening');
    fake.status('done');

    expect(provider.state.status, SpeechRecognitionStatus.listening);
    expect(provider.state.recognizedText, 'أنا عايز أضيف رحلة');

    // automatic restart re-opens the recognizer
    await pumpRestart();
    expect(fake.listenCount, 2);
    await startRecognizer();

    // user continues; the accumulated transcript MUST still be there
    expect(provider.state.recognizedText, 'أنا عايز أضيف رحلة');
    fake.partial('ب');
    fake.partial('بالعربية');
    fake.final_('بالعربية الخضراء');
    expect(provider.state.recognizedText, 'أنا عايز أضيف رحلة بالعربية الخضراء');

    await provider.stopListening();
    expect(provider.state.status, SpeechRecognitionStatus.idle);
    expect(provider.state.recognizedText, 'أنا عايز أضيف رحلة بالعربية الخضراء');
  });

  test('silence timeout (done without final) preserves trailing partial', () async {
    await provider.startListening();
    await startRecognizer();

    fake.partial('أنا عايز أضيف رحلة');
    // session ends from silence with no final result
    fake.status('notListening');
    fake.status('done');

    expect(provider.state.recognizedText, 'أنا عايز أضيف رحلة');

    await pumpRestart();
    expect(fake.listenCount, 2);
    await startRecognizer();
    expect(provider.state.recognizedText, 'أنا عايز أضيف رحلة');

    fake.partial('بالعربية');
    fake.final_('بالعربية الخضراء');
    expect(provider.state.recognizedText, 'أنا عايز أضيف رحلة بالعربية الخضراء');

    await provider.stopListening();
    expect(provider.state.recognizedText, 'أنا عايز أضيف رحلة بالعربية الخضراء');
  });

  test('empty final after partials does not wipe anything', () async {
    await provider.startListening();
    await startRecognizer();

    fake.partial('أنا عايز أضيف رحلة');
    // android sometimes finalises with an empty bundle
    fake.final_('');
    fake.status('notListening');
    fake.status('done');

    expect(provider.state.recognizedText, 'أنا عايز أضيف رحلة');

    await pumpRestart();
    expect(fake.listenCount, 2);
    await startRecognizer();
    expect(provider.state.recognizedText, 'أنا عايز أضيف رحلة');

    await provider.stopListening();
    expect(provider.state.recognizedText, 'أنا عايز أضيف رحلة');
  });

  test('transient error then done still restarts without losing text', () async {
    await provider.startListening();
    await startRecognizer();

    fake.partial('أنا عايز أضيف رحلة');
    fake.error_('error_no_match');
    fake.status('notListening');
    fake.status('done');

    expect(provider.state.recognizedText, 'أنا عايز أضيف رحلة');

    await pumpRestart();
    expect(fake.listenCount, 2);
    await startRecognizer();
    expect(provider.state.recognizedText, 'أنا عايز أضيف رحلة');

    fake.partial('بالعربية');
    fake.final_('بالعربية الخضراء');
    expect(provider.state.recognizedText, 'أنا عايز أضيف رحلة بالعربية الخضراء');

    await provider.stopListening();
    expect(provider.state.recognizedText, 'أنا عايز أضيف رحلة بالعربية الخضراء');
  });

  test('manual stop preserves full accumulated transcript', () async {
    await provider.startListening();
    await startRecognizer();

    fake.partial('أنا عايز');
    fake.final_('أنا عايز أضيف رحلة');
    fake.status('done');
    await pumpRestart();
    await startRecognizer();

    fake.partial('بالعربية');
    fake.final_('بالعربية الخضراء');

    fake.status('notListening');
    await provider.stopListening();

    expect(provider.state.status, SpeechRecognitionStatus.idle);
    expect(provider.state.recognizedText, 'أنا عايز أضيف رحلة بالعربية الخضراء');
  });

  test('transient error with NO following done still restarts (self-heal)', () async {
    await provider.startListening();
    await startRecognizer();

    fake.partial('أنا عايز أضيف رحلة');
    // Some Android builds end the recognizer after a transient error without
    // ever sending 'done'.
    fake.error_('error_no_match');
    fake.status('notListening');
    // no 'done'!

    expect(provider.state.recognizedText, 'أنا عايز أضيف رحلة');

    await pumpRestart();
    expect(fake.listenCount, 2);
    await startRecognizer();
    expect(provider.state.recognizedText, 'أنا عايز أضيف رحلة');

    fake.partial('بالعربية');
    fake.final_('بالعربية الخضراء');
    expect(provider.state.recognizedText, 'أنا عايز أضيف رحلة بالعربية الخضراء');

    await provider.stopListening();
    expect(provider.state.recognizedText, 'أنا عايز أضيف رحلة بالعربية الخضراء');
  });

  test('done racing the session start is not dropped (no dead mic)', () async {
    await provider.startListening();

    // a done arrives while the listen() start is still in flight
    fake.status('done');
    // the start completes a moment later; the flagged restart is re-armed
    fake.startSession();
    await Future<void>.delayed(const Duration(milliseconds: 5));
    await pumpRestart();
    expect(fake.listenCount, 2);
    await startRecognizer();

    fake.partial('أنا عايز أضيف رحلة');
    expect(provider.state.recognizedText, 'أنا عايز أضيف رحلة');

    await provider.stopListening();
    expect(provider.state.recognizedText, 'أنا عايز أضيف رحلة');
  });

  test('notListening alone (no done) still restarts; silence never kills mic', () async {
    await provider.startListening();
    await startRecognizer();

    fake.partial('أنا عايز أضيف رحلة');
    // Android can end a session with ONLY notListening — no 'done' follows.
    fake.status('notListening');

    expect(provider.state.status, SpeechRecognitionStatus.listening);
    expect(provider.state.recognizedText, 'أنا عايز أضيف رحلة');

    await pumpRestart();
    expect(fake.listenCount, 2);
    await startRecognizer();
    expect(provider.state.recognizedText, 'أنا عايز أضيف رحلة');

    fake.partial('بالعربية');
    fake.final_('بالعربية الخضراء');
    expect(provider.state.recognizedText, 'أنا عايز أضيف رحلة بالعربية الخضراء');

    await provider.stopListening();
    expect(provider.state.status, SpeechRecognitionStatus.idle);
    expect(provider.state.recognizedText, 'أنا عايز أضيف رحلة بالعربية الخضراء');
  });

  test('partial delivered AFTER notListening is dropped (stale token)', () async {
    await provider.startListening();
    await startRecognizer();

    fake.partial('أنا عايز أضيف رحلة');
    fake.status('notListening'); // session end invalidates its generation

    // A stray interim from the dead session must never contaminate the
    // committed transcript during the restart window.
    fake.partial('زبالة لاحقة');
    expect(provider.state.recognizedText, 'أنا عايز أضيف رحلة');

    await pumpRestart();
    await startRecognizer();
    expect(provider.state.recognizedText, 'أنا عايز أضيف رحلة');

    fake.partial('بالعربية');
    fake.final_('بالعربية الخضراء');
    expect(provider.state.recognizedText, 'أنا عايز أضيف رحلة بالعربية الخضراء');

    await provider.stopListening();
    expect(provider.state.recognizedText, 'أنا عايز أضيف رحلة بالعربية الخضراء');
  });

  test('empty partial after a useful partial is inert', () async {
    await provider.startListening();
    await startRecognizer();

    fake.partial('أنا عايز');
    expect(provider.state.recognizedText, 'أنا عايز');

    // Empty interim (recognition silence) must not wipe the preview.
    fake.partial('');
    expect(provider.state.recognizedText, 'أنا عايز');

    fake.final_('أنا عايز أضيف رحلة');
    fake.status('notListening');
    await pumpRestart();
    await startRecognizer();
    expect(provider.state.recognizedText, 'أنا عايز أضيف رحلة');

    await provider.stopListening();
    expect(provider.state.status, SpeechRecognitionStatus.idle);
    expect(provider.state.recognizedText, 'أنا عايز أضيف رحلة');
  });

  test('stop during the restart window cancels restart and keeps text', () async {
    await provider.startListening();
    await startRecognizer();

    fake.partial('أنا عايز أضيف رحلة');
    fake.status('notListening'); // arms the automatic restart

    // User stops BEFORE the delayed restart fires.
    await provider.stopListening();

    expect(provider.state.status, SpeechRecognitionStatus.idle);
    expect(provider.state.recognizedText, 'أنا عايز أضيف رحلة');

    // Nothing more may start after the explicit stop.
    await pumpRestart();
    expect(fake.listenCount, 1);
  });

  test('A: refining partials collapse into one utterance on final', () async {
    await provider.startListening();
    await startRecognizer();

    fake.partial('اسم');
    fake.partial('اسم الاتوبيس');
    fake.partial('اسم الاتوبيس الوهاب');
    fake.final_('اسم الاتوبيس الوهاب');

    expect(provider.state.recognizedText, 'اسم الاتوبيس الوهاب');

    await provider.stopListening();
    expect(provider.state.recognizedText, 'اسم الاتوبيس الوهاب');
  });

  test('B: multiple finalized utterances in one session all accumulate', () async {
    await provider.startListening();
    await startRecognizer();

    fake.partial('اسم الاتوبيس الوهاب');
    fake.final_('اسم الاتوبيس الوهاب');

    fake.partial('اسم السواق احمد محمد');
    fake.final_('اسم السواق احمد محمد');

    fake.partial('وقت الرحله الساعه 6:00');
    fake.final_('وقت الرحله الساعه 6:00');

    expect(provider.state.recognizedText,
        'اسم الاتوبيس الوهاب اسم السواق احمد محمد وقت الرحله الساعه 6:00');

    await provider.stopListening();
    expect(provider.state.recognizedText,
        'اسم الاتوبيس الوهاب اسم السواق احمد محمد وقت الرحله الساعه 6:00');
  });

  test('C: session ends with ONLY partials — both utterances preserved', () async {
    await provider.startListening();
    await startRecognizer();

    // Native never finalizes; the second partial starts a NEW utterance, so
    // the first must be committed BEFORE being replaced, and the second must
    // be committed on notListening. NOT just the last partial.
    fake.partial('اسم الاتوبيس الوهاب');
    fake.partial('اسم السواق احمد محمد');
    fake.status('notListening');

    expect(provider.state.status, SpeechRecognitionStatus.listening);
    expect(provider.state.recognizedText,
        'اسم الاتوبيس الوهاب اسم السواق احمد محمد');

    await provider.stopListening();
    expect(provider.state.recognizedText,
        'اسم الاتوبيس الوهاب اسم السواق احمد محمد');
  });

  test('D: cross-session accumulation across automatic restart', () async {
    await provider.startListening();
    await startRecognizer();

    fake.partial('اسم الاتوبيس الوهاب');
    fake.partial('اسم السواق احمد محمد');
    fake.status('notListening');

    expect(provider.state.recognizedText,
        'اسم الاتوبيس الوهاب اسم السواق احمد محمد');

    await pumpRestart();
    expect(fake.listenCount, 2);
    await startRecognizer();

    fake.partial('وقت الرحله الساعه 6:00');
    fake.status('notListening');
    await pumpRestart();
    await startRecognizer();

    await provider.stopListening();
    expect(provider.state.status, SpeechRecognitionStatus.idle);
    expect(provider.state.recognizedText,
        'اسم الاتوبيس الوهاب اسم السواق احمد محمد وقت الرحله الساعه 6:00');
  });

  test('real Android partial stream: ALL utterances preserved, not only last', () async {
    await provider.startListening();
    await startRecognizer();

    // Root-cause replay: a full session where the recognizer only ever emits
    // PARTIALS, never a native final. "اسم" after "اسم الاتوبيس الوهاب" is
    // the recognizer resetting to a NEW utterance, and every completed
    // utterance must survive the notListening that ends the session.
    fake.partial('اسم');
    fake.partial('اسم الاتوبيس');
    fake.partial('اسم الاتوبيس الوهاب');
    fake.partial('اسم');
    fake.partial('اسم السواق');
    fake.partial('اسم السواق احمد');
    fake.partial('اسم السواق احمد محمد');
    fake.partial('وقت الرحله');
    fake.partial('وقت الرحله الساعه');
    fake.partial('وقت الرحله الساعه 6:00');
    fake.partial('الايراد');
    fake.status('notListening');

    expect(provider.state.status, SpeechRecognitionStatus.listening);
    expect(provider.state.recognizedText,
        'اسم الاتوبيس الوهاب اسم السواق احمد محمد وقت الرحله الساعه 6:00 الايراد');

    await provider.stopListening();
    expect(provider.state.status, SpeechRecognitionStatus.idle);
    expect(provider.state.recognizedText,
        'اسم الاتوبيس الوهاب اسم السواق احمد محمد وقت الرحله الساعه 6:00 الايراد');
  });

  test('J: Arabic continuation across session restart is preserved exactly once', () async {
    await provider.startListening();
    await startRecognizer();

    // Session 1: user slowly dictates bus + driver, then Android ends the
    // recognition session after the long speaking period.
    fake.partial('الاتوبيس الوهاب');
    fake.partial('الاتوبيس الوهاب والسواق احمد محمد');
    fake.status('notListening');
    fake.status('done');

    expect(provider.state.status, SpeechRecognitionStatus.listening);
    expect(provider.state.recognizedText, 'الاتوبيس الوهاب والسواق احمد محمد');

    // Automatic restart re-opens the recognizer transparently.
    await pumpRestart();
    expect(fake.listenCount, 2);
    await startRecognizer();

    // Session 2: the user keeps speaking the continuation. Every partial
    // is an extension of the previous one -> a SINGLE new utterance.
    fake.partial('والايراد');
    fake.partial('والايراد 5000');
    fake.partial('والايراد 5000 جنيه');
    fake.status('notListening');
    fake.status('done');

    // Both segments present, exactly once, in order.
    expect(
      provider.state.recognizedText,
      'الاتوبيس الوهاب والسواق احمد محمد والايراد 5000 جنيه',
    );

    await pumpRestart();
    expect(fake.listenCount, 3);
    await startRecognizer();

    await provider.stopListening();
    expect(provider.state.status, SpeechRecognitionStatus.idle);
    expect(
      provider.state.recognizedText,
      'الاتوبيس الوهاب والسواق احمد محمد والايراد 5000 جنيه',
    );
  });

  test('restart gap is minimized: next session starts below old 350ms budget', () async {
    await provider.startListening();
    await startRecognizer();

    fake.partial('أنا عايز أضيف رحلة');
    fake.status('notListening');
    fake.status('done');

    expect(provider.state.recognizedText, 'أنا عايز أضيف رحلة');

    // With the 150ms restart delay the next platform session must already be
    // requested well before the old 350ms budget (the reduced handoff gap).
    await Future<void>.delayed(const Duration(milliseconds: 300));
    expect(fake.listenCount, 2);
    await startRecognizer();

    // Continuation still appends without duplicating the committed text.
    fake.partial('بالعربية');
    fake.final_('بالعربية الخضراء');
    expect(provider.state.recognizedText, 'أنا عايز أضيف رحلة بالعربية الخضراء');

    await provider.stopListening();
    expect(provider.state.recognizedText, 'أنا عايز أضيف رحلة بالعربية الخضراء');
  });

  test('new session echoing the committed tail is deduped, not duplicated', () async {
    await provider.startListening();
    await startRecognizer();

    fake.partial('الاتوبيس الوهاب');
    fake.final_('الاتوبيس الوهاب');
    fake.status('notListening');
    fake.status('done');

    expect(provider.state.recognizedText, 'الاتوبيس الوهاب');

    // Automatic restart. The fresh Android session often replays the tail of
    // the previously committed segment as its first partial: this echo must be
    // dropped by the provider (never appended as a duplicate word).
    await pumpRestart();
    await startRecognizer();
    fake.partial('الوهاب');
    expect(provider.state.recognizedText, 'الاتوبيس الوهاب');

    // The user then actually continues dictating new words; they append on
    // top of the committed transcript without the echoed tail.
    fake.partial('والسواق احمد محمد');
    expect(provider.state.recognizedText, 'الاتوبيس الوهاب والسواق احمد محمد');
    fake.final_('والسواق احمد محمد');
    expect(provider.state.recognizedText, 'الاتوبيس الوهاب والسواق احمد محمد');

    await provider.stopListening();
    expect(provider.state.status, SpeechRecognitionStatus.idle);
    expect(provider.state.recognizedText, 'الاتوبيس الوهاب والسواق احمد محمد');
  });
}