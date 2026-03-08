import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/repositories/i_auth_service.dart';

const _keyRememberMe = 'auth_remember_me';
const _keyRememberEmail = 'auth_remember_email';

class AuthController extends GetxController {
  AuthController(this._authService);

  final IAuthService _authService;

  final RxBool loading = false.obs;
  final RxnString errorMessage = RxnString();
  final RxBool isLoggedIn = false.obs;
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
    }
  }

  Future<bool> login(String email, String password) async {
    loading.value = true;
    errorMessage.value = null;
    try {
      final result = await _authService.signInWithEmail(email, password);
      if (result.isSuccess) {
        isLoggedIn.value = true;
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

  Future<void> signOut() async {
    await _authService.signOut();
    isLoggedIn.value = false;
  }

  Future<void> setRememberMe(bool value) async {
    rememberMe.value = value;
    if (!value) rememberedEmail.value = null;
    await _saveRememberMe();
  }
}
