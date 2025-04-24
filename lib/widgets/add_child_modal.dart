import 'package:flutter/material.dart';
import 'package:mama_taxi/services/firebase_service.dart';
import 'package:mama_taxi/models/child_model.dart';
import 'package:mama_taxi/providers/user_provider.dart';
import 'package:provider/provider.dart';

class AddChildModal extends StatefulWidget {
  final Function(Map<String, dynamic>)? onAdd;
  final Map<String, dynamic>? initialData; // Данные для редактирования

  const AddChildModal({Key? key, this.onAdd, this.initialData})
      : super(key: key);

  @override
  _AddChildModalState createState() => _AddChildModalState();
}

class _AddChildModalState extends State<AddChildModal> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  String _selectedAge = "6 лет";
  bool _isLoading = false;

  final List<String> _ages = [
    "1 год",
    "2 года",
    "3 года",
    "4 года",
    "5 лет",
    "6 лет",
    "7 лет",
    "8 лет",
    "9 лет",
    "10 лет",
    "11 лет",
    "12 лет",
    "13 лет",
    "14 лет",
    "15 лет",
    "16 лет",
    "17 лет"
  ];

  @override
  void initState() {
    super.initState();
    // Если переданы данные для редактирования, заполняем форму
    if (widget.initialData != null) {
      _nameController.text = widget.initialData!['name'] ?? '';
      _notesController.text = widget.initialData!['notes'] ?? '';
      _selectedAge = widget.initialData!['age'] ?? '6 лет';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // Обработка сохранения данных
  Future<void> _handleAdd() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Пожалуйста, укажите ФИО ребенка'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Формируем данные ребенка
    final childData = {
      'name': _nameController.text.trim(),
      'age': _selectedAge,
      'notes': _notesController.text.trim(),
    };

    setState(() {
      _isLoading = true;
    });

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final userId = await FirebaseService().getCurrentUserId() ?? 'unknown';
      childData['userId'] = userId;

      bool success = false;

      // Если редактируем существующего ребенка
      if (widget.initialData != null && widget.initialData!['id'] != null) {
        final child = ChildModel(
          id: widget.initialData!['id'],
          userId: userId,
          name: childData['name'] as String,
          age: childData['age'] as String,
          notes: childData['notes'] as String,
        );

        success = await userProvider.updateChild(child);
        if (success) {
          childData['id'] = widget.initialData!['id'];
        }
      } else {
        // Создаем модель для нового ребенка
        final child = ChildModel(
          userId: userId,
          name: childData['name'] as String,
          age: childData['age'] as String,
          notes: childData['notes'] as String,
        );

        success = await userProvider.addChild(child);
      }

      // Если операция выполнена успешно
      if (success) {
        // Вызываем обработчик, если он задан
        if (widget.onAdd != null) {
          widget.onAdd!(childData);
        }

        // Закрываем модальное окно
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Не удалось сохранить данные ребенка'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка: $e'),
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
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 80),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        width: 358,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Заголовок
            Container(
              height: 76,
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Color(0xFFFCFBFF),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Добавление ребенка',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 20,
                      fontWeight: FontWeight.w400,
                      color: Colors.black,
                    ),
                  ),
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Аватар
            Container(
              height: 112,
              child: Center(
                child: Stack(
                  children: [
                    Container(
                      width: 112,
                      height: 112,
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
                      child: Center(
                        child: Icon(
                          Icons.person,
                          size: 60,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 4,
                      right: 4,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: const Color(0xFF5EC7C3),
                          borderRadius: BorderRadius.circular(16),
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
                        child: const Icon(
                          Icons.add_a_photo,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Форма
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // ФИО поле
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ФИО',
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 14,
                          color: Color(0xFF374151),
                        ),
                      ),
                      const SizedBox(height: 9),
                      Container(
                        height: 42,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFFE5E7EB),
                          ),
                        ),
                        child: Row(
                          children: [
                            const SizedBox(width: 12),
                            const Icon(Icons.person_outline, size: 14),
                            const SizedBox(width: 14),
                            Expanded(
                              child: TextField(
                                controller: _nameController,
                                decoration: const InputDecoration(
                                  hintText: 'Введите ФИО ребенка',
                                  hintStyle: TextStyle(
                                    fontFamily: 'Nunito',
                                    fontSize: 16,
                                    color: Color(0xFFADAEBC),
                                  ),
                                  border: InputBorder.none,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Возраст поле
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Возраст',
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 14,
                          color: Color(0xFF374151),
                        ),
                      ),
                      const SizedBox(height: 9),
                      Container(
                        height: 42,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFFE5E7EB),
                          ),
                        ),
                        child: Row(
                          children: [
                            const SizedBox(width: 12),
                            const Icon(Icons.cake_outlined, size: 14),
                            const SizedBox(width: 4),
                            Expanded(
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _selectedAge,
                                  icon: const Padding(
                                    padding: EdgeInsets.only(right: 8.0),
                                    child: Icon(Icons.arrow_drop_down),
                                  ),
                                  style: const TextStyle(
                                    fontFamily: 'Nunito',
                                    fontSize: 16,
                                    color: Colors.black,
                                  ),
                                  onChanged: (String? newValue) {
                                    setState(() {
                                      _selectedAge = newValue!;
                                    });
                                  },
                                  items: _ages.map<DropdownMenuItem<String>>(
                                      (String value) {
                                    return DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(value),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Особые пожелания
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Особые пожелания',
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 14,
                          color: Color(0xFF374151),
                        ),
                      ),
                      const SizedBox(height: 9),
                      Container(
                        height: 90,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFFE5E7EB),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(left: 12.0, top: 12.0),
                              child: Icon(Icons.note_alt_outlined, size: 14),
                            ),
                            Expanded(
                              child: TextField(
                                controller: _notesController,
                                maxLines: 3,
                                decoration: const InputDecoration(
                                  hintText:
                                      'Укажите особые пожелания (необязательно)',
                                  hintStyle: TextStyle(
                                    fontFamily: 'Nunito',
                                    fontSize: 16,
                                    color: Color(0xFFADAEBC),
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.only(
                                      left: 14, top: 12, right: 12, bottom: 12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Кнопки
                  Column(
                    children: [
                      // Кнопка сохранения
                      Container(
                        width: double.infinity,
                        child: TextButton(
                          onPressed: _isLoading ? null : _handleAdd,
                          style: TextButton.styleFrom(
                            backgroundColor: const Color(0xFF6D4EFC),
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: const Color(0xFFB4B4B4),
                            disabledForegroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                )
                              : const Text(
                                  'Сохранить',
                                  style: TextStyle(
                                    fontFamily: 'Nunito',
                                    fontSize: 16,
                                    fontWeight: FontWeight.w400,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF5EC7C3),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Отмена',
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 16,
                              color: Color(0xFF374151),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
