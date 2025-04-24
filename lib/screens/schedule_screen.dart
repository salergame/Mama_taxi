import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({Key? key}) : super(key: key);

  @override
  _ScheduleScreenState createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  final List<Map<String, dynamic>> _upcomingTrips = [
    {
      'service': 'Мама такси',
      'time': '8:00',
      'date': '15 февраль',
      'price': 450,
      'childName': 'Петя',
      'childAge': '8 лет',
      'fromAddress': 'ул. Пушкина, 10',
      'toAddress': 'Школа №5, ул. Ленина, 25',
    },
    {
      'service': 'Мама такси',
      'time': '12:00',
      'date': '15 февраль',
      'price': 300,
      'childName': 'Петя',
      'childAge': '8 лет',
      'fromAddress': 'ул. Пушкина, 10',
      'toAddress': 'Спорт комплекс, ул. Ленина, 15',
    },
  ];

  String _selectedView = 'day'; // day, week, month

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        shadowColor: Colors.black.withOpacity(0.05),
        title: Row(
          children: [
            Icon(Icons.calendar_today, size: 18),
            SizedBox(width: 16),
            Text(
              'Расписание',
              style: TextStyle(
                fontFamily: 'Manrope',
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: Colors.black,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: CircleAvatar(
              radius: 16,
              backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=44'),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildCalendarHeader(),
          SizedBox(height: 16),
          _buildUpcomingTripsList(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Навигация на экран создания поездки
          Navigator.pushNamed(context, '/home');
        },
        backgroundColor: const Color(0xFF5EC7C3),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCalendarHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Февраль 2025',
                style: TextStyle(
                  fontFamily: 'Rubik',
                  fontSize: 18,
                  fontWeight: FontWeight.w400,
                  color: Colors.black,
                ),
              ),
              Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      // Предыдущий месяц
                    },
                    child: Container(
                      width: 26,
                      height: 32,
                      child: Icon(Icons.chevron_left, size: 16),
                    ),
                  ),
                  SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      // Следующий месяц
                    },
                    child: Container(
                      width: 26,
                      height: 32,
                      child: Icon(Icons.chevron_right, size: 16),
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 16),
          Row(
            children: [
              _buildViewButton('День', 'day'),
              SizedBox(width: 12),
              _buildViewButton('Неделя', 'week'),
              SizedBox(width: 12),
              _buildViewButton('Месяц', 'month'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildViewButton(String title, String view) {
    bool isSelected = _selectedView == view;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedView = view;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFED56AE) : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontFamily: 'Rubik',
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: isSelected ? Colors.white : const Color(0xFF4B5563),
          ),
        ),
      ),
    );
  }

  Widget _buildUpcomingTripsList() {
    return Expanded(
      child: ListView(
        padding: EdgeInsets.symmetric(horizontal: 16),
        children: [
          _buildSectionTitle('Сегодня, 15 Февраля'),
          SizedBox(height: 12),
          _buildSectionTitle('Предстоящие поездки'),
          SizedBox(height: 8),
          ..._upcomingTrips.map((trip) => _buildTripCard(trip)).toList(),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontFamily: 'Rubik',
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: const Color(0xFF6B7280),
      ),
    );
  }

  Widget _buildTripCard(Map<String, dynamic> trip) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
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
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Заголовок с сервисом и ценой
            Row(
              children: [
                Icon(Icons.directions_car, size: 16),
                SizedBox(width: 8),
                Text(
                  trip['service'],
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
                Spacer(),
                Text(
                  '₽${trip['price']}',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF2563EB),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            // Время и дата
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${trip['time']} • ${trip['date']}',
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF4B5563),
                ),
              ),
            ),
            SizedBox(height: 12),
            // Информация о ребенке
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundImage:
                      NetworkImage('https://i.pravatar.cc/150?img=1'),
                ),
                SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      trip['childName'],
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      trip['childAge'],
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF4B5563),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 12),
            // Адреса
            Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.circle, size: 12, color: Colors.black),
                    SizedBox(width: 8),
                    Text(
                      trip['fromAddress'],
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 12, color: Colors.black),
                    SizedBox(width: 8),
                    Text(
                      trip['toAddress'],
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 16),
            // Кнопки действий
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      // Изменить поездку
                    },
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                      side: BorderSide(color: const Color(0xFFEB5CAC)),
                    ),
                    child: Text(
                      'Изменить',
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFFEB5CAC),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      // Отследить поездку
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEB5CAC),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    child: Text(
                      'Отследить',
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
