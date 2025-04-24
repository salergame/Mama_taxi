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
  final Set<Polyline> _polylines = {};

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

  @override
  void initState() {
    super.initState();
    _determinePosition();
    _checkUserType();
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
    // Здесь реализация интерфейса для обычных пользователей
    return const Center(
      child: Text('Интерфейс пассажира'),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: Consumer<UserProvider>(
        builder: (context, userProvider, child) {
          final user = userProvider.user;

          return ListView(
            padding: EdgeInsets.zero,
            children: [
              UserAccountsDrawerHeader(
                decoration: const BoxDecoration(
                  color: Color(0xFF53CFC4),
                ),
                accountName: Text(
                  user?.name != null && user!.name!.isNotEmpty
                      ? '${user.name} ${user.surname ?? ''}'
                      : 'Гость',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                accountEmail: Text(
                  user?.email ?? '',
                  style: const TextStyle(
                    fontSize: 14,
                  ),
                ),
                currentAccountPicture: CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Text(
                    user?.name != null && user!.name!.isNotEmpty
                        ? user.name![0].toUpperCase()
                        : 'Г',
                    style: const TextStyle(
                      fontSize: 32.0,
                      color: Color(0xFF53CFC4),
                    ),
                  ),
                ),
              ),

              // Основные пункты меню
              _buildDrawerItem(
                icon: Icons.person,
                title: 'Профиль',
                onTap: () => Navigator.pushNamed(context, '/profile'),
              ),

              if (!_isDriverMode) ...[
                // Секция "Мои дети" только для обычных пользователей
                const Divider(),
                const Padding(
                  padding: EdgeInsets.only(left: 16.0, top: 8.0),
                  child: Text(
                    'Мои дети',
                    style: TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                // Список детей
                Consumer<UserProvider>(
                  builder: (context, userProvider, child) {
                    if (userProvider.isLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final children = userProvider.children;

                    if (children.isEmpty) {
                      return ListTile(
                        title: const Text('Добавить ребенка'),
                        leading: const Icon(Icons.add_circle_outline),
                        onTap: () {
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
                      );
                    }

                    return Column(
                      children: [
                        ...children.map((ChildModel child) {
                          return ListTile(
                            title: Text(child.name ?? 'Ребенок'),
                            subtitle: Text('${child.age ?? ''} лет'),
                            leading: const Icon(Icons.child_care),
                          );
                        }).toList(),

                        // Кнопка добавления ребенка
                        ListTile(
                          title: const Text('Добавить ребенка'),
                          leading: const Icon(Icons.add_circle_outline),
                          onTap: () {
                            // Логика для открытия модального окна добавления ребенка
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              builder: (BuildContext context) {
                                return Padding(
                                  padding: EdgeInsets.only(
                                    bottom: MediaQuery.of(context)
                                        .viewInsets
                                        .bottom,
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
                    );
                  },
                ),
              ] else ...[
                // Секция для водителей
                _buildDrawerItem(
                  icon: Icons.assignment,
                  title: 'Документы',
                  onTap: () =>
                      Navigator.pushNamed(context, '/driver_documents'),
                ),
              ],

              // Общие пункты меню
              const Divider(),
              _buildDrawerItem(
                icon: Icons.settings,
                title: 'Настройки',
                onTap: () => Navigator.pushNamed(context, '/settings'),
              ),
              _buildDrawerItem(
                icon: Icons.support_agent,
                title: 'Поддержка',
                onTap: () => Navigator.pushNamed(context, '/support'),
              ),
              _buildDrawerItem(
                icon: Icons.exit_to_app,
                title: 'Выйти',
                onTap: _logout,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      onTap: onTap,
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
}
