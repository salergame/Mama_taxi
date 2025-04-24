import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:mama_taxi/models/trip_model.dart';
import 'package:mama_taxi/screens/home_screen.dart';
import 'package:mama_taxi/services/map_service.dart';
import 'package:mama_taxi/services/route_service.dart';

/// Сервис для вызова такси
class TaxiService with ChangeNotifier {
  final MapService _mapService;
  final RouteService _routeService = RouteService();

  // Текущая поездка
  TripModel? _currentTrip;

  // Флаг загрузки
  bool _isLoading = false;

  // Демо-режим для тестирования без бэкенда
  bool _isDemoMode = true;

  // Данные водителя при подтверждении поездки
  Map<String, dynamic>? _driverData;

  // Тарифы (в реальном приложении загружаются с сервера)
  final List<Map<String, dynamic>> _tariffs = [
    {
      'name': 'Мама такси',
      'time': '10-15 мин',
      'price': 450.0,
      'icon': Icons.directions_car,
    },
    {
      'name': 'Личный водитель',
      'time': '15-20 мин',
      'price': 650.0,
      'icon': Icons.person,
    },
    {
      'name': 'Срочная поездка',
      'time': '5-8 мин',
      'price': 850.0,
      'icon': Icons.airport_shuttle,
    },
  ];

  // Выбранный тариф
  String _selectedTariff = 'Мама такси';

  // Геттеры
  TripModel? get currentTrip => _currentTrip;
  bool get isLoading => _isLoading;
  bool get isDemoMode => _isDemoMode;
  List<Map<String, dynamic>> get tariffs => _tariffs;
  String get selectedTariff => _selectedTariff;
  Map<String, dynamic>? get driverData => _driverData;

  TaxiService(this._mapService);

  // Выбор тарифа
  void selectTariff(String tariffName) {
    _selectedTariff = tariffName;
    notifyListeners();
  }

  // Расчет стоимости поездки
  double calculatePrice(String tariffName, double distance) {
    final tariff = _tariffs.firstWhere(
      (t) => t['name'] == tariffName,
      orElse: () => _tariffs.first,
    );

    // Базовая стоимость + километраж
    return tariff['price'] + (distance * 20);
  }

  // Расчет примерного времени прибытия такси
  DateTime calculateEstimatedArrival() {
    return DateTime.now().add(const Duration(minutes: 5));
  }

  // Создание поездки
  Future<TripModel?> createTrip(
      String originAddress, String destinationAddress) async {
    if (originAddress.isEmpty || destinationAddress.isEmpty) {
      return null;
    }

    _isLoading = true;
    notifyListeners();

    try {
      // Поиск координат
      final originPoint = await _mapService.searchAddress(originAddress);
      final destPoint = await _mapService.searchAddress(destinationAddress);

      if (originPoint == null || destPoint == null) {
        _isLoading = false;
        notifyListeners();
        return null;
      }

      // Расчет маршрута
      final routePoints = await _routeService.getRoute(originPoint, destPoint);

      // Расчет расстояния
      final distance = _routeService.getDistance(originPoint, destPoint);
      final distanceStr = '${distance.toStringAsFixed(1)} км';

      // Расчет длительности
      final durationMinutes =
          (distance / 0.5).round(); // Предполагаем среднюю скорость 30 км/ч
      final durationStr = '$durationMinutes мин';

      // Расчет стоимости
      final price = calculatePrice(_selectedTariff, distance);

      // Создание новой поездки
      _currentTrip = TripModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: 'user123', // Временный ID пользователя
        origin: TripLocation(
          latitude: originPoint.latitude,
          longitude: originPoint.longitude,
          address: originAddress,
        ),
        destination: TripLocation(
          latitude: destPoint.latitude,
          longitude: destPoint.longitude,
          address: destinationAddress,
        ),
        scheduledTime: DateTime.now(),
        price: price,
        distance: distance,
        duration: durationMinutes,
        status: TripStatus.pending,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Имитация поиска водителя
      if (_isDemoMode) {
        await _simulateDriverSearch();
      }

      _isLoading = false;
      notifyListeners();
      return _currentTrip;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      print('Ошибка создания поездки: $e');
      return null;
    }
  }

  // Имитация поиска водителя в демо-режиме
  Future<void> _simulateDriverSearch() async {
    await Future.delayed(const Duration(seconds: 2));

    // Генерируем данные водителя
    _driverData = {
      'name': 'Александра М.',
      'phone': '+7 (999) 123-45-67',
      'rating': 4.8,
      'car': 'Tesla Model Y',
      'carColor': 'Белый',
      'carPlate': 'А123БВ77',
      'photoUrl': 'assets/images/driver.png',
      'estimatedArrival': calculateEstimatedArrival(),
    };

    // Обновляем статус поездки
    _currentTrip = _currentTrip!.copyWith(
      status: TripStatus.confirmed,
      driverId: 'driver123',
    );

    notifyListeners();

    // Имитация прибытия водителя
    await Future.delayed(const Duration(seconds: 3));

    _currentTrip = _currentTrip!.copyWith(
      status: TripStatus.driverArrived,
    );

    notifyListeners();
  }

  // Отмена поездки
  Future<bool> cancelTrip() async {
    if (_currentTrip == null) {
      return false;
    }

    _isLoading = true;
    notifyListeners();

    try {
      await Future.delayed(const Duration(milliseconds: 800));

      _currentTrip = _currentTrip!.copyWith(
        status: TripStatus.cancelled,
      );

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      print('Ошибка отмены поездки: $e');
      return false;
    }
  }

  // Завершение поездки
  Future<bool> completeTrip() async {
    if (_currentTrip == null) {
      return false;
    }

    _isLoading = true;
    notifyListeners();

    try {
      _currentTrip = _currentTrip!.copyWith(
        status: TripStatus.completed,
        endTime: DateTime.now(),
      );

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      print('Ошибка завершения поездки: $e');
      return false;
    }
  }

  // Оценка поездки
  Future<bool> rateTrip(double rating) async {
    if (_currentTrip == null) {
      return false;
    }

    _isLoading = true;
    notifyListeners();

    try {
      _currentTrip = _currentTrip!.copyWith(
        notes: "Рейтинг: $rating",
      );

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      print('Ошибка оценки поездки: $e');
      return false;
    }
  }
}
