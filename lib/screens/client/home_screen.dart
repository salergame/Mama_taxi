import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mama_taxi/models/trip_model.dart';
import 'package:mama_taxi/models/user_location.dart';
import 'package:mama_taxi/providers/trip_provider.dart';
import 'package:mama_taxi/services/auth_service.dart';
import 'package:mama_taxi/widgets/add_child_modal.dart';
import 'package:mama_taxi/widgets/drawer_tile.dart';
import 'package:mama_taxi/widgets/services_modal.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mama_taxi/services/taxi_service.dart';
import 'package:mama_taxi/services/map_service.dart';
import 'package:mama_taxi/screens/account_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mama_taxi/services/firebase_service.dart';
import 'package:mama_taxi/providers/user_provider.dart';
import 'package:mama_taxi/models/child_model.dart';

// Для совместимости между типами
class SimpleLocation {
  final double latitude;
  final double longitude;

  SimpleLocation({required this.latitude, required this.longitude});

  LatLng toLatLng() {
    return LatLng(latitude, longitude);
  }
}

class CurrentLocationLayer extends StatelessWidget {
  final Position? position;

  const CurrentLocationLayer({Key? key, this.position}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (position == null) {
      return const SizedBox.shrink();
    }

    return Positioned(
      left: 0,
      top: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(8),
        color: Colors.blue.withOpacity(0.3),
        child: Center(
          child: Text(
            'Ваша позиция: ${position!.latitude.toStringAsFixed(6)}, ${position!.longitude.toStringAsFixed(6)}',
            style: const TextStyle(color: Colors.blue),
          ),
        ),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final AuthService _authService = AuthService();
  final TextEditingController _originController = TextEditingController();
  final TextEditingController _destController = TextEditingController();
  bool _isLoading = false;
  bool _isDriverMode = false;
  bool _isOnline = false; // Для режима водителя

  // Текущая позиция
  Position? _currentPosition;

  // Контроллер для Google Maps
  final Completer<GoogleMapController> _mapController = Completer();

  // Набор маркеров для карты
  final Set<Marker> _markers = {};

  // Полилинии для маршрутов
  Set<Polyline> _polylines = {};

  // Список популярных городов России для быстрого выбора
  static final List<String> popularRussianCities = [
    'Москва, Россия',
    'Химки, Московская область, Россия',
    'Одинцово, Московская область, Россия',
    'Мытищи, Московская область, Россия',
    'Красногорск, Московская область, Россия',
    'Балашиха, Московская область, Россия',
    'Люберцы, Московская область, Россия',
    'Королёв, Московская область, Россия',
    'Зеленоград, Москва, Россия',
    'Подольск, Московская область, Россия',
    'Долгопрудный, Московская область, Россия',
    'Реутов, Московская область, Россия',
    'Домодедово, Московская область, Россия',
    'Жуковский, Московская область, Россия',
    'Раменское, Московская область, Россия'
  ];

  // Добавляем переменные для поиска и результатов
  List<String> _searchResults = [];
  bool _isSearching = false;
  bool _isSearchingOrigin =
      true; // true - поиск для origin, false - для destination
  bool _isLoadingAddresses = false; // Флаг для отображения индикатора загрузки
  String _selectedService = "Мама такси"; // Выбранный тариф по умолчанию
  int _selectedPrice = 450; // Цена по умолчанию
  List<Map<String, dynamic>> _additionalServices = []; // Дополнительные услуги

  // Инициализация MapService для поиска адресов и маршрутов
  late MapService _mapService;
  void _initMapService() {
    try {
      // Пробуем получить MapService из Provider
      _mapService = Provider.of<MapService>(context, listen: false);
    } catch (e) {
      // Если Provider недоступен, создаем локальный экземпляр
      print('Создание локального экземпляра MapService: $e');
      _mapService = MapService();
    }
  }

  @override
  void initState() {
    super.initState();
    _determinePosition();
    _checkUserType();
    _initMapService();
  }

  // Метод для получения текущей позиции
  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Проверяем, включены ли сервисы геолокации
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Включите службу геолокации для вашего местоположения'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Для работы приложения требуются разрешения на геолокацию'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Разрешения на геолокацию отклонены навсегда. Измените их в настройках'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition();

      // Проверяем, находится ли пользователь в зоне обслуживания (Москва и область)
      final mapService = Provider.of<MapService>(context, listen: false);

      if (!mapService.isLocationInMoscowRegion(
          position.latitude, position.longitude)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Вы находитесь вне зоны обслуживания. Сервис работает только в Москве и области'),
            backgroundColor: Colors.orange,
          ),
        );
        // Центрируем карту на Москве вместо текущей локации
        position = Position(
          latitude: 55.751244,
          longitude: 37.618423,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          heading: 0,
          speed: 0,
          speedAccuracy: 0,
          altitudeAccuracy: 0,
          headingAccuracy: 0,
        );
      }

