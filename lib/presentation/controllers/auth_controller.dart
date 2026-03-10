import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/supabase_config.dart';
import '../../core/services/firebase_service.dart';
import '../../data/datasources/fcm_token_supabase_datasource.dart';
import '../../domain/repositories/i_auth_service.dart';
import '../../domain/repositories/i_local_to_cloud_migration_service.dart';
import '../../domain/repositories/i_sync_service.dart';
import '../../domain/repositories/i_plan_service.dart';
import '../../domain/repositories/i_premium_service.dart';

const _keyRememberMe = 'auth_remember_me';
const _keyRememberEmail = 'auth_remember_email';

class AuthController extends GetxController {
  AuthController(this._authService, this._planService);

  final IAuthService _authService;
  final IPlanService _planService;

  final RxBool loading = false.obs;
  final RxnString errorMessage = RxnString();
  final RxBool isLoggedIn = false.obs;
  final RxnString userEmail = RxnString();
  final RxBool isPremium = false.obs;
  final RxBool rememberMe = true.obs;
  final RxnString rememberedEmail = RxnString();

  @override
  void onInit() {
    super.onInit();
    _loadRememberMe();
    _checkAuth();
  }

  Future<void> _loadRememberMe() async {
    final prefs = await SharedPreferences.getInstance();
    rememberMe.value = prefs.getBool(_keyRememberMe) ?? true;
    rememberedEmail.value = prefs.getString(_keyRememberEmail);
  }

