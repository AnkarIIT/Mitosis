import 'ml_service_base.dart';
import 'factory_default.dart'
    if (dart.library.io) 'factory_io.dart'
    if (dart.library.js_interop) 'factory_web.dart';

export 'ml_service_base.dart' show MLService;

/// Public factory for the platform-appropriate ML service.
///
/// - native (io): loads a TensorFlow Lite sentence encoder via `tflite_flutter`.
/// - web (js_interop): no TFLite (unsupported on the web), falls back to
///   string-overlap scoring.
MLService createMLService() => createPlatformMLService();
