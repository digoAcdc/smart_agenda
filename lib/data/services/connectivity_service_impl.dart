import 'package:connectivity_plus/connectivity_plus.dart';

import '../../domain/repositories/i_connectivity_service.dart';

/// Implementacao usando connectivity_plus.
/// Considera online quando ha wifi ou mobile (nao verifica internet real).
class ConnectivityServiceImpl implements IConnectivityService {
  @override
  Future<bool> get isOnline async {
    final result = await Connectivity().checkConnectivity();
    return _hasConnection(result);
  }

  @override
  Stream<bool> get onConnectivityChanged =>
      Connectivity().onConnectivityChanged.map(_hasConnection);

  bool _hasConnection(List<ConnectivityResult> result) {
    if (result.isEmpty) return false;
    return result.any((r) =>
        r == ConnectivityResult.wifi ||
        r == ConnectivityResult.mobile ||
        r == ConnectivityResult.ethernet ||
        r == ConnectivityResult.vpn);
  }
}
