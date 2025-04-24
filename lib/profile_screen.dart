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
      // Очищаем данные аутентификации в SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_authenticated', false);
      await prefs.remove('user_id');
      await prefs.remove('phone_number');

      // Выходим из системы через сервисы
      await _authService.signOut();
      await _firebaseService.signOut();

      print('Выход выполнен успешно');

      // Сбрасываем состояние провайдера (если нужно)
      if (mounted) {
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        await userProvider.clearUserData();
      }

      // Перенаправляем пользователя на экран авторизации
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
                : const Icon(Icons.logout, color: Colors.black),
            onPressed: _isLoggingOut ? null : _logout,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Остальное содержимое экрана...

            // Кнопка выхода внизу экрана
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoggingOut ? null : _logout,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
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
}
