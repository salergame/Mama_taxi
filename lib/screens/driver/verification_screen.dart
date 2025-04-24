import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:mama_taxi/services/firebase_service.dart';
import 'package:mama_taxi/services/auth_service.dart';

class VerificationScreen extends StatefulWidget {
  const VerificationScreen({Key? key}) : super(key: key);

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  // Файлы документов
  File? _licenseFile;
  File? _passportFile;
  File? _photoFile;
  File? _carPhotoFile;

  // Статус проверки документов
  String _licenseStatus = 'Не загружено';
  String _passportStatus = 'Не загружено';
  String _photoStatus = 'Не загружено';
  String _carPhotoStatus = 'Не загружено';

  // Информация о водителе
  final TextEditingController _carModelController = TextEditingController();
  final TextEditingController _carNumberController = TextEditingController();
  final TextEditingController _carYearController = TextEditingController();
  final TextEditingController _carColorController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _loadDriverData();
  }

  @override
  void dispose() {
    _carModelController.dispose();
    _carNumberController.dispose();
    _carYearController.dispose();
    _carColorController.dispose();
    super.dispose();
  }

  // Загрузка данных водителя
  Future<void> _loadDriverData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final driverData = await _firebaseService.getDriverData();
      if (driverData != null) {
        setState(() {
          _carModelController.text = driverData['carModel'] ?? '';
          _carNumberController.text = driverData['carNumber'] ?? '';
          _carYearController.text = driverData['carYear']?.toString() ?? '';
          _carColorController.text = driverData['carColor'] ?? '';

          _licenseStatus = driverData['licenseVerified'] ?? 'Не загружено';
          _passportStatus = driverData['passportVerified'] ?? 'Не загружено';
          _photoStatus = driverData['photoVerified'] ?? 'Не загружено';
          _carPhotoStatus = driverData['carPhotoVerified'] ?? 'Не загружено';
        });
      }
    } catch (e) {
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

  // Выбор изображения
  Future<void> _pickImage(String documentType) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        setState(() {
          switch (documentType) {
            case 'license':
              _licenseFile = File(pickedFile.path);
              _licenseStatus = 'На проверке';
              break;
            case 'passport':
              _passportFile = File(pickedFile.path);
              _passportStatus = 'На проверке';
              break;
            case 'photo':
              _photoFile = File(pickedFile.path);
              _photoStatus = 'На проверке';
              break;
            case 'car_photo':
              _carPhotoFile = File(pickedFile.path);
              _carPhotoStatus = 'На проверке';
              break;
          }
        });

        // Здесь будет загрузка файла в Firebase Storage
        // await _firebaseService.uploadDriverDocument(File(pickedFile.path), documentType);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка загрузки изображения: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Сохранение данных автомобиля
  Future<void> _saveCarData() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      setState(() {
        _isLoading = true;
      });

      final carData = {
        'carModel': _carModelController.text,
        'carNumber': _carNumberController.text,
        'carYear': int.tryParse(_carYearController.text) ?? 0,
        'carColor': _carColorController.text,
      };

      await _firebaseService.updateDriverCarData(carData);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Данные автомобиля сохранены'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка сохранения данных: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Строитель для карточки документа
  Widget _buildDocumentCard({
    required String title,
    required String status,
    required VoidCallback onUpload,
    File? file,
    IconData icon = Icons.file_copy,
  }) {
    Color statusColor;

    switch (status) {
      case 'Проверено':
        statusColor = Colors.green;
        break;
      case 'На проверке':
        statusColor = Colors.orange;
        break;
      case 'Отклонено':
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.grey;
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(icon, color: const Color(0xFF53CFC4)),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            file != null
                ? Container(
                    height: 150,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      image: DecorationImage(
                        image: FileImage(file),
                        fit: BoxFit.cover,
                      ),
                    ),
                  )
                : Container(
                    height: 100,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.image,
                      size: 50,
                      color: Colors.grey,
                    ),
                  ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onUpload,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF53CFC4),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text(file == null ? 'Загрузить' : 'Изменить'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Получаем размеры экрана для адаптивности
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 360;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Проверка документов'),
        backgroundColor: const Color(0xFF53CFC4),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () {
              // Открыть справку
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Помощь'),
                  content: const Text(
                    'Для регистрации в качестве водителя необходимо загрузить следующие документы:\n'
                    '- Водительское удостоверение\n'
                    '- Паспорт (разворот с фото)\n'
                    '- Ваше фото\n'
                    '- Фото автомобиля\n\n'
                    'Также необходимо заполнить информацию об автомобиле. '
                    'После проверки документов вы сможете начать принимать заказы.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Понятно'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF53CFC4)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Заголовок
                  Text(
                    'Загрузите документы для проверки',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 18 : 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Все документы должны быть четкими и разборчивыми. Проверка займет от 1 до 3 рабочих дней.',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: isSmallScreen ? 12 : 14,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Блок с документами
                  _buildDocumentCard(
                    title: 'Водительское удостоверение',
                    status: _licenseStatus,
                    onUpload: () => _pickImage('license'),
                    file: _licenseFile,
                    icon: Icons.card_membership,
                  ),

                  _buildDocumentCard(
                    title: 'Паспорт (разворот с фото)',
                    status: _passportStatus,
                    onUpload: () => _pickImage('passport'),
                    file: _passportFile,
                    icon: Icons.perm_identity,
                  ),

                  _buildDocumentCard(
                    title: 'Ваше фото',
                    status: _photoStatus,
                    onUpload: () => _pickImage('photo'),
                    file: _photoFile,
                    icon: Icons.face,
                  ),

                  _buildDocumentCard(
                    title: 'Фото автомобиля',
                    status: _carPhotoStatus,
                    onUpload: () => _pickImage('car_photo'),
                    file: _carPhotoFile,
                    icon: Icons.directions_car,
                  ),

                  const SizedBox(height: 30),

                  // Информация об автомобиле
                  Text(
                    'Информация об автомобиле',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 18 : 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // Модель автомобиля
                        TextFormField(
                          controller: _carModelController,
                          decoration: const InputDecoration(
                            labelText: 'Марка и модель',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.directions_car,
                                color: Color(0xFF53CFC4)),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Пожалуйста, укажите модель автомобиля';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),

                        // Номер автомобиля
                        TextFormField(
                          controller: _carNumberController,
                          decoration: const InputDecoration(
                            labelText: 'Государственный номер',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.credit_card,
                                color: Color(0xFF53CFC4)),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Пожалуйста, укажите номер автомобиля';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),

                        // Год выпуска
                        TextFormField(
                          controller: _carYearController,
                          decoration: const InputDecoration(
                            labelText: 'Год выпуска',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.calendar_today,
                                color: Color(0xFF53CFC4)),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Пожалуйста, укажите год выпуска автомобиля';
                            }
                            final year = int.tryParse(value);
                            if (year == null ||
                                year < 1950 ||
                                year > DateTime.now().year) {
                              return 'Некорректный год выпуска';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),

                        // Цвет автомобиля
                        TextFormField(
                          controller: _carColorController,
                          decoration: const InputDecoration(
                            labelText: 'Цвет автомобиля',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.color_lens,
                                color: Color(0xFF53CFC4)),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Пожалуйста, укажите цвет автомобиля';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),

                        // Кнопка сохранения
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _saveCarData,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF53CFC4),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text(
                              'Сохранить данные автомобиля',
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Статус проверки и возможность перехода в режим водителя
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Статус проверки',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Ожидается загрузка всех документов',
                            style: TextStyle(
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isAllDocumentsUploaded()
                                  ? () {
                                      // Переход на главный экран водителя
                                      Navigator.pushReplacementNamed(
                                          context, '/driver_home');
                                    }
                                  : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF53CFC4),
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                disabledBackgroundColor: Colors.grey,
                              ),
                              child: const Text(
                                'Перейти в режим водителя',
                                style: TextStyle(fontSize: 16),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // Проверка, все ли документы загружены
  bool _isAllDocumentsUploaded() {
    return _licenseStatus != 'Не загружено' &&
        _passportStatus != 'Не загружено' &&
        _photoStatus != 'Не загружено' &&
        _carPhotoStatus != 'Не загружено' &&
        _carModelController.text.isNotEmpty &&
        _carNumberController.text.isNotEmpty &&
        _carYearController.text.isNotEmpty &&
        _carColorController.text.isNotEmpty;
  }
}
