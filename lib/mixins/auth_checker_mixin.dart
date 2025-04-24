import 'package:flutter/material.dart';
import 'package:mama_taxi/services/firebase_service.dart';

/// Миксин для проверки авторизации пользователя
/// Используется для экранов, которые требуют авторизации
mixin AuthCheckerMixin<T extends StatefulWidget> on State<T> {
  final FirebaseService _firebaseService = FirebaseService();

  /// Проверяет, авторизован ли пользователь
  /// Если нет, перенаправляет на экран авторизации
  Future<bool> checkAuth() async {
    print('ОТЛАДКА: Проверка авторизации для экрана ${widget.runtimeType}');
    final isAuthenticated = await _firebaseService.isUserAuthenticated();
    print('ОТЛАДКА: Статус авторизации: $isAuthenticated');

    if (!isAuthenticated && mounted) {
      print(
          'ОТЛАДКА: Пользователь не авторизован, перенаправление на экран авторизации');
      // Если пользователь не авторизован, перенаправляем на экран авторизации
      Navigator.of(context).pushReplacementNamed('/auth');
      return false;
    }

    print('ОТЛАДКА: Пользователь авторизован, продолжение работы');
    return true;
  }
}
