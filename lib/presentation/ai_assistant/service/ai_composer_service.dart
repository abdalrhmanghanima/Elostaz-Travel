class AiComposerService {
  const AiComposerService._();

  /// Merges a voice/speech segment into the current composer text.
  ///
  /// Supports multi-segment dictation: a new transcript is appended after the
  /// existing text instead of replacing it, and never duplicates a segment.
  /// Empty or whitespace-only segments are ignored so interim results never
  /// clobber the composer and never auto-submit.
  static String mergeVoiceSegment(String baseText, String newSegment) {
    final base = baseText.trim();
    final segment = newSegment.trim();
    if (segment.isEmpty) return base;
    if (base.isEmpty) return segment;
    return '$base $segment';
  }
}