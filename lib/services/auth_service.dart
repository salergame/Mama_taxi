import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';
import 'package:mama_taxi/services/firebase_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mama_taxi/models/user_model.dart';

class AuthService {
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;
  final FirebaseService _firebaseService = FirebaseService();
  late SharedPreferences _prefs;
  UserModel? _currentUser;
  bool _isDemoMode = false; // Отключаем демо-режим для реальной аутентификации
  final String _demoUserId = 'demo_user_id';

  // Конструктор с инициализацией SharedPreferences
  AuthService() {
    _initSharedPreferences();
  }

  Future<void> _initSharedPreferences() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Метод для регистрации пользователя по email и паролю
  Future<bool> registerWithEmailAndPassword(String email, String password,
      {bool isDriver = false}) async {
    debugPrint(
        'Регистрация с email: $email, тип пользователя: ${isDriver ? 'Водитель' : 'Пассажир'}');

    try {
      // В демо-режиме возвращаем фейкового пользователя
      if (_isDemoMode) {
        final demoUser = UserModel(
          id: _demoUserId,
          email: email,
          name: 'Демо',
          surname: 'Пользователь',
          phone: '+7 999 123 45 67',
        );
        _currentUser = demoUser;
        await _saveUserLocally(demoUser);
        return true;
      }

      // Создаем пользователя в Firebase Auth
      final firebaseUser = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (firebaseUser.user != null) {
        final userId = firebaseUser.user!.uid;

        // Сохраняем статус водителя в SharedPreferences
        await _prefs.setBool('is_driver', isDriver);
        await _prefs.setString('user_id', userId);
        await _prefs.setString('user_email', email);

        // Инициализируем данные пользователя в Firestore
        await _firebaseService
            .initUserData(userId, email, userData: {'isDriver': isDriver});

        // Создаем объект пользователя
        final user = UserModel(
          id: userId,
          email: email,
          name: '',
          surname: '',
          phone: '',
        );

        _currentUser = user;
        await _saveUserLocally(user);

        // Возвращаем успех
        return true;
      }
      return false;
    } on firebase_auth.FirebaseAuthException catch (e) {
      debugPrint('Ошибка при регистрации: ${e.code} - ${e.message}');
      throw _getLocalizedAuthError(e.code);
    } catch (e) {
      debugPrint('Неизвестная ошибка при регистрации: $e');
      throw ('Произошла неизвестная ошибка при регистрации. Пожалуйста, попробуйте позже.');
    }
  }

  // Метод для входа по email и паролю
  Future<bool> signInWithEmailAndPassword(String email, String password) async {
    debugPrint('Вход с email: $email');

    try {
      // В демо-режиме возвращаем фейкового пользователя
      if (_isDemoMode) {
        final demoUser = UserModel(
          id: _demoUserId,
          email: email,
          name: 'Демо',
          surname: 'Пользователь',
          phone: '+7 999 123 45 67',
        );
        _currentUser = demoUser;
        await _saveUserLocally(demoUser);
        return true;
      }

      // Получаем пользователя из Firebase Auth
      final firebaseUser = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (firebaseUser.user != null) {
        final userId = firebaseUser.user!.uid;

        // Получаем данные пользователя из Firestore
        final userData = await _firebaseService.getUserData();

        // Сохраняем статус водителя в SharedPreferences
        await _prefs.setBool('is_driver', userData?['isDriver'] ?? false);
        await _prefs.setString('user_id', userId);
        await _prefs.setString('user_email', email);

        // Создаем объект пользователя
        final user = UserModel(
          id: userId,
          email: email,
          name: userData?['name'] ?? '',
          surname: userData?['surname'] ?? '',
          phone: userData?['phone'] ?? '',
        );

        _currentUser = user;
        await _saveUserLocally(user);

        // Возвращаем успех
        return true;
      }
      return false;
    } on firebase_auth.FirebaseAuthException catch (e) {
      debugPrint('Ошибка при входе: ${e.code} - ${e.message}');
      throw _getLocalizedAuthError(e.code);
    } catch (e) {
      debugPrint('Неизвестная ошибка при входе: $e');
      throw ('Произошла неизвестная ошибка при входе. Пожалуйста, попробуйте позже.');
    }
  }

  // Получить тип пользователя (водитель или пассажир)
  Future<bool> isUserDriver() async {
    return _prefs.getBool('is_driver') ?? false;
  }

