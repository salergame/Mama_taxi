import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mama_taxi/models/trip_model.dart';
import 'package:mama_taxi/services/map_service.dart';
import 'package:mama_taxi/services/firebase_service.dart';
import 'package:mama_taxi/services/route_service.dart';
import 'package:mama_taxi/screens/home_screen.dart';

class TripProvider with ChangeNotifier {
  final MapService _mapService;
  final FirebaseService _firebaseService = FirebaseService();
  final RouteService _routeService = RouteService();

  TripModel? _currentTrip;
  bool _isLoading = false;
  List<TripModel> _tripHistory = [];
  List<Map<String, dynamic>>? _selectedServices = [];

  // Маршрутные данные
  List<LatLng>? _routePoints;

  // Тарифы (в реальном приложении могут загружаться с сервера)
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

  String _selectedTariff = 'Мама такси';
  String _paymentMethod = '**** 4242';

  // Геттеры для доступа к данным
  TripModel? get currentTrip => _currentTrip;
  List<TripModel> get tripHistory => _tripHistory;
  bool get isLoading => _isLoading;
  List<Map<String, dynamic>> get tariffs => _tariffs;
  String get selectedTariff => _selectedTariff;
  String get paymentMethod => _paymentMethod;
  List<Map<String, dynamic>>? get selectedServices => _selectedServices;
  List<LatLng>? get routePoints => _routePoints;

  // Конструктор
  TripProvider(this._mapService) {
    // Инициализируем сервис карт при создании провайдера
    _initMapService();
    // Загружаем историю поездок из Firestore при инициализации
    _loadTripHistory();
  }

  // Загрузка истории поездок
  Future<void> _loadTripHistory() async {
    try {
      final tripData = await _firebaseService.getUserTrips();
      _tripHistory = tripData.map((data) => TripModel.fromJson(data)).toList();
      notifyListeners();
    } catch (e) {
      print('Ошибка при загрузке истории поездок: $e');
    }
  }

  // Метод для обновления выбранных дополнительных услуг
  void updateSelectedServices(List<Map<String, dynamic>> services) {
    _selectedServices = services;
    notifyListeners();
  }

  // Инициализация сервиса карт
  Future<void> _initMapService() async {
    try {
      await _mapService.init();
      notifyListeners();
    } catch (e) {
      print('Error initializing map service: $e');
    }
  }

  // Установка выбранного тарифа
  void setSelectedTariff(String tariffName) {
    _selectedTariff = tariffName;
    notifyListeners();
  }

  // Установка способа оплаты
  void setPaymentMethod(String method) {
    _paymentMethod = method;
    notifyListeners();
  }

  // Сохранение недавних адресов
  Future<void> saveRecentAddresses(String origin, String destination) async {
    if (origin.isNotEmpty) {
      await _firebaseService.saveRecentAddress(origin, 'origin');
    }

    if (destination.isNotEmpty) {
      await _firebaseService.saveRecentAddress(destination, 'destination');
    }
  }

  // Получение недавних адресов отправления
  Future<List<String>> getRecentOriginAddresses() async {
    final addresses = await _firebaseService.getRecentAddresses('origin');
    return addresses.map((data) => data['address'] as String).toList();
  }

  // Получение недавних адресов назначения
  Future<List<String>> getRecentDestinationAddresses() async {
    final addresses = await _firebaseService.getRecentAddresses('destination');
    return addresses.map((data) => data['address'] as String).toList();
  }

