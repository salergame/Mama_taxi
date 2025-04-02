import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:mama_taxi/models/trip_model.dart';
import 'package:mama_taxi/providers/trip_provider.dart';
import 'package:mama_taxi/services/auth_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService _authService = AuthService();
  final TextEditingController _originController = TextEditingController();
  final TextEditingController _destController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final tripProvider = Provider.of<TripProvider>(context, listen: false);
      tripProvider.createDemoTrip();

      final trip = tripProvider.currentTrip;
      if (trip != null) {
        _originController.text = trip.originAddress;
        _destController.text = trip.destinationAddress;
      }
    });
  }

  @override
  void dispose() {
    _originController.dispose();
    _destController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tripProvider = Provider.of<TripProvider>(context);

    return Scaffold(
      body: Stack(
        children: [
          // Google Map
          SizedBox(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            child: GoogleMap(
              initialCameraPosition: const CameraPosition(
                target: LatLng(55.751244, 37.618423),
                zoom: 15,
              ),
              onMapCreated: (GoogleMapController controller) {
                tripProvider.setMapController(controller);
              },
              markers: tripProvider.markers,
              polylines: tripProvider.polylines,
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
            ),
          ),

          // Атрибуция Google (обязательна по правилам использования API)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: 16,
              color: Colors.white70,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.network(
                    'https://developers.google.com/static/maps/images/google-logo.png',
                    height: 12,
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'Картографические данные ©2023 Google',
                    style: TextStyle(fontSize: 10, color: Colors.black54),
                  ),
                ],
              ),
            ),
          ),

          // Карточка снизу экрана (согласно CSS из Фигмы)
          Positioned(
            left: 0,
            top: 449,
            width: 390,
            height: 638,
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFFF9FAFB),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Stack(
                children: [
                  // Блок полей для ввода адресов
                  Positioned(
                    left: 24,
                    top: 24,
                    width: 342,
                    height: 112,
                    child: Column(
                      children: [
                        // Поле "Откуда"
                        Container(
                          height: 50,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.grey.shade200,
                            ),
                          ),
                          child: TextField(
                            controller: _originController,
                            decoration: InputDecoration(
                              hintText: 'Откуда',
                              hintStyle: TextStyle(
                                color: Colors.grey.shade400,
                                fontSize: 16,
                              ),
                              border: InputBorder.none,
                              prefixIcon: const Icon(
                                Icons.my_location,
                                color: Colors.green,
                                size: 20,
                              ),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Поле "Куда"
                        Container(
                          height: 50,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.grey.shade200,
                            ),
                          ),
                          child: TextField(
                            controller: _destController,
                            decoration: InputDecoration(
                              hintText: 'Куда',
                              hintStyle: TextStyle(
                                color: Colors.grey.shade400,
                                fontSize: 16,
                              ),
                              border: InputBorder.none,
                              prefixIcon: const Icon(
                                Icons.location_on,
                                color: Colors.red,
                                size: 20,
                              ),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Кнопка "Тестовый маршрут"
                  Positioned(
                    left: 24,
                    top: 160,
                    width: 342,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        _originController.text = 'Красная площадь, Москва';
                        _destController.text = 'Третьяковская галерея, Москва';
                        tripProvider.setOriginAddress(_originController.text);
                        tripProvider
                            .setDestinationAddress(_destController.text);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3B82F6), // Синий цвет
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Тестовый маршрут',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                    ),
                  ),

                  // Кнопка "Заказать"
                  Positioned(
                    left: 24,
                    top: 603,
                    width: 342,
                    height: 60,
                    child: ElevatedButton(
                      onPressed: () {
                        _originController.text = 'Красная площадь, Москва';
                        _destController.text = 'Третьяковская галерея, Москва';
                        tripProvider.setOriginAddress(_originController.text);
                        tripProvider
                            .setDestinationAddress(_destController.text);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            const Color(0xFFEC4899), // Розовый цвет из CSS
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        minimumSize: const Size(342, 60),
                      ),
                      child: const Text(
                        'Заказать',
                        style: TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 18,
                          fontWeight: FontWeight.normal,
                          height: 25 / 18, // line-height: 25px из CSS
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
