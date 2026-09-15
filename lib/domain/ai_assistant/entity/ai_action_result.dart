import 'package:elostaz_travel/domain/ai_assistant/entity/ai_trip_draft.dart';

enum AiActionType {
  createTrip,
  missingFields,
  generalChat,
}

class AiActionResult {
  final AiActionType type;
  final String assistantMessage;
  final AiTripDraft? tripDraft;
  final List<String> missingFields;

  const AiActionResult({
    required this.type,
    required this.assistantMessage,
    this.tripDraft,
    this.missingFields = const [],
  });
}
