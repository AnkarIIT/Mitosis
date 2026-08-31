import 'dart:async';
import 'package:internet_connection_checker/internet_connection_checker.dart';

/// Monitors connectivity and exposes a broadcast stream.
class ConnectivityService {
  ConnectivityService._();
  static final ConnectivityService instance = ConnectivityService._();

  final _controller = StreamController<bool>.broadcast();
  bool _isOnline = false;
  StreamSubscription<InternetConnectionStatus>? _statusSubscription;
  bool _skipNetworkCheck = false;

  Stream<bool> get connectivityStream => _controller.stream;
  bool get isOnline => _isOnline;

  void setSkipNetworkCheck(bool skip) {
    _skipNetworkCheck = skip;
  }

  Future<void> init() async {
    if (_skipNetworkCheck) {
      _isOnline = true;
      _controller.add(_isOnline);
      return;
    }

    _isOnline = await InternetConnectionChecker().hasConnection;
    _controller.add(_isOnline);

    _statusSubscription = InternetConnectionChecker().onStatusChange.listen((
      status,
    ) {
      _isOnline = status == InternetConnectionStatus.connected;
      _controller.add(_isOnline);
    });
  }

  void dispose() {
    _statusSubscription?.cancel();
    _statusSubscription = null;
    _controller.close();
  }
}
