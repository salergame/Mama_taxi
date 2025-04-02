import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:http/http.dart' as http;

class MapService extends ChangeNotifier {
  // Для демо-режима можно использовать фиксированные координаты
  bool _isDemoMode = false;

  // API-ключи для разных платформ
  String get _apiKey {
    if (kIsWeb) {
      return 'AIzaSyB1eJJ6Aa0zRRqDh8N2_2-z8ZvnkrYevDg'; // Замените на ваш веб API ключ
    } else if (Platform.isAndroid) {
      return 'AIzaSyBOycSDJy1RCQUJz0qp4FI9ElocwFoBSoc'; // Ключ для Android
    } else if (Platform.isIOS) {
      return 'AIzaSyAUuoazcF4PULRDko7nH6VMynTMgU4VWyA'; // Ключ для iOS
    }
    return ''; // Возвращаем пустую строку для других платформ
  }

  // Контроллер Google карты
  GoogleMapController? _mapController;

  // Текущее местоположение
  LatLng? _currentLatLng;
  LocationData? _currentLocation;

  // Маркеры на карте
  final Set<Marker> _markers = {};

  // Полилиния маршрута
  final Set<Polyline> _polylines = {};

  // Начальная и конечная точки маршрута
  LatLng? _origin;
  LatLng? _destination;

  // Переменная для отслеживания инициализации карты
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  // Демо-координаты центра карты (Москва)
  final LatLng _demoCenter = const LatLng(55.751244, 37.618423);

  // Геттеры для доступа к данным
  Set<Marker> get markers => _markers;
  Set<Polyline> get polylines => _polylines;
  LatLng? get currentLatLng => _currentLatLng;
  LocationData? get currentLocation => _currentLocation;
  GoogleMapController? get mapController => _mapController;
  bool get isDemoMode => _isDemoMode;

  // Инициализация сервиса
  Future<void> init() async {
    try {
      if (!_isDemoMode) {
        await _getCurrentLocation();
        if (_currentLocation != null) {
          _currentLatLng = LatLng(
            _currentLocation!.latitude!,
            _currentLocation!.longitude!,
          );
        }
      } else {
        // В демо-режиме используем фиксированные координаты Москвы
        _currentLatLng = const LatLng(55.751244, 37.618423);
        _origin = _currentLatLng;
        _destination = LatLng(
          55.751244 + 0.02, // Увеличиваем расстояние
          37.618423 + 0.03, // Увеличиваем расстояние
        );
        await getDirections(_origin!, _destination!);
      }
      _isInitialized = true;
    } catch (e) {
      print('Error initializing map service: $e');
      // Если не удалось получить местоположение, используем координаты центра Москвы
      _currentLatLng = const LatLng(55.751244, 37.618423);
      _isInitialized = true;
    }
  }

  // Установка контроллера карты
  void setMapController(GoogleMapController controller) {
    _mapController = controller;
    notifyListeners();
  }

