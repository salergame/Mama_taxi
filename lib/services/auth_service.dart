import 'dart:async';

class AuthService {
  bool _isDemoMode = true;

  // Метод для верификации номера телефона
  Future<void> verifyPhoneNumber(
    String phoneNumber,
    Function(String) onCodeSent,
    Function(String) onError,
  ) async {
    try {
      // В демо режиме просто возвращаем тестовый верификационный ID
      await Future.delayed(const Duration(seconds: 1));
      onCodeSent('demo-verification-id');
    } catch (e) {
      onError(e.toString());
    }
  }

  // Метод для подтверждения OTP кода
  Future<bool> verifyOtp(String verificationId, String smsCode) async {
    // В демо режиме принимаем любой код
    await Future.delayed(const Duration(seconds: 1));
    return true;
  }

  // Метод для выхода из системы
  Future<void> signOut() async {
    // Ничего не делаем, просто симулируем успешный выход
    await Future.delayed(const Duration(milliseconds: 500));
  }

  // Метод для проверки состояния авторизации
  Future<bool> isUserAuthenticated() async {
    // В демо режиме всегда считаем что пользователь не авторизован,
    // чтобы показать процесс авторизации
    return false;
  }

  // Включить демо-режим
  void setDemoMode(bool enabled) {
    _isDemoMode = enabled;
  }

  // Получить текущего пользователя
  dynamic getCurrentUser() {
    // В демо режиме возвращаем тестовый объект пользователя
    return {'uid': 'demo-user-id', 'phoneNumber': '+7 (999) 999-99-99'};
  }
}