  // Метод для восстановления пароля
  Future<bool> resetPassword(String email) async {
    debugPrint('AuthService: сброс пароля для $email');

    try {
      await _auth.sendPasswordResetEmail(email: email);
      return true;
    } on firebase_auth.FirebaseAuthException catch (e) {
      String errorMessage = 'Произошла ошибка при сбросе пароля';

      if (e.code == 'user-not-found') {
        errorMessage = 'Пользователь с таким email не найден';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'Неверный формат email';
      }

      debugPrint('Ошибка сброса пароля: $errorMessage (${e.code})');
      throw errorMessage;
    } catch (e) {
      debugPrint('Непредвиденная ошибка при сбросе пароля: $e');
      throw 'Произошла непредвиденная ошибка при сбросе пароля';
    }
  }

  // Проверка статуса аутентификации
  Future<bool> isUserAuthenticated() async {
    // Проверяем статус аутентификации
    final user = _auth.currentUser;
    if (_isDemoMode) {
      final userId = _prefs.getString('user_id');
      return userId != null && userId.isNotEmpty;
    }

    if (user != null) {
      // Получаем сохраненный ID пользователя
      final savedUserId = _prefs.getString('user_id');

      // Проверяем, что ID пользователя совпадает с сохраненным
      return savedUserId != null && savedUserId == user.uid;
    }

    return false;
  }

  // Метод для выхода из системы
  Future<void> signOut() async {
    debugPrint('Выход из аккаунта');
    try {
      // В демо-режиме просто очищаем локальные данные
      if (_isDemoMode) {
        await _clearUserData();
        return;
      }

      // Выход из Firebase Auth
      await _auth.signOut();

      // Очистка локальных данных
      await _clearUserData();
    } catch (e) {
      debugPrint('Ошибка при выходе из аккаунта: $e');
      throw ('Произошла ошибка при выходе из аккаунта. Пожалуйста, попробуйте позже.');
    }
  }

  // Получить текущего пользователя
  UserModel? getCurrentUser() {
    return _currentUser;
  }

  // Получить email текущего пользователя
  String? getCurrentUserEmail() {
    return _auth.currentUser?.email;
  }

  // Получить ID текущего пользователя
  Future<String?> getCurrentUserId() async {
    return _auth.currentUser?.uid ?? _prefs.getString('user_id');
  }

  // Получить данные текущего пользователя
  Future<Map<String, dynamic>?> getUserData() async {
    return await _firebaseService.getUserData();
  }

  // Обновить данные пользователя
  Future<bool> updateUserData(Map<String, dynamic> userData) async {
    final result = await _firebaseService.updateUserData(userData);
    return result != null;
  }

  // Обновить email пользователя
  Future<bool> updateEmail(String newEmail) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await user.updateEmail(newEmail);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Ошибка обновления email: $e');
      return false;
    }
  }

  // Обновить пароль пользователя
  Future<bool> updatePassword(String newPassword) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await user.updatePassword(newPassword);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Ошибка обновления пароля: $e');
      return false;
    }
  }

  // Сохранение данных пользователя локально
  Future<void> _saveUserLocally(UserModel user) async {
    await _prefs.setString('user_id', user.id ?? '');
    await _prefs.setString('user_email', user.email ?? '');
    await _prefs.setString('user_name', user.name ?? '');
    await _prefs.setString('user_surname', user.surname ?? '');
    await _prefs.setString('user_phone', user.phone ?? '');
  }

  // Очистка локальных данных пользователя
  Future<void> _clearUserData() async {
    _currentUser = null;
    await _prefs.remove('user_id');
    await _prefs.remove('user_email');
    await _prefs.remove('user_name');
    await _prefs.remove('user_surname');
    await _prefs.remove('user_phone');
    await _prefs.remove('is_driver');
  }

  // Локализация ошибок авторизации
  String _getLocalizedAuthError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'Пользователь с таким email не найден';
      case 'wrong-password':
        return 'Неверный пароль';
      case 'invalid-email':
        return 'Неверный формат email';
      case 'email-already-in-use':
        return 'Этот email уже используется другим пользователем';
      case 'weak-password':
        return 'Слишком простой пароль. Используйте как минимум 6 символов';
      case 'user-disabled':
        return 'Этот аккаунт отключен. Обратитесь в службу поддержки';
      case 'too-many-requests':
        return 'Слишком много попыток входа. Попробуйте позже';
      case 'operation-not-allowed':
        return 'Операция не разрешена. Обратитесь в службу поддержки';
      default:
        return 'Произошла ошибка авторизации. Пожалуйста, попробуйте позже';
    }
  }
}
