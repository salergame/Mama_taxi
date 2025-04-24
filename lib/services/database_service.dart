import 'package:flutter/material.dart';
import 'package:mama_taxi/services/firebase_service.dart';
import 'package:mama_taxi/models/trip_model.dart';

/// Сервис для работы с базой данных Firebase
class DatabaseService {
  final FirebaseService _firebaseService = FirebaseService();

  // В демо-режиме для тестирования
  bool get _isDemoMode => true;

  /// Создание таблиц в Supabase (для локальной среды разработки)
  static List<String> getTableCreationScripts() {
    return [
      '''
      CREATE TABLE IF NOT EXISTS users (
        id UUID PRIMARY KEY,
        phone TEXT,
        name TEXT,
        surname TEXT,
        email TEXT,
        birthday TEXT,
        gender TEXT,
        city TEXT,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
        last_login TIMESTAMP WITH TIME ZONE,
        is_profile_completed BOOLEAN DEFAULT FALSE
      );
      ''',
      '''
      CREATE TABLE IF NOT EXISTS trips (
        id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
        user_id UUID REFERENCES users(id),
        driver_id UUID,
        origin_address TEXT NOT NULL,
        destination_address TEXT NOT NULL,
        origin_lat DOUBLE PRECISION,
        origin_lng DOUBLE PRECISION,
        destination_lat DOUBLE PRECISION,
        destination_lng DOUBLE PRECISION,
        distance TEXT,
        duration TEXT,
        price DOUBLE PRECISION,
        tariff_name TEXT,
        status TEXT,
        driver_name TEXT,
        driver_phone TEXT,
        car_info TEXT,
        car_plate TEXT,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
        started_at TIMESTAMP WITH TIME ZONE,
        completed_at TIMESTAMP WITH TIME ZONE,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
        estimated_arrival TIMESTAMP WITH TIME ZONE,
        payment_method TEXT,
        passenger_rating INTEGER,
        driver_rating INTEGER,
        comment TEXT
      );
      ''',
      '''
      CREATE TABLE IF NOT EXISTS drivers (
        id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
        name TEXT,
        surname TEXT,
        phone TEXT,
        email TEXT,
        car_model TEXT,
        car_color TEXT,
        car_plate TEXT,
        rating DOUBLE PRECISION DEFAULT 5.0,
        status TEXT DEFAULT 'offline',
        position_lat DOUBLE PRECISION,
        position_lng DOUBLE PRECISION,
        last_activity TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
        approval_status TEXT DEFAULT 'pending',
        balance DOUBLE PRECISION DEFAULT 0,
        commission_rate DOUBLE PRECISION DEFAULT 0.15,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
      );
      ''',
      '''
      CREATE TABLE IF NOT EXISTS recent_addresses (
        id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
        user_id UUID REFERENCES users(id),
        address TEXT NOT NULL,
        type TEXT NOT NULL,
        lat DOUBLE PRECISION,
        lng DOUBLE PRECISION,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
      );
      ''',
      '''
      CREATE TABLE IF NOT EXISTS children (
        id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
        user_id UUID REFERENCES users(id),
        name TEXT NOT NULL,
        age INTEGER,
        school TEXT,
        image_url TEXT,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
      );
      ''',
      '''
      CREATE TABLE IF NOT EXISTS user_settings (
        id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
        user_id UUID REFERENCES users(id) UNIQUE,
        notifications_enabled BOOLEAN DEFAULT TRUE,
        dark_mode BOOLEAN DEFAULT FALSE,
        language TEXT DEFAULT 'ru',
        created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
      );
      ''',
      '''
      CREATE TABLE IF NOT EXISTS driver_documents (
        id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
        driver_id UUID REFERENCES drivers(id),
        type TEXT NOT NULL,
        url TEXT NOT NULL,
        verified BOOLEAN DEFAULT FALSE,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
      );
      ''',
      '''
      CREATE TABLE IF NOT EXISTS driver_earnings (
        id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
        driver_id UUID REFERENCES drivers(id),
        trip_id UUID REFERENCES trips(id),
        amount DOUBLE PRECISION NOT NULL,
        commission DOUBLE PRECISION NOT NULL,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
      );
      '''
    ];
  }

