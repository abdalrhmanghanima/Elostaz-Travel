enum AiMessageRole {
  user,
  assistant,
  system,
}

class ChatMessage {
  final AiMessageRole role;
  final String content;
  final DateTime? timestamp;

  const ChatMessage({
    required this.role,
    required this.content,
    this.timestamp,
  });

  bool get isUser => role == AiMessageRole.user;
  bool get isAssistant => role == AiMessageRole.assistant;
  bool get isSystem => role == AiMessageRole.system;
}
