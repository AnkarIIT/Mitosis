import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Sidebar visibility state provider
/// Default: false on mobile, true on desktop (handled by responsive logic)
final sidebarVisibilityProvider = StateProvider<bool>((ref) => false);

/// Sidebar width provider - responsive
/// Desktop: 280, Mobile: full width (bottom sheet)
final sidebarWidthProvider = Provider<double>((ref) {
  // This will be overridden by responsive logic in the UI
  return 280.0;
});

/// Current breakpoint provider for responsive design
final breakpointProvider = StateProvider<Breakpoint>((ref) => Breakpoint.mobile);

enum Breakpoint {
  mobile,
  tablet,
  desktop,
}

extension BreakpointX on Breakpoint {
  bool get isMobile => this == Breakpoint.mobile;
  bool get isTablet => this == Breakpoint.tablet;
  bool get isDesktop => this == Breakpoint.desktop;
}