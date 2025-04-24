import 'dart:async';
import 'dart:math' as math;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:location/location.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mama_taxi/screens/home_screen.dart';
import 'package:mama_taxi/services/route_service.dart';
import 'package:flutter/services.dart' show rootBundle;

// Простая реализация маркера для карты
class MapMarker {
  final LatLng point;
  final String markerId;
  final Color color;
  final String? title;

  MapMarker({
    required this.point,
    required this.markerId,
    this.color = Colors.red,
    this.title,
  });
}

class MapService extends ChangeNotifier {
  // Для демо-режима можно использовать фиксированные координаты
  bool _isDemoMode = false;

  // Текущее местоположение
  SimpleLocation? _currentLocation;
  LocationData? _currentLocationData;

  // Маркеры на карте
  final List<MapMarker> _markers = [];

  // Полилиния маршрута
  final List<List<LatLng>> _routes = [];

  // Начальная и конечная точки маршрута
  SimpleLocation? _origin;
  SimpleLocation? _destination;

  // Переменная для отслеживания инициализации карты
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  // Контроллер для Google Maps
  final Completer<GoogleMapController> _mapController =
      Completer<GoogleMapController>();

  // Демо-координаты центра карты (Москва)
  final SimpleLocation _demoCenter =
      SimpleLocation(latitude: 55.751244, longitude: 37.618423);

  // Геттеры для доступа к данным
  List<MapMarker> get markers => _markers;
  List<List<LatLng>> get routes => _routes;
  SimpleLocation? get currentLocation => _currentLocation;
  LocationData? get currentLocationData => _currentLocationData;
  bool get isDemoMode => _isDemoMode;

  // Инициализация сервиса
  Future<void> init() async {
    try {
      if (!_isDemoMode) {
        await _getCurrentLocation();
        if (_currentLocationData != null) {
          _currentLocation = SimpleLocation(
            latitude: _currentLocationData!.latitude!,
            longitude: _currentLocationData!.longitude!,
          );
        }
      } else {
        // В демо-режиме используем фиксированные координаты Москвы
        _currentLocation =
            SimpleLocation(latitude: 55.751244, longitude: 37.618423);
        _origin = _currentLocation;
        _destination = SimpleLocation(
          latitude: 55.751244 + 0.02, // Увеличиваем расстояние
          longitude: 37.618423 + 0.03, // Увеличиваем расстояние
        );
      }
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      print('Error initializing map service: $e');
      // Если не удалось получить местоположение, используем координаты центра Москвы
      _currentLocation =
          SimpleLocation(latitude: 55.751244, longitude: 37.618423);
      _isInitialized = true;
      notifyListeners();
    }
  }

  // Метод для получения текущего местоположения пользователя
  Future<LocationData?> getCurrentLocation() async {
    return await _getCurrentLocation();
  }

