import 'package:flutter/material.dart';
import 'package:mama_taxi/providers/user_provider.dart';
import 'package:provider/provider.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({Key? key}) : super(key: key);

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _surnameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  String _gender = 'Мужской';
  String _city = 'Москва';

  @override
  void initState() {
    super.initState();
    _nameController.text = 'test';
    _surnameController.text = 'test';
    _phoneController.text = '+7 (999) 123-45-67';
    _emailController.text = 'test@example.com';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _surnameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text(
          'Личный кабинет',
          style: TextStyle(
            color: Colors.black,
            fontFamily: 'Rubik',
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Профиль
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(top: 12),
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEDE9FE),
                          borderRadius: BorderRadius.circular(99),
                          border: Border.all(color: Colors.white, width: 4),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              spreadRadius: 0,
                              blurRadius: 4,
                              offset: const Offset(0, 4),
                            ),
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              spreadRadius: 0,
                              blurRadius: 10,
                              offset: const Offset(0, 10),
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
                      GestureDetector(
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'Функция изменения фото будет доступна в следующем обновлении'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.edit,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '${_nameController.text} ${_surnameController.text}',
                    style: const TextStyle(
                      fontFamily: 'Rubik',
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _phoneController.text,
                    style: const TextStyle(
                      fontFamily: 'Rubik',
                      fontSize: 16,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Личные данные
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Личные данные',
                    style: TextStyle(
                      fontFamily: 'Rubik',
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildTextField('Имя', _nameController),
                  const SizedBox(height: 12),
                  _buildTextField('Фамилия', _surnameController),
                  const SizedBox(height: 12),
                  _buildTextField('Телефон', _phoneController, enabled: false),
                  const SizedBox(height: 12),
                  _buildTextField('Email', _emailController),
                  const SizedBox(height: 12),
                  _buildDropdownField('Пол', _gender, ['Мужской', 'Женский'],
                      (value) {
                    setState(() {
                      _gender = value!;
                    });
                  }),
                  const SizedBox(height: 12),
                  _buildDropdownField('Город', _city, [
                    'Москва',
                    'Санкт-Петербург',
                    'Казань',
                    'Новосибирск'
                  ], (value) {
                    setState(() {
                      _city = value!;
                    });
                  }),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Настройки аккаунта
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Настройки аккаунта',
                    style: TextStyle(
                      fontFamily: 'Rubik',
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildSettingsItem(
                    'Уведомления',
                    'Настройка уведомлений',
                    Icons.notifications_none,
                    () => Navigator.pushNamed(context, '/notifications'),
                  ),
                  const Divider(),
                  _buildSettingsItem(
                    'Безопасность',
                    'Смена пароля, верификация',
                    Icons.security,
                    () => Navigator.pushNamed(context, '/verification'),
                  ),
                  const Divider(),
                  _buildSettingsItem(
                    'Способы оплаты',
                    'Управление картами',
                    Icons.payment,
                    () => Navigator.pushNamed(context, '/settings'),
                  ),
                  const Divider(),
                  _buildSettingsItem(
                    'Документы',
                    'Загрузка документов',
                    Icons.insert_drive_file,
                    () => Navigator.pushNamed(context, '/driver_documents'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Кнопка сохранения
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Профиль обновлен'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
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

            const SizedBox(height: 16),

            // Кнопка выхода
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              width: double.infinity,
              child: TextButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Выход из аккаунта'),
                      content: const Text('Вы уверены, что хотите выйти?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Отмена'),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.pushReplacementNamed(context, '/auth');
                          },
                          child: const Text('Выйти',
                              style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  );
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    side: const BorderSide(color: Colors.red),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Выйти из аккаунта',
                  style: TextStyle(
                    fontFamily: 'Rubik',
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.red,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {bool enabled = true}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Rubik',
            fontSize: 14,
            color: Color(0xFF6B7280),
          ),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          enabled: enabled,
          decoration: InputDecoration(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide:
                  BorderSide(color: Theme.of(context).colorScheme.primary),
            ),
            filled: !enabled,
            fillColor: enabled ? Colors.transparent : const Color(0xFFF9FAFB),
          ),
          style: const TextStyle(
            fontFamily: 'Rubik',
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField(String label, String value, List<String> items,
      Function(String?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Rubik',
            fontSize: 14,
            color: Color(0xFF6B7280),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE5E7EB)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButton<String>(
            value: value,
            isExpanded: true,
            underline: Container(),
            icon: const Icon(Icons.arrow_drop_down),
            items: items.map((String item) {
              return DropdownMenuItem<String>(
                value: item,
                child: Text(item),
              );
            }).toList(),
            onChanged: onChanged,
            style: const TextStyle(
              fontFamily: 'Rubik',
              fontSize: 16,
              color: Colors.black,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsItem(
      String title, String subtitle, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: const Color(0xFF6B7280),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Rubik',
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontFamily: 'Rubik',
                      fontSize: 14,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Color(0xFF6B7280),
            ),
          ],
        ),
      ),
    );
  }
}
