// lib/providers/connectivity_provider.dart
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityProvider with ChangeNotifier {
  final Connectivity _connectivity = Connectivity();
  List<ConnectivityResult> _connectivityResults = [ConnectivityResult.none];

  List<ConnectivityResult> get connectivityResults => _connectivityResults;
  bool get isOnline => !_connectivityResults
      .every((result) => result == ConnectivityResult.none);

  ConnectivityProvider() {
    _initConnectivity();
    _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
  }

  Future<void> _initConnectivity() async {
    try {
      final result = await _connectivity.checkConnectivity();
      _updateConnectionStatus(result);
    } catch (e) {
      debugPrint('Error checking connectivity: $e');
    }
  }

  void _updateConnectionStatus(List<ConnectivityResult> results) {
    _connectivityResults = results;
    notifyListeners();
  }

  Future<void> checkConnectivity() async {
    await _initConnectivity();
  }
}
