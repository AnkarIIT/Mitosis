import 'dart:async';
import 'package:internet_connection_checker/internet_connection_checker.dart';

/// Monitors connectivity and exposes a broadcast stream.
class ConnectivityService {
  ConnectivityService._();
  static final ConnectivityService instance = ConnectivityService._();

  final _controller = StreamController<bool>.broadcast();
  bool _isOnline = false;

  Stream<bool> get connectivityStream => _controller.stream;
  bool get isOnline => _isOnline;

  Future<void> init() async {
    _isOnline = await InternetConnectionChecker().hasConnection;
    _controller.add(_isOnline);

    InternetConnectionChecker().onStatusChange.listen((status) {
      _isOnline = status == InternetConnectionStatus.connected;
      _controller.add(_isOnline);
    });
  }

  void dispose() {
    _controller.close();
  }
}
