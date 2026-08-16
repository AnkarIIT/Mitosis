import 'package:tflite_flutter/tflite_flutter.dart';
import 'dart:math';
import 'package:flutter/foundation.dart';

class MLService {
  Interpreter? _interpreter;

  Future<void> initializeModels() async {
    try {
      _interpreter = await Interpreter.fromAsset('ml/sentence_encoder.tflite');
      if (kDebugMode) {
        print('✅ ML Model Loaded Successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to load ML model: $e');
      }
    }
  }

  // Pre-processing: Simple Tokenizer (Boilerplate - needs actual vocab for production)
  List<double> _tokenize(String text) {
    List<double> tokens = List.filled(512, 0.0);
    for (int i = 0; i < text.length && i < 512; i++) {
      tokens[i] = text.codeUnitAt(i).toDouble();
    }
    return tokens;
  }

  Future<double> calculateSemanticSimilarity(String text1, String text2) async {
    if (_interpreter == null) {
      // Fallback: String overlap if model is missing
      return _fallbackSimilarity(text1, text2);
    }

    try {
      var input1 = [_tokenize(text1)];
      var input2 = [_tokenize(text2)];
      
      var output1 = List.filled(1 * 512, 0.0).reshape([1, 512]);
      var output2 = List.filled(1 * 512, 0.0).reshape([1, 512]);

      _interpreter!.run(input1, output1);
      _interpreter!.run(input2, output2);

      return _cosineSimilarity(output1[0], output2[0]);
    } catch (e) {
      return _fallbackSimilarity(text1, text2);
    }
  }

  double _cosineSimilarity(List<dynamic> v1, List<dynamic> v2) {
    double dotProduct = 0.0;
    double normA = 0.0;
    double normB = 0.0;
    for (int i = 0; i < v1.length; i++) {
      dotProduct += v1[i] * v2[i];
      normA += pow(v1[i], 2);
      normB += pow(v2[i], 2);
    }
    double result = dotProduct / (sqrt(normA) * sqrt(normB));
    return result.isNaN ? 0.0 : result;
  }

  double _fallbackSimilarity(String s1, String text2) {
    final set1 = s1.toLowerCase().split(' ').toSet();
    final set2 = text2.toLowerCase().split(' ').toSet();
    final intersection = set1.intersection(set2);
    final union = set1.union(set2);
    return intersection.length / union.length;
  }

  Future<double> evaluateShortAnswer(String studentAnswer, String correctAnswer) async {
    // 1. Keyword match (40%)
    final kwScore = _calculateKeywordMatch(studentAnswer, correctAnswer);
    
    // 2. Semantic Similarity (60%)
    final semanticScore = await calculateSemanticSimilarity(studentAnswer, correctAnswer);
    
    final finalScore = (kwScore * 0.4) + (semanticScore * 0.6);
    return finalScore;
  }

  double _calculateKeywordMatch(String student, String correct) {
    final studentWords = student.toLowerCase().split(RegExp(r'\s+')).toSet();
    final correctWords = correct.toLowerCase().split(RegExp(r'\s+')).toSet();
    
    // Filter common words (stop words) for better keyword matching
    final stopWords = {'the', 'is', 'at', 'which', 'on', 'and', 'a', 'an', 'to', 'of', 'in'};
    final importantCorrectWords = correctWords.difference(stopWords).where((w) => w.length > 2).toSet();
    
    if (importantCorrectWords.isEmpty) return 1.0;
    
    final intersection = studentWords.intersection(importantCorrectWords);
    return (intersection.length / importantCorrectWords.length);
  }
}
