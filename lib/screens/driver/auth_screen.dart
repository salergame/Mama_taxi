import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mama_taxi/services/auth_service.dart';
import 'package:mama_taxi/providers/user_provider.dart';
import 'package:provider/provider.dart';
import 'package:mama_taxi/screens/driver_home_screen.dart';
import 'dart:ui' as ui;

class DriverAuthScreen extends StatefulWidget {
  const DriverAuthScreen({Key? key}) : super(key: key);

  @override
  State<DriverAuthScreen> createState() => _DriverAuthScreenState();
}

class _DriverAuthScreenState extends State<DriverAuthScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  bool _isSignUp = false;
  bool _obscurePassword = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Проверка авторизации
  Future<void> _checkAuth() async {
    final isAuthenticated = await _authService.isUserAuthenticated();
    if (isAuthenticated && mounted) {
      final isDriver = await _authService.isUserDriver();
      if (isDriver) {
        // Если пользователь водитель, перенаправляем на экран водителя
        _navigateToHome();
      } else {
        // Если пользователь не водитель, выходим и остаемся на экране авторизации
        await _authService.signOut();
      }
    }
  }

  // Переход на главный экран
  void _navigateToHome() async {
    Navigator.of(context).pushReplacementNamed('/driver_home');
  }

  // Обработка нажатия на кнопку входа/регистрации
  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Скрываем клавиатуру
    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      bool success;

      if (_isSignUp) {
        // Регистрация нового водителя
        success = await _authService.registerWithEmailAndPassword(
            _emailController.text, _passwordController.text,
            isDriver: true);
      } else {
        // Вход существующего водителя
        success = await _authService.signInWithEmailAndPassword(
            _emailController.text, _passwordController.text);

        // Проверяем, является ли пользователь водителем
        if (success) {
          final isDriver = await _authService.isUserDriver();
          if (!isDriver) {
            success = false;
            setState(() {
              _errorMessage = 'Этот аккаунт не зарегистрирован как водитель';
            });
          }
        }
      }

      if (success && mounted) {
        if (_isSignUp) {
          // Если это новая регистрация - переходим на заполнение документов
          Navigator.pushReplacementNamed(context, '/driver_documents');
        } else {
          // Если вход успешен - идем на главную
          _navigateToHome();
        }
      } else if (_errorMessage.isEmpty) {
        setState(() {
          _errorMessage = 'Ошибка авторизации. Проверьте введенные данные.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _toggleSignUp() {
    setState(() {
      _isSignUp = !_isSignUp;
      _errorMessage = '';
    });
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Пожалуйста, введите email';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Пожалуйста, введите корректный email';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Пожалуйста, введите пароль';
    }
    if (value.length < 6) {
      return 'Пароль должен содержать минимум 6 символов';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: Stack(
          children: [
            // Верхняя панель с заголовком
            Positioned(
              top: 45,
              left: 0,
              child: Container(
                width: 390,
                height: 60,
                color: Colors.white,
                child: Stack(
                  children: [
                    // Кнопка назад
                    Positioned(
                      left: 16,
                      top: 20,
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                        },
                        child: const Icon(
                          Icons.arrow_back,
                          color: Colors.black,
                          size: 20,
                        ),
                      ),
                    ),
                    // Заголовок
                    Positioned(
                      left: 72.44,
                      top: 16,
                      child: Text(
                        _isSignUp ? "Регистрация водителя" : "Вход водителя",
                        style: const TextStyle(
                          fontFamily: 'Rubik',
                          fontSize: 20,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Основное содержимое (прокручиваемое)
            Positioned(
              top: 105,
              left: 0,
              child: Container(
                width: 390,
                height: MediaQuery.of(context).size.height - 105,
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Блок авторизации
                          Container(
                            width: 358,
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
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Заголовок "Вход по email и паролю"
                                  Text(
                                    "Вход по email и паролю",
                                    style: const TextStyle(
                                      fontFamily: 'Rubik',
                                      fontSize: 18,
                                      fontWeight: FontWeight.w400,
                                      color: Colors.black,
                                    ),
                                  ),
                                  const SizedBox(height: 16),

                                  // Поле для ввода email
                                  Container(
                                    height: 50,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF9FAFB),
                                      border: Border.all(
                                        color: const Color(0xFFE5E7EB),
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: TextFormField(
                                      controller: _emailController,
                                      decoration: const InputDecoration(
                                        prefixIcon: Icon(
                                          Icons.email,
                                          color: Color(0xFF6B7280),
                                        ),
                                        hintText: 'example@mail.com',
                                        hintStyle: TextStyle(
                                          color: Color(0xFFADAEBC),
                                          fontFamily: 'Nunito',
                                          fontSize: 16,
                                        ),
                                        border: InputBorder.none,
                                        contentPadding: EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 13,
                                        ),
                                      ),
                                      validator: _validateEmail,
                                    ),
                                  ),
                                  const SizedBox(height: 8),

                                  // Поле для ввода пароля
                                  Container(
                                    height: 50,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF9FAFB),
                                      border: Border.all(
                                        color: const Color(0xFFE5E7EB),
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: TextFormField(
                                      controller: _passwordController,
                                      obscureText: _obscurePassword,
                                      decoration: InputDecoration(
                                        prefixIcon: const Icon(
                                          Icons.lock,
                                          color: Color(0xFF6B7280),
                                        ),
                                        hintText: '••••••',
                                        hintStyle: const TextStyle(
                                          color: Color(0xFFADAEBC),
                                          fontFamily: 'Nunito',
                                          fontSize: 16,
                                        ),
                                        suffixIcon: IconButton(
                                          icon: Icon(
                                            _obscurePassword
                                                ? Icons.visibility
                                                : Icons.visibility_off,
                                            color: const Color(0xFF6B7280),
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              _obscurePassword =
                                                  !_obscurePassword;
                                            });
                                          },
                                        ),
                                        border: InputBorder.none,
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 13,
                                        ),
                                      ),
                                      validator: _validatePassword,
                                    ),
                                  ),
                                  const SizedBox(height: 16),

                                  // Сообщение об ошибке
                                  if (_errorMessage.isNotEmpty)
                                    Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 8.0),
                                      child: Text(
                                        _errorMessage,
                                        style: const TextStyle(
                                          color: Colors.red,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),

                                  // Кнопка входа
                                  Container(
                                    width: 342,
                                    height: 56,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF654AA),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: ElevatedButton(
                                      onPressed:
                                          _isLoading ? null : _handleSubmit,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            const Color(0xFFF654AA),
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                      ),
                                      child: _isLoading
                                          ? const SizedBox(
                                              width: 24,
                                              height: 24,
                                              child: CircularProgressIndicator(
                                                color: Colors.white,
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : Text(
                                              _isSignUp
                                                  ? "Зарегистрироваться"
                                                  : "Получить код",
                                              style: const TextStyle(
                                                fontFamily: 'Nunito',
                                                fontSize: 16,
                                                fontWeight: FontWeight.w400,
                                                color: Colors.white,
                                              ),
                                            ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Блок входа через соцсети
                          Container(
                            width: 358,
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
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Заголовок "Вход через социальные сети"
                                  Text(
                                    "Вход через социальные сети",
                                    style: const TextStyle(
                                      fontFamily: 'Rubik',
                                      fontSize: 18,
                                      fontWeight: FontWeight.w400,
                                      color: Colors.black,
                                    ),
                                  ),
                                  const SizedBox(height: 16),

                                  // Кнопки соцсетей
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      _buildSocialButton(Icons.language),
                                      _buildSocialButton(Icons.account_circle),
                                      _buildSocialButton(Icons.facebook),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Блок фотоконтроля
                          Container(
                            width: 358,
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
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Заголовок "Фотоконтроль"
                                  Text(
                                    "Фотоконтроль",
                                    style: const TextStyle(
                                      fontFamily: 'Rubik',
                                      fontSize: 18,
                                      fontWeight: FontWeight.w400,
                                      color: Colors.black,
                                    ),
                                  ),
                                  const SizedBox(height: 16),

                                  // Поле для селфи
                                  Container(
                                    width: 326,
                                    height: 142,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: CustomPaint(
                                      painter: DashedBorderPainter(
                                        color: const Color(0xFFE5E7EB),
                                        strokeWidth: 2,
                                        dashPattern: [6, 3],
                                      ),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const Icon(
                                            Icons.camera_alt,
                                            size: 30,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            "Сделайте селфи",
                                            style: const TextStyle(
                                              fontFamily: 'Rubik',
                                              fontSize: 14,
                                              color: Color(0xFF4B5563),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),

                                  // Подсказка о фото
                                  Container(
                                    width: 290,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEFF6FF),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        const SizedBox(width: 12),
                                        const Icon(
                                          Icons.info,
                                          color: Color(0xFF1D4ED8),
                                          size: 12,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            "Фото должно быть при хорошем освещении",
                                            style: const TextStyle(
                                              fontFamily: 'Rubik',
                                              fontSize: 12,
                                              color: Color(0xFF1D4ED8),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 16),

                                  // Статус проверки
                                  Container(
                                    width: 326,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFFBEB),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        const SizedBox(width: 12),
                                        const Icon(
                                          Icons.pending,
                                          color: Color(0xFFB45309),
                                          size: 16,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          "Ожидает проверки",
                                          style: const TextStyle(
                                            fontFamily: 'Rubik',
                                            fontSize: 16,
                                            color: Color(0xFFB45309),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Блок загрузки документов
                          Container(
                            width: 358,
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
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Заголовок "Загрузка документов"
                                  Text(
                                    "Загрузка документов",
                                    style: const TextStyle(
                                      fontFamily: 'Rubik',
                                      fontSize: 18,
                                      fontWeight: FontWeight.w400,
                                      color: Colors.black,
                                    ),
                                  ),
                                  const SizedBox(height: 16),

                                  // Кнопка "Паспорт"
                                  Container(
                                    width: 326,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: const Color(0xFFE5E7EB),
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        const SizedBox(width: 13),
                                        const Icon(
                                          Icons.assignment_ind,
                                          size: 18,
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          "Паспорт",
                                          style: const TextStyle(
                                            fontFamily: 'Rubik',
                                            fontSize: 16,
                                            color: Colors.black,
                                          ),
                                        ),
                                        const Spacer(),
                                        const Icon(
                                          Icons.arrow_forward_ios,
                                          size: 14,
                                        ),
                                        const SizedBox(width: 13),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 12),

                                  // Кнопка "Водительское удостоверение"
                                  Container(
                                    width: 326,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: const Color(0xFFE5E7EB),
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        const SizedBox(width: 13),
                                        const Icon(
                                          Icons.drive_eta,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          "Водительское удостоверение",
                                          style: const TextStyle(
                                            fontFamily: 'Rubik',
                                            fontSize: 16,
                                            color: Colors.black,
                                          ),
                                        ),
                                        const Spacer(),
                                        const Icon(
                                          Icons.arrow_forward_ios,
                                          size: 14,
                                        ),
                                        const SizedBox(width: 13),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Кнопка "Продолжить"
                          Container(
                            width: 358,
                            height: 56,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF654AA),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _handleSubmit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFF654AA),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                "Продолжить",
                                style: const TextStyle(
                                  fontFamily: 'Rubik',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w400,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Виджет для социальных кнопок
  Widget _buildSocialButton(IconData icon) {
    return Container(
      width: 100,
      height: 46,
      decoration: BoxDecoration(
        border: Border.all(
          color: const Color(0xFFE5E7EB),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: Colors.black),
    );
  }
}

class DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final List<double> dashPattern;

  DashedBorderPainter({
    required this.color,
    required this.strokeWidth,
    required this.dashPattern,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final path = Path();
    double x = 0;
    while (x < size.width) {
      for (final dash in dashPattern) {
        path.moveTo(x, 0);
        x += dash;
        if (x > size.width) {
          x = size.width;
        }
        path.lineTo(x, 0);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}
