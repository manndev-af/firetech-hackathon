import 'dart:io';

import '../core/network/api_client.dart';
import '../core/network/api_endpoints.dart';
import '../core/utils/api_exception.dart';

class AssistantHistoryItem {
  const AssistantHistoryItem({
    required this.role,
    required this.text,
  });

  final String role; // 'user' or 'assistant'
  final String text;

  Map<String, String> toJson() => {
    'role': role,
    'text': text,
  };
}

class CitationSource {
  const CitationSource({
    required this.id,
    required this.title,
    required this.url,
    this.version,
    this.reviewedAt,
  });

  factory CitationSource.fromJson(Map<String, dynamic> json) {
    return CitationSource(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      url: json['url'] as String? ?? '',
      version: json['version'] as String?,
      reviewedAt: json['reviewedAt'] as String?,
    );
  }

  final String id;
  final String title;
  final String url;
  final String? version;
  final String? reviewedAt;
}

class AssistantResponse {
  const AssistantResponse({
    required this.reply,
    required this.sources,
    required this.warnings,
    required this.mode,
    this.patternEvidence,
  });

  factory AssistantResponse.fromJson(Map<String, dynamic> json) {
    final rawSources = json['sources'] as List<dynamic>? ?? [];
    final sources = rawSources
        .whereType<Map<String, dynamic>>()
        .map(CitationSource.fromJson)
        .toList();

    final rawWarnings = json['warnings'] as List<dynamic>? ?? [];
    final warnings = rawWarnings.map((e) => e.toString()).toList();

    final contextSummary = json['contextSummary'] as Map<String, dynamic>? ?? {};
    final mode = contextSummary['mode'] as String? ?? 'general';
    final patternEvidence = contextSummary['patternEvidence'] as Map<String, dynamic>?;

    return AssistantResponse(
      reply: json['reply'] as String? ?? '',
      sources: sources,
      warnings: warnings,
      mode: mode,
      patternEvidence: patternEvidence,
    );
  }

  final String reply;
  final List<CitationSource> sources;
  final List<String> warnings;
  final String mode;
  final Map<String, dynamic>? patternEvidence;
}

class AssistantApi {
  AssistantApi({required this.client});

  factory AssistantApi.withDefaultBase({String? baseUrl, HttpClient? httpClient}) {
    final resolvedUrl = resolveDefaultBaseUrl(baseUrl);
    return AssistantApi(
      client: ApiClient(
        baseUri: Uri.parse(resolvedUrl),
        httpClient: httpClient,
      ),
    );
  }

  final ApiClient client;

  Future<AssistantResponse> sendMessage({
    required String message,
    String mode = 'general',
    List<AssistantHistoryItem> history = const [],
  }) async {
    final cleanMessage = message.trim();
    if (cleanMessage.isEmpty) {
      throw const FormatException('Pesan pertanyaan tidak boleh kosong.');
    }
    if (cleanMessage.length > 2000) {
      throw const FormatException('Pesan maksimal 2000 karakter.');
    }

    final validMode = (mode == 'pattern') ? 'pattern' : 'general';

    // Ensure history conforms to backend schema: max 10 items, alternating completed user/assistant pairs
    final validHistory = <Map<String, String>>[];
    var totalChars = cleanMessage.length;

    // Take at most the last 10 messages (5 pairs)
    final candidateHistory = history.length > 10 ? history.sublist(history.length - 10) : history;
    for (final item in candidateHistory) {
      if (item.text.trim().isNotEmpty && totalChars + item.text.length <= 12000) {
        validHistory.add(item.toJson());
        totalChars += item.text.length;
      }
    }

    // Backend requires history to start with user and end with assistant
    // If last is user, drop it to maintain valid pairs
    while (validHistory.isNotEmpty && validHistory.last['role'] != 'assistant') {
      validHistory.removeLast();
    }
    // If first is assistant, drop it
    while (validHistory.isNotEmpty && validHistory.first['role'] != 'user') {
      validHistory.removeAt(0);
    }

    final payload = {
      'mode': validMode,
      'message': cleanMessage,
      'history': validHistory,
    };

    try {
      final response = await client.post(
        ApiEndpoints.assistantMessages,
        body: payload,
      );

      if (response is Map<String, dynamic>) {
        final data = response['data'] as Map<String, dynamic>? ?? response;
        return AssistantResponse.fromJson(data);
      }
      throw const FormatException('Format jawaban asisten tidak dikenali.');
    } on ApiException catch (e) {
      if (e.code == 'SCAN_BUSY' || e.statusCode == 429) {
        throw ApiException(
          message: 'Layanan AI sedang sibuk memproses. Coba beberapa saat lagi.',
          statusCode: 429,
          code: 'SCAN_BUSY',
        );
      }
      rethrow;
    }
  }
}
