import 'package:flutter/material.dart';
import 'package:mama_taxi/services/firebase_service.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class ProfileSettingsScreen extends StatefulWidget {
  const ProfileSettingsScreen({Key? key}) : super(key: key);

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final _formKey = GlobalKey<FormState>();

  // Контроллеры для полей ввода
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  // Данные пользователя
  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  File? _imageFile;
  String? _currentPhotoUrl;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userData = await _firebaseService.getUserData();

      setState(() {
        _userData = userData;
        _nameController.text = userData?['name'] ?? '';
        _phoneController.text = userData?['phone'] ?? '';
        _emailController.text = userData?['email'] ?? '';
        _currentPhotoUrl = userData?['photoUrl'];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorDialog('Ошибка при загрузке данных: $e');
    }
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? pickedFile =
          await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      _showErrorDialog('Не удалось загрузить изображение: $e');
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Обновляем данные пользователя
      final userData = {
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'email': _emailController.text.trim(),
      };

      // Обновляем фото профиля, если выбрано новое
      if (_currentPhotoUrl != null) {
        userData['photoUrl'] = _currentPhotoUrl!;
      }

      // Временно отключена загрузка изображений
      // if (_imageFile != null) {
      //   final uploadedPhotoUrl = await _firebaseService.uploadUserProfileImage(_imageFile!);
      //   userData['photoUrl'] = uploadedPhotoUrl;
      // }

      // Сохраняем изменения в Firebase
      await _firebaseService.updateUserData(userData);

      setState(() {
        _isLoading = false;
      });

      // Показываем сообщение об успешном сохранении
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Профиль успешно обновлен')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorDialog('Ошибка при сохранении данных: $e');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ошибка'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ОК'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Настройки профиля',
          style: TextStyle(
            color: Colors.black,
            fontFamily: 'Rubik',
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Фото профиля
                    Center(
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: _pickImage,
                            child: Stack(
                              children: [
                                Container(
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    image: DecorationImage(
                                      image: _imageFile != null
                                          ? FileImage(_imageFile!)
                                              as ImageProvider
                                          : (_currentPhotoUrl != null &&
                                                  _currentPhotoUrl!.isNotEmpty
                                              ? NetworkImage(_currentPhotoUrl!)
                                                  as ImageProvider
                                              : const AssetImage(
                                                      'assets/images/default_avatar.png')
                                                  as ImageProvider),
                                      fit: BoxFit.cover,
                                    ),
                                    border: Border.all(
                                      color: const Color(0xFF53CFC4),
                                      width: 2,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF53CFC4),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.camera_alt,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Нажмите для изменения фото',
                            style: TextStyle(
                              fontFamily: 'Rubik',
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Поля формы
                    const Text(
                      'Личные данные',
                      style: TextStyle(
                        fontFamily: 'Rubik',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Поле имени
                    _buildTextField(
                      controller: _nameController,
                      label: 'Имя',
                      icon: Icons.person,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Пожалуйста, введите ваше имя';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Поле телефона
                    _buildTextField(
                      controller: _phoneController,
                      label: 'Телефон',
                      icon: Icons.phone,
                      keyboardType: TextInputType.phone,
                      readOnly:
                          true, // телефон обычно не меняют, т.к. это идентификатор аккаунта
                    ),
                    const SizedBox(height: 16),

                    // Поле email
                    _buildTextField(
                      controller: _emailController,
                      label: 'Email',
                      icon: Icons.email,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          // Простая валидация email
                          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                              .hasMatch(value)) {
                            return 'Пожалуйста, введите корректный email';
                          }
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Дополнительные настройки
                    const Text(
                      'Настройки приложения',
                      style: TextStyle(
                        fontFamily: 'Rubik',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Настройки уведомлений
                    _buildSettingsTile(
                      title: 'Уведомления',
                      icon: Icons.notifications,
                      onTap: () {
                        // Навигация на экран настроек уведомлений
                      },
                    ),

                    // Настройки адресов
                    _buildSettingsTile(
                      title: 'Адреса и избранное',
                      icon: Icons.location_on,
                      onTap: () {
                        // Навигация на экран управления адресами
                      },
                    ),

                    // Настройки безопасности
                    _buildSettingsTile(
                      title: 'Безопасность',
                      icon: Icons.security,
                      onTap: () {
                        // Навигация на экран настроек безопасности
                      },
                    ),

                    const SizedBox(height: 32),

                    // Кнопка сохранения
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _saveChanges,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF53CFC4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Сохранить изменения',
                          style: TextStyle(
                            fontFamily: 'Rubik',
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    bool readOnly = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      readOnly: readOnly,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF53CFC4)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF53CFC4), width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      ),
    );
  }

  Widget _buildSettingsTile({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF53CFC4).withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: const Color(0xFF53CFC4),
          size: 24,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontFamily: 'Rubik',
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
    );
  }
}
