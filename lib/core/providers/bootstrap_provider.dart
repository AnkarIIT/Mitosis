import 'package:flutter_riverpod/flutter_riverpod.dart';

enum BootstrapStatus {
  initializing,
  readyOffline,
  readyWithCloud,
  cloudUnavailable,
}

final bootstrapStatusProvider = StateProvider<BootstrapStatus>(
  (ref) => BootstrapStatus.initializing,
);