  /// Получение актуальной версии схемы базы данных
  Future<String> getDatabaseSchemaVersion() async {
    // В реальном проекте здесь можно запросить версию схемы из таблицы migrations
    return "1.0.0";
  }

  /// Получение пользователя по ID
  Future<Map<String, dynamic>?> getUserById(String userId) async {
    try {
      return await _firebaseService.getUserData();
    } catch (e) {
      print('Ошибка получения пользователя по ID: $e');
      return null;
    }
  }

  /// Получение поездки по ID
  Future<TripModel?> getTripById(String tripId) async {
    try {
      if (_isDemoMode) {
        // В демо-режиме возвращаем тестовую поездку
        return null;
      }

      // Здесь был бы код для получения поездки из Firebase
      return null; // Заглушка
    } catch (e) {
      print('Ошибка получения поездки по ID: $e');
      return null;
    }
  }

  /// Получение детей пользователя
  Future<List<Map<String, dynamic>>> getChildrenForUser(String userId) async {
    debugPrint('Получение детей для пользователя: $userId');

    if (_isDemoMode) {
      // В демо-режиме возвращаем фиктивные данные
      return [
        {
          'id': 'demo-child-1',
          'name': 'Маша',
          'age': 7,
          'school': 'Школа №15',
          'image_url': 'https://i.pravatar.cc/150?img=5',
        },
        {
          'id': 'demo-child-2',
          'name': 'Петя',
          'age': 10,
          'school': 'Гимназия №8',
          'image_url': 'https://i.pravatar.cc/150?img=1',
        },
      ];
    }

    try {
      // Для реализации в Firebase
      return [];
    } catch (e) {
      debugPrint('Ошибка получения детей: $e');
      return [];
    }
  }

  /// Добавление ребенка
  Future<String?> addChild(
      String userId, Map<String, dynamic> childData) async {
    debugPrint('Добавление ребенка для пользователя: $userId');

    if (_isDemoMode) {
      return 'demo-child-id';
    }

    try {
      // Для реализации в Firebase
      return 'child-id';
    } catch (e) {
      debugPrint('Ошибка добавления ребенка: $e');
      return null;
    }
  }

  /// Обновление данных ребенка
  Future<bool> updateChild(
      String childId, Map<String, dynamic> childData) async {
    debugPrint('Обновление данных ребенка: $childId');

    if (_isDemoMode) {
      return true;
    }

    try {
      // Для реализации в Firebase
      return true;
    } catch (e) {
      debugPrint('Ошибка обновления данных ребенка: $e');
      return false;
    }
  }

  /// Удаление ребенка
  Future<bool> deleteChild(String childId) async {
    debugPrint('Удаление ребенка: $childId');

    if (_isDemoMode) {
      return true;
    }

    try {
      // Для реализации в Firebase
      return true;
    } catch (e) {
      debugPrint('Ошибка удаления ребенка: $e');
      return false;
    }
  }

  /// Получение настроек пользователя
  Future<Map<String, dynamic>?> getUserSettings(String userId) async {
    debugPrint('Получение настроек для пользователя: $userId');

    if (_isDemoMode) {
      // В демо-режиме возвращаем фиктивные данные
      return {
        'id': 'demo-settings-id',
        'notifications_enabled': true,
        'dark_mode': false,
        'language': 'ru',
      };
    }

    try {
      // Для реализации в Firebase
      return null;
    } catch (e) {
      debugPrint('Ошибка получения настроек пользователя: $e');
      return null;
    }
  }

  /// Обновление настроек пользователя
  Future<bool> updateUserSettings(
      String userId, Map<String, dynamic> settings) async {
    debugPrint('Обновление настроек для пользователя: $userId');

    if (_isDemoMode) {
      return true;
    }

    try {
      // Для реализации в Firebase
      return true;
    } catch (e) {
      debugPrint('Ошибка обновления настроек пользователя: $e');
      return false;
    }
  }
}