  // Получение текущего местоположения
  Future<void> _getCurrentLocation() async {
    Location location = Location();
    bool serviceEnabled;
    PermissionStatus permissionGranted;

    // Проверяем, включена ли геолокация
    serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled.');
      }
    }

    // Проверяем разрешения
    permissionGranted = await location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        throw Exception('Location permissions are denied.');
      }
    }

    // Получаем координаты
    _currentLocation = await location.getLocation();

    // Устанавливаем обработчик для обновления местоположения
    location.onLocationChanged.listen((LocationData currentLocation) {
      _currentLocation = currentLocation;
      _currentLatLng = LatLng(
        currentLocation.latitude!,
        currentLocation.longitude!,
      );
      notifyListeners();
    });
  }

  // Поиск адреса по названию
  Future<LatLng?> searchAddress(String address) async {
    if (isDemoMode) {
      // В демо-режиме генерируем координаты вокруг центра
      return _generateDemoCoordinates(55.751244, 37.618423, 0.005);
    }

    try {
      List<geocoding.Location> locations =
          await geocoding.locationFromAddress(address);
      if (locations.isNotEmpty) {
        return LatLng(locations.first.latitude, locations.first.longitude);
      }
    } catch (e) {
      print('Error searching address: $e');
      return null;
    }
    return null;
  }

  // Установка адреса отправления
  Future<bool> setOriginAddress(String address) async {
    final position = await searchAddress(address);

    if (position != null) {
      _origin = position;
      _addMarker(
        position,
        'origin',
        BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        title: 'Отправление',
      );

      // Перемещаем камеру к этой точке
      if (_mapController != null) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(position, 15),
        );
      }

      if (_destination != null) {
        await getDirections(_origin!, _destination!);
      }

      notifyListeners();
      return true;
    }

    return false;
  }

  // Установка адреса назначения
  Future<bool> setDestinationAddress(String address) async {
    final position = await searchAddress(address);

    if (position != null) {
      _destination = position;
      _addMarker(
        position,
        'destination',
        BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        title: 'Назначение',
      );

      // Перемещаем камеру к этой точке
      if (_mapController != null) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(position, 15),
        );
      }

      if (_origin != null) {
        await getDirections(_origin!, _destination!);
      }

      notifyListeners();
      return true;
    }

    return false;
  }

  // Получение маршрута между двумя точками
  Future<void> getDirections(LatLng origin, LatLng destination) async {
    try {
      // Очищаем предыдущие полилинии
      _polylines.clear();

      // URL для запроса к Directions API
      final String url = 'https://maps.googleapis.com/maps/api/directions/json?'
          'origin=${origin.latitude},${origin.longitude}'
          '&destination=${destination.latitude},${destination.longitude}'
          '&key=$_apiKey'
          '&mode=driving' // Указываем режим передвижения на автомобиле
          '&alternatives=true'; // Запрашиваем альтернативные маршруты

      // Делаем запрос
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK') {
          // Получаем список точек маршрута
          final points = PolylinePoints()
              .decodePolyline(data['routes'][0]['overview_polyline']['points']);

          // Преобразуем точки в LatLng для Google Maps
          List<LatLng> polylineCoordinates = [];
          for (var point in points) {
            polylineCoordinates.add(LatLng(point.latitude, point.longitude));
          }

          // Создаем Polyline
          final String polylineId =
              'polyline_${DateTime.now().millisecondsSinceEpoch}';
          final Polyline polyline = Polyline(
            polylineId: PolylineId(polylineId),
            color: Colors.blue,
            points: polylineCoordinates,
            width: 8,
            patterns: [PatternItem.dash(20), PatternItem.gap(10)],
          );

          _polylines.add(polyline);

          // Добавляем маркеры начала и конца маршрута
          _addMarker(
            origin,
            'origin',
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
            title: 'Точка отправления',
          );

          _addMarker(
            destination,
            'destination',
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
            title: 'Точка назначения',
          );

          notifyListeners();

          // Настраиваем камеру, чтобы было видно весь маршрут
          fitMapToBounds();
        } else {
          print('Directions API error: ${data['status']}');
        }
      } else {
        print('Failed to get directions: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting directions: $e');
    }
  }

  // Добавление маркера на карту
  void _addMarker(LatLng position, String markerId, BitmapDescriptor icon,
      {String? title}) {
    final marker = Marker(
      markerId: MarkerId(markerId),
      position: position,
      infoWindow: InfoWindow(title: title ?? markerId),
      icon: icon,
    );

    _markers.add(marker);
    notifyListeners();
  }

  // Создание демо-маршрута между двумя точками
  void _createDemoRoute(LatLng origin, LatLng destination) {
    // Очищаем существующие маркеры и маршруты
    _polylines.clear();

    // Создаем список точек для демо-маршрута
    List<LatLng> points = [];
    points.add(origin);

    // Вычисляем общее расстояние
    final latDiff = destination.latitude - origin.latitude;
    final lngDiff = destination.longitude - origin.longitude;
    final totalDistance = math.sqrt(latDiff * latDiff + lngDiff * lngDiff);

    // Создаем промежуточные точки, имитирующие движение по дорогам
    final random = math.Random();
    final numPoints =
        10; // Увеличиваем количество точек для более плавного маршрута

    for (int i = 1; i <= numPoints; i++) {
      final ratio = i / (numPoints + 1);

      // Базовые координаты для текущей точки
      double lat = origin.latitude + latDiff * ratio;
      double lng = origin.longitude + lngDiff * ratio;

      // Добавляем отклонения, имитирующие движение по дорогам
      if (i % 2 == 0) {
        // Для четных точек делаем отклонение вправо
        lat += (random.nextDouble() - 0.5) * 0.001 * totalDistance;
        lng += random.nextDouble() * 0.001 * totalDistance;
      } else {
        // Для нечетных точек делаем отклонение влево
        lat += (random.nextDouble() - 0.5) * 0.001 * totalDistance;
        lng -= random.nextDouble() * 0.001 * totalDistance;
      }

      points.add(LatLng(lat, lng));
    }

    points.add(destination);

    // Создаем Polyline с более толстой линией
    final String polylineId =
        'polyline_${DateTime.now().millisecondsSinceEpoch}';
    final Polyline polyline = Polyline(
      polylineId: PolylineId(polylineId),
      color: Colors.blue,
      points: points,
      width: 8, // Увеличиваем толщину линии
      patterns: [
        PatternItem.dash(20),
        PatternItem.gap(10)
      ], // Добавляем пунктирный стиль
    );

    _polylines.add(polyline);

    // Добавляем маркеры начала и конца маршрута
    _addMarker(
      origin,
      'origin',
      BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      title: 'Точка отправления',
    );

    _addMarker(
      destination,
      'destination',
      BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      title: 'Точка назначения',
    );

    // Настраиваем камеру, чтобы было видно весь маршрут
    Future.microtask(() {
      fitMapToBounds();
      notifyListeners();
    });
  }

  // Генерация координат в демо-режиме
  LatLng _generateDemoCoordinates(
      double latitude, double longitude, double radius) {
    // Генерируем координаты в пределах заданного радиуса
    final random = math.Random();
    final double lat = latitude + (random.nextDouble() - 0.5) * radius;
    final double lng = longitude + (random.nextDouble() - 0.5) * radius;

    return LatLng(lat, lng);
  }

  // Перемещение камеры к указанной позиции
  Future<void> _animateToPosition(LatLng position) async {
    if (_mapController == null) return;

    await _mapController!.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: position,
          zoom: 15,
        ),
      ),
    );
  }

  // Настройка камеры для отображения всего маршрута
  Future<void> _fitMapToRoute(List<LatLng> points) async {
    if (_mapController == null || points.isEmpty) return;

    // Находим границы маршрута
    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (final point in points) {
      minLat = point.latitude < minLat ? point.latitude : minLat;
      maxLat = point.latitude > maxLat ? point.latitude : maxLat;
      minLng = point.longitude < minLng ? point.longitude : minLng;
      maxLng = point.longitude > maxLng ? point.longitude : maxLng;
    }

    // Создаем границы с учетом отступов
    final bounds = LatLngBounds(
      southwest: LatLng(minLat - 0.002, minLng - 0.002),
      northeast: LatLng(maxLat + 0.002, maxLng + 0.002),
    );

    // Перемещаем камеру
    await _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 50),
    );
  }

  // Очистка всех маркеров на карте
  void clearMarkers() {
    _markers.clear();
    notifyListeners();
  }

  // Очистка маршрута
  void clearRoute() {
    _polylines.clear();
    notifyListeners();
  }

  // Установка позиции отправления
  void setOriginPosition(LatLng position) {
    _origin = position;
    _addMarker(
      position,
      'origin',
      BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      title: 'Точка отправления',
    );
    notifyListeners();
  }

  // Установка позиции назначения
  void setDestinationPosition(LatLng position) {
    _destination = position;
    _addMarker(
      position,
      'destination',
      BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      title: 'Точка назначения',
    );
    notifyListeners();
  }

  // Подгонка карты, чтобы были видны все маркеры
  void fitMapToBounds() {
    if (_mapController != null && _origin != null && _destination != null) {
      final bounds = LatLngBounds(
        southwest: LatLng(
          math.min(_origin!.latitude, _destination!.latitude),
          math.min(_origin!.longitude, _destination!.longitude),
        ),
        northeast: LatLng(
          math.max(_origin!.latitude, _destination!.latitude),
          math.max(_origin!.longitude, _destination!.longitude),
        ),
      );

      _mapController!.animateCamera(
        CameraUpdate.newLatLngBounds(bounds, 50), // 50 - отступ от краев
      );
    }
  }

  // Очистка ресурсов при уничтожении сервиса
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  // Обновление состояния карты и уведомление слушателей
  void _notifyListeners() {
    notifyListeners();
  }

  // При изменении маркеров
  void _updateMarkers() {
    _notifyListeners();
  }

  // При изменении полилиний
  void _updatePolylines() {
    _notifyListeners();
  }

  // При изменении местоположения
  void _updateLocation() {
    _notifyListeners();
  }

  Future<void> _initMapService() async {
    if (_isDemoMode) {
      _currentLatLng = _generateDemoCoordinates(55.751244, 37.618423, 0.005);
      _origin = _currentLatLng;
      _destination = LatLng(
        _currentLatLng!.latitude + 0.01,
        _currentLatLng!.longitude + 0.01,
      );
      await getDirections(_origin!, _destination!);
    } else {
      await _getCurrentLocation();
    }
  }

  MapService() {
    _isDemoMode = false;
    _initMapService();
  }
}
