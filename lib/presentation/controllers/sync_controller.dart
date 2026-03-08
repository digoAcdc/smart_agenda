import 'dart:async';

import 'package:get/get.dart';

import '../../core/config/supabase_config.dart';
import '../../domain/repositories/i_connectivity_service.dart';
import '../../domain/repositories/i_sync_service.dart';

/// Dispara sync ao iniciar app e quando conectividade retorna.
class SyncController extends GetxController {
  SyncController(this._connectivity, this._syncService);

  final IConnectivityService _connectivity;
  final ISyncService _syncService;

  StreamSubscription<bool>? _connectivitySub;

  @override
  void onInit() {
    super.onInit();
    if (!SupabaseConfig.isConfigured) return;
    _connectivitySub = _connectivity.onConnectivityChanged.listen((online) {
      if (online) _syncService.syncNow();
    });
    _syncService.syncNow();
  }

  @override
  void onClose() {
    _connectivitySub?.cancel();
    super.onClose();
  }
}
