import 'dart:async';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mama_taxi/models/child_model.dart';

class FirebaseService {
  // Синглтон для доступа к сервису
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  // Ключи для хранения локальных данных
  static const String _phoneKey = 'phone_number';
  static const String _userIdKey = 'user_id';

  // Флаг для включения демо-режима
  final bool _isDemoMode = false;

  // Ссылки на Firebase сервисы
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Демо данные пользователя для тестирования
  final Map<String, dynamic> _demoUserData = {
    'id': 'demo-user-id',
    'phone': '+7 (999) 999-99-99',
    'name': 'Тест',
    'surname': 'Тест',
    'email': 'test@example.com',
  };

  /// Включение/выключение демо-режима
  void setDemoMode(bool enabled) {
    debugPrint('Демо-режим изменен с $_isDemoMode на $enabled');
  }

  /// Отправка кода верификации на номер телефона
  Future<String?> sendOTP(String phoneNumber) async {
    // Форматируем номер телефона (удаляем пробелы, скобки и т.д.)
    String formattedPhone = phoneNumber.replaceAll(RegExp(r'[\s\(\)\-]'), '');

    // Проверяем что номер начинается с +
    if (!formattedPhone.startsWith('+')) {
      formattedPhone = '+$formattedPhone';
    }

    debugPrint(
        'Отправка OTP на номер: $formattedPhone, демо-режим: $_isDemoMode');

    if (_isDemoMode) {
      // В демо-режиме просто возвращаем фиктивный ID
      await Future.delayed(const Duration(seconds: 1));
      await _savePhoneLocally(formattedPhone);
      return 'demo-verification-id';
    }

    try {
      // Отключаем проверку приложения для тестовых номеров
      // (только на этапе разработки)
      _auth.setSettings(appVerificationDisabledForTesting: true);

      // В реальном режиме отправляем запрос через Firebase
      debugPrint('Отправляем SMS через Firebase Auth на: $formattedPhone');

      Completer<String> verificationIdCompleter = Completer<String>();

      await _auth.verifyPhoneNumber(
        phoneNumber: formattedPhone,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto-verification on Android (не используем, так как нам нужен ручной ввод кода)
          debugPrint('Автоматическая верификация завершена');
        },
        verificationFailed: (FirebaseAuthException e) {
          debugPrint('Ошибка верификации: ${e.message}');
          verificationIdCompleter.completeError(e);
        },
        codeSent: (String verificationId, int? resendToken) {
          debugPrint('Код отправлен, verificationId: $verificationId');
          verificationIdCompleter.complete(verificationId);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          debugPrint('Таймаут автоматического получения кода');
          if (!verificationIdCompleter.isCompleted) {
            verificationIdCompleter.complete(verificationId);
          }
        },
        timeout: const Duration(seconds: 60),
      );

      final verificationId = await verificationIdCompleter.future;
      await _savePhoneLocally(formattedPhone);
      return verificationId;
    } catch (e) {
      debugPrint('Ошибка отправки OTP: $e');
      return null;
    }
  }

  /// Проверка кода верификации
  Future<bool> verifyOTP(String verificationId, String smsCode) async {
    // Проверяем, что в демо-режиме любой код проходит
    if (_isDemoMode) {
      debugPrint('Демо-режим: OTP проверка пропущена, возвращаем true');

      // Сохраняем идентификатор пользователя локально
      final userId = 'demo-user-id-${DateTime.now().millisecondsSinceEpoch}';
      await _saveUserIdLocally(userId);

      return true;
    }

    // Для не-демо режима добавьте реальную логику проверки
    try {
      // Существующая логика, если есть

      // Возвращаем результат успешной проверки
      return false; // Измените на true, когда реализуете проверку
    } catch (e) {
      debugPrint('Ошибка при проверке OTP: $e');
      return false;
    }
  }

  /// Проверка авторизации пользователя
  Future<bool> isUserAuthenticated() async {
    debugPrint('Проверка авторизации, демо-режим: $_isDemoMode');

    if (_isDemoMode) {
      // В демо-режиме проверяем локальное хранилище
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString(_userIdKey);
      return userId != null;
    }

    // В реальном режиме проверяем через Firebase
    final currentUser = _auth.currentUser;
    final isAuthenticated = currentUser != null;
    debugPrint('Статус авторизации: $isAuthenticated');
    return isAuthenticated;
  }

  /// Выход из системы
  Future<void> signOut() async {
    debugPrint('Выход из системы, демо-режим: $_isDemoMode');

    if (_isDemoMode) {
      // В демо-режиме просто очищаем локальное хранилище
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userIdKey);
      await prefs.remove(_phoneKey);
      return;
    }

    // В реальном режиме выходим через Firebase
    try {
      await _auth.signOut();
      debugPrint('Выход выполнен успешно');
    } catch (e) {
      debugPrint('Ошибка при выходе: $e');
    }
  }

  /// Получение ID текущего пользователя
  Future<String?> getCurrentUserId() async {
    if (_isDemoMode) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_userIdKey);
    }

    final userId = _auth.currentUser?.uid;
    return userId;
  }

  /// Получение телефона текущего пользователя
  Future<String?> getCurrentUserPhone() async {
    if (_isDemoMode) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_phoneKey);
    }

    final phone = _auth.currentUser?.phoneNumber;
    return phone;
  }

  /// Получение данных пользователя
  Future<Map<String, dynamic>?> getUserData() async {
    debugPrint('Получение данных пользователя, демо-режим: $_isDemoMode');

    if (_isDemoMode) {
      return _demoUserData;
    }

    try {
      final userId = await getCurrentUserId();
      if (userId == null) {
        debugPrint('Пользователь не авторизован');
        return null;
      }

      final docSnapshot =
          await _firestore.collection('users').doc(userId).get();

      if (docSnapshot.exists) {
        final data = docSnapshot.data();
        debugPrint('Данные пользователя получены: $data');
        return data;
      } else {
        debugPrint('Документ пользователя не найден');
        return null;
      }
    } catch (e) {
      debugPrint('Ошибка получения данных пользователя: $e');
      return null;
    }
  }

  /// Обновление данных пользователя
  Future<Map<String, dynamic>?> updateUserData(
      Map<String, dynamic> userData) async {
    debugPrint(
        'Обновление данных пользователя: $userData, демо-режим: $_isDemoMode');

    if (_isDemoMode) {
      // В демо-режиме обновляем локальные данные
      _demoUserData.addAll(userData);
      return _demoUserData;
    }

    try {
      final userId = await getCurrentUserId();
      if (userId == null) {
        debugPrint('Пользователь не авторизован');
        return null;
      }

      // Добавляем время обновления
      userData['updated_at'] = FieldValue.serverTimestamp();

      await _firestore.collection('users').doc(userId).update(userData);
      debugPrint('Данные пользователя обновлены успешно');

      // Получаем и возвращаем обновленные данные
      return await getUserData();
    } catch (e) {
      debugPrint('Ошибка обновления данных пользователя: $e');
      return null;
    }
  }

  /// Сохранение номера телефона локально
  Future<void> _savePhoneLocally(String phone) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_phoneKey, phone);
    debugPrint('Телефон сохранен локально: $phone');
  }

  /// Сохранение ID пользователя локально
  Future<void> _saveUserIdLocally(String? userId) async {
    if (userId == null) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userIdKey, userId);
    debugPrint('ID пользователя сохранен локально: $userId');
  }

  /// Создание демо-пользователя при необходимости
  Future<void> _createDemoUserIfNeeded() async {
    if (!_isDemoMode) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userIdKey, _demoUserData['id']);
    debugPrint('Демо-пользователь создан');
  }

  /// Создание пользователя в Firebase при необходимости
  Future<void> _createUserIfNeeded() async {
    if (_isDemoMode) return;

    try {
      final userId = await getCurrentUserId();
      final phone = await getCurrentUserPhone();

      if (userId == null || phone == null) {
        debugPrint('Недостаточно данных для создания пользователя');
        return;
      }

      // Проверяем, существует ли пользователь
      final docRef = _firestore.collection('users').doc(userId);
      final doc = await docRef.get();

      if (!doc.exists) {
        // Создаем нового пользователя
        final userData = {
          'id': userId,
          'phone': phone,
          'name': '',
          'surname': '',
          'email': '',
          'created_at': FieldValue.serverTimestamp(),
          'updated_at': FieldValue.serverTimestamp(),
          'last_login': FieldValue.serverTimestamp(),
        };

        await docRef.set(userData);
        debugPrint('Создан новый пользователь с ID: $userId');
      } else {
        // Обновляем время последнего входа
        await docRef.update({
          'last_login': FieldValue.serverTimestamp(),
        });
        debugPrint(
            'Обновлено время последнего входа для пользователя: $userId');
      }
    } catch (e) {
      debugPrint('Ошибка при создании/обновлении пользователя: $e');
    }
  }

  /// Инициализация данных пользователя при регистрации через email
  Future<void> initUserData(String userId, String email,
      {Map<String, dynamic>? userData}) async {
    if (_isDemoMode) return;

    try {
      // Проверяем, существует ли пользователь
      final docRef = _firestore.collection('users').doc(userId);
      final doc = await docRef.get();

      if (!doc.exists) {
        // Создаем базовые данные пользователя
        final Map<String, dynamic> newUserData = {
          'id': userId,
          'email': email,
          'name': '',
          'surname': '',
          'phone': '',
          'created_at': FieldValue.serverTimestamp(),
          'updated_at': FieldValue.serverTimestamp(),
          'last_login': FieldValue.serverTimestamp(),
          'isDriver': false, // По умолчанию пользователь не является водителем
        };

        // Добавляем переданные данные, если они есть
        if (userData != null) {
          newUserData.addAll(userData);
        }

        await docRef.set(newUserData);
        debugPrint(
            'Создан новый пользователь с ID: $userId и email: $email, isDriver: ${newUserData['isDriver']}');

        // Сохраняем ID пользователя локально
        await _saveUserIdLocally(userId);
      } else {
        // Создаем базовое обновление
        Map<String, dynamic> updates = {
          'last_login': FieldValue.serverTimestamp(),
          'email': email,
        };

        // Добавляем переданные данные, если они есть
        if (userData != null) {
          updates.addAll(userData);
        }

        // Обновляем время последнего входа и дополнительные данные
        await docRef.update(updates);
        debugPrint('Обновлены данные для пользователя: $userId');
      }
    } catch (e) {
      debugPrint('Ошибка при создании/обновлении пользователя: $e');
    }
  }

  /// Получение email текущего пользователя
  Future<String?> getCurrentUserEmail() async {
    if (_isDemoMode) {
      return 'demo@example.com';
    }

    return _auth.currentUser?.email;
  }

  /// Методы для работы с чатом

  /// Получение сообщений чата
  Future<List<Map<String, dynamic>>> getChatMessages(String driverId) async {
    debugPrint('Получение сообщений чата для водителя: $driverId');

    if (_isDemoMode) {
      // В демо-режиме возвращаем пустой список (приветственное сообщение будет создано в виджете)
      return [];
    }

    try {
      final userId = await getCurrentUserId();
      if (userId == null) {
        debugPrint('Пользователь не авторизован');
        return [];
      }

      // Формируем идентификатор чата (комбинация ID пользователя и водителя)
      final chatId = '${userId}_$driverId';

      final querySnapshot = await _firestore
          .collection('chat_messages')
          .where('chat_id', isEqualTo: chatId)
          .orderBy('timestamp', descending: true)
          .get();

      debugPrint('Получено ${querySnapshot.docs.length} сообщений');

      return querySnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      debugPrint('Ошибка получения сообщений чата: $e');
      return [];
    }
  }

  /// Сохранение сообщения в чате
  Future<bool> saveMessage(
      String driverId, String text, bool isFromUser) async {
    debugPrint('Сохранение сообщения для водителя: $driverId');

    if (_isDemoMode) {
      // В демо-режиме просто возвращаем успешный результат
      return true;
    }

    try {
      final userId = await getCurrentUserId();
      if (userId == null) {
        debugPrint('Пользователь не авторизован');
        return false;
      }

      // Формируем идентификатор чата
      final chatId = '${userId}_$driverId';

      // Создаем данные сообщения
      final messageData = {
        'chat_id': chatId,
        'text': text,
        'is_from_user': isFromUser,
        'is_read':
            !isFromUser, // Сообщения от водителя сразу считаются прочитанными
        'timestamp': FieldValue.serverTimestamp(),
      };

      // Сохраняем сообщение
      await _firestore.collection('chat_messages').add(messageData);
      debugPrint('Сообщение сохранено успешно');
      return true;
    } catch (e) {
      debugPrint('Ошибка сохранения сообщения: $e');
      return false;
    }
  }

  /// Отметка сообщений как прочитанных
  Future<bool> markMessagesAsRead(String driverId) async {
    debugPrint('Отметка сообщений как прочитанных для водителя: $driverId');

    if (_isDemoMode) {
      // В демо-режиме возвращаем успешный результат
      return true;
    }

    try {
      final userId = await getCurrentUserId();
      if (userId == null) {
        debugPrint('Пользователь не авторизован');
        return false;
      }

      // Формируем идентификатор чата
      final chatId = '${userId}_$driverId';

      // Получаем непрочитанные сообщения от водителя
      final querySnapshot = await _firestore
          .collection('chat_messages')
          .where('chat_id', isEqualTo: chatId)
          .where('is_from_user', isEqualTo: false)
          .where('is_read', isEqualTo: false)
          .get();

      // Обновляем статус для каждого сообщения
      final batch = _firestore.batch();
      for (var doc in querySnapshot.docs) {
        batch.update(doc.reference, {'is_read': true});
      }

      await batch.commit();
      debugPrint(
          'Отмечено ${querySnapshot.docs.length} сообщений как прочитанные');
      return true;
    } catch (e) {
      debugPrint('Ошибка отметки сообщений как прочитанных: $e');
      return false;
    }
  }

  /// Методы для работы с поездками и другими функциями

  /// Получение поездок пользователя
  Future<List<Map<String, dynamic>>> getUserTrips() async {
    debugPrint('Получение поездок пользователя, демо-режим: $_isDemoMode');

    if (_isDemoMode) {
      // В демо-режиме возвращаем тестовые данные
      return [
        {
          'id': 'demo-trip-1',
          'origin_address': 'ул. Пушкина, 10',
          'destination_address': 'ул. Ленина, 15',
          'tariff_name': 'Мама такси',
          'price': 450.0,
          'status': 'completed',
          'created_at': DateTime.now()
              .subtract(const Duration(days: 2))
              .toIso8601String(),
        },
        {
          'id': 'demo-trip-2',
          'origin_address': 'ул. Гагарина, 8',
          'destination_address': 'пр. Мира, 22',
          'tariff_name': 'Личный водитель',
          'price': 650.0,
          'status': 'completed',
          'created_at': DateTime.now()
              .subtract(const Duration(days: 5))
              .toIso8601String(),
        },
      ];
    }

    try {
      final userId = await getCurrentUserId();
      if (userId == null) {
        debugPrint('Пользователь не авторизован');
        return [];
      }

      final querySnapshot = await _firestore
          .collection('trips')
          .where('user_id', isEqualTo: userId)
          .orderBy('created_at', descending: true)
          .get();

      return querySnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      debugPrint('Ошибка получения поездок: $e');
      return [];
    }
  }

  /// Создание новой поездки
  Future<String?> createTrip(dynamic trip) async {
    debugPrint('Создание новой поездки, демо-режим: $_isDemoMode');

    if (_isDemoMode) {
      // В демо-режиме просто возвращаем фиктивный ID
      return 'demo-trip-id';
    }

    try {
      final userId = await getCurrentUserId();
      if (userId == null) {
        debugPrint('Пользователь не авторизован');
        return null;
      }

      // Преобразуем данные поездки в карту
      final tripData = trip.toJson();
      tripData['user_id'] = userId;
      tripData['created_at'] = FieldValue.serverTimestamp();

      // Создаем новую поездку
      final docRef = await _firestore.collection('trips').add(tripData);
      debugPrint('Поездка создана с ID: ${docRef.id}');

      return docRef.id;
    } catch (e) {
      debugPrint('Ошибка создания поездки: $e');
      return null;
    }
  }

  /// Обновление статуса поездки
  Future<bool> updateTripStatus(String tripId, dynamic status) async {
    debugPrint('Обновление статуса поездки: $tripId, демо-режим: $_isDemoMode');

    if (_isDemoMode) {
      // В демо-режиме просто возвращаем успешный результат
      return true;
    }

    try {
      // Обновляем статус
      await _firestore.collection('trips').doc(tripId).update({
        'status': status.toString(),
        'updated_at': FieldValue.serverTimestamp(),
      });

      debugPrint('Статус поездки обновлен успешно');
      return true;
    } catch (e) {
      debugPrint('Ошибка обновления статуса поездки: $e');
      return false;
    }
  }

  /// Методы для работы с программой лояльности

  /// Получение данных программы лояльности пользователя
  Future<Map<String, dynamic>?> getUserLoyaltyData() async {
    debugPrint('Получение данных лояльности, демо-режим: $_isDemoMode');

    if (_isDemoMode) {
      // В демо-режиме возвращаем тестовые данные
      return {
        'points': 350,
        'transactions': [
          {
            'id': 'demo-trans-1',
            'type': 'earned',
            'amount': 150,
            'description': 'Начисление: 150 баллов за поездку',
            'date': DateTime.now()
                .subtract(const Duration(days: 1))
                .toIso8601String(),
          },
          {
            'id': 'demo-trans-2',
            'type': 'earned',
            'amount': 200,
            'description': 'Начисление: 200 баллов за поездку',
            'date': DateTime.now()
                .subtract(const Duration(days: 5))
                .toIso8601String(),
          },
        ],
      };
    }

    try {
      final userId = await getCurrentUserId();
      if (userId == null) {
        debugPrint('Пользователь не авторизован');
        return null;
      }

      // Получаем профиль лояльности
      final docSnapshot =
          await _firestore.collection('loyalty').doc(userId).get();

      if (!docSnapshot.exists) {
        // Создаем профиль лояльности, если его нет
        await _createLoyaltyProfile(userId);
        return {'points': 0, 'transactions': []};
      }

      // Получаем транзакции
      final transactionsSnapshot = await _firestore
          .collection('loyalty_transactions')
          .where('user_id', isEqualTo: userId)
          .orderBy('date', descending: true)
          .get();

      final transactions =
          transactionsSnapshot.docs.map((doc) => doc.data()).toList();

      // Объединяем данные
      final loyaltyData = docSnapshot.data() ?? {'points': 0};
      loyaltyData['transactions'] = transactions;

      return loyaltyData;
    } catch (e) {
      debugPrint('Ошибка получения данных лояльности: $e');
      return null;
    }
  }

  /// Создание профиля лояльности
  Future<bool> _createLoyaltyProfile(String userId) async {
    try {
      await _firestore.collection('loyalty').doc(userId).set({
        'points': 0,
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      });

      debugPrint('Профиль лояльности создан для пользователя: $userId');
      return true;
    } catch (e) {
      debugPrint('Ошибка создания профиля лояльности: $e');
      return false;
    }
  }

  /// Начисление баллов лояльности
  Future<bool> addLoyaltyPoints(int points, String description) async {
    debugPrint(
        'Начисление баллов лояльности: $points, демо-режим: $_isDemoMode');

    if (_isDemoMode) {
      // В демо-режиме просто возвращаем успешный результат
      return true;
    }

    try {
      final userId = await getCurrentUserId();
      if (userId == null) {
        debugPrint('Пользователь не авторизован');
        return false;
      }

      // Получаем текущие баллы
      final docSnapshot =
          await _firestore.collection('loyalty').doc(userId).get();

      if (!docSnapshot.exists) {
        await _createLoyaltyProfile(userId);
      }

      final currentPoints =
          (docSnapshot.data()?['points'] as num?)?.toInt() ?? 0;
      final newPoints = currentPoints + points;

      // Обновляем баллы
      await _firestore.collection('loyalty').doc(userId).update({
        'points': newPoints,
        'updated_at': FieldValue.serverTimestamp(),
      });

      // Создаем транзакцию
      await _firestore.collection('loyalty_transactions').add({
        'user_id': userId,
        'type': 'earned',
        'amount': points,
        'description': description,
        'date': FieldValue.serverTimestamp(),
      });

      debugPrint('Баллы начислены успешно. Новый баланс: $newPoints');
      return true;
    } catch (e) {
      debugPrint('Ошибка начисления баллов: $e');
      return false;
    }
  }

  /// Списание баллов лояльности
  Future<bool> useLoyaltyPoints(int points, String description) async {
    debugPrint('Списание баллов лояльности: $points, демо-режим: $_isDemoMode');

    if (_isDemoMode) {
      // В демо-режиме просто возвращаем успешный результат
      return true;
    }

    try {
      final userId = await getCurrentUserId();
      if (userId == null) {
        debugPrint('Пользователь не авторизован');
        return false;
      }

      // Получаем текущие баллы
      final docSnapshot =
          await _firestore.collection('loyalty').doc(userId).get();

      if (!docSnapshot.exists) {
        debugPrint('Профиль лояльности не найден');
        return false;
      }

      final currentPoints =
          (docSnapshot.data()?['points'] as num?)?.toInt() ?? 0;

      if (currentPoints < points) {
        debugPrint('Недостаточно баллов для списания');
        return false;
      }

      final newPoints = currentPoints - points;

      // Обновляем баллы
      await _firestore.collection('loyalty').doc(userId).update({
        'points': newPoints,
        'updated_at': FieldValue.serverTimestamp(),
      });

      // Создаем транзакцию
      await _firestore.collection('loyalty_transactions').add({
        'user_id': userId,
        'type': 'spent',
        'amount': points,
        'description': description,
        'date': FieldValue.serverTimestamp(),
      });

      debugPrint('Баллы списаны успешно. Новый баланс: $newPoints');
      return true;
    } catch (e) {
      debugPrint('Ошибка списания баллов: $e');
      return false;
    }
  }

  /// Методы для работы с недавними адресами

  /// Сохранение недавнего адреса
  Future<bool> saveRecentAddress(String address, String type) async {
    debugPrint(
        'Сохранение недавнего адреса: $address, тип: $type, демо-режим: $_isDemoMode');

    if (_isDemoMode) {
      // В демо-режиме просто возвращаем успешный результат
      return true;
    }

    try {
      final userId = await getCurrentUserId();
      if (userId == null) {
        debugPrint('Пользователь не авторизован');
        return false;
      }

      // Проверяем, существует ли уже такой адрес
      final querySnapshot = await _firestore
          .collection('recent_addresses')
          .where('user_id', isEqualTo: userId)
          .where('address', isEqualTo: address)
          .where('type', isEqualTo: type)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        // Если адрес уже существует, обновляем время
        await _firestore
            .collection('recent_addresses')
            .doc(querySnapshot.docs.first.id)
            .update({
          'updated_at': FieldValue.serverTimestamp(),
        });

        debugPrint('Обновлено время для существующего адреса');
        return true;
      }

      // Создаем новую запись
      await _firestore.collection('recent_addresses').add({
        'user_id': userId,
        'address': address,
        'type': type,
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      });

      debugPrint('Недавний адрес сохранен успешно');
      return true;
    } catch (e) {
      debugPrint('Ошибка сохранения недавнего адреса: $e');
      return false;
    }
  }

  /// Получение недавних адресов
  Future<List<Map<String, dynamic>>> getRecentAddresses(String type) async {
    debugPrint(
        'Получение недавних адресов типа: $type, демо-режим: $_isDemoMode');

    if (_isDemoMode) {
      // В демо-режиме возвращаем тестовые данные
      if (type == 'origin') {
        return [
          {'address': 'ул. Пушкина, 10'},
          {'address': 'ул. Гагарина, 5'},
        ];
      } else {
        return [
          {'address': 'ул. Ленина, 15'},
          {'address': 'пр. Мира, 22'},
        ];
      }
    }

    try {
      final userId = await getCurrentUserId();
      if (userId == null) {
        debugPrint('Пользователь не авторизован');
        return [];
      }

      final querySnapshot = await _firestore
          .collection('recent_addresses')
          .where('user_id', isEqualTo: userId)
          .where('type', isEqualTo: type)
          .orderBy('updated_at', descending: true)
          .limit(5)
          .get();

      return querySnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      debugPrint('Ошибка получения недавних адресов: $e');
      return [];
    }
  }

  /// Методы для работы с детьми пользователя

  /// Получение списка детей пользователя
  Future<List<ChildModel>> getChildren() async {
    debugPrint('Получение списка детей, демо-режим: $_isDemoMode');

    if (_isDemoMode) {
      // В демо-режиме возвращаем тестовые данные
      return [
        ChildModel(
          id: '1',
          userId: 'demoUser',
          name: 'Анна',
          age: '7',
          notes: 'Занятия по понедельникам и средам',
        ),
        ChildModel(
          id: '2',
          userId: 'demoUser',
          name: 'Михаил',
          age: '10',
          notes: 'Футбол по вторникам',
        ),
      ];
    }

    try {
      final userId = await getCurrentUserId();
      if (userId == null) {
        debugPrint('Пользователь не авторизован');
        return [];
      }

      final querySnapshot = await _firestore
          .collection('children')
          .where('user_id', isEqualTo: userId)
          .orderBy('created_at', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return ChildModel.fromJson({
          'id': doc.id,
          ...data,
        });
      }).toList();
    } catch (e) {
      debugPrint('Ошибка получения списка детей: $e');
      return [];
    }
  }

  /// Добавление нового ребенка
  Future<String?> addChild(ChildModel child) async {
    debugPrint('Добавление ребенка, демо-режим: $_isDemoMode');

    if (_isDemoMode) {
      // В демо-режиме возвращаем тестовый ID
      return 'demo-child-id';
    }

    try {
      final userId = await getCurrentUserId();
      if (userId == null) {
        debugPrint('Пользователь не авторизован');
        return null;
      }

      final childData = child.toJson();

      // Добавляем текущую дату создания и обновления
      childData['created_at'] = FieldValue.serverTimestamp();
      childData['updated_at'] = FieldValue.serverTimestamp();

      final docRef = await _firestore.collection('children').add(childData);
      return docRef.id;
    } catch (e) {
      debugPrint('Ошибка при добавлении ребенка: $e');
      return null;
    }
  }

  /// Обновление данных ребенка
  Future<bool> updateChild(ChildModel child) async {
    debugPrint(
        'Обновление ребенка с ID: ${child.id}, демо-режим: $_isDemoMode');

    if (_isDemoMode) {
      // В демо-режиме всегда возвращаем успех
      return true;
    }

    try {
      if (child.id == null) {
        debugPrint('ID ребенка не найден');
        return false;
      }

      final childData = child.toJson();

      // Обновляем дату последнего изменения
      childData['updated_at'] = FieldValue.serverTimestamp();

      await _firestore.collection('children').doc(child.id).update(childData);
      return true;
    } catch (e) {
      debugPrint('Ошибка при обновлении данных ребенка: $e');
      return false;
    }
  }

  /// Удаление ребенка
  Future<bool> deleteChild(String childId) async {
    debugPrint('Удаление ребенка с ID: $childId, демо-режим: $_isDemoMode');

    if (_isDemoMode) {
      // В демо-режиме всегда возвращаем успех
      return true;
    }

    try {
      await _firestore.collection('children').doc(childId).delete();
      return true;
    } catch (e) {
      debugPrint('Ошибка при удалении ребенка: $e');
      return false;
    }
  }

  /// Получение ребенка по ID
  Future<ChildModel?> getChildById(String childId) async {
    debugPrint(
        'Получение данных ребёнка по ID: $childId, демо-режим: $_isDemoMode');

    if (!await isUserAuthenticated()) {
      debugPrint('Пользователь не авторизован');
      return null;
    }

    try {
      if (_isDemoMode) {
        // В демо-режиме возвращаем тестовые данные
        await Future.delayed(const Duration(milliseconds: 500));
        return ChildModel(
          id: childId,
          userId: 'demo-user-id',
          name: 'Демо ребёнок',
          age: '7',
          notes: 'Демо заметки',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      }

      final userId = await getCurrentUserId();
      if (userId == null) {
        debugPrint('Не удалось получить ID пользователя');
        return null;
      }

      final docSnapshot =
          await _firestore.collection('children').doc(childId).get();

      if (docSnapshot.exists) {
        final data = docSnapshot.data()!;
        debugPrint('Данные ребёнка получены: $data');
        data['id'] = docSnapshot.id;
        return ChildModel.fromJson(data);
      } else {
        debugPrint('Ребёнок с ID $childId не найден');
        return null;
      }
    } catch (e) {
      debugPrint('Ошибка получения данных ребёнка: $e');
      return null;
    }
  }

  /// Получение поездки по ID
  Future<Map<String, dynamic>?> getTripById(String tripId) async {
    debugPrint('Получение поездки по ID: $tripId, демо-режим: $_isDemoMode');

    if (_isDemoMode) {
      // В демо-режиме возвращаем тестовые данные
      await Future.delayed(const Duration(milliseconds: 500));
      return {
        'id': tripId,
        'userId': 'demo-user-id',
        'origin': {
          'latitude': 55.751244,
          'longitude': 37.618423,
          'address': 'ул. Тверская, 1, Москва',
        },
        'destination': {
          'latitude': 55.761244,
          'longitude': 37.638423,
          'address': 'Красная площадь, 1, Москва',
        },
        'scheduledTime': DateTime.now().toIso8601String(),
        'status': 'pending',
        'price': 450.0,
        'distance': 5.2,
        'duration': 15,
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      };
    }

    try {
      final docSnapshot =
          await _firestore.collection('trips').doc(tripId).get();

      if (docSnapshot.exists) {
        final data = docSnapshot.data();
        debugPrint('Данные поездки получены: $data');
        return data;
      } else {
        debugPrint('Поездка с ID $tripId не найдена');
        return null;
      }
    } catch (e) {
      debugPrint('Ошибка получения поездки: $e');
      return null;
    }
  }

  /// Отладочный метод для проверки данных пользователя в базе данных
  Future<void> debugUserData() async {
    try {
      final userId = await getCurrentUserId();
      if (userId == null) {
        debugPrint('ОТЛАДКА: Пользователь не авторизован');
        return;
      }

      if (_isDemoMode) {
        debugPrint('ОТЛАДКА (ДЕМО): Данные пользователя');
        debugPrint(jsonEncode(_demoUserData));
        return;
      }

      final docSnapshot =
          await _firestore.collection('users').doc(userId).get();

      if (docSnapshot.exists) {
        final data = docSnapshot.data() ?? {};
        debugPrint('ОТЛАДКА: Найдены данные пользователя в Firestore');
        debugPrint(jsonEncode(data));
      } else {
        debugPrint('ОТЛАДКА: Данные пользователя не найдены в Firestore!');
      }
    } catch (e) {
      debugPrint('ОТЛАДКА: Ошибка при проверке данных пользователя: $e');
    }
  }

  // Получение данных водителя из Firebase
  Future<Map<String, dynamic>?> getDriverData() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return null;

      final docRef =
          FirebaseFirestore.instance.collection('drivers').doc(currentUser.uid);

      final docSnap = await docRef.get();
      if (docSnap.exists) {
        return docSnap.data();
      }
      return null;
    } catch (e) {
      debugPrint('Ошибка при получении данных водителя: $e');
      return null;
    }
  }

  // Обновление данных автомобиля водителя в Firebase
  Future<bool> updateDriverCarData(Map<String, dynamic> carData) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return false;

      await FirebaseFirestore.instance
          .collection('drivers')
          .doc(currentUser.uid)
          .update({
        'carModel': carData['carModel'],
        'carNumber': carData['carNumber'],
        'carYear': carData['carYear'],
        'carColor': carData['carColor'],
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      debugPrint('Ошибка при обновлении данных автомобиля: $e');
      return false;
    }
  }
}
