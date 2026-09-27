import 'package:flutter/foundation.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

import 'ml_service_base.dart';

/// Native (io) implementation of the ML service.
///
/// Loads a TensorFlow Lite sentence encoder via `tflite_flutter`.
class IOMLService extends MLService {
  Interpreter? _interpreter;

  @override
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

  @override
  Future<double> calculateSemanticSimilarity(String text1, String text2) async {
    if (_interpreter == null) {
      // Fallback: String overlap if model is missing
      return fallbackSimilarity(text1, text2);
    }

    try {
      var input1 = [tokenize(text1)];
      var input2 = [tokenize(text2)];

      var output1 = List.filled(1 * 512, 0.0).reshape([1, 512]);
      var output2 = List.filled(1 * 512, 0.0).reshape([1, 512]);

      _interpreter!.run(input1, output1);
      _interpreter!.run(input2, output2);

      return cosineSimilarity(output1[0], output2[0]);
    } catch (e) {
      return fallbackSimilarity(text1, text2);
    }
  }
}
