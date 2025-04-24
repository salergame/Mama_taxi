import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:mama_taxi/services/taxi_service.dart';
import 'package:mama_taxi/models/trip_model.dart';
import 'package:mama_taxi/services/map_service.dart';
import 'package:mama_taxi/services/google_maps_services.dart';
import 'dart:math' show cos, sqrt, asin;

class TripTrackingScreen extends StatefulWidget {
  const TripTrackingScreen({Key? key}) : super(key: key);

  @override
  State<TripTrackingScreen> createState() => _TripTrackingScreenState();
}

class _TripTrackingScreenState extends State<TripTrackingScreen> {
  Timer? _timer;
  bool _isCancelDialogShown = false;
  final Completer<GoogleMapController> _controller = Completer();

  // Исходное местоположение
  static const SourceLocation = LatLng(55.751244, 37.618423);

  // Место назначения
  static const DestinationLocation = LatLng(55.761244, 37.638423);

  // Информация о списке координат для полилиний
  List<LatLng> polylineCoordinates = [];

  // Текущее местоположение
  LocationData? currentLocation;

  // Режим отображения маркера местоположения водителя
  BitmapDescriptor currentLocationIcon = BitmapDescriptor.defaultMarker;
  BitmapDescriptor sourceIcon = BitmapDescriptor.defaultMarker;
  BitmapDescriptor destinationIcon = BitmapDescriptor.defaultMarker;

  // Для рассчета расстояния
  double distance = 0.0;

  // Создаем экземпляр для службы местоположения
  final Location _locationService = Location();

