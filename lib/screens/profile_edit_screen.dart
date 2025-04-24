import 'package:flutter/material.dart';
import 'package:mama_taxi/providers/user_provider.dart';
import 'package:provider/provider.dart';
import 'package:mama_taxi/services/auth_service.dart';
import 'package:mama_taxi/services/firebase_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({Key? key}) : super(key: key);

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _surnameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _birthDateController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  String _gender = 'Мужской';
  String _city = 'Москва';
  bool _hasEmailError = false;
  bool _isNewProfile =
      true; // Флаг для определения нового профиля или редактирования
  bool _isLoading = false;
  bool _isLoggingOut = false;
  bool _isChangingPassword = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String _emailErrorText = '';
  String _selectedDate = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      await userProvider.initUser();
      final user = userProvider.user;

      if (user != null) {
        _nameController.text = user.name ?? '';
        _surnameController.text = user.surname ?? '';
        _phoneController.text = user.phone ?? '';
        _emailController.text = user.email ?? '';
        if (user.birthDate != null) _selectedDate = user.birthDate ?? '';
        if (user.gender != null) _gender = user.gender ?? 'Мужской';
        _city = user.city ?? 'Москва';
      }
    } catch (e) {
      print('Ошибка при загрузке данных пользователя: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка загрузки данных: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _logout() async {
    setState(() {
      _isLoggingOut = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_authenticated', false);
      await prefs.remove('user_id');
      await prefs.remove('phone_number');
      await prefs.remove('verification_id');
      await prefs.remove('otp_code');

      await prefs.remove('auth_token');
      await prefs.remove('refresh_token');
      await prefs.remove('user_data');

      final authService = AuthService();
      await authService.signOut();
      final firebaseService = FirebaseService();
      await firebaseService.signOut();

      print('Выход выполнен успешно');

      if (mounted) {
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        await userProvider.clearUserData();
      }

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

  bool _validateEmail(String email) {
    if (email.isEmpty) {
      setState(() {
        _emailErrorText = 'Введите email';
      });
      return false;
    }

    final regex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!regex.hasMatch(email)) {
      setState(() {
        _emailErrorText = 'Неверный формат email';
      });
      return false;
    }

    setState(() {
      _emailErrorText = '';
    });
    return true;
  }

  bool _validateForm() {
    // Проверка имени и фамилии
    if (_nameController.text.isEmpty || _surnameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Имя и фамилия обязательны'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }

    // Проверка email
    if (!_validateEmail(_emailController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_emailErrorText),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }

    // Проверка паролей, если пользователь решил их изменить
    if (_isChangingPassword) {
      if (_passwordController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Введите новый пароль'),
            backgroundColor: Colors.red,
          ),
        );
        return false;
      }

      if (_passwordController.text.length < 6) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Пароль должен содержать не менее 6 символов'),
            backgroundColor: Colors.red,
          ),
        );
        return false;
      }

      if (_passwordController.text != _confirmPasswordController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Пароли не совпадают'),
            backgroundColor: Colors.red,
          ),
        );
        return false;
      }
    }

    return true;
  }

  Future<void> _saveProfile() async {
    if (!_validateForm()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);

      // Обновляем основные данные профиля, включая телефон
      await userProvider.updateProfile(
        name: _nameController.text,
        surname: _surnameController.text,
        email: _emailController.text,
        birthday: _selectedDate,
        gender: _gender,
        city: _city,
        phone: _phoneController.text, // Добавляем номер телефона
      );

      // Если пользователь изменил email
      final userData = await userProvider.userData;
      if (userData != null && userData['email'] != _emailController.text) {
        await userProvider.updateUserEmail(_emailController.text);
      }

      // Если пользователь изменил пароль
      if (_isChangingPassword && _passwordController.text.isNotEmpty) {
        await userProvider.updateUserPassword(_passwordController.text);
      }

      // Очищаем поля пароля после сохранения
      _passwordController.clear();
      _confirmPasswordController.clear();
      setState(() {
        _isChangingPassword = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Профиль успешно обновлен'),
          backgroundColor: Colors.green,
        ),
      );

      // После сохранения переходим на главный экран
      Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      print('Ошибка при сохранении профиля: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка сохранения: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _surnameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _birthDateController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: _isNewProfile ? null : () => Navigator.pop(context),
        ),
        title: Text(
          _isNewProfile ? 'Заполните профиль' : 'Редактировать профиль',
          style: const TextStyle(
            color: Colors.black,
            fontFamily: 'Manrope',
            fontSize: 16,
            fontWeight: FontWeight.w400,
          ),
        ),
        actions: [
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
          children: [
            // Профиль с аватаром
            Container(
              width: 390,
              height: 144,
              color: Colors.white,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Аватар
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEDE9FE),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.person,
                        size: 60,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  // Кнопка редактирования
                  Positioned(
                    right: 147,
                    bottom: 24,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: const Color(0xFF5EC7C3),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 6,
                            offset: const Offset(0, 4),
                          ),
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 15,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.edit,
                        color: Colors.black,
                        size: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Форма с личными данными
            Container(
              width: 358,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Имя
                    const Text(
                      'Имя',
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 14,
                        color: Color(0xFF4B5563),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 42,
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: TextField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          hintText: 'Введите имя',
                          hintStyle: TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 16,
                            color: Color(0xFFADAEBC),
                          ),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Фамилия
                    const Text(
                      'Фамилия',
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 14,
                        color: Color(0xFF4B5563),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 42,
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: TextField(
                        controller: _surnameController,
                        decoration: const InputDecoration(
                          hintText: 'Введите фамилию',
                          hintStyle: TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 16,
                            color: Color(0xFFADAEBC),
                          ),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Телефон
                    const Text(
                      'Телефон',
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 14,
                        color: Color(0xFF4B5563),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 42,
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: TextField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        enabled:
                            true, // Разрешаем редактирование номера телефона
                        decoration: const InputDecoration(
                          hintText: '+7',
                          hintStyle: TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 16,
                            color: Color(0xFFADAEBC),
                          ),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Email
                    const Text(
                      'Email',
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 14,
                        color: Color(0xFF4B5563),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 42,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: _hasEmailError
                              ? const Color(0xFFEF4444)
                              : const Color(0xFFE5E7EB),
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        onChanged: (value) {
                          setState(() {
                            _hasEmailError =
                                value.isNotEmpty && !_validateEmail(value);
                          });
                        },
                        decoration: const InputDecoration(
                          hintText: 'your@email.com',
                          hintStyle: TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 16,
                            color: Color(0xFFADAEBC),
                          ),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    if (_hasEmailError)
                      const Padding(
                        padding: EdgeInsets.only(top: 5.0),
                        child: Text(
                          'Ошибка при вводе email',
                          style: TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 12,
                            color: Color(0xFFEF4444),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Дополнительные данные
            Container(
              width: 358,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Дата рождения
                    const Text(
                      'Дата рождения',
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 14,
                        color: Color(0xFF4B5563),
                      ),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now()
                              .subtract(const Duration(days: 365 * 18)),
                          firstDate: DateTime(1950),
                          lastDate: DateTime.now(),
                        );
                        if (date != null) {
                          setState(() {
                            _selectedDate =
                                '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
                          });
                        }
                      },
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: TextField(
                          controller: _birthDateController,
                          enabled: false,
                          decoration: const InputDecoration(
                            hintText: 'ДД.ММ.ГГГГ',
                            hintStyle: TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 16,
                              color: Color(0xFFADAEBC),
                            ),
                            contentPadding:
                                EdgeInsets.symmetric(horizontal: 12),
                            border: InputBorder.none,
                            suffixIcon: Icon(Icons.calendar_today, size: 20),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Пол
                    const Text(
                      'Пол',
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 14,
                        color: Color(0xFF4B5563),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Radio(
                          value: 'Мужской',
                          groupValue: _gender,
                          onChanged: (value) {
                            setState(() {
                              _gender = value.toString();
                            });
                          },
                        ),
                        const Text(
                          'Мужской',
                          style: TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Radio(
                          value: 'Женский',
                          groupValue: _gender,
                          onChanged: (value) {
                            setState(() {
                              _gender = value.toString();
                            });
                          },
                        ),
                        const Text(
                          'Женский',
                          style: TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Город
                    const Text(
                      'Город',
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 14,
                        color: Color(0xFF4B5563),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 39,
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _city,
                          isExpanded: true,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          items: [
                            'Москва',
                            'Санкт-Петербург',
                            'Казань',
                            'Новосибирск',
                          ].map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(
                                value,
                                style: const TextStyle(
                                  fontFamily: 'Roboto',
                                  fontSize: 16,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (newValue) {
                            setState(() {
                              _city = newValue!;
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Кнопка смены пароля
            OutlinedButton(
              onPressed: () {
                setState(() {
                  _isChangingPassword = !_isChangingPassword;
                });
              },
              child: Text(_isChangingPassword
                  ? 'Отменить смену пароля'
                  : 'Сменить пароль'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.teal,
                side: BorderSide(color: Colors.teal),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            if (_isChangingPassword) ...[
              SizedBox(height: 20),
              // Новый пароль
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Новый пароль',
                  prefixIcon: Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              SizedBox(height: 20),
              // Подтверждение пароля
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirmPassword,
                decoration: InputDecoration(
                  labelText: 'Подтвердите пароль',
                  prefixIcon: Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      });
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ElevatedButton(
                  onPressed: _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5EC7C3),
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Сохранить',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}
