import 'package:flutter/material.dart';
import 'package:mama_taxi/providers/user_provider.dart';
import 'package:mama_taxi/services/auth_service.dart';
import 'package:provider/provider.dart';
import 'package:mama_taxi/services/firebase_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AuthService _authService = AuthService();
  bool _isDarkMode = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final user = userProvider.user;

        return Scaffold(
          backgroundColor: const Color(0xFFF9FAFB),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: const Text(
              'Настройки',
              style: TextStyle(
                fontFamily: 'Manrope',
                fontSize: 16,
                color: Colors.black,
              ),
            ),
          ),
          body: Column(
            children: [
              // Секция с профилем пользователя
              Container(
                height: 96,
                color: Colors.white,
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Фото профиля с кнопкой редактирования
                    Stack(
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEDE9FE),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.person,
                            size: 40,
                            color: Colors.white,
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: const Color(0xFF5EC7C3),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.edit,
                              color: Colors.white,
                              size: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    // Имя и телефон
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          (user?.name?.isNotEmpty ?? false)
                              ? '${user!.name} ${user.surname}'
                              : 'Анна Смирнова',
                          style: const TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 18,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        Text(
                          user?.phone ?? '+7 (999) 123-45-67',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Основной список настроек
              Container(
                color: Colors.white,
                child: Column(
                  children: [
                    // Редактировать профиль
                    _buildSettingsItem(
                      icon: Icons.person_outline,
                      title: 'Редактировать профиль',
                      onTap: () => Navigator.pushNamed(context, '/profile'),
                    ),

                    // Платежи и баланс
                    _buildSettingsItem(
                      icon: Icons.credit_card,
                      title: 'Платежи и баланс',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                'Функция будет доступна в следующей версии'),
                          ),
                        );
                      },
                    ),

                    // Безопасность
                    _buildSettingsItem(
                      icon: Icons.shield_outlined,
                      title: 'Безопасность',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                'Функция будет доступна в следующей версии'),
                          ),
                        );
                      },
                    ),

                    // Уведомления
                    _buildSettingsItem(
                      icon: Icons.notifications_none,
                      title: 'Уведомления',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                'Функция будет доступна в следующей версии'),
                          ),
                        );
                      },
                    ),

                    // Язык и регион
                    _buildSettingsItem(
                      icon: Icons.language,
                      title: 'Язык и регион',
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Русский',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 14,
                              color: Color(0xFF9CA3AF),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.chevron_right,
                            size: 16,
                            color: Colors.grey.shade400,
                          ),
                        ],
                      ),
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                'Функция будет доступна в следующей версии'),
                          ),
                        );
                      },
                    ),

                    // Поддержка и информация
                    _buildSettingsItem(
                      icon: Icons.info_outline,
                      title: 'Поддержка и информация',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                'Функция будет доступна в следующей версии'),
                          ),
                        );
                      },
                    ),

                    // Темная тема
                    _buildSwitchItem(
                      icon: Icons.dark_mode_outlined,
                      title: 'Тёмная тема',
                      value: _isDarkMode,
                      onChanged: (value) {
                        setState(() {
                          _isDarkMode = value;
                        });
                        // TODO: Добавить сохранение настройки
                      },
                    ),

                    // Очистка кеша
                    _buildSettingsItem(
                      icon: Icons.cleaning_services_outlined,
                      title: 'Очистка кеша',
                      trailing: const Text(
                        '234 МБ',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          color: Color(0xFF9CA3AF),
                        ),
                      ),
                      onTap: () {
                        // TODO: Добавить очистку кеша
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Кеш очищен'),
                          ),
                        );
                      },
                    ),

                    // Проверка данных (отладка)
                    _buildSettingsItem(
                      icon: Icons.bug_report_outlined,
                      title: 'Проверить данные',
                      onTap: () async {
                        await FirebaseService().debugUserData();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content:
                                Text('Данные пользователя выведены в консоль'),
                          ),
                        );
                      },
                    ),

                    // Оплата и счета
                    _buildSettingsItem(
                      icon: Icons.payment,
                      title: 'Оплата и счета',
                      onTap: () {
                        Navigator.pushNamed(context, '/payment');
                      },
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Кнопка выхода из аккаунта
              Container(
                width: double.infinity,
                height: 56,
                color: Colors.white,
                child: InkWell(
                  onTap: () => _showLogoutDialog(context),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.logout,
                        size: 16,
                        color: Color(0xFFEF4444),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Выход из аккаунта',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 16,
                          color: Color(0xFFEF4444),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: const Color(0xFFF3F4F6),
              width: 1,
            ),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: Colors.black,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 16,
                  color: Colors.black,
                ),
              ),
            ),
            trailing ??
                Icon(
                  Icons.chevron_right,
                  size: 16,
                  color: Colors.grey.shade400,
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchItem({
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: const Color(0xFFF3F4F6),
            width: 1,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: Colors.black,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 16,
                color: Colors.black,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF5EC7C3),
          ),
        ],
      ),
    );
  }

  Future<void> _showLogoutDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Выход из аккаунта'),
          content: const Text('Вы уверены, что хотите выйти из аккаунта?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Отмена'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Выйти'),
              onPressed: () async {
                Navigator.of(context).pop();
                await _authService.signOut();
                if (mounted) {
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    '/auth',
                    (Route<dynamic> route) => false,
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }
}
