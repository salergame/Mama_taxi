import 'package:flutter/material.dart';
import 'package:mama_taxi/models/trip_model.dart';
import 'package:mama_taxi/services/firebase_service.dart';
import 'package:intl/intl.dart';

class TripsScreen extends StatefulWidget {
  const TripsScreen({Key? key}) : super(key: key);

  @override
  State<TripsScreen> createState() => _TripsScreenState();
}

class _TripsScreenState extends State<TripsScreen>
    with SingleTickerProviderStateMixin {
  final FirebaseService _firebaseService = FirebaseService();
  List<TripModel> _tripHistory = [];
  bool _isLoading = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadTripHistory();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadTripHistory() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final tripData = await _firebaseService.getUserTrips();
      setState(() {
        _tripHistory =
            tripData.map((data) => TripModel.fromJson(data)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Ошибка загрузки истории поездок: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Мои поездки',
          style: TextStyle(
            color: Colors.black,
            fontFamily: 'Rubik',
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF53CFC4),
          labelColor: Colors.black,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'Текущие'),
            Tab(text: 'История'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildActiveTrips(),
                _buildTripHistory(),
              ],
            ),
    );
  }

  Widget _buildActiveTrips() {
    final activeTrips = _tripHistory
        .where((trip) =>
            trip.status == TripStatus.pending ||
            trip.status == TripStatus.confirmed ||
            trip.status == TripStatus.inProgress)
        .toList();

    if (activeTrips.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.directions_car_outlined,
                size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text(
              'У вас нет текущих поездок',
              style: TextStyle(
                fontFamily: 'Rubik',
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pushNamed('/home');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF53CFC4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text(
                'Заказать поездку',
                style: TextStyle(
                  fontFamily: 'Rubik',
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: activeTrips.length,
      itemBuilder: (context, index) {
        return _buildTripCard(activeTrips[index], isActive: true);
      },
    );
  }

  Widget _buildTripHistory() {
    final completedTrips = _tripHistory
        .where((trip) =>
            trip.status == TripStatus.completed ||
            trip.status == TripStatus.cancelled)
        .toList();

    if (completedTrips.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text(
              'История поездок пуста',
              style: TextStyle(
                fontFamily: 'Rubik',
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: completedTrips.length,
      itemBuilder: (context, index) {
        return _buildTripCard(completedTrips[index]);
      },
    );
  }

  Widget _buildTripCard(TripModel trip, {bool isActive = false}) {
    final dateFormat = DateFormat('dd.MM.yyyy, HH:mm');
    final formattedDate = dateFormat.format(trip.createdAt);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  formattedDate,
                  style: const TextStyle(
                    fontFamily: 'Rubik',
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                _buildStatusChip(trip.status),
              ],
            ),
            const SizedBox(height: 16),
            _buildAddressRow(
                'Откуда', trip.origin.address, Icons.circle_outlined),
            const SizedBox(height: 8),
            _buildAddressRow(
                'Куда', trip.destination.address, Icons.location_on),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Стоимость',
                      style: TextStyle(
                        fontFamily: 'Rubik',
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    Text(
                      '${trip.price.toStringAsFixed(0)} ₽',
                      style: const TextStyle(
                        fontFamily: 'Rubik',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                if (isActive)
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pushNamed(
                        '/trip_details',
                        arguments: trip,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF53CFC4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Подробнее',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                if (!isActive && trip.status == TripStatus.completed)
                  Row(
                    children: [
                      Icon(Icons.star, color: Colors.amber, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '5.0',
                        style: TextStyle(
                          fontFamily: 'Rubik',
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressRow(String label, String? address, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 18,
          color: label == 'Откуда' ? Colors.grey : const Color(0xFF53CFC4),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Rubik',
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              Text(
                address ?? 'Адрес не указан',
                style: const TextStyle(
                  fontFamily: 'Rubik',
                  fontSize: 14,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChip(TripStatus status) {
    String label;
    Color color;

    switch (status) {
      case TripStatus.pending:
        label = 'Ожидание';
        color = Colors.orange;
        break;
      case TripStatus.confirmed:
        label = 'Подтверждено';
        color = Colors.blue;
        break;
      case TripStatus.inProgress:
        label = 'В пути';
        color = const Color(0xFF53CFC4);
        break;
      case TripStatus.completed:
        label = 'Завершено';
        color = Colors.green;
        break;
      case TripStatus.cancelled:
        label = 'Отменено';
        color = Colors.red;
        break;
      default:
        label = 'Неизвестно';
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Rubik',
          fontSize: 12,
          color: color,
        ),
      ),
    );
  }
}
