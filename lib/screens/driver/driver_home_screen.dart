import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mama_taxi/services/firebase_service.dart';
import 'package:mama_taxi/services/auth_service.dart';
import 'package:mama_taxi/services/map_service.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({Key? key}) : super(key: key);

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  bool _isOnline = false;
  bool _hasNewOrder = false;
  bool _isOrderExpanded = false;
  bool _isNavigating = false;

  // Контроллер для Google Maps
  final Completer<GoogleMapController> _mapController = Completer();

  // Текущая позиция
  Position? _currentPosition;

  // Набор маркеров для карты
  final Set<Marker> _markers = {};

  // Полилинии для маршрутов
  final Set<Polyline> _polylines = {};

  // Паттерн Singleton для сохранения состояния при перестроении
  static _DriverHomeScreenState? _instance;

  // Модель для заказа
  Map<String, dynamic>? _currentOrder;

  @override
  void initState() {
    super.initState();
    _instance = this;
    _determinePosition();
    _loadProfile();

    // Здесь можно добавить подписку на получение заказов
    // Для демонстрации просто используем Timer
    Timer(const Duration(seconds: 5), () {
      if (mounted && _isOnline) {
        _showNewOrder();
      }
    });
  }

  Future<void> _loadProfile() async {
    final userData = await _firebaseService.getUserData();
    if (userData != null) {
      // Загрузка статуса водителя, рейтинга и т.д.
    }
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
          content: Text('Включите службу геолокации для работы приложения'),
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

      // Регулярное обновление местоположения
      Geolocator.getPositionStream().listen((Position position) {
        setState(() {
          _currentPosition = position;
          _updateMarker(position);
        });
      });

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка получения местоположения: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Обновление маркера текущего местоположения
  void _updateMarker(Position position) {
    _addMarker(
        LatLng(position.latitude, position.longitude),
        'current_location',
        BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        'Моя локация');

    if (_isNavigating && _mapController.isCompleted) {
      _centerOnPosition(position);
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
      // Удаляем старый маркер с тем же ID, если он существует
      _markers.removeWhere((m) => m.markerId.value == markerId);
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

  // Метод для отображения нового заказа (демо)
  void _showNewOrder() {
    if (_currentPosition == null) return;

    // Создаем тестовый заказ
    _currentOrder = {
      'id': 'order-${DateTime.now().millisecondsSinceEpoch}',
      'pickupLocation': {
        'address': 'ул. Ленина, 15',
        'lat': _currentPosition!.latitude + 0.002,
        'lng': _currentPosition!.longitude + 0.002,
      },
      'dropLocation': {
        'address': 'ул. Пушкина, 42',
        'lat': _currentPosition!.latitude + 0.005,
        'lng': _currentPosition!.longitude - 0.003,
      },
      'clientName': 'Анна М.',
      'totalDistance': '2.3 км',
      'estimatedTime': '8 мин',
      'price': 320,
      'childrenCount': 1,
      'hasChildSeat': true,
    };

    // Добавляем маркеры для точек маршрута
    _addMarker(
        LatLng(_currentOrder!['pickupLocation']['lat'],
            _currentOrder!['pickupLocation']['lng']),
        'pickup_location',
        BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        'Точка отправления');

    _addMarker(
        LatLng(_currentOrder!['dropLocation']['lat'],
            _currentOrder!['dropLocation']['lng']),
        'drop_location',
        BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        'Точка назначения');

    // Добавляем линию маршрута (упрощенно)
    final polyline = Polyline(
      polylineId: const PolylineId('route'),
      color: const Color(0xFF53CFC4),
      width: 5,
      points: [
        LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        LatLng(_currentOrder!['pickupLocation']['lat'],
            _currentOrder!['pickupLocation']['lng']),
        LatLng(_currentOrder!['dropLocation']['lat'],
            _currentOrder!['dropLocation']['lng']),
      ],
    );

    setState(() {
      _polylines.clear();
      _polylines.add(polyline);
      _hasNewOrder = true;
    });

    // Показываем уведомление
    _showOrderNotification();
  }

  // Показать уведомление о новом заказе
  void _showOrderNotification() {
    if (!_isOnline) return;

    // Воспроизводим звук уведомления
    // await player.play('sounds/notification.mp3');

    // Вибрируем
    // await Vibration.vibrate(duration: 500);

    // Показываем всплывающее уведомление
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Поступил новый заказ!'),
        backgroundColor: const Color(0xFF53CFC4),
        action: SnackBarAction(
          label: 'Открыть',
          textColor: Colors.white,
          onPressed: () {
            setState(() {
              _isOrderExpanded = true;
            });
          },
        ),
      ),
    );
  }

  // Принятие заказа
  void _acceptOrder() {
    setState(() {
      _hasNewOrder = false;
      _isOrderExpanded = false;
      _isNavigating = true;
    });

    // Здесь логика принятия заказа
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content:
            Text('Вы приняли заказ. Начинайте движение к точке отправления'),
        backgroundColor: Colors.green,
      ),
    );
  }

  // Отклонение заказа
  void _declineOrder() {
    setState(() {
      _hasNewOrder = false;
      _isOrderExpanded = false;
      _currentOrder = null;

      // Удаляем маркеры и маршрут
      _markers.removeWhere((m) =>
          m.markerId.value == 'pickup_location' ||
          m.markerId.value == 'drop_location');
      _polylines.clear();
    });

    // Здесь логика отклонения заказа
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Вы отклонили заказ'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Мама Такси - Водитель'),
        backgroundColor: const Color(0xFF53CFC4),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              Navigator.pushNamed(context, '/notifications');
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Выйти',
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: Stack(
        children: [
          // Карта Google Maps
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _currentPosition != null
                  ? LatLng(
                      _currentPosition!.latitude, _currentPosition!.longitude)
                  : const LatLng(55.751244, 37.618423), // Москва по умолчанию
              zoom: 14.0,
            ),
            markers: _markers,
            polylines: _polylines,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            mapToolbarEnabled: false,
            zoomControlsEnabled: false,
            onMapCreated: (GoogleMapController controller) {
              _mapController.complete(controller);
            },
          ),

          // Статус водителя
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
            color: const Color(0xFF53CFC4),
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
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
                        if (!value) {
                          // При выходе из сети отменяем текущие заказы
                          _hasNewOrder = false;
                          _isOrderExpanded = false;
                          _isNavigating = false;
                          _currentOrder = null;
                          _markers.removeWhere((m) =>
                              m.markerId.value == 'pickup_location' ||
                              m.markerId.value == 'drop_location');
                          _polylines.clear();
                        }
                    });
                  },
                  activeColor: Colors.white,
                  activeTrackColor: Colors.green,
                ),
              ],
            ),
          ),
          ),

          // Кнопка центрирования карты
          Positioned(
            right: 16,
            bottom: _hasNewOrder && _isOrderExpanded ? 320 : 16,
            child: FloatingActionButton(
              onPressed: () {
                if (_currentPosition != null) {
                  _centerOnPosition(_currentPosition!);
                }
              },
              backgroundColor: Colors.white,
              child: const Icon(Icons.my_location, color: Color(0xFF53CFC4)),
            ),
          ),

          // Виджет содержимого в зависимости от статуса
          if (!_isOnline)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _buildOfflineInterface(),
            ),

          // Виджет нового заказа
          if (_hasNewOrder && _isOnline)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _buildOrderCard(),
            ),

          // Информация о навигации
          if (_isNavigating && !_hasNewOrder)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _buildNavigationPanel(),
            ),
        ],
      ),
    );
  }

  // Боковое меню
  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              color: Color(0xFF53CFC4),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(
                  radius: 36,
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.person,
                    size: 40,
                    color: Color(0xFF53CFC4),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Водитель',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: const [
                    Icon(Icons.star, color: Colors.amber, size: 16),
                    SizedBox(width: 4),
                    Text(
                      '4.8',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Главная'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.account_circle),
            title: const Text('Профиль'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/profile');
            },
          ),
          ListTile(
            leading: const Icon(Icons.article),
            title: const Text('Документы'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/driver_documents');
            },
          ),
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('История поездок'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/trips');
            },
          ),
          ListTile(
            leading: const Icon(Icons.schedule),
            title: const Text('График работы'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/schedule');
            },
          ),
          ListTile(
            leading: const Icon(Icons.paid),
            title: const Text('Финансы'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/payment');
            },
          ),
          ListTile(
            leading: const Icon(Icons.support_agent),
            title: const Text('Поддержка'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/support');
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Настройки'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/settings');
            },
          ),
          ListTile(
            leading: const Icon(Icons.exit_to_app),
            title: const Text('Выйти'),
            onTap: () {
              Navigator.pop(context);
              _logout();
            },
          ),
        ],
      ),
    );
  }

  // Виджет для отображения карточки заказа
  Widget _buildOrderCard() {
    if (_currentOrder == null) return const SizedBox.shrink();

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      height: _isOrderExpanded ? 320 : 120,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Новый заказ',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${_currentOrder!['price']} ₽',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
            color: Color(0xFF53CFC4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Column(
                children: [
                  const Icon(Icons.circle, color: Colors.green, size: 12),
                  Container(
                    width: 1,
                    height: 20,
                    color: Colors.grey,
                  ),
                  const Icon(Icons.circle, color: Colors.red, size: 12),
                ],
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_currentOrder!['pickupLocation']['address']),
                    const SizedBox(height: 12),
                    Text(_currentOrder!['dropLocation']['address']),
                  ],
                ),
              ),
            ],
          ),

          // Кнопка для раскрытия/скрытия деталей
          InkWell(
            onTap: () {
              setState(() {
                _isOrderExpanded = !_isOrderExpanded;
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _isOrderExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: Colors.grey,
                  ),
                  Text(
                    _isOrderExpanded ? 'Скрыть детали' : 'Показать детали',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),

          // Дополнительные детали заказа
          if (_isOrderExpanded) ...[
            const Divider(),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildDetailRow('Клиент', _currentOrder!['clientName']),
                    _buildDetailRow(
                        'Расстояние', _currentOrder!['totalDistance']),
                    _buildDetailRow(
                        'Время в пути', _currentOrder!['estimatedTime']),
                    _buildDetailRow(
                        'Кол-во детей', '${_currentOrder!['childrenCount']}'),
                    _buildDetailRow('Детское кресло',
                        _currentOrder!['hasChildSeat'] ? 'Да' : 'Нет'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _declineOrder,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade200,
                      foregroundColor: Colors.black,
                    ),
                    child: const Text('Отклонить'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _acceptOrder,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF53CFC4),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Принять'),
                  ),
                ),
              ],
            ),
          ] else ...[
            // Кнопки принять/отклонить в компактном режиме
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _declineOrder,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade200,
                      foregroundColor: Colors.black,
                    ),
                    child: const Text('Отклонить'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _acceptOrder,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF53CFC4),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Принять'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // Строка с деталями
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.grey),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  // Интерфейс в режиме офлайн
  Widget _buildOfflineInterface() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Вы не в сети',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Чтобы начать получать заказы, перейдите в режим "В сети"',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
            onPressed: () {
              setState(() {
                _isOnline = true;
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF53CFC4),
              foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
            ),
            child: const Text(
              'Перейти в сеть',
              style: TextStyle(fontSize: 16),
            ),
            ),
          ),
        ],
      ),
    );
  }

  // Панель для навигации к клиенту
  Widget _buildNavigationPanel() {
    if (_currentOrder == null) return const SizedBox.shrink();

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const CircleAvatar(
                backgroundColor: Colors.green,
                radius: 16,
                child:
                    Icon(Icons.directions_car, color: Colors.white, size: 16),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Направляйтесь к точке отправления',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(_currentOrder!['pickupLocation']['address']),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    // Здесь логика для звонка клиенту
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: const BorderSide(color: Color(0xFF53CFC4)),
                  ),
                  child: const Text('Позвонить'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    // Здесь логика навигации через карты
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF53CFC4),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Навигация'),
                ),
              ),
            ],
          ),
        ],
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
}
