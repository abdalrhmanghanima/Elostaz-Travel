import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:elostaz_travel/domain/ai_assistant/entity/ai_chat_message_entity.dart' as entities;
import 'package:elostaz_travel/domain/ai_assistant/entity/ai_action_result.dart';
import 'package:elostaz_travel/domain/ai_assistant/entity/ai_trip_draft.dart';

class AiLlmService {
  String _apiEndpoint = '';
  String _apiKey = '';
  String _model = '';

  void configure({
    required String apiEndpoint,
    required String apiKey,
    String model = '',
  }) {
    _apiEndpoint = apiEndpoint;
    _apiKey = apiKey;
    _model = model;
  }

  bool get isConfigured => _apiEndpoint.isNotEmpty && _apiKey.isNotEmpty;

  Future<AiActionResult> sendMessage({
    required List<entities.ChatMessage> conversationHistory,
    required AiTripDraft currentDraft,
    required List<String> availableBusNames,
    required List<String> availableDriverNames,
    required List<String> availableFactoryNames,
  }) async {
    if (!isConfigured) {
      return const AiActionResult(
        type: AiActionType.generalChat,
        assistantMessage: 'الخدمة غير مُعدّة بعد.',
      );
    }

    try {
      final messages = _buildMessages(
        conversationHistory: conversationHistory,
        currentDraft: currentDraft,
        availableBusNames: availableBusNames,
        availableDriverNames: availableDriverNames,
        availableFactoryNames: availableFactoryNames,
      );

      final response = await http.post(
        Uri.parse(_apiEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          if (_model.isNotEmpty) 'model': _model,
          'messages': messages,
          'temperature': 0.3,
        }),
      );

      if (response.statusCode != 200) {
        return const AiActionResult(
          type: AiActionType.generalChat,
          assistantMessage: 'حدث خطأ في الاتصال. الرجاء المحاولة مرة أخرى.',
        );
      }

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final content = _extractContent(body);

      return _parseResponse(content);
    } catch (_) {
      return const AiActionResult(
        type: AiActionType.generalChat,
        assistantMessage: 'حدث خطأ غير متوقع.',
      );
    }
  }

  String _extractContent(Map<String, dynamic> body) {
    if (body['choices'] != null && body['choices'] is List) {
      final choice = (body['choices'] as List).firstOrNull;
      if (choice != null && choice['message'] != null) {
        return choice['message']['content'] as String? ?? '';
      }
    }
    if (body['candidates'] != null && body['candidates'] is List) {
      final candidate = (body['candidates'] as List).firstOrNull;
      if (candidate != null && candidate['content'] != null) {
        final parts = candidate['content']['parts'] as List?;
        if (parts != null && parts.isNotEmpty) {
          return parts[0]['text'] as String? ?? '';
        }
      }
    }
    return '';
  }

  List<Map<String, String>> _buildMessages({
    required List<entities.ChatMessage> conversationHistory,
    required AiTripDraft currentDraft,
    required List<String> availableBusNames,
    required List<String> availableDriverNames,
    required List<String> availableFactoryNames,
  }) {
    final messages = <Map<String, String>>[
      {'role': 'system', 'content': 'You are an Arabic travel assistant.'},
    ];

    for (final msg in conversationHistory) {
      messages.add({
        'role': msg.role == entities.AiMessageRole.user ? 'user' : 'assistant',
        'content': msg.content,
      });
    }

    return messages;
  }

  AiActionResult _parseResponse(String content) {
    try {
      final json = jsonDecode(content) as Map<String, dynamic>;
      final action = json['action'] as String? ?? 'generalChat';
      final message = json['message'] as String? ?? '';
      final missingFields =
          (json['missingFields'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [];

      AiTripDraft? draft;
      if (json['draft'] != null) {
        final d = json['draft'] as Map<String, dynamic>;
        DateTime? tripDate;
        if (d['tripDate'] != null && d['tripDate'] is String) {
          tripDate = DateTime.tryParse(d['tripDate'] as String);
        }

        draft = AiTripDraft(
          busName: d['busName'] as String?,
          plateNumber: d['plateNumber'] as String?,
          driverName: d['driverName'] as String?,
          factoryName: d['factoryName'] as String?,
          revenue: (d['revenue'] as num?)?.toDouble(),
          driverWage: (d['driverWage'] as num?)?.toDouble(),
          tripDate: tripDate,
          departureTime: d['departureTime'] as String?,
          type: d['type'] as String?,
          details: d['details'] as String?,
          expenses: (d['expenses'] as num?)?.toDouble(),
          expenseDetails: d['expenseDetails'] as String?,
        );
      }

      final actionType = AiActionType.values.firstWhere(
        (e) => e.name == action,
        orElse: () => AiActionType.generalChat,
      );

      return AiActionResult(
        type: actionType,
        assistantMessage: message,
        tripDraft: draft,
        missingFields: missingFields,
      );
    } catch (_) {
      return AiActionResult(
        type: AiActionType.generalChat,
        assistantMessage: content.isNotEmpty
            ? content
            : 'لم أتمكن من فهم الرد.',
      );
    }
  }
}
