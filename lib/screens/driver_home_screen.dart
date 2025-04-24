import 'package:flutter/material.dart';
import 'package:mama_taxi/services/firebase_service.dart';
import 'package:mama_taxi/services/auth_service.dart';

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
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Выйти',
          ),
        ],
      ),
      body: Column(
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
            child:
                _isOnline ? _buildActiveInterface() : _buildOfflineInterface(),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveInterface() {
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

  Widget _buildOfflineInterface() {
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
