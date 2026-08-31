import 'ml_service_base.dart';

/// Web implementation of the ML service.
///
/// TensorFlow Lite (`tflite_flutter`) is not available on the web (it depends
/// on `dart:ffi`), so this implementation uses the string-overlap fallback for
/// semantic similarity. It keeps the web build compiling and the app usable.
class WebMLService extends MLService {}
