import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mama_taxi/services/firebase_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mama_taxi/models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseService _firebaseService = FirebaseService();
  SharedPreferences? _prefs;
  UserModel? _currentUser;

  // Ключи для SharedPreferences
  static const String _isAuthenticatedKey = 'is_authenticated';
  static const String _isDriverKey = 'is_driver';
  static const String _userIdKey = 'user_id';

  AuthService() {
    _initPrefs();
  }

  // Инициализация SharedPreferences
  Future<void> _initPrefs() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Метод для регистрации пользователя по email и паролю
  Future<bool> registerWithEmailAndPassword(String email, String password,
      {bool isDriver = false}) async {
    debugPrint(
        'Регистрация ${isDriver ? "водителя" : "пассажира"} с email: $email');

    try {
      // Создаем пользователя в Firebase Auth
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        final userId = userCredential.user!.uid;

        // Сохраняем статус авторизации и тип пользователя
        await _prefs?.setBool(_isAuthenticatedKey, true);
        await _prefs?.setBool(_isDriverKey, isDriver);
        await _prefs?.setString(_userIdKey, userId);

        // Инициализируем данные пользователя в Firestore
        await _firebaseService
            .initUserData(userId, email, userData: {'isDriver': isDriver});

        return true;
      }
      return false;
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Произошла ошибка при регистрации';

      if (e.code == 'weak-password') {
        errorMessage = 'Пароль слишком слабый';
      } else if (e.code == 'email-already-in-use') {
        errorMessage = 'Пользователь с таким email уже существует';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'Неверный формат email';
      }

      debugPrint('Ошибка регистрации: $errorMessage (${e.code})');
      throw errorMessage;
    } catch (e) {
      debugPrint('Непредвиденная ошибка при регистрации: $e');
      throw 'Произошла непредвиденная ошибка при регистрации';
    }
  }

  // Метод для входа по email и паролю
  Future<bool> signInWithEmailAndPassword(String email, String password) async {
    debugPrint('Вход пользователя с email: $email');

    try {
      // Входим с учетными данными
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Если пользователь успешно вошел
      if (userCredential.user != null) {
        final userId = userCredential.user!.uid;

        // Сохраняем статус авторизации
        await _prefs?.setBool(_isAuthenticatedKey, true);
        await _prefs?.setString(_userIdKey, userId);

        // Получаем данные пользователя и проверяем, является ли он водителем
        final userData = await _firebaseService.getUserData();
        final isDriver = userData?['isDriver'] == true;
        await _prefs?.setBool(_isDriverKey, isDriver);

        return true;
      }
      return false;
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Произошла ошибка при входе';

      if (e.code == 'user-not-found' || e.code == 'wrong-password') {
        errorMessage = 'Неверный email или пароль';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'Неверный формат email';
      } else if (e.code == 'user-disabled') {
        errorMessage = 'Пользователь заблокирован';
      }

      debugPrint('Ошибка входа: $errorMessage (${e.code})');
      throw errorMessage;
    } catch (e) {
      debugPrint('Непредвиденная ошибка при входе: $e');
      throw 'Произошла непредвиденная ошибка при входе';
    }
  }

  // Проверка, является ли пользователь водителем
  Future<bool> isUserDriver() async {
    await _initPrefsIfNeeded();
    return _prefs?.getBool(_isDriverKey) ?? false;
  }

  // Проверка статуса аутентификации
  Future<bool> isUserAuthenticated() async {
    await _initPrefsIfNeeded();

    // Проверяем сначала локальное хранилище для поддержки сессии
    final savedAuth = _prefs?.getBool(_isAuthenticatedKey) ?? false;

    if (savedAuth) {
      debugPrint('Восстановлена предыдущая сессия из SharedPreferences');
      return true;
    }

    // Если в локальном хранилище нет данных, проверяем Firebase
    final isAuthenticated = _auth.currentUser != null;

    // Если пользователь аутентифицирован, сохраняем это в SharedPreferences
    if (isAuthenticated) {
      await _prefs?.setBool(_isAuthenticatedKey, true);
    }

    return isAuthenticated;
  }

  // Инициализация SharedPreferences при необходимости
  Future<void> _initPrefsIfNeeded() async {
    if (_prefs == null) {
      await _initPrefs();
    }
  }

  // Метод для выхода из системы
  Future<void> signOut() async {
    // Очищаем локальное хранилище при выходе
    await _initPrefsIfNeeded();
    await _prefs?.setBool(_isAuthenticatedKey, false);
    await _prefs?.setBool(_isDriverKey, false);
    await _prefs?.remove(_userIdKey);

    // Выходим из Firebase
    await _auth.signOut();
  }

  // Получить текущего пользователя Firebase
  User? getCurrentFirebaseUser() {
    return _auth.currentUser;
  }

  // Получить ID текущего пользователя
  Future<String?> getCurrentUserId() async {
    await _initPrefsIfNeeded();
    return _prefs?.getString(_userIdKey) ?? _auth.currentUser?.uid;
  }
}
 