  // Метод для создания поездки
  Future<void> createTrip(
      String originAddress, String destinationAddress) async {
    if (originAddress.isEmpty || destinationAddress.isEmpty) {
      return;
    }

    // Показываем индикатор загрузки
    _isLoading = true;
    notifyListeners();

    try {
      // Сохраняем адреса в историю
      await saveRecentAddresses(originAddress, destinationAddress);

      // Находим координаты для адресов
      final originPoint = await _mapService.searchAddress(originAddress);
      final destPoint = await _mapService.searchAddress(destinationAddress);

      if (originPoint == null || destPoint == null) {
        // Используем тестовые координаты, если не удалось найти адрес
        final SimpleLocation defaultOrigin =
            SimpleLocation(latitude: 55.751244, longitude: 37.618423);
        final SimpleLocation defaultDest =
            SimpleLocation(latitude: 55.761244, longitude: 37.638423);

        // Получаем маршрут с тестовыми координатами
        await _mapService.getDirections(defaultOrigin, defaultDest);

        // Рассчитываем примерную стоимость
        final tariffData = _tariffs.firstWhere(
          (tariff) => tariff['name'] == _selectedTariff,
          orElse: () => _tariffs.first,
        );

        final price = tariffData['price'];

        // Рассчитываем расстояние и время в пути
        final double distance = 5.2;
        final int duration = 15;

        // Получаем идентификатор пользователя
        final userId = await _firebaseService.getCurrentUserId() ?? 'unknown';

        // Создаем модель поездки с тестовыми данными
        final trip = TripModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          userId: userId,
          origin: TripLocation(
            latitude: defaultOrigin.latitude,
            longitude: defaultOrigin.longitude,
            address: originAddress.isEmpty
                ? "Тестовый адрес отправления"
                : originAddress,
          ),
          destination: TripLocation(
            latitude: defaultDest.latitude,
            longitude: defaultDest.longitude,
            address: destinationAddress.isEmpty
                ? "Тестовый адрес назначения"
                : destinationAddress,
          ),
          scheduledTime: DateTime.now(),
          status: TripStatus.pending,
          price: price,
          distance: distance,
          duration: duration,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        _updateTrip(trip);

        // Задержка для имитации поиска водителя
        await Future.delayed(const Duration(seconds: 2));

        // Обновляем статус поездки - водитель найден
        final confirmedTrip = _currentTrip!.copyWith(
          status: TripStatus.confirmed,
          driverId: 'driver123',
        );

        _updateTrip(confirmedTrip);

        // Задержка для имитации прибытия водителя
        await Future.delayed(const Duration(seconds: 3));

        // Обновляем статус поездки - водитель прибыл
        final arrivedTrip = confirmedTrip.copyWith(
          status: TripStatus.driverArrived,
        );

        _updateTrip(arrivedTrip);

        _isLoading = false;
        notifyListeners();
        return;
      }

      // Получаем маршрут
      await _mapService.getDirections(originPoint, destPoint);

      // Рассчитываем примерную стоимость
      final tariffData = _tariffs.firstWhere(
        (tariff) => tariff['name'] == _selectedTariff,
        orElse: () => _tariffs.first,
      );

      final price = tariffData['price'];

      // Рассчитываем расстояние и время в пути
      final double distance = 5.2;
      final int duration = 15;

      // Получаем идентификатор пользователя
      final userId = await _firebaseService.getCurrentUserId() ?? 'unknown';

      // Создаем модель поездки
      final trip = TripModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: userId,
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
        status: TripStatus.pending,
        price: price,
        distance: distance,
        duration: duration,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Сохраняем поездку в Firestore
      String? tripId = await _firebaseService.createTrip(trip);

      if (tripId != null) {
        // Обновляем локальный идентификатор
        final updatedTrip = trip.copyWith(id: tripId);
        _updateTrip(updatedTrip);
      } else {
        _updateTrip(trip);
      }

      // Задержка для имитации поиска водителя
      await Future.delayed(const Duration(seconds: 2));

      // Обновляем статус поездки - водитель найден
      final confirmedTrip = _currentTrip!.copyWith(
        status: TripStatus.confirmed,
        driverId: 'driver123',
      );

      // Обновляем статус в Firestore
      if (tripId != null) {
        await _firebaseService.updateTripStatus(tripId, TripStatus.confirmed);
      }

      _updateTrip(confirmedTrip);

      // Задержка для имитации прибытия водителя
      await Future.delayed(const Duration(seconds: 3));

      // Обновляем статус поездки - водитель прибыл
      final arrivedTrip = confirmedTrip.copyWith(
        status: TripStatus.driverArrived,
      );

      // Обновляем статус в Firestore
      if (tripId != null) {
        await _firebaseService.updateTripStatus(
            tripId, TripStatus.driverArrived);
      }

      _updateTrip(arrivedTrip);

      // Отключаем индикатор загрузки
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('Error creating trip: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  // Отмена текущей поездки
  Future<void> cancelTrip() async {
    if (_currentTrip != null) {
      // Обновляем статус в Firestore
      await _firebaseService.updateTripStatus(
          _currentTrip!.id, TripStatus.cancelled);

      _currentTrip = _currentTrip!.copyWith(
        status: TripStatus.cancelled,
      );

      notifyListeners();

      // Через 2 секунды сбрасываем состояние
      Future.delayed(const Duration(seconds: 2), () {
        _currentTrip = null;
        notifyListeners();
      });
    }
  }

  // Создание демо-поездки для тестирования
  void createDemoTrip() {
    final originPosition =
        SimpleLocation(latitude: 55.751244, longitude: 37.618423);

    final destinationPosition =
        SimpleLocation(latitude: 55.751244 + 0.02, longitude: 37.618423 + 0.03);

    final trip = TripModel.demo(
      originAddress: 'ул. Тверская, 1, Москва',
      destinationAddress: 'Красная площадь, 1, Москва',
      originPosition: originPosition,
      destinationPosition: destinationPosition,
    );

    _updateTrip(trip);

    // Явно запрашиваем маршрут и выводим отладочную информацию
    print(
        'Инициируем построение маршрута для демо-поездки: ${originPosition.latitude},${originPosition.longitude} -> ${destinationPosition.latitude},${destinationPosition.longitude}');
    setRoute(originPosition, destinationPosition);
  }

  // Метод для обновления состояния поездки
  void _updateTrip(TripModel updatedTrip) {
    _currentTrip = updatedTrip;

    // Проверяем, инициализирован ли сервис карты
    // и устанавливаем соответствующие маркеры
    if (_mapService.isInitialized) {
      if (updatedTrip.status == TripStatus.cancelled ||
          updatedTrip.status == TripStatus.completed) {
        // Если поездка завершена или отменена, очищаем маркеры
        _mapService.clearMarkers();
        _mapService.clearRoute();
      } else {
        // Иначе обновляем маркеры
        _mapService.setOriginPosition(SimpleLocation(
          latitude: updatedTrip.origin.latitude,
          longitude: updatedTrip.origin.longitude,
        ));
        _mapService.setDestinationPosition(SimpleLocation(
          latitude: updatedTrip.destination.latitude,
          longitude: updatedTrip.destination.longitude,
        ));

        // Перемещаем карту чтобы были видны все маркеры
        _mapService.fitMapToBounds();
      }
    }

    // Уведомляем слушателей об изменении
    notifyListeners();
  }

  Future<bool> setOriginAddress(String address) async {
    return await _mapService.setOriginAddress(address);
  }

  Future<bool> setDestinationAddress(String address) async {
    return await _mapService.setDestinationAddress(address);
  }

  void setOriginPosition(SimpleLocation position) {
    _mapService.setOriginPosition(position);
  }

  void setDestinationPosition(SimpleLocation position) {
    _mapService.setDestinationPosition(position);
  }

  // Установка маршрута
  Future<void> setRoute(
      SimpleLocation origin, SimpleLocation destination) async {
    try {
      print(
          'Запрашиваем маршрут: ${origin.latitude},${origin.longitude} -> ${destination.latitude},${destination.longitude}');
      final routePoints = await _routeService.getRoute(origin, destination);
      _routePoints = routePoints;

      print('Получен маршрут с ${routePoints.length} точками');

      // Тестовая проверка первой и последней точки маршрута
      if (routePoints.length > 1) {
        print(
            'Первая точка маршрута: ${routePoints.first.latitude},${routePoints.first.longitude}');
        print(
            'Последняя точка маршрута: ${routePoints.last.latitude},${routePoints.last.longitude}');
      }

      notifyListeners();
    } catch (e) {
      print('Error setting route: $e');
    }
  }

  // Получение поездки по id
  Future<TripModel?> getTripById(String tripId) async {
    try {
      _isLoading = true;
      notifyListeners();

      final tripData = await _firebaseService.getTripById(tripId);

      _isLoading = false;
      notifyListeners();

      if (tripData != null) {
        return TripModel.fromJson(tripData);
      }
      return null;
    } catch (e) {
      print('Ошибка при получении поездки: $e');
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }
}
