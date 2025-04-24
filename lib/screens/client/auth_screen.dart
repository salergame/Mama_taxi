import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mama_taxi/services/auth_service.dart';
import 'package:mama_taxi/providers/user_provider.dart';
import 'package:provider/provider.dart';
import 'package:mama_taxi/screens/home_screen.dart';

class ClientAuthScreen extends StatefulWidget {
  const ClientAuthScreen({Key? key}) : super(key: key);

  @override
  State<ClientAuthScreen> createState() => _ClientAuthScreenState();
}

class _ClientAuthScreenState extends State<ClientAuthScreen> {
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
      // Проверяем, заполнен ли профиль
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      await userProvider.initUser();

      // Если пользователь есть и профиль заполнен, идем на главную страницу
      if (userProvider.user != null &&
          userProvider.user!.name != null &&
          userProvider.user!.name!.isNotEmpty) {
        _navigateToHome();
      } else if (userProvider.user != null) {
        // Если пользователь есть, но профиль не заполнен
        Navigator.of(context).pushReplacementNamed('/profile_edit');
      }
    }
  }

  // Переход на главный экран
  void _navigateToHome() async {
    Navigator.of(context).pushReplacementNamed('/home');
  }

  // Метод для кнопки "Продолжить без регистрации"
  void _continueWithoutRegistration() {
    // Перенаправляем на главный экран вместо профиля
    Navigator.pushReplacementNamed(context, '/home');
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
        // Регистрация нового пользователя
        success = await _authService.registerWithEmailAndPassword(
            _emailController.text, _passwordController.text);
      } else {
        // Вход существующего пользователя
        success = await _authService.signInWithEmailAndPassword(
            _emailController.text, _passwordController.text);
      }

      if (success && mounted) {
        if (_isSignUp) {
          // Если это новая регистрация - переходим на заполнение профиля
          Navigator.pushReplacementNamed(context, '/profile_edit');
        } else {
          // Если вход успешен - идем на главную
          _navigateToHome();
        }
      } else {
        setState(() {
          _errorMessage = 'Ошибка авторизации. Проверьте введенные данные.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
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
    // Получаем размеры экрана для адаптивности
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 360;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // Градиентный фон
            Container(
              height: screenSize.height * 0.35,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFEDE9FE), Colors.white],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
            ),

            SingleChildScrollView(
              child: Column(
                children: [
                  // Логотип и заголовок
                  Container(
                    height: screenSize.height * 0.2,
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: screenSize.width * 0.3,
                          height: screenSize.width * 0.3,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius:
                                BorderRadius.circular(screenSize.width * 0.15),
                          ),
                          child: ClipRRect(
                            borderRadius:
                                BorderRadius.circular(screenSize.width * 0.15),
                            child: Image.asset(
                              'assets/images/logo.png',
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: screenSize.height * 0.01),

                  // Текст "Безопасные поездки для ваших детей"
                  Container(
                    width: screenSize.width * 0.8,
                    alignment: Alignment.center,
                    child: const Text(
                      'Безопасные поездки для ваших детей',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF4B5563),
                      ),
                    ),
                  ),

                  SizedBox(height: screenSize.height * 0.04),

                  // Основной контейнер с формой
                  Container(
                    width: screenSize.width,
                    padding: EdgeInsets.all(screenSize.width * 0.06),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(32),
                        topRight: Radius.circular(32),
                      ),
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Заголовок "Вход в систему" или "Регистрация"
                          Center(
                            child: Text(
                              _isSignUp ? 'Регистрация' : 'Вход в систему',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 18 : 20,
                                color: const Color(0xFF1F2937),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),

                          SizedBox(height: screenSize.height * 0.01),

                          // Подзаголовок
                          Center(
                            child: Text(
                              _isSignUp
                                  ? 'Создайте новую учетную запись'
                                  : 'Введите email и пароль для входа',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 12 : 14,
                                color: const Color(0xFF6B7280),
                              ),
                            ),
                          ),

                          SizedBox(height: screenSize.height * 0.03),

                          // Метка "Email"
                          Text(
                            'Email',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 12 : 14,
                              color: const Color(0xFF4B5563),
                            ),
                          ),

                          SizedBox(height: screenSize.height * 0.008),

                          // Поле ввода email
                          Container(
                            height: 50,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF9FAFB),
                              border: Border.all(
                                color: const Color(0xFFFFABBA),
                                width: 1,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: const InputDecoration(
                                hintText: 'example@mail.com',
                                hintStyle: TextStyle(color: Color(0xFFADAEBC)),
                                prefixIcon:
                                    Icon(Icons.email, color: Color(0xFF6B7280)),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 14),
                              ),
                              validator: _validateEmail,
                            ),
                          ),

                          SizedBox(height: screenSize.height * 0.02),

                          // Метка "Пароль"
                          Text(
                            'Пароль',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 12 : 14,
                              color: const Color(0xFF4B5563),
                            ),
                          ),

                          SizedBox(height: screenSize.height * 0.008),

                          // Поле ввода пароля
                          Container(
                            height: 50,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF9FAFB),
                              border: Border.all(
                                color: const Color(0xFFFFABBA),
                                width: 1,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              decoration: InputDecoration(
                                hintText: '••••••',
                                hintStyle:
                                    const TextStyle(color: Color(0xFFADAEBC)),
                                prefixIcon: const Icon(Icons.lock,
                                    color: Color(0xFF6B7280)),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility
                                        : Icons.visibility_off,
                                    color: const Color(0xFF6B7280),
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 14),
                              ),
                              validator: _validatePassword,
                            ),
                          ),

                          // Ссылка "Забыли пароль"
                          if (!_isSignUp)
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () {
                                  // Функционал восстановления пароля
                                },
                                child: Text(
                                  'Забыли пароль?',
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 12 : 14,
                                    color: const Color(0xFFF654AA),
                                  ),
                                ),
                              ),
                            ),

                          // Сообщение об ошибке
                          if (_errorMessage.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                _errorMessage,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.red,
                                ),
                              ),
                            ),

                          SizedBox(height: screenSize.height * 0.02),

                          // Кнопка "Войти" или "Зарегистрироваться"
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _handleSubmit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFF654AA),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                elevation: 0,
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
                                          ? 'Зарегистрироваться'
                                          : 'Войти',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),

                          // Переключатель режима вход/регистрация
                          Center(
                            child: TextButton(
                              onPressed: _toggleSignUp,
                              child: Text(
                                _isSignUp
                                    ? 'Уже есть аккаунт? Войти'
                                    : 'Нет аккаунта? Зарегистрироваться',
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 12 : 14,
                                  color: const Color(0xFFF654AA),
                                ),
                              ),
                            ),
                          ),

                          SizedBox(height: screenSize.height * 0.02),

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
                                    fontSize: isSmallScreen ? 12 : 14,
                                    color: const Color(0xFF9CA3AF),
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

                          SizedBox(height: screenSize.height * 0.02),

                          // Социальные кнопки
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildSocialButton(Icons.language),
                              _buildSocialButton(Icons.account_circle),
                              _buildSocialButton(Icons.facebook),
                            ],
                          ),

                          SizedBox(height: screenSize.height * 0.02),

                          // Разделитель "Зарегистрироваться как водитель"
                          Row(
                            children: [
                              const Expanded(
                                flex: 1,
                                child: Divider(
                                  color: Color(0xFFE5E7EB),
                                  thickness: 1,
                                ),
                              ),
                              Expanded(
                                flex: 5,
                                child: TextButton(
                                  onPressed: () {
                                    // Переход на экран регистрации водителя
                                    Navigator.pushNamed(
                                        context, '/auth_driver');
                                  },
                                  child: Text(
                                    'Зарегистрироваться как водитель',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: isSmallScreen ? 12 : 14,
                                      color: const Color(0xFF025FFE),
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
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Виджет для социальных кнопок
  Widget _buildSocialButton(IconData icon) {
    final screenSize = MediaQuery.of(context).size;
    final buttonWidth = (screenSize.width - (32 * 2) - (8 * 2)) / 3;

    return Container(
      width: buttonWidth,
      height: 48,
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
