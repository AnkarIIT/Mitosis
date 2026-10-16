import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_providers.dart';

/// Local owner for user-scoped data. Guests use a dedicated negative owner
/// rather than sharing the legacy magic id 0 with real accounts.
const guestOwnerId = -1;

final currentLocalUserIdProvider = Provider<int?>((ref) {
  final auth = ref.watch(authProvider);
  if (auth.user != null) return auth.user!.id;
  if (auth.isGuest) return guestOwnerId;
  return null;
});
