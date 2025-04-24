import 'package:flutter/material.dart';
import 'package:mama_taxi/widgets/driver_chat_widget.dart';

class DriverChatScreen extends StatefulWidget {
  final String driverName;
  final String driverPhoto;
  final String driverId;

  const DriverChatScreen({
    Key? key,
    this.driverName = 'Александр',
    this.driverPhoto = '',
    this.driverId = 'driver123',
  }) : super(key: key);

  @override
  State<DriverChatScreen> createState() => _DriverChatScreenState();
}

class _DriverChatScreenState extends State<DriverChatScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Чат с водителем',
          style: TextStyle(
            fontFamily: 'Nunito',
            fontSize: 20,
            fontWeight: FontWeight.w400,
            color: Color(0xFF53CFC4),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.grey),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Информация о чате'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
      ),
      body: DriverChatWidget(
        driverName: widget.driverName,
        driverPhoto: widget.driverPhoto,
        driverId: widget.driverId,
      ),
    );
  }
}
