import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mama_taxi/models/trip_model.dart';
import 'package:mama_taxi/services/map_service.dart';

class TripProvider with ChangeNotifier {
  final MapService _mapService;
  TripModel? _currentTrip;
  bool _isLoading = false;

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
  bool get isLoading => _isLoading;
  List<Map<String, dynamic>> get tariffs => _tariffs;
  String get selectedTariff => _selectedTariff;
  String get paymentMethod => _paymentMethod;

  // Конструктор
  TripProvider(this._mapService) {
    // Инициализируем сервис карт при создании провайдера
    _initMapService();
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
      // Находим координаты для адресов
      final originLatLng = await _mapService.searchAddress(originAddress);
      final destLatLng = await _mapService.searchAddress(destinationAddress);

      if (originLatLng == null || destLatLng == null) {
        _isLoading = false;
        notifyListeners();
        return;
      }

      // Получаем маршрут
      await _mapService.getDirections(originLatLng, destLatLng);

      // Рассчитываем примерную стоимость (для демонстрации)
      final tariffData = _tariffs.firstWhere(
        (tariff) => tariff['name'] == _selectedTariff,
        orElse: () => _tariffs.first,
      );

      final price = tariffData['price'];

      // Рассчитываем расстояние и время в пути (для демонстрации)
      final distance =
          '${(2 + math.Random().nextDouble() * 3).toStringAsFixed(1)} км';
      final duration = '${(5 + math.Random().nextInt(15))} мин';

      // Создаем модель поездки
      final trip = TripModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        originAddress: originAddress,
        destinationAddress: destinationAddress,
        originPosition: originLatLng,
        destinationPosition: destLatLng,
        tariffName: _selectedTariff,
        price: price,
        distance: distance,
        duration: duration,
        status: TripStatus.searching,
        createdAt: DateTime.now(),
      );

      // Задержка для имитации поиска водителя
      await Future.delayed(const Duration(seconds: 2));

      // Обновляем статус поездки - водитель найден
      final confirmedTrip = trip.copyWith(
        status: TripStatus.confirmed,
        driverName: 'Алексей',
        driverPhone: '+7 (999) 123-45-67',
        carInfo: 'Tesla Model Y',
        carPlate: 'А123БВ77',
        estimatedArrival: DateTime.now().add(const Duration(minutes: 3)),
      );

      _updateTrip(confirmedTrip);

      // Задержка для имитации прибытия водителя
      await Future.delayed(const Duration(seconds: 3));

      // Обновляем статус поездки - водитель в пути
      final arrivingTrip = confirmedTrip.copyWith(
        status: TripStatus.arriving,
        estimatedArrival: DateTime.now().add(const Duration(minutes: 1)),
      );

      _updateTrip(arrivingTrip);

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
  void cancelTrip() {
    if (_currentTrip != null) {
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
  Future<void> createDemoTrip() async {
    try {
      // Устанавливаем адреса для демо-поездки
      const String originAddress = "ул. Пушкина, 10, Москва";
      const String destinationAddress = "ул. Ленина, 25, Москва";

      // Создаем демо-координаты
      final LatLng originLatLng = LatLng(55.751244, 37.618423);
      final LatLng destLatLng = LatLng(55.761244, 37.638423);

      // Устанавливаем маркеры на карте
      _mapService.setOriginPosition(originLatLng);
      _mapService.setDestinationPosition(destLatLng);

      // Получаем маршрут
      await _mapService.getDirections(originLatLng, destLatLng);

      // Подгоняем карту, чтобы были видны все маркеры
      _mapService.fitMapToBounds();

      // Создаем модель поездки
      final trip = TripModel.demo(
        originAddress: originAddress,
        destinationAddress: destinationAddress,
        originPosition: originLatLng,
        destinationPosition: destLatLng,
      );

      // Обновляем текущую поездку
      _updateTrip(trip);
    } catch (e) {
      print('Error creating demo trip: $e');
    }
  }

  // Получение контроллера карты
  GoogleMapController? get mapController => _mapService.mapController;

  // Установка контроллера карты
  void setMapController(GoogleMapController controller) {
    _mapService.setMapController(controller);
  }

  // Геттеры для доступа к данным карты
  Set<Marker> get markers => _mapService.markers;
  Set<Polyline> get polylines => _mapService.polylines;

  // Метод для обновления состояния поездки
  void _updateTrip(TripModel updatedTrip) {
    _currentTrip = updatedTrip;

    // Проверяем, инициализирован ли контроллер карты
    // и устанавливаем соответствующие маркеры
    if (_mapService.isInitialized) {
      if (updatedTrip.status == TripStatus.cancelled ||
          updatedTrip.status == TripStatus.completed) {
        // Если поездка завершена или отменена, очищаем маркеры
        _mapService.clearMarkers();
        _mapService.clearRoute();
      } else if (updatedTrip.originPosition != null &&
          updatedTrip.destinationPosition != null) {
        // Иначе обновляем маркеры и положение камеры
        _mapService.setOriginPosition(updatedTrip.originPosition!);
        _mapService.setDestinationPosition(updatedTrip.destinationPosition!);

        // Перемещаем камеру чтобы были видны все маркеры
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

  void setOriginPosition(LatLng position) {
    _mapService.setOriginPosition(position);
  }

  void setDestinationPosition(LatLng position) {
    _mapService.setDestinationPosition(position);
  }
}
