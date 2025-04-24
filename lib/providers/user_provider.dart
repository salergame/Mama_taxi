import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mama_taxi/models/user_model.dart';
import 'package:mama_taxi/models/child_model.dart';
import 'package:mama_taxi/services/firebase_service.dart';
import 'package:flutter/material.dart';
import 'package:mama_taxi/services/auth_service.dart';

class UserProvider extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  Map<String, dynamic>? _userData;
  bool _isLoading = false;
  List<ChildModel> _children = [];

  bool get isLoading => _isLoading;
  List<ChildModel> get children => _children;

  /// Геттер для получения объекта UserModel
  UserModel? get user {
    if (_userData == null) return null;
    return UserModel.fromJson(_userData!);
  }

  Future<Map<String, dynamic>?> get userData async {
    if (_userData == null) {
      await _loadUserData();
    }
    return _userData;
  }

  /// Инициализация данных пользователя
  Future<void> initUser() async {
    await _loadUserData();
    await loadChildren();
  }

  Future<void> _loadUserData() async {
    _isLoading = true;
    notifyListeners();

    try {
      final data = await _firebaseService.getUserData();
      _userData = data;
    } catch (e) {
      print('Ошибка при загрузке данных пользователя: $e');
      // Для демо режима возвращаем тестовые данные
      _userData = {
        'id': 'test_id',
        'name': 'test',
        'surname': 'test',
        'phone': '+7 747 048 0557',
        'email': 'test@example.com',
        'birthDate': '01.01.1990',
        'gender': 'Мужской',
        'city': 'Москва',
        'rating': 4.92,
        'isVerified': true,
        'createdAt': DateTime.now().toString(),
      };
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Загрузка списка детей пользователя
  Future<void> loadChildren() async {
    _isLoading = true;
    notifyListeners();

    try {
      final childrenList = await _firebaseService.getChildren();
      _children = childrenList;
    } catch (e) {
      print('Ошибка при загрузке списка детей: $e');
      _children = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Добавление нового ребенка
  Future<bool> addChild(ChildModel child) async {
    _isLoading = true;
    notifyListeners();

    try {
      final childId = await _firebaseService.addChild(child);
      if (childId != null) {
        final updatedChild = child.copyWith(id: childId);
        _children.add(updatedChild);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      print('Ошибка при добавлении ребенка: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Обновление данных ребенка
  Future<bool> updateChild(ChildModel child) async {
    _isLoading = true;
    notifyListeners();

    try {
      final success = await _firebaseService.updateChild(child);
      if (success) {
        final index = _children.indexWhere((c) => c.id == child.id);
        if (index >= 0) {
          _children[index] = child;
          notifyListeners();
        }
        return true;
      }
      return false;
    } catch (e) {
      print('Ошибка при обновлении данных ребенка: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Удаление ребенка
  Future<bool> deleteChild(String childId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final success = await _firebaseService.deleteChild(childId);
      if (success) {
        _children.removeWhere((child) => child.id == childId);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      print('Ошибка при удалении ребенка: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Обновление профиля пользователя
  Future<void> updateProfile({
    required String name,
    required String surname,
    required String email,
    required String birthday,
    required String gender,
    required String city,
    String? phone,
  }) async {
    await updateUserData({
      'name': name,
      'surname': surname,
      'email': email,
      'birthDate': birthday,
      'gender': gender,
      'city': city,
      'phone': phone,
      'isProfileCompleted': true,
    });
  }

  Future<bool> updateUserData(Map<String, dynamic> userData) async {
    try {
      await _firebaseService.updateUserData(userData);

      // Обновляем текущие данные пользователя
      if (_userData != null) {
        _userData!.addAll(userData);
      } else {
        _userData = userData;
      }

      notifyListeners();
      return true;
    } catch (e) {
      print('Error updating user data: $e');
      return false;
    }
  }

  // Метод для очистки данных пользователя при выходе из аккаунта
  Future<void> clearUserData() async {
    // Очищаем все данные пользователя
    _userData = null;
    _children = [];
    _isLoading = false;
    notifyListeners();
  }

  // Получить email пользователя
  Future<String?> getUserEmail() async {
    return await _firebaseService.getCurrentUserEmail();
  }

  // Обновить email пользователя
  Future<bool> updateUserEmail(String newEmail) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Обновляем в Firebase Auth
      final authService = AuthService();
      await authService.updateEmail(newEmail);

      // Обновляем в Firestore
      await updateUserData({'email': newEmail});
      return true;
    } catch (e) {
      print('Ошибка при обновлении email пользователя: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Обновить пароль пользователя
  Future<bool> updateUserPassword(String newPassword) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Обновляем в Firebase Auth
      final authService = AuthService();
      await authService.updatePassword(newPassword);
      return true;
    } catch (e) {
      print('Ошибка при обновлении пароля пользователя: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshUserData() async {
    await _loadUserData();
    await loadChildren();
  }
}
