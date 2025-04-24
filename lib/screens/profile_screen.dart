import 'package:flutter/material.dart';
import 'package:mama_taxi/providers/user_provider.dart';
import 'package:mama_taxi/services/auth_service.dart';
import 'package:mama_taxi/services/firebase_service.dart';
import 'package:provider/provider.dart';
import 'package:mama_taxi/widgets/add_child_modal.dart';
import 'package:mama_taxi/mixins/auth_checker_mixin.dart';
import 'package:mama_taxi/models/child_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with AuthCheckerMixin {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _surnameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _birthdayController = TextEditingController();
  String _gender = 'Мужской';
  String _city = 'Москва';
  String _emailErrorText = '';
  String? _selectedDate;
  String _selectedGender = 'Мужской';
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final AuthService _authService = AuthService();
  final FirebaseService _firebaseService = FirebaseService();
  bool _isLoadingChildren = false;
  bool _isLoggingOut = false;

  @override
  void initState() {
    super.initState();
    // Добавим отладочную информацию
    print('ProfileScreen initialized');
    _init();
  }

  Future<void> _init() async {
    final isAuthenticated = await checkAuth();
    if (isAuthenticated) {
      _initUserData();
      _loadChildren();
    }
  }

  // Загрузка списка детей
  Future<void> _loadChildren() async {
    setState(() {
      _isLoadingChildren = true;
    });

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      await userProvider.loadChildren();
    } catch (e) {
      print('Ошибка при загрузке списка детей: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка загрузки данных детей: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingChildren = false;
        });
      }
    }
  }

  // Инициализируем контроллеры из данных пользователя
  void _initUserData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      print('ProfileScreen loaded');
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final user = userProvider.user;

      if (user != null) {
        _nameController.text = user.name ?? '';
        _surnameController.text = user.surname ?? '';
        _emailController.text = user.email ?? '';
        _phoneController.text = user.phone ?? '';

        if (user.birthDate?.isNotEmpty ?? false) {
          _selectedDate = user.birthDate;
        }

        if (user.gender?.isNotEmpty ?? false) {
          _selectedGender = user.gender ?? 'Мужской';
        }

        _city = user.city ?? 'Москва';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Экран профиля загружен успешно'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    });
  }

  // Выход из аккаунта
  Future<void> _logout() async {
    setState(() {
      _isLoggingOut = true;
    });

    try {
      // Очищаем все данные аутентификации в SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_authenticated', false);
      await prefs.remove('user_id');
      await prefs.remove('phone_number');
      await prefs.remove('verification_id');
      await prefs.remove('otp_code');

      // Прочие возможные ключи связанные с авторизацией
      await prefs.remove('auth_token');
      await prefs.remove('refresh_token');
      await prefs.remove('user_data');

      // Выходим из системы через сервисы
      await _authService.signOut();
      await _firebaseService.signOut();

      print('Выход выполнен успешно');

      // Сбрасываем состояние провайдера
      if (mounted) {
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        await userProvider.clearUserData();
      }

      // Перенаправляем пользователя на экран авторизации и удаляем историю навигации
      if (mounted) {
        Navigator.of(context)
            .pushNamedAndRemoveUntil('/auth', (route) => false);
      }
    } catch (e) {
      print('Ошибка при выходе из аккаунта: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка при выходе из аккаунта: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoggingOut = false;
        });
      }
    }
  }

  // Добавление нового ребенка
  void _addChild() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AddChildModal(
          onAdd: (childData) async {
            // Создаем модель ребенка из полученных данных
            final userProvider =
                Provider.of<UserProvider>(context, listen: false);
            final child = ChildModel(
              userId: childData['userId'] ?? '',
              name: childData['name'] ?? '',
              age: childData['age'] ?? '',
              notes: childData['notes'] ?? '',
            );

            // Добавляем ребенка через провайдер
            final success = await userProvider.addChild(child);
            if (success) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Ребенок "${child.name}" успешно добавлен'),
                  backgroundColor: Colors.green,
                ),
              );
              setState(() {}); // Обновляем UI
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Ошибка при добавлении ребенка'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _surnameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _birthdayController.dispose();
    super.dispose();
  }

  bool _validateEmail(String email) {
    if (email.isEmpty) return true;

    final regex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return regex.hasMatch(email);
  }

  void _saveProfile(BuildContext context) async {
    print('Попытка сохранения профиля');
    if (_formKey.currentState!.validate()) {
      print('Форма валидна, сохраняем данные');
      _formKey.currentState!.save();
      final userProvider = Provider.of<UserProvider>(context, listen: false);

      try {
        await userProvider.updateProfile(
          name: _nameController.text,
          surname: _surnameController.text,
          email: _emailController.text,
          birthday: _selectedDate ?? '',
          gender: _selectedGender,
          city: _city,
          phone: _phoneController.text,
        );

        print('Профиль успешно обновлен, переходим на главный экран');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Профиль успешно сохранен'),
              backgroundColor: Colors.green,
            ),
          );

          // Переходим на главный экран
          Navigator.pushReplacementNamed(context, '/home');
        }
      } catch (e) {
        print('Ошибка при обновлении профиля: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Произошла ошибка: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } else {
      print('Форма невалидна');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Пожалуйста, заполните все необходимые поля'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    print('ProfileScreen building');
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Личный кабинет',
          style: TextStyle(
            fontFamily: 'Manrope',
            fontSize: 18,
            fontWeight: FontWeight.w400,
            color: Colors.black,
          ),
        ),
        actions: [
          // Кнопка выхода
          IconButton(
            icon: _isLoggingOut
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                    ),
                  )
                : const Icon(Icons.logout, color: Colors.red),
            onPressed: _isLoggingOut ? null : _logout,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Профиль
            Container(
              width: double.infinity,
              height: 96,
              margin: const EdgeInsets.only(top: 12),
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/account'),
                child: Row(
                  children: [
                    // Аватар
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
                    const SizedBox(width: 16),
                    // Информация
                    Consumer<UserProvider>(
                        builder: (context, userProvider, child) {
                      final user = userProvider.user;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            user?.name ?? 'Имя не указано',
                            style: const TextStyle(
                              fontFamily: 'Manrope',
                              fontSize: 18,
                              fontWeight: FontWeight.w400,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user?.phone ?? '+7 XXX XXX XX XX',
                            style: const TextStyle(
                              fontFamily: 'Manrope',
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      );
                    }),
                    const Spacer(),
                    // Иконка стрелки
                    const Icon(
                      Icons.chevron_right,
                      color: Colors.black,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Меню действий (Новая поездка, Расписание, Оплата)
            Container(
              width: double.infinity,
              height: 108,
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Новая поездка
                  GestureDetector(
                    onTap: () => Navigator.pushNamed(context, '/home'),
                    child: Column(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: const BoxDecoration(
                            color: Color(0xFFDBEAFE),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.directions_car,
                            size: 24,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Новая поездка',
                          style: TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Расписание
                  GestureDetector(
                    onTap: () => Navigator.pushNamed(context, '/schedule'),
                    child: Column(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: const BoxDecoration(
                            color: Color(0xFFEDE9FE),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.calendar_today,
                            size: 24,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Расписание',
                          style: TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Оплата
                  GestureDetector(
                    onTap: () => Navigator.pushNamed(context, '/payment'),
                    child: Column(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: const BoxDecoration(
                            color: Color(0xFFD1FAE5),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.payment,
                            size: 24,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Оплата',
                          style: TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Секция "Дети"
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Дети',
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 18,
                      fontWeight: FontWeight.w400,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Consumer<UserProvider>(
                    builder: (context, userProvider, child) {
                      final children = userProvider.children;
                      return Row(
                        children: [
                          // Добавить ребенка
                          GestureDetector(
                            onTap: _addChild,
                            child: Column(
                              children: [
                                Container(
                                  width: 64,
                                  height: 64,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFF3F4F6),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.add,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Добавить',
                                  style: TextStyle(
                                    fontFamily: 'Manrope',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                    color: Color(0xFF6B7280),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(width: 16),

                          // Отображение списка детей
                          if (_isLoadingChildren)
                            const CircularProgressIndicator()
                          else if (children.isEmpty)
                            const Text(
                              'У вас пока нет добавленных детей',
                              style: TextStyle(
                                fontFamily: 'Manrope',
                                fontSize: 14,
                                color: Color(0xFF6B7280),
                              ),
                            )
                          else
                            Expanded(
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: children
                                      .map((child) => Padding(
                                            padding: const EdgeInsets.only(
                                                right: 16),
                                            child: Column(
                                              children: [
                                                Container(
                                                  width: 64,
                                                  height: 64,
                                                  decoration: BoxDecoration(
                                                    color:
                                                        const Color(0xFFEDE9FE),
                                                    shape: BoxShape.circle,
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: Colors.black
                                                            .withOpacity(0.1),
                                                        blurRadius: 4,
                                                        offset:
                                                            const Offset(0, 2),
                                                      ),
                                                    ],
                                                  ),
                                                  child: const Icon(
                                                    Icons.person,
                                                    size: 40,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  child.name,
                                                  style: const TextStyle(
                                                    fontFamily: 'Manrope',
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w400,
                                                  ),
                                                ),
                                                Text(
                                                  child.age,
                                                  style: const TextStyle(
                                                    fontFamily: 'Manrope',
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w400,
                                                    color: Color(0xFF6B7280),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ))
                                      .toList(),
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Секция "Недавние поездки"
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Недавние поездки',
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 18,
                      fontWeight: FontWeight.w400,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Поездка 1
                  GestureDetector(
                    onTap: () => Navigator.pushNamed(context, '/trip_tracking'),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(
                            color: Color(0xFFDBEAFE),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.directions_car,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'Школа → Дом',
                                style: TextStyle(
                                  fontFamily: 'Manrope',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              Text(
                                '15 марта, 14:30',
                                style: TextStyle(
                                  fontFamily: 'Manrope',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                  color: Color(0xFF6B7280),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Text(
                          '450₽',
                          style: TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF059669),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Поездка 2
                  GestureDetector(
                    onTap: () => Navigator.pushNamed(context, '/trip_review'),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(
                            color: Color(0xFFDBEAFE),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.directions_car,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'Дом → Бассейн',
                                style: TextStyle(
                                  fontFamily: 'Manrope',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              Text(
                                '14 марта, 10:00',
                                style: TextStyle(
                                  fontFamily: 'Manrope',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                  color: Color(0xFF6B7280),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Text(
                          '350₽',
                          style: TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF059669),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Добавляем кнопку выхода внизу экрана
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoggingOut ? null : _logout,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoggingOut
                      ? const CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        )
                      : const Text(
                          'Выйти из аккаунта',
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 16,
                            color: Colors.white,
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

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildChildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildChildAddressRow(String label, String address) {
    return Row(
      children: [
        Icon(
          Icons.location_on,
          size: 18,
          color: Colors.grey,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              Text(
                address,
                style: const TextStyle(
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
