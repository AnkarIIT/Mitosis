import 'ml_service_base.dart';

/// Fallback ML service used only when neither `dart.library.io` nor
/// `dart.library.js_interop` is available. Normal Flutter targets always
/// resolve to `factory_io.dart` or `factory_web.dart`.
class DefaultMLService extends MLService {}

MLService createPlatformMLService() => DefaultMLService();
