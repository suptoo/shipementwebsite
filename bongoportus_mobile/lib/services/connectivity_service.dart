import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Reactive connectivity monitor.
/// Exposes a [ValueNotifier<bool>] that widgets can listen to for online/offline state.
class ConnectivityService {
  static ConnectivityService? _instance;
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<ConnectivityResult> _subscription;

  /// Current online status as a reactive notifier
  final ValueNotifier<bool> isOnline = ValueNotifier(true);

  ConnectivityService._() {
    _init();
  }

  static ConnectivityService get instance {
    _instance ??= ConnectivityService._();
    return _instance!;
  }

  void _init() {
    // Check initial state
    _connectivity.checkConnectivity().then((result) {
      isOnline.value = _hasConnection(result);
    });

    // Listen for changes
    _subscription = _connectivity.onConnectivityChanged.listen((result) {
      isOnline.value = _hasConnection(result);
    });
  }

  bool _hasConnection(ConnectivityResult result) {
    return result == ConnectivityResult.wifi ||
        result == ConnectivityResult.mobile ||
        result == ConnectivityResult.ethernet;
  }

  void dispose() {
    _subscription.cancel();
    isOnline.dispose();
  }
}
