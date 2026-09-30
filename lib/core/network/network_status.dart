import 'package:connectivity_plus/connectivity_plus.dart';

/// Whether the device has a network, and when it comes back (auth spec
/// §6). A hint only: a call can still fail offline, and that is handled
/// where it fails.
abstract interface class NetworkStatus {
  Future<bool> get isOnline;

  Stream<void> get reconnects;
}

class ConnectivityNetworkStatus implements NetworkStatus {
  ConnectivityNetworkStatus([Connectivity? connectivity])
    : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  @override
  Future<bool> get isOnline async => (await _connectivity.checkConnectivity())
      .any((result) => result != ConnectivityResult.none);

  @override
  Stream<void> get reconnects => _connectivity.onConnectivityChanged
      .where((results) => !results.contains(ConnectivityResult.none))
      .map((_) {});
}