  // Приватный метод для получения текущего местоположения
  Future<LocationData?> _getCurrentLocation() async {
    Location location = Location();
    bool serviceEnabled;
    PermissionStatus permissionGranted;

    // Проверяем, включена ли геолокация
    serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) {
        throw Exception('Сервисы геолокации отключены');
      }
    }

    // Проверяем разрешения
    permissionGranted = await location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        throw Exception('Нет разрешения на использование геолокации');
      }
    }

    // Получаем координаты
    _currentLocationData = await location.getLocation();

    // Устанавливаем обработчик для обновления местоположения
    location.onLocationChanged.listen((LocationData currentLocation) {
      _currentLocationData = currentLocation;
      _currentLocation = SimpleLocation(
        latitude: currentLocation.latitude!,
        longitude: currentLocation.longitude!,
      );
      notifyListeners();
    });

    return _currentLocationData;
  }

  // Обновлённый метод загрузки стиля карты
  Future<String?> loadMapStyle() async {
    try {
      // Путь к файлу стиля карты. Нужно создать этот файл в assets/maps/style.json
      const String path = 'assets/maps/style.json';
      return await rootBundle.loadString(path);
    } catch (e) {
      debugPrint('Ошибка загрузки стиля карты: $e');
      return null;
    }
  }

  // Метод для установки стиля карты
  Future<void> setMapStyle(GoogleMapController controller) async {
    final String? style = await loadMapStyle();
    if (style != null) {
      await controller.setMapStyle(style);
    }
  }

  // Инициализация сервиса карты
  Future<void> initialize() async {
    print('Инициализация MapService с Google Maps на русском языке');

    if (!_mapController.isCompleted) return;

    try {
      final controller = await _mapController.future;
      // Устанавливаем русский язык как основной для карты
      await controller.setMapStyle('''
        [
          {
            "featureType": "administrative",
            "elementType": "labels.text.fill",
            "stylers": [{ "color": "#444444" }]
          },
          {
            "featureType": "water",
            "elementType": "geometry",
            "stylers": [{ "color": "#e9e9e9" }]
          }
        ]
      ''');
    } catch (e) {
      print('Ошибка при установке стиля карты: $e');
    }
  }

  // Поиск адреса по названию
  Future<SimpleLocation?> searchAddress(String address) async {
    if (isDemoMode) {
      // В демо-режиме генерируем координаты вокруг центра Москвы
      return _generateDemoCoordinates(55.751244, 37.618423, 0.005);
    }

    try {
      // Добавляем "Москва" к адресу, если не указаны Москва или область
      String searchQuery = address;
      if (!searchQuery.toLowerCase().contains('москва') &&
          !searchQuery.toLowerCase().contains('московская')) {
        searchQuery = '$searchQuery, Москва, Россия';
      } else if (!searchQuery.toLowerCase().contains('россия')) {
        searchQuery = '$searchQuery, Россия';
      }

      print('Поиск адреса: $searchQuery');

      // Используем geocoding для поиска координат с указанием русской локали
      List<geocoding.Location> locations = await geocoding
          .locationFromAddress(searchQuery, localeIdentifier: 'ru_RU');

      if (locations.isNotEmpty) {
        // Проверяем, находится ли точка в пределах Москвы и области
        if (!isLocationInMoscowRegion(
            locations.first.latitude, locations.first.longitude)) {
          print('Найденные координаты вне допустимой зоны (Москва и область)');
          return null;
        }

        print(
            'Найдены координаты: ${locations.first.latitude}, ${locations.first.longitude}');
        return SimpleLocation(
          latitude: locations.first.latitude,
          longitude: locations.first.longitude,
        );
      } else {
        print('Координаты не найдены, пробую альтернативный поиск');

        // Пробуем искать через Nominatim
        SimpleLocation? location =
            await _searchAddressWithNominatim(searchQuery);

        // Проверяем, находится ли точка в пределах Москвы и области
        if (location != null) {
          if (!isLocationInMoscowRegion(
              location.latitude, location.longitude)) {
            print(
                'Найденные координаты через Nominatim вне допустимой зоны (Москва и область)');
            return null;
          }
          return location;
        }
        return null;
      }
    } catch (e) {
      print('Ошибка поиска адреса: $e');

      try {
        // Пробуем искать с явным указанием Москвы
        String searchQuery = address;
        if (!searchQuery.toLowerCase().contains('москва')) {
          searchQuery = '$searchQuery, Москва, Россия';
        }

        List<geocoding.Location> locations = await geocoding
            .locationFromAddress(searchQuery, localeIdentifier: 'ru_RU');

        if (locations.isNotEmpty) {
          // Проверяем, находится ли точка в пределах Москвы и области
          if (!isLocationInMoscowRegion(
              locations.first.latitude, locations.first.longitude)) {
            print(
                'Найденные координаты вне допустимой зоны (Москва и область)');
            return null;
          }

          print(
              'Найдены координаты (альтернативный поиск): ${locations.first.latitude}, ${locations.first.longitude}');
          return SimpleLocation(
            latitude: locations.first.latitude,
            longitude: locations.first.longitude,
          );
        } else {
          return null;
        }
      } catch (e) {
        print('Ошибка альтернативного поиска адреса: $e');
        return null;
      }
    }
  }

  // Проверка, находится ли точка в пределах Москвы и области
  bool isLocationInMoscowRegion(double lat, double lng) {
    return _isLocationInMoscowRegion(lat, lng);
  }

  // Внутренняя проверка региона
  bool _isLocationInMoscowRegion(double lat, double lng) {
    // Примерные границы Московской области с запасом
    const double minLat = 54.5; // Расширены на юг
    const double maxLat = 57.0; // Расширены на север
    const double minLng = 35.0; // Расширены на запад
    const double maxLng = 40.0; // Расширены на восток

    return lat >= minLat && lat <= maxLat && lng >= minLng && lng <= maxLng;
  }

  // Поиск адреса через Nominatim API (OpenStreetMap) для лучшей поддержки русских адресов
  Future<SimpleLocation?> _searchAddressWithNominatim(String address) async {
    try {
      final encodedAddress = Uri.encodeComponent(address);
      final url =
          'https://nominatim.openstreetmap.org/search?q=$encodedAddress&format=json&addressdetails=1&accept-language=ru';

      print('Поиск через Nominatim: $url');

      final response = await http.get(Uri.parse(url),
          headers: {'User-Agent': 'MamaTaxi_App/1.0', 'Accept-Language': 'ru'});

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data != null && data is List && data.isNotEmpty) {
          final location = data[0];
          final double lat = double.parse(location['lat']);
          final double lon = double.parse(location['lon']);

          print('Найдены координаты через Nominatim: $lat, $lon');
          return SimpleLocation(latitude: lat, longitude: lon);
        }
      }

      print('Не удалось найти адрес через Nominatim');
      return null;
    } catch (e) {
      print('Ошибка поиска через Nominatim: $e');
      return null;
    }
  }

  // Установка адреса отправления
  Future<bool> setOriginAddress(String address) async {
    final position = await searchAddress(address);

    if (position != null) {
      _origin = position;
      _addMarker(position, 'origin', Colors.green, 'Отправление');
      notifyListeners();

      if (_destination != null) {
        // Логика для расчета маршрута будет в RouteService
      }

      return true;
    }

    return false;
  }

  // Установка адреса назначения
  Future<bool> setDestinationAddress(String address) async {
    final position = await searchAddress(address);

    if (position != null) {
      _destination = position;
      _addMarker(position, 'destination', Colors.red, 'Назначение');
      notifyListeners();

      if (_origin != null) {
        // Логика для расчета маршрута будет в RouteService
      }

      return true;
    }

    return false;
  }

  // Добавление маркера на карту
  void _addMarker(
      SimpleLocation position, String markerId, Color color, String? title) {
    // Удаляем предыдущий маркер с таким же ID
    _markers.removeWhere((marker) => marker.markerId == markerId);

    // Добавляем новый маркер
    _markers.add(MapMarker(
      point: LatLng(position.latitude, position.longitude),
      markerId: markerId,
      color: color,
      title: title,
    ));

    notifyListeners();
  }

  // Генерация координат в демо-режиме
  SimpleLocation _generateDemoCoordinates(
      double latitude, double longitude, double radius) {
    // Генерируем координаты в пределах заданного радиуса
    final random = math.Random();
    final double lat = latitude + (random.nextDouble() - 0.5) * radius;
    final double lng = longitude + (random.nextDouble() - 0.5) * radius;

    return SimpleLocation(latitude: lat, longitude: lng);
  }

  // Очистка всех маркеров на карте
  void clearMarkers() {
    _markers.clear();
    notifyListeners();
  }

  // Очистка маршрута
  void clearRoute() {
    _routes.clear();
    notifyListeners();
  }

  // Установка позиции отправления
  void setOriginPosition(SimpleLocation position) {
    _origin = position;
    _addMarker(position, 'origin', Colors.green, 'Точка отправления');
    notifyListeners();

    // Если есть точка назначения, автоматически обновляем маршрут
    if (_destination != null) {
      getDirections(_origin!, _destination!);
    }
  }

  // Установка позиции назначения
  void setDestinationPosition(SimpleLocation position) {
    _destination = position;
    _addMarker(position, 'destination', Colors.red, 'Точка назначения');
    notifyListeners();

    // Если есть точка отправления, автоматически обновляем маршрут
    if (_origin != null) {
      getDirections(_origin!, _destination!);
    }
  }

  // Получение маршрута с использованием RouteService
  Future<void> getDirections(
      SimpleLocation origin, SimpleLocation destination) async {
    try {
      // Создаем экземпляр RouteService напрямую
      final routeService = RouteService();

      // Получаем точки маршрута
      final List<LatLng> routePoints =
          await routeService.getRoute(origin, destination);

      print("Получено ${routePoints.length} точек маршрута");

      if (routePoints.isEmpty) {
        print("Маршрут пустой! Создаем прямую линию...");
        // Создаем прямую линию, если маршрут пустой
        _routes.clear();
        _routes.add([
          LatLng(origin.latitude, origin.longitude),
          LatLng(destination.latitude, destination.longitude),
        ]);
      } else {
        // Добавляем маршрут
        _routes.clear();
        _routes.add(routePoints);
      }

      notifyListeners();
    } catch (e) {
      print('Error getting directions: $e');

      // В случае ошибки создаем прямую линию между точками
      final List<LatLng> straightLine = [
        LatLng(origin.latitude, origin.longitude),
        LatLng(destination.latitude, destination.longitude),
      ];

      _routes.clear();
      _routes.add(straightLine);

      notifyListeners();
    }
  }

  // Метод для обновления всех объектов на карте
  void _updateMapObjects() {
    notifyListeners();
  }

  // Подгонка карты, чтобы были видны все маркеры
  Future<void> fitMapToBounds() async {
    if (_markers.isEmpty || !_mapController.isCompleted) {
      return;
    }

    try {
      final GoogleMapController controller = await _mapController.future;

      // Находим крайние точки для всех маркеров
      final double minLat =
          _markers.map((m) => m.point.latitude).reduce(math.min);
      final double maxLat =
          _markers.map((m) => m.point.latitude).reduce(math.max);
      final double minLng =
          _markers.map((m) => m.point.longitude).reduce(math.min);
      final double maxLng =
          _markers.map((m) => m.point.longitude).reduce(math.max);

      // Создаем границы
      final LatLngBounds bounds = LatLngBounds(
        southwest: LatLng(minLat, minLng),
        northeast: LatLng(maxLat, maxLng),
      );

      // Добавляем отступы
      final double padding = 50.0;

      // Перемещаем камеру, чтобы были видны все маркеры
      controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, padding));
    } catch (e) {
      print('Error fitting map to bounds: $e');
    }

    notifyListeners();
  }

  // Очистка ресурсов при уничтожении сервиса
  void dispose() {
    super.dispose();
  }

  MapService() {
    _isDemoMode = false;
    _initMapService();
  }

  Future<void> _initMapService() async {
    if (_isDemoMode) {
      _currentLocation = _generateDemoCoordinates(55.751244, 37.618423, 0.005);
      _origin = _currentLocation;
      _destination = SimpleLocation(
        latitude: _currentLocation!.latitude + 0.01,
        longitude: _currentLocation!.longitude + 0.01,
      );
    } else {
      await _getCurrentLocation();
    }
  }

  // Преобразование SimpleLocation в LatLng
  LatLng simpleLocationToLatLng(SimpleLocation location) {
    return LatLng(location.latitude, location.longitude);
  }

  // Создание маркера Google Maps
  Marker createGoogleMapMarker(SimpleLocation location,
      {Color color = Colors.red, String? markerId, String? title}) {
    return Marker(
      markerId: MarkerId(markerId ?? DateTime.now().toString()),
      position: LatLng(location.latitude, location.longitude),
      infoWindow: InfoWindow(
        title: title ?? 'Маркер',
      ),
      icon: BitmapDescriptor.defaultMarkerWithHue(color == Colors.red
          ? BitmapDescriptor.hueRed
          : color == Colors.green
              ? BitmapDescriptor.hueGreen
              : color == Colors.blue
                  ? BitmapDescriptor.hueBlue
                  : BitmapDescriptor.hueRed),
    );
  }

  // Получение маркеров Google Maps
  Set<Marker> getGoogleMapMarkers() {
    final Set<Marker> googleMarkers = {};

    for (var marker in _markers) {
      googleMarkers.add(
        Marker(
          markerId: MarkerId(marker.markerId),
          position: marker.point,
          infoWindow: InfoWindow(
            title: marker.title ?? 'Маркер',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(marker.color == Colors.red
              ? BitmapDescriptor.hueRed
              : marker.color == Colors.green
                  ? BitmapDescriptor.hueGreen
                  : marker.color == Colors.blue
                      ? BitmapDescriptor.hueBlue
                      : BitmapDescriptor.hueRed),
        ),
      );
    }

    return googleMarkers;
  }

  // Центрирование карты на указанной локации
  Future<void> centerMap(SimpleLocation location, {double zoom = 15.0}) async {
    if (!_mapController.isCompleted) return;

    final GoogleMapController controller = await _mapController.future;

    controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(location.latitude, location.longitude),
          zoom: zoom,
        ),
      ),
    );
  }

  // Отображение маршрута на карте - возвращает набор полилиний
  Set<Polyline> getRoutePolylines() {
    final Set<Polyline> polylines = {};

    for (var i = 0; i < _routes.length; i++) {
      if (_routes[i].isNotEmpty) {
        print("Добавление полилинии с ${_routes[i].length} точками");
        polylines.add(
          Polyline(
            polylineId: PolylineId('route_$i'),
            points: _routes[i],
            color: Colors.blue,
            width: 5,
            patterns: [
              PatternItem.dash(20),
              PatternItem.gap(10),
            ],
            startCap: Cap.roundCap,
            endCap: Cap.roundCap,
            jointType: JointType.round,
          ),
        );
      } else {
        print("Пустой маршрут - пропускаем полилинию");
      }
    }

    return polylines;
  }

  // Установка контроллера карты
  void setMapController(GoogleMapController controller) {
    if (!_mapController.isCompleted) {
      _mapController.complete(controller);
    }
  }

  // Получение адреса по координатам
  Future<String?> getAddressFromLatLng(
      double latitude, double longitude) async {
    if (isDemoMode) {
      return 'Тестовый адрес, Москва, Россия';
    }

    try {
      // Сначала пробуем через Nominatim для более точных результатов на русском
      final String? nominatimAddress =
          await _getAddressFromNominatim(latitude, longitude);
      if (nominatimAddress != null && nominatimAddress.isNotEmpty) {
        return nominatimAddress;
      }

      // Если Nominatim не сработал, используем стандартный geocoding
      List<geocoding.Placemark> placemarks =
          await geocoding.placemarkFromCoordinates(latitude, longitude,
              localeIdentifier: 'ru_RU');

      if (placemarks.isNotEmpty) {
        geocoding.Placemark place = placemarks[0];
        // Форматируем адрес с указанием города и страны
        final street = place.street ?? '';
        final number = place.subThoroughfare ?? '';
        final city = place.locality ?? '';
        final area = place.administrativeArea ?? '';
        final country = place.country ?? 'Россия';

        String address = '';

        if (street.isNotEmpty) {
          address += street;
          if (number.isNotEmpty) {
            address += ' $number';
          }
        }

        if (city.isNotEmpty) {
          if (address.isNotEmpty) address += ', ';
          address += city;
        }

        if (area.isNotEmpty && area != city) {
          if (address.isNotEmpty) address += ', ';
          address += area;
        }

        if (country.isNotEmpty) {
          if (address.isNotEmpty) address += ', ';
          address += country;
        }

        return address;
      }
    } catch (e) {
      print('Ошибка получения адреса по координатам: $e');
    }
    return null;
  }

  // Получение адреса через Nominatim (OpenStreetMap) для лучшей поддержки русских адресов
  Future<String?> _getAddressFromNominatim(
      double latitude, double longitude) async {
    try {
      final url =
          'https://nominatim.openstreetmap.org/reverse?lat=$latitude&lon=$longitude&format=json&addressdetails=1&accept-language=ru';

      final response = await http.get(Uri.parse(url),
          headers: {'User-Agent': 'MamaTaxi_App/1.0', 'Accept-Language': 'ru'});

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data != null && data['display_name'] != null) {
          return data['display_name'];
        }
      }

      return null;
    } catch (e) {
      print('Ошибка получения адреса через Nominatim: $e');
      return null;
    }
  }

  // Обновление маршрута (вызывает getDirections если заданы точки отправления и назначения)
  Future<bool> updateRoute() async {
    if (_origin != null && _destination != null) {
      await getDirections(_origin!, _destination!);
      return true;
    }
    return false;
  }

  // Поиск предложений адресов (автозаполнение)
  Future<List<String>> searchAddressSuggestions(String query) async {
    if (query.length < 3) {
      return [];
    }

    List<String> suggestions = [];

    try {
      // Добавляем "Москва" к запросу, если не указано
      String searchQuery = query;
      if (!searchQuery.toLowerCase().contains('москва') &&
          !searchQuery.toLowerCase().contains('московская')) {
        searchQuery = '$searchQuery, Москва';
      }

      // Вариант 1: Nominatim для поиска предложений
      suggestions.addAll(await _searchSuggestionsWithNominatim(searchQuery));

      // Если Nominatim не дал результатов, пробуем дополнить начальными предложениями
      if (suggestions.isEmpty) {
        // Если запрос начинается с "улица" или содержит номер дома, пробуем сформировать адрес
        if (searchQuery.toLowerCase().contains('улица') ||
            searchQuery.toLowerCase().contains('ул.') ||
            _containsHouseNumber(searchQuery)) {
          suggestions.add('$searchQuery, Москва, Россия');
        }

        // Пробуем предложить известные районы Москвы
        for (var district in _moscowDistricts) {
          if (district.toLowerCase().contains(searchQuery.toLowerCase()) ||
              searchQuery.toLowerCase().contains(district.toLowerCase())) {
            suggestions.add('$district, Москва, Россия');
          }
        }
      }

      return suggestions;
    } catch (e) {
      print('Ошибка поиска предложений адресов: $e');
      return [query];
    }
  }

  // Поиск предложений через Nominatim API
  Future<List<String>> _searchSuggestionsWithNominatim(String query) async {
    List<String> results = [];

    try {
      final encodedQuery = Uri.encodeComponent(query);
      final url =
          'https://nominatim.openstreetmap.org/search?q=$encodedQuery&format=json&addressdetails=1&accept-language=ru&countrycodes=ru&viewbox=35.0,57.0,40.0,54.5&bounded=1&limit=10';

      print('Поиск предложений адресов через Nominatim: $url');

      final response = await http.get(Uri.parse(url),
          headers: {'User-Agent': 'MamaTaxi_App/1.0', 'Accept-Language': 'ru'});

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data != null && data is List) {
          for (var item in data) {
            if (item['display_name'] != null) {
              String address = item['display_name'];

              // Проверяем, находится ли адрес в Москве или области
              if (_isAddressInMoscowRegion(address)) {
                // Форматируем адрес для удобочитаемости
                address = _formatNominatimAddress(address);
                results.add(address);
              }
            }
          }
        }
      }

      return results;
    } catch (e) {
      print('Ошибка поиска через Nominatim: $e');
      return [];
    }
  }

  // Проверка, содержит ли строка номер дома
  bool _containsHouseNumber(String text) {
    // Регулярное выражение для поиска номера дома (например: 10, 10а, 10/2, 10 к.2)
    RegExp houseNumberRegex =
        RegExp(r'\b\d+(\s*[а-яА-Я])?(\s*/\s*\d+)?(\s*к\.?\s*\d+)?\b');
    return houseNumberRegex.hasMatch(text);
  }

  // Проверка, относится ли адрес к Москве или области
  bool _isAddressInMoscowRegion(String address) {
    address = address.toLowerCase();
    return address.contains('москва') ||
        address.contains('московская область') ||
        address.contains('москов') ||
        _moscowDistricts
            .any((district) => address.contains(district.toLowerCase()));
  }

  // Форматирование адреса от Nominatim для лучшей читаемости
  String _formatNominatimAddress(String address) {
    // Удаляем страну из конца, если это Россия
    if (address.endsWith(', Россия')) {
      address = address.substring(0, address.length - 8) + ', Россия';
    }

    // Убираем избыточную информацию
    List<String> parts = address.split(', ');
    if (parts.length > 7) {
      // Оставляем самые важные части адреса: улица, дом, район, город
      List<String> significantParts = [];

      // Ищем улицу и дом
      bool foundStreet = false;
      for (var part in parts) {
        if (part.toLowerCase().contains('улица') ||
            part.toLowerCase().contains('проспект') ||
            part.toLowerCase().contains('шоссе') ||
            part.toLowerCase().contains('переулок') ||
            _containsHouseNumber(part)) {
          significantParts.add(part);
          foundStreet = true;
        }
      }

      // Обязательно добавляем город и регион
      significantParts.add('Москва');
      significantParts.add('Россия');

      if (significantParts.length >= 2) {
        return significantParts.join(', ');
      }
    }

    return address;
  }

  // Список районов Москвы для проверки адресов
  final List<String> _moscowDistricts = [
    'Центральный',
    'Северный',
    'Северо-Восточный',
    'Восточный',
    'Юго-Восточный',
    'Южный',
    'Юго-Западный',
    'Западный',
    'Северо-Западный',
    'Зеленоград',
    'Новомосковский',
    'Троицкий',
    'Хамовники',
    'Арбат',
    'Тверской',
    'Пресненский',
    'Мещанский',
    'Красносельский',
    'Басманный',
    'Таганский',
    'Замоскворечье',
    'Якиманка',
    'Донской',
    'Даниловский',
    'Нагатино-Садовники',
    'Нагатинский Затон',
    'Чертаново Северное',
    'Чертаново Центральное',
    'Чертаново Южное',
    'Бирюлево Западное',
    'Бирюлево Восточное',
    'Царицыно',
    'Москворечье-Сабурово',
    'Зябликово',
    'Орехово-Борисово Северное',
    'Орехово-Борисово Южное',
    'Братеево',
    'Марьино',
    'Люблино',
    'Капотня',
    'Печатники',
    'Лефортово',
    'Текстильщики',
    'Кузьминки',
    'Выхино-Жулебино',
    'Рязанский',
    'Нижегородский',
    'Некрасовка',
    'Перово',
    'Новогиреево',
    'Вешняки',
    'Ивановское',
    'Сокольники',
    'Метрогородок',
    'Богородское',
    'Преображенское',
    'Гольяново',
    'Северное Измайлово',
    'Измайлово',
    'Восточное Измайлово',
    'Соколиная Гора',
    'Марьина Роща',
    'Алексеевский',
    'Ростокино',
    'Останкинский',
    'Свиблово',
    'Бабушкинский',
    'Лосиноостровский',
    'Ярославский',
    'Метрогородок',
    'Богородское',
    'Сокольники'
  ];
}