  Future<void> _saveRememberMe() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyRememberMe, rememberMe.value);
    if (rememberedEmail.value != null) {
      await prefs.setString(_keyRememberEmail, rememberedEmail.value!);
    } else {
      await prefs.remove(_keyRememberEmail);
    }
  }

  Future<void> _checkAuth() async {
    final result = await _authService.isLoggedIn();
    if (result.isSuccess) {
      isLoggedIn.value = result.data ?? false;
      if (isLoggedIn.value) {
        await _planService.refresh();
        await _runMigrationIfNeeded();
        await _updateUserInfo();
      } else {
        userEmail.value = null;
        isPremium.value = false;
      }
    }
    _refreshPremiumService();
  }

  Future<void> _updateUserInfo() async {
    final authResult = await _authService.getCurrentUser();
    userEmail.value = authResult.data?.email;
    final userId = authResult.data?.id;
    if (userId != null) {
      await FirebaseService.setUserId(userId);
      await _saveFcmTokenIfNeeded(userId);
    }
    isPremium.value = await _planService.isPremium();
    _refreshPremiumService();
  }

  void _refreshPremiumService() {
    if (Get.isRegistered<IPremiumService>()) {
      Get.find<IPremiumService>().refresh();
    }
  }

  Future<void> _saveFcmTokenIfNeeded(String userId) async {
    if (!SupabaseConfig.isConfigured) {
      if (kDebugMode) debugPrint('[FCM] Supabase nao configurado');
      return;
    }
    if (!Get.isRegistered<FcmTokenSupabaseDataSource>()) {
      if (kDebugMode) debugPrint('[FCM] FcmTokenSupabaseDataSource nao registrado');
      return;
    }
    final token = await FirebaseService.getToken();
    if (token == null) {
      if (kDebugMode) debugPrint('[FCM] Token FCM null (Firebase nao init ou permissao negada)');
      return;
    }
    try {
      await Get.find<FcmTokenSupabaseDataSource>().upsertToken(userId, token);
      if (kDebugMode) debugPrint('[FCM] Token salvo no Supabase');
    } catch (e, st) {
      if (kDebugMode) debugPrint('[FCM] Erro ao salvar token: $e\n$st');
    }
  }

  Future<void> _runMigrationIfNeeded() async {
    if (!SupabaseConfig.isConfigured) return;
    if (!Get.isRegistered<ILocalToCloudMigrationService>()) return;
    try {
      await Get.find<ILocalToCloudMigrationService>().migrateIfNeeded();
      await Get.find<ISyncService>().syncNow();
    } catch (_) {}
  }

  Future<bool> login(String email, String password) async {
    loading.value = true;
    errorMessage.value = null;
    try {
      final result = await _authService.signInWithEmail(email, password);
      if (result.isSuccess) {
        isLoggedIn.value = true;
        userEmail.value = email;
        final userResult = await _authService.getCurrentUser();
        if (userResult.data?.id != null) {
          await FirebaseService.setUserId(userResult.data!.id);
          await _saveFcmTokenIfNeeded(userResult.data!.id);
        }
        await _planService.refresh();
        isPremium.value = await _planService.isPremium();
        _refreshPremiumService();
        await _runMigrationIfNeeded();
        if (rememberMe.value) {
          rememberedEmail.value = email;
          await _saveRememberMe();
        } else {
          rememberedEmail.value = null;
          await _saveRememberMe();
        }
        loading.value = false;
        return true;
      }
      errorMessage.value = result.errorMessage ?? 'Erro ao entrar.';
      loading.value = false;
      return false;
    } catch (e) {
      errorMessage.value = 'Erro inesperado. Tente novamente.';
      loading.value = false;
      return false;
    }
  }

  Future<bool> signUp(String email, String password) async {
    loading.value = true;
    errorMessage.value = null;
    try {
      final result = await _authService.signUp(email, password);
      if (result.isSuccess) {
        isLoggedIn.value = true;
        userEmail.value = email;
        final userResult = await _authService.getCurrentUser();
        if (userResult.data?.id != null) {
          await FirebaseService.setUserId(userResult.data!.id);
          await _saveFcmTokenIfNeeded(userResult.data!.id);
        }
        await _planService.refresh();
        isPremium.value = await _planService.isPremium();
        _refreshPremiumService();
        loading.value = false;
        return true;
      }
      errorMessage.value = result.errorMessage ?? 'Erro ao cadastrar.';
      loading.value = false;
      return false;
    } catch (e) {
      errorMessage.value = 'Erro inesperado. Tente novamente.';
      loading.value = false;
      return false;
    }
  }

  Future<bool> resetPassword(String email) async {
    loading.value = true;
    errorMessage.value = null;
    try {
      final result = await _authService.resetPasswordForEmail(email);
      if (result.isSuccess) {
        loading.value = false;
        return true;
      }
      errorMessage.value = result.errorMessage ?? 'Erro ao enviar e-mail.';
      loading.value = false;
      return false;
    } catch (e) {
      errorMessage.value = 'Erro inesperado. Tente novamente.';
      loading.value = false;
      return false;
    }
  }

  Future<bool> verifyRecoveryAndUpdatePassword(
    String email,
    String code,
    String newPassword,
  ) async {
    loading.value = true;
    errorMessage.value = null;
    try {
      final result = await _authService.verifyRecoveryAndUpdatePassword(
        email,
        code,
        newPassword,
      );
      if (result.isSuccess) {
        loading.value = false;
        return true;
      }
      errorMessage.value =
          result.errorMessage ?? 'Erro ao redefinir senha. Tente novamente.';
      loading.value = false;
      return false;
    } catch (e) {
      errorMessage.value = 'Erro inesperado. Tente novamente.';
      loading.value = false;
      return false;
    }
  }

  Future<void> signOut() async {
    final userId = SupabaseConfig.isConfigured
        ? Supabase.instance.client.auth.currentUser?.id
        : null;
    final token = await FirebaseService.getToken();
    if (userId != null &&
        token != null &&
        Get.isRegistered<FcmTokenSupabaseDataSource>()) {
      try {
        await Get.find<FcmTokenSupabaseDataSource>().deleteToken(userId, token);
      } catch (_) {}
    }
    await _authService.signOut();
    await FirebaseService.setUserId(null);
    isLoggedIn.value = false;
    userEmail.value = null;
    isPremium.value = false;
    await _planService.refresh();
    _refreshPremiumService();
  }

  Future<void> setRememberMe(bool value) async {
    rememberMe.value = value;
    if (!value) rememberedEmail.value = null;
    await _saveRememberMe();
  }
}
