import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/repositories/i_auth_service.dart';
import '../../domain/repositories/i_plan_service.dart';

/// Implementacao do PlanService: verifica allow list no Supabase.
/// Sem Supabase ou sem auth, retorna free.
class PlanServiceImpl extends GetxController implements IPlanService {
  PlanServiceImpl(this._authService, this._client);

  final IAuthService _authService;
  final SupabaseClient? _client;

  final RxBool _isLoading = false.obs;
  final RxnString _error = RxnString();
  bool? _cachedPremium;
  String? _cachedUserId;

  @override
  bool get isLoading => _isLoading.value;

  @override
  String? get error => _error.value;

  @override
  Future<bool> isPremium() async {
    if (_client == null) {
      debugPrint('[PlanService] Supabase nao configurado -> free');
      return false;
    }

    final authResult = await _authService.getCurrentUser();
    if (!authResult.isSuccess || authResult.data == null) {
      _cachedPremium = false;
      debugPrint('[PlanService] Usuario nao autenticado -> free');
      return false;
    }

    final user = authResult.data!;
    if (_cachedPremium != null && _cachedUserId == user.id) {
      return _cachedPremium!;
    }

    _isLoading.value = true;
    _error.value = null;
    try {
      // 1. Consultar assinatura validada (fonte oficial)
      final subResult = await _client.rpc('get_subscription_premium_status');
      final subList = subResult as List?;
      if (subList != null && subList.isNotEmpty) {
        final row = subList.first as Map<String, dynamic>;
        final isPremiumFromSub = row['is_premium'] as bool? ?? false;
        if (isPremiumFromSub) {
          _cachedPremium = true;
          _cachedUserId = user.id;
          debugPrint('[PlanService] subscription active -> premium');
          return true;
        }
      }

      // 2. TEMPORÁRIO: fallback allow list para dev/admin
      // Nao filtrar por email aqui: a RLS so expoe linhas em que
      // LOWER(email) = LOWER(jwt email). Um .eq('email', ...) falha se a
      // capitalizacao no banco nao bater exatamente com o filtro.
      final response = await _client
          .from('premium_allowlist')
          .select('id')
          .eq('is_active', true)
          .maybeSingle();

      final isPremium = response != null;
      _cachedPremium = isPremium;
      _cachedUserId = user.id;
      debugPrint('[PlanService] email=${user.email} -> ${isPremium ? "premium (allowlist)" : "free"}');
      return isPremium;
    } catch (e) {
      debugPrint('[PlanService] Erro ao verificar allow list: $e');
      _error.value = 'Erro ao verificar status premium.';
      _cachedPremium = false;
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  @override
  Future<void> refresh() async {
    _cachedPremium = null;
    _cachedUserId = null;
    await isPremium();
  }
}
