import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mama_taxi/services/auth_service.dart';
import 'package:mama_taxi/providers/user_provider.dart';
import 'package:provider/provider.dart';
import 'package:mama_taxi/screens/home_screen.dart';
import 'package:mama_taxi/screens/driver_home_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({Key? key}) : super(key: key);

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  bool _isSignUp = false;
  bool _obscurePassword = true;
  String _errorMessage = '';
  bool _isDriverMode = false;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Проверка авторизации
  Future<void> _checkAuth() async {
    final isAuthenticated = await _authService.isUserAuthenticated();
    if (isAuthenticated && mounted) {
      print('Пользователь авторизован, проверяем данные профиля');
      // Проверяем, заполнен ли профиль
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      await userProvider.initUser();

      // Если пользователь есть и профиль заполнен, идем на главную страницу
      if (userProvider.user != null &&
          userProvider.user!.name != null &&
          userProvider.user!.name!.isNotEmpty) {
        print('Профиль заполнен, переходим на главную');
        _navigateToHome();
      } else if (userProvider.user != null) {
        // Если пользователь есть, но профиль не заполнен
        print('Профиль не заполнен, переходим к редактированию профиля');
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

      // Временно для демо: используем email="demo@mail.ru", пароль="123456"
      final email = "demo@mail.ru";
      final password = "123456";

      if (_isSignUp) {
        // Регистрация нового пользователя
        success = await _authService.registerWithEmailAndPassword(
            email, password,
            isDriver: _isDriverMode);
      } else {
        // Вход существующего пользователя
        success =
            await _authService.signInWithEmailAndPassword(email, password);
      }

      if (success && mounted) {
        final isDriver = await _authService.isUserDriver();

        if (_isSignUp) {
          // Если это новая регистрация - переходим на заполнение профиля
          Navigator.pushReplacementNamed(context, '/profile_edit');
        } else {
          // Если вход - проверяем тип пользователя и переходим на соответствующий экран
          if (isDriver) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const DriverHomeScreen()),
            );
          } else {
            _navigateToHome();
          }
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

  void _switchMode() {
    setState(() {
      _isSignUp = !_isSignUp;
      _errorMessage = '';
    });
  }

  void _switchUserType() {
    setState(() {
      _isDriverMode = !_isDriverMode;
    });
  }

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Пожалуйста, введите номер телефона';
    }
    if (!RegExp(r'^\(\d{3}\) \d{3}-\d{2}-\d{2}$').hasMatch(value)) {
      return 'Формат: (999) 123-45-67';
    }
    return null;
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
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Заголовок "Вход в систему"
                          Center(
                            child: Text(
                              'Вход в систему',
                              style: const TextStyle(
                                fontSize: 20,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                          ),

                          const SizedBox(height: 32),

                          // Метка "Номер телефона"
                          const Text(
                            'Номер телефона',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF4B5563),
                            ),
                          ),

                          const SizedBox(height: 8),

                          // Поле ввода телефона
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
                            child: Row(
                              children: [
                                const SizedBox(width: 13),
                                const Text(
                                  '+7',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Color(0xFF6B7280),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextFormField(
                                    controller: _phoneController,
                                    decoration: const InputDecoration(
                                      hintText: '(999) 123-45-67',
                                      hintStyle: TextStyle(
                                        color: Color(0xFFADAEBC),
                                        fontSize: 16,
                                      ),
                                      border: InputBorder.none,
                                    ),
                                    keyboardType: TextInputType.phone,
                                    validator: _validatePhone,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 32),

                          // Кнопка "Получить код"
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
                                  : const Text(
                                      'Получить код',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Разделитель "или войти через"
                          Row(
                            children: const [
                              Expanded(
                                child: Divider(
                                  color: Color(0xFFE5E7EB),
                                  thickness: 1,
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 12),
                                child: Text(
                                  'или войти через',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF9CA3AF),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Divider(
                                  color: Color(0xFFE5E7EB),
                                  thickness: 1,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),

                          // Социальные кнопки
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                width: 103,
                                height: 48,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: const Color(0xFFE5E7EB),
                                    width: 1,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.language,
                                    color: Colors.black),
                              ),
                              Container(
                                width: 103,
                                height: 48,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: const Color(0xFFE5E7EB),
                                    width: 1,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.account_circle,
                                    color: Colors.black),
                              ),
                              Container(
                                width: 103,
                                height: 48,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: const Color(0xFFE5E7EB),
                                    width: 1,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.facebook,
                                    color: Colors.black),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

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
                                    setState(() {
                                      _isDriverMode = true;
                                      _isSignUp = true;
                                    });
                                    Navigator.pushNamed(
                                        context, '/auth_driver');
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
                        ],
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