      setState(() {
        _currentPosition = position;
        _addMarker(
            LatLng(position.latitude, position.longitude),
            'current_location',
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
            'Моя локация');
      });

      _centerOnPosition(position);
    } catch (e) {
      print('Ошибка получения местоположения: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка получения местоположения: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Добавление маркера на карту
  void _addMarker(
      LatLng position, String markerId, BitmapDescriptor icon, String title) {
    final marker = Marker(
      markerId: MarkerId(markerId),
      position: position,
      icon: icon,
      infoWindow: InfoWindow(
        title: title,
      ),
    );

    setState(() {
      _markers.add(marker);
    });
  }

  // Центрирование карты на указанной позиции
  Future<void> _centerOnPosition(Position position) async {
    if (!_mapController.isCompleted) return;

    final controller = await _mapController.future;
    controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(position.latitude, position.longitude),
          zoom: 15,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(_isDriverMode ? 'Мама Такси - Водитель' : 'Мама Такси'),
        backgroundColor: const Color(0xFF53CFC4),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Выйти',
          ),
        ],
      ),
      drawer: _buildDrawer(context),
      body:
          _isDriverMode ? _buildDriverInterface() : _buildPassengerInterface(),
    );
  }

  Widget _buildDriverInterface() {
    return Column(
      children: [
        // Статус водителя
        Container(
          color: const Color(0xFF53CFC4),
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _isOnline ? 'В сети' : 'Не в сети',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 10),
              Switch(
                value: _isOnline,
                onChanged: (value) {
                  setState(() {
                    _isOnline = value;
                  });
                },
                activeColor: Colors.white,
                activeTrackColor: Colors.green,
              ),
            ],
          ),
        ),

        Expanded(
          child: _isOnline
              ? _buildActiveDriverInterface()
              : _buildOfflineDriverInterface(),
        ),
      ],
    );
  }

  Widget _buildActiveDriverInterface() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.search,
            size: 100,
            color: Color(0xFF53CFC4),
          ),
          const SizedBox(height: 20),
          const Text(
            'Ожидание заказов',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Вы в сети и можете получать заказы',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 20),
          // Здесь в будущем можно добавить статистику по заказам и т.д.
        ],
      ),
    );
  }

  Widget _buildOfflineDriverInterface() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.car_rental,
            size: 100,
            color: Colors.grey,
          ),
          const SizedBox(height: 20),
          const Text(
            'Вы не в сети',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Чтобы начать получать заказы, перейдите в режим "В сети"',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _isOnline = true;
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF53CFC4),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: const Text(
              'Перейти в сеть',
              style: TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPassengerInterface() {
    // Размеры экрана для адаптивности
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Stack(
      children: [
        // Карта
        SizedBox(
          height: screenHeight,
          width: screenWidth,
          child: GoogleMap(
            initialCameraPosition: const CameraPosition(
              target: LatLng(55.751244, 37.618423), // Москва
              zoom: 15,
            ),
            markers: _markers,
            polylines: _polylines,
            onMapCreated: (GoogleMapController controller) {
              _mapController.complete(controller);
            },
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            mapToolbarEnabled: false,
            zoomControlsEnabled: false,
            compassEnabled: false,
          ),
        ),

        // Кнопка текущего местоположения
        Positioned(
          right: 16,
          bottom: screenHeight * 0.3,
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.my_location, color: Colors.black),
              onPressed: () {
                if (_currentPosition != null) {
                  _centerOnPosition(_currentPosition!);
                } else {
                  _determinePosition();
                }
              },
            ),
          ),
        ),

        // Нижний бар вызова такси с тремя состояниями
        DraggableScrollableSheet(
          initialChildSize: 0.15, // Начальное состояние (показан ярлычок)
          minChildSize:
              0.05, // Минимальное состояние (скрыт, виден только ярлычок)
          maxChildSize: 0.85, // Максимальное состояние (полностью развернут)
          snapSizes: const [
            0.05,
            0.35,
            0.85
          ], // Фиксированные положения для трех состояний
          snap: true, // Включаем "прилипание" к фиксированным положениям
          builder: (BuildContext context, ScrollController scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Color(0xFFF9FAFB),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color.fromRGBO(0, 0, 0, 0.1),
                    blurRadius: 10,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Ярлычок для перетаскивания
                  Container(
                    width: 36,
                    height: 5,
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF9B9B9B),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),

                  // Основное содержимое, скроллируемое
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: EdgeInsets.zero,
                      children: [
                        // Секция адресов
                        Container(
                          width: 358,
                          margin: const EdgeInsets.only(
                              left: 16, right: 16, top: 8, bottom: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 2,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Stack(
                                  children: [
                                    // Индикаторы маршрута
                                    Column(
                                      children: [
                                        Container(
                                          width: 12,
                                          height: 12,
                                          decoration: const BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Color(0xFF3B82F6),
                                          ),
                                        ),
                                        Container(
                                          width: 1,
                                          height: 32,
                                          color: const Color(0xFF3B82F6),
                                        ),
                                        Container(
                                          width: 12,
                                          height: 16,
                                          decoration: const BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Colors.red,
                                          ),
                                        ),
                                      ],
                                    ),

                                    // Поля ввода
                                    Padding(
                                      padding: const EdgeInsets.only(left: 24),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // Поле ввода места отправления
                                          Container(
                                            width: 302,
                                            height: 40,
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFF9FAFB),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: TextField(
                                              controller: _originController,
                                              onChanged: (value) =>
                                                  _searchAddress(value, true),
                                              decoration: const InputDecoration(
                                                hintText: 'Место отправления',
                                                hintStyle: TextStyle(
                                                  color: Color(0xFFADAEBC),
                                                  fontFamily: 'Rubik',
                                                  fontSize: 16,
                                                ),
                                                contentPadding:
                                                    EdgeInsets.symmetric(
                                                        horizontal: 16),
                                                border: InputBorder.none,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 12),

                                          // Поле ввода места назначения
                                          Container(
                                            width: 302,
                                            height: 40,
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFF9FAFB),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: TextField(
                                              controller: _destController,
                                              onChanged: (value) =>
                                                  _searchAddress(value, false),
                                              decoration: const InputDecoration(
                                                hintText: 'Место назначения',
                                                hintStyle: TextStyle(
                                                  color: Color(0xFFADAEBC),
                                                  fontFamily: 'Rubik',
                                                  fontSize: 16,
                                                ),
                                                contentPadding:
                                                    EdgeInsets.symmetric(
                                                        horizontal: 16),
                                                border: InputBorder.none,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 16),

                                // Секция "Недавние"
                                Row(
                                  children: [
                                    const Icon(Icons.history,
                                        size: 14, color: Color(0xFF4B5563)),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Недавние',
                                      style: TextStyle(
                                        fontFamily: 'Rubik',
                                        fontSize: 14,
                                        color: Color(0xFF4B5563),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Результаты поиска, если есть
                        if (_isSearching)
                          Container(
                            width: 358,
                            margin: const EdgeInsets.symmetric(horizontal: 16),
                            constraints: const BoxConstraints(maxHeight: 200),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 5,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: _isLoadingAddresses
                                ? const Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(16.0),
                                      child: CircularProgressIndicator(),
                                    ),
                                  )
                                : _searchResults.isEmpty
                                    ? const Padding(
                                        padding: EdgeInsets.all(16.0),
                                        child: Text('Адреса не найдены'),
                                      )
                                    : ListView.builder(
                                        shrinkWrap: true,
                                        physics:
                                            const NeverScrollableScrollPhysics(),
                                        itemCount: _searchResults.length,
                                        itemBuilder: (context, index) {
                                          return ListTile(
                                            title: Text(_searchResults[index]),
                                            dense: true,
                                            onTap: () => _selectAddress(
                                                _searchResults[index],
                                                _isSearchingOrigin),
                                          );
                                        },
                                      ),
                          ),

                        const SizedBox(height: 10),

                        // Секция выбора тарифа
                        Container(
                          width: 358,
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 2,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Выбор тарифа',
                                  style: TextStyle(
                                    fontFamily: 'Rubik',
                                    fontSize: 18,
                                    fontWeight: FontWeight.w400,
                                    color: Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 12),

                                // Тариф 1 - Мама такси
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _selectedService = "Мама такси";
                                      _selectedPrice = 450;
                                    });
                                  },
                                  child: Container(
                                    width: 326,
                                    height: 70,
                                    padding: const EdgeInsets.all(13),
                                    decoration: BoxDecoration(
                                      color: _selectedService == "Мама такси"
                                          ? const Color(0xFFEFF6FF)
                                          : Colors.white,
                                      border: Border.all(
                                        color: _selectedService == "Мама такси"
                                            ? const Color(0xFFBFDBFE)
                                            : const Color(0xFFE5E7EB),
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.local_taxi),
                                        const SizedBox(width: 12),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: const [
                                            Text(
                                              'Мама такси',
                                              style: TextStyle(
                                                fontFamily: 'Rubik',
                                                fontSize: 16,
                                                color: Colors.black,
                                              ),
                                            ),
                                            Text(
                                              '10-15 мин',
                                              style: TextStyle(
                                                fontFamily: 'Rubik',
                                                fontSize: 14,
                                                color: Color(0xFF4B5563),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const Spacer(),
                                        const Text(
                                          '450₽',
                                          style: TextStyle(
                                            fontFamily: 'Rubik',
                                            fontSize: 16,
                                            color: Colors.black,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                // Другие тарифы добавляются по аналогии...
                                // ... (остальные тарифы оставляем без изменений)
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Тариф 2 - Личный водитель
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedService = "Личный водитель";
                              _selectedPrice = 650;
                            });
                          },
                          child: Container(
                            width: 326,
                            height: 70,
                            padding: const EdgeInsets.all(13),
                            decoration: BoxDecoration(
                              color: _selectedService == "Личный водитель"
                                  ? const Color(0xFFEFF6FF)
                                  : Colors.white,
                              border: Border.all(
                                color: _selectedService == "Личный водитель"
                                    ? const Color(0xFFBFDBFE)
                                    : const Color(0xFFE5E7EB),
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.directions_car_filled),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    Text(
                                      'Личный водитель',
                                      style: TextStyle(
                                        fontFamily: 'Rubik',
                                        fontSize: 16,
                                        color: Colors.black,
                                      ),
                                    ),
                                    Text(
                                      '15-20 мин',
                                      style: TextStyle(
                                        fontFamily: 'Rubik',
                                        fontSize: 14,
                                        color: Color(0xFF4B5563),
                                      ),
                                    ),
                                  ],
                                ),
                                const Spacer(),
                                const Text(
                                  '650₽',
                                  style: TextStyle(
                                    fontFamily: 'Rubik',
                                    fontSize: 16,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Тариф 3 - Срочная поездка
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedService = "Срочная поездка";
                              _selectedPrice = 850;
                            });
                          },
                          child: Container(
                            width: 326,
                            height: 70,
                            padding: const EdgeInsets.all(13),
                            decoration: BoxDecoration(
                              color: _selectedService == "Срочная поездка"
                                  ? const Color(0xFFEFF6FF)
                                  : Colors.white,
                              border: Border.all(
                                color: _selectedService == "Срочная поездка"
                                    ? const Color(0xFFBFDBFE)
                                    : const Color(0xFFE5E7EB),
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.access_time_filled),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    Text(
                                      'Срочная поездка',
                                      style: TextStyle(
                                        fontFamily: 'Rubik',
                                        fontSize: 16,
                                        color: Colors.black,
                                      ),
                                    ),
                                    Text(
                                      '5-8 мин',
                                      style: TextStyle(
                                        fontFamily: 'Rubik',
                                        fontSize: 14,
                                        color: Color(0xFF4B5563),
                                      ),
                                    ),
                                  ],
                                ),
                                const Spacer(),
                                const Text(
                                  '850₽',
                                  style: TextStyle(
                                    fontFamily: 'Rubik',
                                    fontSize: 16,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Тариф 4 - Женское такси
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedService = "Женское такси";
                              _selectedPrice = 550;
                            });
                          },
                          child: Container(
                            width: 326,
                            height: 70,
                            padding: const EdgeInsets.all(13),
                            decoration: BoxDecoration(
                              color: _selectedService == "Женское такси"
                                  ? const Color(0xFFEFF6FF)
                                  : Colors.white,
                              border: Border.all(
                                color: _selectedService == "Женское такси"
                                    ? const Color(0xFFBFDBFE)
                                    : const Color(0xFFE5E7EB),
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.person),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    Text(
                                      'Женское такси',
                                      style: TextStyle(
                                        fontFamily: 'Rubik',
                                        fontSize: 16,
                                        color: Colors.black,
                                      ),
                                    ),
                                    Text(
                                      '15-20 мин',
                                      style: TextStyle(
                                        fontFamily: 'Rubik',
                                        fontSize: 14,
                                        color: Color(0xFF4B5563),
                                      ),
                                    ),
                                  ],
                                ),
                                const Spacer(),
                                const Text(
                                  '550₽',
                                  style: TextStyle(
                                    fontFamily: 'Rubik',
                                    fontSize: 16,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 10),

                        // Секция способа оплаты
                        Container(
                          width: 358,
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 2,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Способ оплаты',
                                      style: TextStyle(
                                        fontFamily: 'Rubik',
                                        fontSize: 18,
                                        color: Colors.black,
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        Navigator.pushNamed(
                                            context, '/payment');
                                      },
                                      child: const Text(
                                        'Изменить',
                                        style: TextStyle(
                                          fontFamily: 'Rubik',
                                          fontSize: 16,
                                          color: Color(0xFF3B82F6),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    const Icon(Icons.credit_card,
                                        size: 18, color: Colors.black),
                                    const SizedBox(width: 8),
                                    const Text(
                                      '•••• 4242',
                                      style: TextStyle(
                                        fontFamily: 'Rubik',
                                        fontSize: 16,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 10),

                        // Секция дополнительных услуг
                        Container(
                          width: 358,
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 2,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Доп. услуги',
                                      style: TextStyle(
                                        fontFamily: 'Rubik',
                                        fontSize: 18,
                                        color: Colors.black,
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        // Открыть модальное окно с дополнительными услугами
                                        showModalBottomSheet(
                                          context: context,
                                          isScrollControlled: true,
                                          builder: (BuildContext context) {
                                            return ServicesModal(
                                              selectedServices:
                                                  _additionalServices,
                                              onApply: (selectedServices) {
                                                setState(() {
                                                  _additionalServices =
                                                      selectedServices;
                                                });
                                              },
                                            );
                                          },
                                        );
                                      },
                                      child: const Text(
                                        'Изменить',
                                        style: TextStyle(
                                          fontFamily: 'Rubik',
                                          fontSize: 16,
                                          color: Color(0xFF3B82F6),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Выбрано: ${_additionalServices.length} ${_declOfNum(_additionalServices.length, [
                                        'услуга',
                                        'услуги',
                                        'услуг'
                                      ])}',
                                  style: const TextStyle(
                                    fontFamily: 'Manrope',
                                    fontSize: 16,
                                    color: Color(0xFF3B82F6),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 10),

                        // Секция комментария к заказу
                        Container(
                          width: 358,
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 2,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Комментарий к заказу',
                                  style: TextStyle(
                                    fontFamily: 'Rubik',
                                    fontSize: 18,
                                    color: Colors.black,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit_note),
                                  onPressed: () {
                                    // Открыть поле для ввода комментария
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Кнопка заказа внутри нижнего бара
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Container(
                            width: double.infinity,
                            height: 56,
                            margin: const EdgeInsets.only(top: 10, bottom: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF654AA),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: TextButton(
                              onPressed: () {
                                // Логика оформления заказа
                                if (_originController.text.isEmpty ||
                                    _destController.text.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'Пожалуйста, укажите адрес отправления и назначения'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                  return;
                                }

                                // Создание заказа
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        'Заказ успешно создан! Ожидайте водителя.'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              },
                              child: Text(
                                'Заказать $_selectedService',
                                style: const TextStyle(
                                  fontFamily: 'Rubik',
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Добавляем немного места внизу, чтобы можно было прокрутить до конца
                        const SizedBox(height: 80),

                        // Остальные секции добавляются по аналогии...
                        // ... (остальные секции оставляем без изменений)
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  String _declOfNum(int number, List<String> titles) {
    List<int> cases = [2, 0, 1, 1, 1, 2];
    return titles[(number % 100 > 4 && number % 100 < 20)
        ? 2
        : cases[number % 10 < 5 ? number % 10 : 5]];
  }

  Widget _buildDrawer(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final user = userProvider.user;
        final children = userProvider.children;

        return Container(
          width: 320,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topRight: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
            boxShadow: [
              BoxShadow(
                color: Color.fromRGBO(0, 0, 0, 0.1),
                blurRadius: 10,
                offset: Offset(30, 8),
              ),
              BoxShadow(
                color: Color.fromRGBO(0, 0, 0, 0.1),
                blurRadius: 25,
                offset: Offset(0, 20),
              ),
            ],
          ),
          child: Column(
            children: [
              // Профиль пользователя
              Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Color(0xFFE5E7EB),
                      width: 1,
                    ),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        // Аватар
                        CircleAvatar(
                          radius: 32,
                          backgroundColor: const Color(0xFF53CFC4),
                          child: Text(
                            user?.name != null && user!.name!.isNotEmpty
                                ? user.name![0].toUpperCase()
                                : 'Г',
                            style: const TextStyle(
                              fontSize: 32.0,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user?.name != null && user!.name!.isNotEmpty
                                  ? '${user.name} ${user.surname ?? ''}'
                                  : 'Гость',
                              style: const TextStyle(
                                fontFamily: 'Manrope',
                                fontSize: 18,
                                color: Colors.black,
                              ),
                            ),
                            Row(
                              children: const [
                                Icon(Icons.star, size: 16, color: Colors.black),
                                SizedBox(width: 4),
                                Text(
                                  '4.92',
                                  style: TextStyle(
                                    fontFamily: 'Manrope',
                                    fontSize: 14,
                                    color: Color(0xFF4B5563),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 40,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.edit, size: 16),
                        label: const Text('Редактировать профиль'),
                        onPressed: () {
                          Navigator.pushNamed(context, '/profile_edit');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF53CFC4),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Секция "Мои дети"
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Color(0xFFE5E7EB),
                      width: 1,
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Мои дети',
                      style: TextStyle(
                        fontFamily: 'Rubik',
                        fontSize: 16,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Дети (если есть)
                    if (children.isNotEmpty)
                      ...children.map((ChildModel child) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: const Color(0xFFE5E7EB),
                                child: Text(
                                  child.name != null && child.name!.isNotEmpty
                                      ? child.name![0].toUpperCase()
                                      : 'Р',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 15),
                              Text(
                                '${child.name ?? "Ребенок"}, ${child.age ?? ""} лет',
                                style: const TextStyle(
                                  fontFamily: 'Rubik',
                                  fontSize: 16,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),

                    // Кнопка "Добавить ребенка"
                    TextButton.icon(
                      icon: const Icon(Icons.add, color: Color(0xFF2563EB)),
                      label: const Text(
                        'Добавить ребенка',
                        style: TextStyle(
                          fontFamily: 'Rubik',
                          fontSize: 16,
                          color: Color(0xFF2563EB),
                        ),
                      ),
                      onPressed: () {
                        // Логика для открытия модального окна добавления ребенка
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          builder: (BuildContext context) {
                            return Padding(
                              padding: EdgeInsets.only(
                                bottom:
                                    MediaQuery.of(context).viewInsets.bottom,
                              ),
                              child: const FractionallySizedBox(
                                heightFactor: 0.9,
                                child: AddChildModal(),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),

              // Навигационное меню
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildMenuItem(
                      icon: Icons.directions_car,
                      title: 'Мои поездки',
                      isActive: true,
                      onTap: () {},
                    ),
                    _buildMenuItem(
                      icon: Icons.credit_card,
                      title: 'Оплата и счета',
                      onTap: () {
                        Navigator.pushNamed(context, '/payment');
                      },
                    ),
                    _buildLoyaltyMenuItem(
                      icon: Icons.card_giftcard,
                      title: 'Программа лояльности',
                      points: '120',
                      onTap: () {
                        Navigator.pushNamed(context, '/loyalty');
                      },
                    ),
                    _buildMenuItem(
                      icon: Icons.settings,
                      title: 'Настройки',
                      onTap: () {
                        Navigator.pushNamed(context, '/settings');
                      },
                    ),
                    _buildMenuItem(
                      icon: Icons.help,
                      title: 'Поддержка и помощь',
                      onTap: () {
                        Navigator.pushNamed(context, '/support');
                      },
                    ),
                  ],
                ),
              ),

              // Кнопка выхода
              Container(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: TextButton.icon(
                    icon:
                        const Icon(Icons.exit_to_app, color: Color(0xFFDC2626)),
                    label: const Text(
                      'Выход из аккаунта',
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 16,
                        color: Color(0xFFDC2626),
                      ),
                    ),
                    onPressed: _logout,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFFEFF6FF) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isActive ? const Color(0xFF1D4ED8) : Colors.black,
        ),
        title: Text(
          title,
          style: TextStyle(
            fontFamily: 'Rubik',
            fontSize: 16,
            color: isActive ? const Color(0xFF1D4ED8) : Colors.black,
          ),
        ),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
        visualDensity: const VisualDensity(horizontal: 0, vertical: -2),
      ),
    );
  }

  Widget _buildLoyaltyMenuItem({
    required IconData icon,
    required String title,
    required String points,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        leading: Icon(icon),
        title: Text(
          title,
          style: const TextStyle(
            fontFamily: 'Rubik',
            fontSize: 16,
            color: Colors.black,
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFD1FAE5),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                points,
                style: const TextStyle(
                  fontFamily: 'Rubik',
                  fontSize: 12,
                  color: Color(0xFF047857),
                ),
              ),
              const Text(
                'баллов',
                style: TextStyle(
                  fontFamily: 'Rubik',
                  fontSize: 12,
                  color: Color(0xFF047857),
                ),
              ),
            ],
          ),
        ),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
        visualDensity: const VisualDensity(horizontal: 0, vertical: -2),
      ),
    );
  }

  Future<void> _logout() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Выполняем выход из системы
      await _authService.signOut();

      // Перенаправляем на экран авторизации
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/auth',
          (route) => false,
        );
      }
    } catch (e) {
      // Показываем сообщение об ошибке
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка при выходе: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _checkUserType() async {
    final isDriver = await _authService.isUserDriver();
    setState(() {
      _isDriverMode = isDriver;
    });
  }

  // Метод для поиска адресов
  void _searchAddress(String query, bool isOrigin) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _isSearchingOrigin = isOrigin;
      _searchResults = []; // Очищаем предыдущие результаты на время поиска
      _isLoadingAddresses = true; // Показываем индикатор загрузки
    });

    try {
      // Используем экземпляр MapService для поиска подсказок адресов
      List<String> suggestions =
          await _mapService.searchAddressSuggestions(query);

      // Форматируем адреса для лучшей читаемости
      suggestions =
          suggestions.map((address) => _formatAddress(address)).toList();

      if (mounted) {
        setState(() {
          _searchResults = suggestions;
          _isLoadingAddresses = false;
        });
      }
    } catch (e) {
      print('Ошибка при поиске адресов: $e');
      if (mounted) {
        setState(() {
          _searchResults = [];
          _isLoadingAddresses = false;
        });
      }
    }
  }

  // Форматирование адреса для лучшей читаемости
  String _formatAddress(String address) {
    // Удаляем страну из конца, если это Россия
    if (address.endsWith(', Россия')) {
      address = address.substring(0, address.length - 8) + ', Россия';
    }

    // Сокращаем адрес до основных компонентов
    List<String> parts = address.split(', ');

    if (parts.length > 3) {
      // Оставляем только ключевые части: улица/дом, район/город, страна
      List<String> shortAddress = [];

      // Ищем самую информативную часть адреса (обычно содержит "улица", "дом" и т.д.)
      bool foundStreet = false;
      for (String part in parts) {
        if (part.toLowerCase().contains('улица') ||
            part.toLowerCase().contains('ул.') ||
            part.toLowerCase().contains('проспект') ||
            part.toLowerCase().contains('пр-т') ||
            part.toLowerCase().contains('переулок') ||
            part.toLowerCase().contains('шоссе') ||
            _containsHouseNumber(part)) {
          shortAddress.add(part);
          foundStreet = true;
          break;
        }
      }

      // Если улица не найдена, берем первую часть
      if (!foundStreet && parts.isNotEmpty) {
        shortAddress.add(parts[0]);
      }

      // Добавляем город
      bool foundCity = false;
      for (String part in parts) {
        if (part.toLowerCase().contains('москва') ||
            part.toLowerCase().contains('одинцово') ||
            part.toLowerCase().contains('химки') ||
            part.toLowerCase().contains('красногорск') ||
            part.toLowerCase().contains('мытищи')) {
          shortAddress.add(part);
          foundCity = true;
          break;
        }
      }

      // Если город не найден явно, ищем в середине списка
      if (!foundCity && parts.length > 2) {
        shortAddress.add(parts[parts.length ~/ 2]);
      }

      // Добавляем страну
      shortAddress.add('Россия');

      return shortAddress.join(', ');
    }

    return address;
  }

  // Проверка наличия номера дома в строке
  bool _containsHouseNumber(String text) {
    RegExp houseNumberRegex =
        RegExp(r'\b\d+(\s*[а-яА-Я])?(\s*/\s*\d+)?(\s*к\.?\s*\d+)?\b');
    return houseNumberRegex.hasMatch(text);
  }

  // Метод для выбора адреса из результатов поиска
  void _selectAddress(String address, bool isOrigin) async {
    setState(() {
      if (isOrigin) {
        _originController.text = address;
      } else {
        _destController.text = address;
      }
      _searchResults = [];
      _isSearching = false;
    });

    try {
      // Используем экземпляр MapService для получения координат выбранного адреса
      final position = await _mapService.searchAddress(address);

      if (position != null) {
        if (isOrigin) {
          _mapService.setOriginPosition(position);
        } else {
          _mapService.setDestinationPosition(position);
        }

        // Центрируем карту на выбранной позиции
        final controller = await _mapController.future;
        controller.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: LatLng(position.latitude, position.longitude),
              zoom: 15,
            ),
          ),
        );

        // Добавляем маркер на карту
        setState(() {
          _addMarker(
            LatLng(position.latitude, position.longitude),
            isOrigin ? 'origin' : 'destination',
            isOrigin
                ? BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueGreen)
                : BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueRed),
            isOrigin ? 'Место отправления' : 'Место назначения',
          );
        });

        // Если выбраны и точка отправления, и точка назначения, строим маршрут
        if (_originController.text.isNotEmpty &&
            _destController.text.isNotEmpty) {
          final origin =
              await _mapService.searchAddress(_originController.text);
          final destination =
              await _mapService.searchAddress(_destController.text);

          if (origin != null && destination != null) {
            await _mapService.getDirections(origin, destination);

            // Обновляем полилинии маршрута на карте
            setState(() {
              _polylines = _mapService.getRoutePolylines();
            });
          }
        }
      }
    } catch (e) {
      print('Ошибка при выборе адреса: $e');
    }
  }
}
