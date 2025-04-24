import 'package:flutter/material.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  _NotificationsScreenState createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final List<Map<String, dynamic>> _notifications = [
    {
      'type': 'success',
      'title': 'Ребенка довезли',
      'time': 'Сегодня, 08:40',
      'message': 'Ребенок успешно прибыл в пункт назначения (Школа №12).',
      'actions': [
        {
          'title': 'Оставить отзыв',
          'color': 0xFFEB5CAC,
          'action': 'review',
        }
      ],
    },
    {
      'type': 'warning',
      'title': 'Водитель сбился с маршрута',
      'time': 'Сегодня, 08:25',
      'message': 'Отклонение от маршрута на 2 км! Проверьте поездку.',
      'actions': [
        {
          'title': 'Открыть карту',
          'color': 0xFFEB5CAC,
          'action': 'map',
        },
        {
          'title': 'Связаться с водителем',
          'color': 0xFF5EC7C3,
          'action': 'call',
        }
      ],
    },
    {
      'type': 'warning',
      'title': 'Водитель задерживается',
      'time': 'Сегодня, 07:55',
      'message': 'Водитель задерживается более чем на 5 минут.',
      'actions': [
        {
          'title': 'Обновить статус',
          'color': 0xFFEB5CAC,
          'action': 'update',
        },
        {
          'title': 'Позвонить водителю',
          'color': 0xFF5EC7C3,
          'action': 'call',
        }
      ],
    },
    {
      'type': 'info',
      'title': 'Ребенка забрали',
      'time': 'Сегодня, 08:15',
      'message': 'Водитель Иван Петров забрал ребенка и выехал.',
      'actions': [
        {
          'title': 'Посмотреть маршрут',
          'color': 0xFFEB5CAC,
          'action': 'route',
        },
        {
          'title': 'Позвонить водителю',
          'color': 0xFF5EC7C3,
          'action': 'call',
        }
      ],
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.4),
      body: SafeArea(
        child: Center(
          child: Container(
            width: 358,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Заголовок
                Container(
                  height: 76,
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFCFBFF),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Уведомления',
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 20,
                          fontWeight: FontWeight.w400,
                          color: Colors.black,
                        ),
                      ),
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),

                // Список уведомлений
                Container(
                  height:
                      550, // Ограничиваем высоту, чтобы не выходило за экран
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(0),
                    child: Column(
                      children: _notifications
                          .map((notification) =>
                              _buildNotificationItem(notification))
                          .toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationItem(Map<String, dynamic> notification) {
    Color backgroundColor = Colors.white;

    // Определяем цвет фона в зависимости от типа уведомления
    if (notification['type'] == 'warning') {
      backgroundColor = const Color(0xFFFFFBEB);
    } else if (notification['type'] == 'success') {
      backgroundColor = Colors.white;
    } else if (notification['type'] == 'info') {
      backgroundColor = Colors.white;
    }

    // Определяем иконку в зависимости от типа уведомления
    IconData iconData = Icons.info_outline;
    if (notification['type'] == 'warning') {
      iconData = Icons.warning_amber_outlined;
    } else if (notification['type'] == 'success') {
      iconData = Icons.check_circle_outline;
    } else if (notification['type'] == 'info') {
      iconData = Icons.info_outline;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border.all(color: const Color(0xFFF3F4F6)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Иконка
            Icon(iconData, size: 20),
            const SizedBox(width: 12),

            // Контент
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Заголовок и время
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification['title'],
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF111827),
                          ),
                        ),
                      ),
                      Text(
                        notification['time'],
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Сообщение
                  Text(
                    notification['message'],
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF4B5563),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Кнопки действий
                  Row(
                    children:
                        (notification['actions'] as List).map<Widget>((action) {
                      bool isRightAction =
                          (notification['actions'] as List).indexOf(action) > 0;

                      if (action['title'].toString().contains(' ')) {
                        // Если название действия содержит пробел, разделяем на две строки
                        List<String> parts =
                            action['title'].toString().split(' ');

                        return Expanded(
                          child: Container(
                            margin:
                                EdgeInsets.only(left: isRightAction ? 8 : 0),
                            height: 52,
                            decoration: BoxDecoration(
                              color: Color(action['color']),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  parts[0],
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 14,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  parts.sublist(1).join(' '),
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 14,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      } else {
                        // Если название действия не содержит пробел
                        return Expanded(
                          child: Container(
                            margin:
                                EdgeInsets.only(left: isRightAction ? 8 : 0),
                            height: 32,
                            decoration: BoxDecoration(
                              color: Color(action['color']),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Center(
                              child: Text(
                                action['title'],
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 14,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        );
                      }
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
