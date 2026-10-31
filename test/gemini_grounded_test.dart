import 'package:flutter_test/flutter_test.dart';

import 'package:neet_mitos/core/services/gemini_chat_service.dart';
import 'package:neet_mitos/core/services/ncert_text_index_service.dart';

/// Case-insensitive `contains` for prose assertions.
bool containsIgnoringCase(String haystack, String needle) =>
    haystack.toLowerCase().contains(needle.toLowerCase());

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('groundedSystemPrompt', () {
    final prompt = GeminiChatService.groundedSystemPrompt(
      'Class 11 Biology — The Living World',
    );

    test('demands strict grounding from the reference text', () {
      expect(prompt, contains('REFERENCE TEXT'));
      expect(containsIgnoringCase(prompt, 'answer only'), isTrue);
      expect(prompt, contains('Do not use outside knowledge'));
    });

    test('demands [p.N] citations', () {
      expect(prompt, contains('[p.N]'));
      expect(containsIgnoringCase(prompt, 'cite'), isTrue);
    });

    test('forbids invented page numbers', () {
      expect(prompt, contains('Never invent page numbers'));
    });

    test('names the chapter being studied', () {
      expect(prompt, contains('The Living World'));
    });
  });

  group('GeminiTurn', () {
    test('carries role and text', () {
      const turn = GeminiTurn(isUser: true, text: 'What is a cell?');
      expect(turn.isUser, isTrue);
      expect(turn.text, 'What is a cell?');
    });
  });

  group('GeminiChatService (no key configured)', () {
    final service = GeminiChatService();

    test('stable default model is gemini-2.5-flash', () {
      expect(GeminiChatService.defaultModel, 'gemini-2.5-flash');
    });

    test('sendGrounded refuses honestly without a key', () async {
      final reply = await service.sendGrounded(
        prompt: 'Explain the chapter.',
        contextualText: '[p.1]\nChapter text.',
        sourceLabel: 'Class 11 Biology — The Living World',
      );
      expect(reply, contains('API Key is not configured'));
    });

    test('maxHistoryTurns bounded to keep token cost sane', () {
      // A grounded chapter is already ~40k tokens; unbounded history would
      // compound that every turn.
      expect(GeminiChatService.maxHistoryTurns, lessThanOrEqualTo(12));
    });
  });

  group('grounded context wiring (NCERT index -> service shape)', () {
    test('a real chapter context block is non-trivial in size', () async {
      // 1M-token context design: the whole chapter travels per request, so
      // the block must actually be substantial text.
      final service = NcertTextIndexService();
      final chapter = await service.load('bio_ch1');
      expect(chapter, isNotNull);
      expect(chapter!.toContextBlock().length, greaterThan(15000));
    });
  });
}
