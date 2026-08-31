import 'package:flutter_test/flutter_test.dart';
import 'package:neet_mitos/core/services/gemini_proxy_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Builds a service with a scripted invoker and forced "configured" state.
GeminiProxyService _service(
  Future<dynamic> Function(String name, {Object? body}) invoker, {
  bool configured = true,
}) {
  return GeminiProxyService(invoker: invoker, configured: configured);
}

void main() {
  group('GeminiProxyService.generate', () {
    test('returns text marked as cache when source is "cache"', () async {
      final service = _service((name, {body}) async {
        expect(name, 'gemini-proxy');
        expect(body, isA<Map>());
        return {'cached': true, 'source': 'cache', 'response': 'Cached answer'};
      });

      final result = await service.generate(prompt: 'Explain meiosis');

      expect(result.source, GeminiProxySource.cache);
      expect(result.isFromCache, isTrue);
      expect(result.text, 'Cached answer');
    });

    test('returns text marked as live when source is "gemini"', () async {
      final service = _service((name, {body}) async {
        return {'source': 'gemini', 'response': 'Fresh answer'};
      });

      final result = await service.generate(prompt: 'Explain mitosis');

      expect(result.source, GeminiProxySource.live);
      expect(result.isFromCache, isFalse);
      expect(result.text, 'Fresh answer');
    });

    test('passes systemPrompt and questionId through to the body', () async {
      Map<String, dynamic>? captured;
      final service = _service((name, {body}) async {
        captured = body as Map<String, dynamic>;
        return {'source': 'cache', 'response': 'x'};
      });

      await service.generate(
        prompt: 'Explain Q23',
        systemPrompt: 'NEET tutor',
        questionId: 'q-42',
      );

      expect(captured, isNotNull);
      expect(captured!['prompt'], 'Explain Q23');
      expect(captured!['systemPrompt'], 'NEET tutor');
      expect(captured!['questionId'], 'q-42');
    });

    test('maps a non-map payload to an error result', () async {
      final service = _service((name, {body}) async => 'not a map');

      final result = await service.generate(prompt: 'hi');

      expect(result.source, GeminiProxySource.error);
      expect(result.text, contains('unexpected response'));
    });

    test('maps an empty response to an error result', () async {
      final service = _service(
        (name, {body}) async => {'source': 'gemini', 'response': '  '},
      );

      final result = await service.generate(prompt: 'hi');

      expect(result.source, GeminiProxySource.error);
    });

    test('maps a 429 FunctionException to rateLimited', () async {
      final service = _service((name, {body}) async {
        throw const FunctionException(
          status: 429,
          reasonPhrase: 'Too many requests',
        );
      });

      final result = await service.generate(prompt: 'hi');

      expect(result.source, GeminiProxySource.rateLimited);
      expect(result.isRateLimited, isTrue);
    });

    test('maps a 500 FunctionException to an error result', () async {
      final service = _service((name, {body}) async {
        throw const FunctionException(status: 500);
      });

      final result = await service.generate(prompt: 'hi');

      expect(result.source, GeminiProxySource.error);
      expect(result.text, contains('500'));
    });

    test('maps a generic exception to offline', () async {
      final service = _service((name, {body}) async {
        throw Exception('connection refused');
      });

      final result = await service.generate(prompt: 'hi');

      expect(result.source, GeminiProxySource.offline);
      expect(result.isOffline, isTrue);
    });

    test('returns offline without invoking when not configured', () async {
      var invoked = false;
      final service = _service((name, {body}) async {
        invoked = true;
        return {'source': 'cache', 'response': 'x'};
      }, configured: false);

      final result = await service.generate(prompt: 'hi');

      expect(invoked, isFalse);
      expect(result.source, GeminiProxySource.offline);
    });
  });
}
