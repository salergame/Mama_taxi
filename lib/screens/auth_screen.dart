import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mama_taxi/screens/otp_screen.dart';
import 'package:mama_taxi/services/auth_service.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({Key? key}) : super(key: key);

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  // Проверка авторизации
  Future<void> _checkAuth() async {
    final isAuthenticated = await _authService.isUserAuthenticated();
    if (isAuthenticated && mounted) {
      _navigateToHome();
    }
  }

  // Переход на главный экран
  void _navigateToHome() {
    Navigator.of(context).pushReplacementNamed('/home');
  }

  // Обработка нажатия на кнопку продолжить
  Future<void> _handleContinue() async {
    // Получаем номер телефона из контроллера
    final phoneNumber = _phoneController.text.trim();

    if (phoneNumber.isEmpty) {
      setState(() {
        _errorMessage = 'Введите номер телефона';
      });
      return;
    }

    // Форматируем номер телефона
    final formattedPhone = '+7 $phoneNumber';

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Отправляем запрос на верификацию
      await _authService.verifyPhoneNumber(
        formattedPhone,
        (verificationId) {
          setState(() {
            _isLoading = false;
          });
          // Переход на экран ввода OTP
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OtpScreen(
                phoneNumber: formattedPhone,
                verificationId: verificationId,
              ),
            ),
          );
        },
        (error) {
          setState(() {
            _isLoading = false;
            _errorMessage = error;
          });
        },
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  // Авторизация через соц. сети
  void _handleSocialLogin() {
    // В демо-режиме просто переходим на главный экран
    _navigateToHome();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Градиентный фон
          Container(
            height: 300,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFEDE9FE), Colors.white],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Логотип и заголовок
                  Container(
                    height: 180,
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 144,
                          height: 144,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(72),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(72),
                            child: Image.asset(
                              'assets/images/logo.png',
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Текст "Безопасные поездки для ваших детей"
                  const Text(
                    'Безопасные поездки для ваших детей',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF4B5563),
                    ),
                  ),

                  const SizedBox(height: 38),

                  // Основной контейнер с формой
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(32),
                        topRight: Radius.circular(32),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Заголовок "Вход в систему"
                        const Center(
                          child: Text(
                            'Вход в систему',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w400,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Поле ввода номера телефона
                        const Text(
                          'Номер телефона',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF4B5563),
                          ),
                        ),

                        const SizedBox(height: 8),

                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF9FAFB),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: const Color(0xFFFFABBA),
                              width: 1,
                            ),
                          ),
                          child: TextField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              contentPadding: EdgeInsets.symmetric(
                                  vertical: 13, horizontal: 13),
                              border: InputBorder.none,
                              prefixIcon: Padding(
                                padding: EdgeInsets.only(left: 13, right: 5),
                                child: Text(
                                  '+7',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Color(0xFF6B7280),
                                  ),
                                ),
                              ),
                              prefixIconConstraints:
                                  BoxConstraints(minWidth: 0, minHeight: 0),
                              hintText: '(999) 123-45-67',
                              hintStyle: TextStyle(
                                fontSize: 16,
                                color: Color(0xFFADAEBC),
                              ),
                            ),
                          ),
                        ),

                        if (_errorMessage.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              _errorMessage,
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 12,
                              ),
                            ),
                          ),

                        const SizedBox(height: 24),

                        // Кнопка "Продолжить"
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleContinue,
                            child: _isLoading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('Продолжить'),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Кнопка для регистрации водителя
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.pushNamed(context, '/driver_auth');
                            },
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(
                                color: Color(0xFF4FD8C4),
                                width: 1,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.drive_eta_outlined,
                                  color: Color(0xFF4FD8C4),
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Стать водителем',
                                  style: TextStyle(
                                    color: Color(0xFF4FD8C4),
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Разделитель "или войти через"
                        Row(
                          children: [
                            const Expanded(
                              child: Divider(
                                color: Color(0xFFE5E7EB),
                                thickness: 1,
                              ),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                'или войти через',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ),
                            const Expanded(
                              child: Divider(
                                color: Color(0xFFE5E7EB),
                                thickness: 1,
                              ),
                            ),
                          ],
                        ),

                        // Ссылка "Зарегистрироваться как водитель"
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Expanded(
                                flex: 1,
                                child: Divider(
                                  color: Color(0xFFE5E7EB),
                                  thickness: 1,
                                ),
                              ),
                              Expanded(
                                flex: 6,
                                child: TextButton(
                                  onPressed: () {
                                    Navigator.pushNamed(
                                        context, '/driver_auth');
                                  },
                                  child: const Text(
                                    'Зарегистрироваться как водитель',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF025FFE),
                                    ),
                                  ),
                                ),
                              ),
                              const Expanded(
                                flex: 1,
                                child: Divider(
                                  color: Color(0xFFE5E7EB),
                                  thickness: 1,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Кнопки соц. сетей
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildSocialButton(
                              onPressed: _handleSocialLogin,
                              svgPath: 'assets/icons/google.svg',
                            ),
                            _buildSocialButton(
                              onPressed: _handleSocialLogin,
                              svgPath: 'assets/icons/vk.svg',
                            ),
                            _buildSocialButton(
                              onPressed: _handleSocialLogin,
                              svgPath: 'assets/icons/telegram.svg',
                            ),
                          ],
                        ),

                        // Кнопка быстрого перехода на карту (для демо)
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: OutlinedButton(
                              onPressed: _navigateToHome,
                              style: OutlinedButton.styleFrom(
                                side:
                                    const BorderSide(color: Color(0xFF4FD8C4)),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.map,
                                    color: Color(0xFF4FD8C4),
                                    size: 20,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Перейти к карте',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Color(0xFF4FD8C4),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
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

  Widget _buildSocialButton({
    required VoidCallback onPressed,
    required String svgPath,
  }) {
    return Container(
      width: 103,
      height: 48,
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: SvgPicture.asset(
          svgPath,
          width: 20,
          height: 20,
        ),
      ),
    );
  }
}
