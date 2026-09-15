import 'package:elostaz_travel/presentation/ai_assistant/service/ai_composer_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AiComposerService.mergeVoiceSegment (composer separation)', () {
    test('empty base takes the segment as-is', () {
      expect(
        AiComposerService.mergeVoiceSegment('', 'الأتوبيس الوهاب'),
        'الأتوبيس الوهاب',
      );
    });

    test('empty or whitespace segment preserves the base text', () {
      expect(
        AiComposerService.mergeVoiceSegment('الأتوبيس الوهاب', ''),
        'الأتوبيس الوهاب',
      );
      expect(
        AiComposerService.mergeVoiceSegment('الأتوبيس الوهاب', '   '),
        'الأتوبيس الوهاب',
      );
    });

    test('second voice segment appends after the first without duplication', () {
      final first = AiComposerService.mergeVoiceSegment('', 'الأتوبيس الوهاب');
      final second =
          AiComposerService.mergeVoiceSegment(first, 'السواق أحمد');
      expect(second, 'الأتوبيس الوهاب السواق أحمد');
    });

    test('segments are merged with a single space separator', () {
      expect(
        AiComposerService.mergeVoiceSegment('الوهاب', 'أحمد'),
        'الوهاب أحمد',
      );
    });

    test('whitespace around inputs is trimmed', () {
      expect(
        AiComposerService.mergeVoiceSegment('  الوهاب ', '  أحمد  '),
        'الوهاب أحمد',
      );
    });
  });
}