import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/chat_context.dart';
import 'gemini_proxy_service.dart';

enum AiSource { rag, groq, gemini, onDevice, error, offline }

class AiResponse {
  final String text;
  final AiSource source;
  final double confidence;
  final List<String>? weakTopicsIdentified;
  final String? suggestedChapter;

  AiResponse({
    required this.text,
    required this.source,
    this.confidence = 0.0,
    this.weakTopicsIdentified,
    this.suggestedChapter,
  });

  factory AiResponse.error(String message) {
    return AiResponse(
      text: message,
      source: AiSource.error,
      confidence: 0.0,
    );
  }
}

class AiRouterService {
  final GeminiProxyService _geminiProxy;

  AiRouterService()
      : _geminiProxy = GeminiProxyService();

  double _calculateConfidence(AiSource source, {double ragScore = 0.0}) {
    switch (source) {
      case AiSource.rag: return ragScore.clamp(0.0, 1.0);
      case AiSource.groq: return 0.85;
      case AiSource.gemini: return 0.90;
      case AiSource.onDevice: return 0.70;
      default: return 0.0;
    }
  }

  Future<AiResponse> generate({
    required String prompt,
    ChatContext? context,
    List<String>? weakTopics,
  }) async {
    try {
      final ragResponse = await _searchLocalRag(prompt, context, weakTopics);
      if (ragResponse != null && ragResponse.isNotEmpty) {
        return AiResponse(
          text: ragResponse,
          source: AiSource.rag,
          confidence: 0.95,
          weakTopicsIdentified: weakTopics,
        );
      }
    } catch (e) {
      debugPrint('RAG search error: $e');
    }

    // Fallback to Gemini (already integrated)
    try {
      final geminiResponse = await _geminiProxy.generate(
        prompt: prompt,
        context: context,
      );

      return AiResponse(
        text: geminiResponse.text,
        source: AiSource.gemini,
        confidence: _calculateConfidence(AiSource.gemini),
        weakTopicsIdentified: weakTopics,
      );
    } catch (e) {
      debugPrint('Gemini error: $e');
    }

    return AiResponse.error('AI is temporarily unavailable.');
  }

  Future<String?> _searchLocalRag(
    String prompt,
    ChatContext? context,
    List<String>? weakTopics,
  ) async {
    // Simple mock logic for now
    return null;
  }
}

final aiRouterProvider = Provider<AiRouterService>((ref) {
  return AiRouterService();
});