  @override
  void initState() {
    super.initState();

    // Имитация движения автомобиля
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {});
    });

    // Получаем текущее местоположение и инициализируем все данные
    _initializeLocationAndData();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // Метод для настройки пользовательских маркеров
  void _setCustomMarkerIcons() async {
    await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size(24, 24)),
      'assets/images/current_location.png',
    ).then((icon) {
      setState(() {
        currentLocationIcon = icon;
      });
    }).catchError((error) {
      print("Ошибка загрузки маркера: $error");
      // Используем маркер по умолчанию в случае ошибки
      currentLocationIcon =
          BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
    });

    BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size(24, 24)),
      'assets/images/source_pin.png',
    ).then((icon) {
      sourceIcon = icon;
    }).catchError((error) {
      print("Ошибка загрузки маркера источника: $error");
      sourceIcon =
          BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
    });

    BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size(24, 24)),
      'assets/images/destination_pin.png',
    ).then((icon) {
      destinationIcon = icon;
    }).catchError((error) {
      print("Ошибка загрузки маркера назначения: $error");
      destinationIcon =
          BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
    });
  }

  // Получаем текущее местоположение и следим за изменениями
  void _getCurrentLocation() async {
    bool serviceEnabled;
    PermissionStatus permissionGranted;

    // Проверяем, включена ли геолокация
    serviceEnabled = await _locationService.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _locationService.requestService();
      if (!serviceEnabled) {
        return;
      }
    }

    // Проверяем разрешения
    permissionGranted = await _locationService.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await _locationService.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        return;
      }
    }

    // Получаем текущее местоположение
    _locationService.getLocation().then((location) {
      setState(() {
        currentLocation = location;
      });
    });

    // Реальное отслеживание местоположения
    _locationService.onLocationChanged.listen((newLocation) {
      setState(() {
        currentLocation = newLocation;

        // Обновляем камеру карты при изменении местоположения
        _updateCameraPosition(newLocation);
      });
    });
  }

  // Обновляем позицию камеры
  void _updateCameraPosition(LocationData location) async {
    final GoogleMapController controller = await _controller.future;
    final CameraPosition position = CameraPosition(
      target: LatLng(location.latitude!, location.longitude!),
      zoom: 16.0,
    );

    controller.animateCamera(CameraUpdate.newCameraPosition(position));
  }

  // Получаем точки полилинии
  void _getPolylinePoints() async {
    GoogleMapsServices _googleMapsServices = GoogleMapsServices();

    try {
      // Получаем маршрут через Google Maps API
      String route = await _googleMapsServices.getRouteCoordinates(
          SourceLocation, DestinationLocation);

      // Создаем маршрут из закодированной полилинии
      _createRoute(route);

      setState(() {});
    } catch (e) {
      print("Ошибка при построении маршрута: $e");

      // Если API вернул ошибку, создаем прямую линию
      polylineCoordinates = [
        SourceLocation,
        DestinationLocation,
      ];

      // Считаем приблизительное расстояние между точками
      _calculateDistance(polylineCoordinates);

      setState(() {});
    }
  }

  // Метод для создания маршрута из закодированной полилинии
  void _createRoute(String encodedPoly) {
    polylineCoordinates = _convertToLatLng(_decodePoly(encodedPoly));
    _calculateDistance(polylineCoordinates);
  }

  // Преобразование списка точек в список LatLng
  List<LatLng> _convertToLatLng(List points) {
    List<LatLng> result = <LatLng>[];
    for (int i = 0; i < points.length; i++) {
      if (i % 2 != 0) {
        result.add(LatLng(points[i - 1], points[i]));
      }
    }
    return result;
  }

  // Декодирование закодированной полилинии
  List _decodePoly(String poly) {
    var list = poly.codeUnits;
    var lList = [];
    int index = 0;
    int len = poly.length;
    int c = 0;

    do {
      var shift = 0;
      int result = 0;

      do {
        c = list[index] - 63;
        result |= (c & 0x1F) << (shift * 5);
        index++;
        shift++;
      } while (c >= 32);

      if (result & 1 == 1) {
        result = ~result;
      }

      var result1 = (result >> 1) * 0.00001;
      lList.add(result1);
    } while (index < len);

    for (var i = 2; i < lList.length; i++) {
      lList[i] += lList[i - 2];
    }

    return lList;
  }

  // Рассчитываем расстояние между точками маршрута
  void _calculateDistance(List<LatLng> polylineCoordinates) {
    double totalDistance = 0;

    for (int i = 0; i < polylineCoordinates.length - 1; i++) {
      totalDistance += _coordinateDistance(
        polylineCoordinates[i].latitude,
        polylineCoordinates[i].longitude,
        polylineCoordinates[i + 1].latitude,
        polylineCoordinates[i + 1].longitude,
      );
    }

    setState(() {
      distance = totalDistance;
    });
  }

  // Вычисление расстояния между координатами с использованием формулы гаверсинуса
  double _coordinateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    const p = 0.017453292519943295; // π/180
    const c = cos;

    final term1 = 0.5 - c((lat2 - lat1) * p) / 2;
    final term2 = c(lat1 * p) * c(lat2 * p) * (1 - c((lon2 - lon1) * p)) / 2;

    final distance = 12742 * asin(sqrt(term1 + term2)); // 2 * R * asin(...)

    return distance;
  }

  // Инициализация всех данных и местоположения
  void _initializeLocationAndData() async {
    // Получаем текущее местоположение
    _getCurrentLocation();

    // Инициализируем иконки маркеров
    _setCustomMarkerIcons();

    // Получаем маршрут
    _getPolylinePoints();
  }

  // Функция для отображения информации о водителе
  Widget _buildDriverInfo(TaxiService taxiService) {
    final trip = taxiService.currentTrip;
    if (trip == null) {
      return const SizedBox.shrink();
    }

    // Отображаем разную информацию в зависимости от статуса поездки
    switch (trip.status) {
      case TripStatus.pending:
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Поиск водителя...', style: TextStyle(fontSize: 18)),
            ],
          ),
        );

      case TripStatus.confirmed:
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Ожидание подтверждения...', style: TextStyle(fontSize: 18)),
            ],
          ),
        );

      case TripStatus.confirmed:
      case TripStatus.driverArrived:
        final bool isArriving = trip.status == TripStatus.driverArrived;

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isArriving ? 'Водитель в пути' : 'Водитель найден',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.grey[300],
                    child: const Icon(Icons.person, size: 40),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          trip.driverId ?? 'Имя водителя',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Автомобиль',
                          style: const TextStyle(fontSize: 14),
                        ),
                        Text(
                          'Номер',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.phone),
                    onPressed: () {
                      // Вызов водителя
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.chat),
                    onPressed: () {
                      // Переход к чату
                      Navigator.pushNamed(context, '/chat', arguments: {
                        'driverId': 'driver123',
                        'driverName': trip.driverId,
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      spreadRadius: 1,
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.location_on, color: Colors.green),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            trip.origin.address ?? '',
                            style: const TextStyle(fontSize: 16),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Icon(Icons.location_on, color: Colors.red),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            trip.destination.address ?? '',
                            style: const TextStyle(fontSize: 16),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _showCancelDialog(taxiService),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Отменить поездку'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );

      case TripStatus.inProgress:
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Поездка в процессе',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      spreadRadius: 1,
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Расстояние:',
                          style: TextStyle(fontSize: 16),
                        ),
                        Text(
                          trip.distance?.toString() ?? '0.0 км',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Время в пути:',
                          style: TextStyle(fontSize: 16),
                        ),
                        Text(
                          trip.duration?.toString() ?? '0 мин',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Стоимость:',
                          style: TextStyle(fontSize: 16),
                        ),
                        Text(
                          '${trip.price.toStringAsFixed(0)} ₽',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );

      case TripStatus.completed:
      case TripStatus.cancelled:
        // Перенаправляем на экран обзора поездки
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.pushReplacementNamed(context, '/trip_review');
        });
        return const SizedBox.shrink();
    }
  }

  // Диалог отмены поездки
  Future<void> _showCancelDialog(TaxiService taxiService) async {
    if (_isCancelDialogShown) return;

    _isCancelDialogShown = true;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Отмена поездки'),
          content: const Text(
            'Вы уверены, что хотите отменить поездку? Это может повлечь штраф.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _isCancelDialogShown = false;
              },
              child: const Text('Нет'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await taxiService.cancelTrip();
                _isCancelDialogShown = false;
                if (mounted) {
                  Navigator.pushReplacementNamed(context, '/home');
                }
              },
              child: const Text('Да, отменить'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final taxiService = Provider.of<TaxiService>(context);
    final mapService = Provider.of<MapService>(context);
    final trip = taxiService.currentTrip;

    if (trip == null) {
      // Если нет активной поездки, перенаправляем на главный экран
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/home');
      });
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Создаем точки для карты
    final List<LatLng> routePoints = [
      LatLng(trip.origin.latitude, trip.origin.longitude),
      LatLng(trip.destination.latitude, trip.destination.longitude),
    ];

    // Набор маркеров для отображения на карте
    Set<Marker> markers = {
      // Маркер текущего местоположения (водитель)
      if (currentLocation != null)
        Marker(
          markerId: const MarkerId("currentLocation"),
          position: LatLng(
            currentLocation!.latitude!,
            currentLocation!.longitude!,
          ),
          icon: currentLocationIcon,
          infoWindow: const InfoWindow(
            title: "Ваше текущее местоположение",
          ),
        ),

      // Маркер точки отправления
      Marker(
        markerId: const MarkerId("source"),
        position: SourceLocation,
        icon: sourceIcon,
        infoWindow: const InfoWindow(
          title: "Точка отправления",
          snippet: "Тестовый адрес отправления",
        ),
      ),

      // Маркер точки назначения
      Marker(
        markerId: const MarkerId("destination"),
        position: DestinationLocation,
        icon: destinationIcon,
        infoWindow: const InfoWindow(
          title: "Точка назначения",
          snippet: "Тестовый адрес назначения",
        ),
      ),
    };

    // Набор полилиний для отображения маршрута
    Set<Polyline> polylines = {
      Polyline(
        polylineId: const PolylineId("route"),
        points: polylineCoordinates,
        color: Colors.blue,
        width: 5,
      ),
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text('Отслеживание поездки'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          // Карта Google
          GoogleMap(
            initialCameraPosition: const CameraPosition(
              target: SourceLocation,
              zoom: 14.5,
            ),
            markers: markers,
            polylines: polylines,
            mapType: MapType.normal,
            myLocationEnabled: true,
            compassEnabled: true,
            zoomControlsEnabled: false,
            onMapCreated: (GoogleMapController controller) {
              _controller.complete(controller);
            },
          ),

          // Информационная карточка поездки
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Информация о поездке
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.local_taxi,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Иван - Toyota Camry",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              "А777AA 77",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.green[100],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.star,
                              color: Colors.green,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              "4.8",
                              style: TextStyle(
                                color: Colors.green[800],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Информация о маршруте
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.location_on,
                                    color: Colors.green, size: 20),
                                const SizedBox(width: 8),
                                const Expanded(
                                  child: Text(
                                    "ул. Тверская, 8",
                                    style: TextStyle(fontSize: 14),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Container(
                              height: 20,
                              width: 1,
                              color: Colors.grey[300],
                              margin: const EdgeInsets.only(left: 10),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.location_on,
                                    color: Colors.red, size: 20),
                                const SizedBox(width: 8),
                                const Expanded(
                                  child: Text(
                                    "Кремлевская набережная, 1",
                                    style: TextStyle(fontSize: 14),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            "${distance.toStringAsFixed(2)} км",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Прибытие через 12 мин",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Кнопки действий
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildActionButton(Icons.call, "Позвонить"),
                      _buildActionButton(Icons.message, "Написать"),
                      _buildActionButton(Icons.cancel, "Отменить"),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Метод для создания кнопки действия
  Widget _buildActionButton(IconData icon, String label) {
    return InkWell(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Нажата кнопка: $label"),
            duration: const Duration(seconds: 1),
          ),
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
}
