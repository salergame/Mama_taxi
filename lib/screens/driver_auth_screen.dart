import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';

class DriverAuthScreen extends StatefulWidget {
  const DriverAuthScreen({Key? key}) : super(key: key);

  @override
  State<DriverAuthScreen> createState() => _DriverAuthScreenState();
}

class _DriverAuthScreenState extends State<DriverAuthScreen> {
  final TextEditingController _phoneController = TextEditingController();
  File? _carPhotoFront;
  File? _carPhotoBack;
  File? _carPhotoSide;

  // Для веб-версии будем хранить байты файлов
  Uint8List? _passportFileBytes;
  Uint8List? _driverLicenseFileBytes;

  // Для не-веб-версий будем хранить файлы
  File? _passportFile;
  File? _driverLicenseFile;

  // Имена файлов для отображения
  String? _passportFileName;
  String? _driverLicenseFileName;

  bool _isPhotosUploaded = false;
  bool _isPhoneVerified = false;
  bool _isLoading = false;
  bool _isDocumentsUploaded = false;
  bool _isDocumentsVerified = false;
  bool _isPhotosVerified = false;

  // Индикаторы загрузки для документов
  bool _isPassportUploading = false;
  bool _isLicenseUploading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _handleContinue() {
    if (_isPhoneVerified) {
      Navigator.pushNamed(context, '/home');
    } else {
      _verifyPhoneNumber();
    }
  }

  void _verifyPhoneNumber() {
    // Проверяем, что номер телефона введен
    if (_phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введите номер телефона')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Имитация отправки СМС кода
    Future.delayed(const Duration(seconds: 2), () {
      // Показываем диалоговое окно для ввода СМС кода
      _showSmsCodeDialog();
    });
  }

  void _showSmsCodeDialog() {
    final TextEditingController smsController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Введите код из СМС'),
          content: TextField(
            controller: smsController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            decoration: const InputDecoration(
              hintText: 'Код из СМС',
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Отмена'),
              onPressed: () {
                setState(() {
                  _isLoading = false;
                });
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Подтвердить'),
              onPressed: () {
                // Проверяем код (в демо режиме любой код подойдет)
                if (smsController.text.isNotEmpty) {
                  Navigator.of(context).pop();
                  // Отмечаем телефон как подтвержденный
                  setState(() {
                    _isPhoneVerified = true;
                    _isLoading = false;
                  });
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _handleSocialLogin() {
    Navigator.pushNamed(context, '/home');
  }

  Future<void> _takePicture(int photoIndex) async {
    final ImagePicker _picker = ImagePicker();
    try {
      final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
      if (photo != null) {
        setState(() {
          if (photoIndex == 1) {
            _carPhotoFront = File(photo.path);
          } else if (photoIndex == 2) {
            _carPhotoBack = File(photo.path);
          } else if (photoIndex == 3) {
            _carPhotoSide = File(photo.path);
          }

          // Проверяем, сделаны ли все фотографии
          if (_carPhotoFront != null &&
              _carPhotoBack != null &&
              _carPhotoSide != null) {
            _isPhotosUploaded = true;
          } else {
            _isPhotosUploaded = false;
          }
        });

        // Убираем автоматическую отметку о загрузке фотографий
        // Вместо этого будем проверять наличие всех фотографий
        // _uploadPhotosToDatabase();
      }
    } catch (e) {
      print('Ошибка при съемке фото: $e');
    }
  }

  Future<void> _uploadPhotosToDatabase() async {
    // Проверяем, сделаны ли все фотографии
    if (_carPhotoFront == null ||
        _carPhotoBack == null ||
        _carPhotoSide == null) {
      return; // Выходим, если не все фотографии сделаны
    }

    // Здесь будет логика загрузки фотографий в базу данных
    // Например, использование Firebase Storage или другого API

    // Имитация загрузки
    await Future.delayed(const Duration(seconds: 1));

    // После успешной загрузки меняем состояние
    setState(() {
      _isPhotosUploaded = true;

      // Для демонстрации через 3 секунды отмечаем фото как проверенные
      Future.delayed(const Duration(seconds: 3), () {
        setState(() {
          _isPhotosVerified = true;
          // Проверяем, все ли проверки пройдены
          _checkAllVerifications();
        });
      });
    });
  }

  Future<void> _pickPdfFile(String documentType) async {
    try {
      // Начинаем загрузку
      setState(() {
        if (documentType == 'passport') {
          _isPassportUploading = true;
        } else if (documentType == 'license') {
          _isLicenseUploading = true;
        }
      });

      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null) {
        setState(() {
          if (documentType == 'passport') {
            if (kIsWeb) {
              // Для веб используем байты
              _passportFileBytes = result.files.single.bytes;
              _passportFileName = result.files.single.name;
            } else {
              // Для не-веб используем путь файла
              _passportFile = File(result.files.single.path!);
              _passportFileName = result.files.single.name;
            }
          } else if (documentType == 'license') {
            if (kIsWeb) {
              // Для веб используем байты
              _driverLicenseFileBytes = result.files.single.bytes;
              _driverLicenseFileName = result.files.single.name;
            } else {
              // Для не-веб используем путь файла
              _driverLicenseFile = File(result.files.single.path!);
              _driverLicenseFileName = result.files.single.name;
            }
          }

          // Имитация задержки загрузки для демонстрации
          Future.delayed(const Duration(milliseconds: 1500), () {
            setState(() {
              if (documentType == 'passport') {
                _isPassportUploading = false;
              } else if (documentType == 'license') {
                _isLicenseUploading = false;
              }

              // Проверяем, загружены ли все документы
              if ((kIsWeb &&
                      _passportFileBytes != null &&
                      _driverLicenseFileBytes != null) ||
                  (!kIsWeb &&
                      _passportFile != null &&
                      _driverLicenseFile != null)) {
                _isDocumentsUploaded = true;
              } else {
                _isDocumentsUploaded = false;
              }
            });
          });
        });

        // В реальном приложении тут будет загрузка файлов в базу данных
        // Убираем автоматическую отметку о загрузке документов
        // _uploadDocumentsToDatabase();
      } else {
        // Если пользователь отменил выбор, отключаем индикаторы загрузки
        setState(() {
          if (documentType == 'passport') {
            _isPassportUploading = false;
          } else if (documentType == 'license') {
            _isLicenseUploading = false;
          }
        });
      }
    } catch (e) {
      print('Ошибка при выборе файла: $e');
      // В случае ошибки тоже отключаем индикаторы загрузки
      setState(() {
        if (documentType == 'passport') {
          _isPassportUploading = false;
        } else if (documentType == 'license') {
          _isLicenseUploading = false;
        }
      });
    }
  }

  Future<void> _uploadDocumentsToDatabase() async {
    // Эта функция теперь должна вызываться только когда все документы загружены
    // Здесь будет логика загрузки документов в базу данных

    // Проверяем, загружены ли все документы
    bool allDocumentsUploaded = (kIsWeb &&
            _passportFileBytes != null &&
            _driverLicenseFileBytes != null) ||
        (!kIsWeb && _passportFile != null && _driverLicenseFile != null);

    if (!allDocumentsUploaded) {
      return; // Выходим, если не все документы загружены
    }

    // Имитация загрузки
    await Future.delayed(const Duration(seconds: 1));

    // После успешной загрузки меняем состояние
    setState(() {
      _isDocumentsUploaded = true;

      // Для демонстрации через 3 секунды отмечаем документы как проверенные
      Future.delayed(const Duration(seconds: 3), () {
        setState(() {
          _isDocumentsVerified = true;
          // Проверяем, все ли проверки пройдены
          _checkAllVerifications();
        });
      });
    });
  }

  void _showPdfPreview(String documentType) {
    // На вебе будем просто показывать название файла
    if (kIsWeb) {
      String fileName = documentType == 'passport'
          ? _passportFileName ?? 'паспорт.pdf'
          : _driverLicenseFileName ?? 'водительское.pdf';

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Файл PDF: $fileName'),
            content: const Text('Предпросмотр PDF не доступен в веб-версии.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Закрыть'),
              ),
            ],
          );
        },
      );
      return;
    }

    // Для не-веб версий покажем PDF
    File? file =
        documentType == 'passport' ? _passportFile : _driverLicenseFile;

    if (file == null) {
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: Container(
            height: 500,
            width: 300,
            child: Column(
              children: [
                Expanded(
                  child: PDFView(
                    filePath: file.path,
                    enableSwipe: true,
                    swipeHorizontal: true,
                    autoSpacing: false,
                    pageFling: false,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Закрыть'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Регистрация водителя',
          style: TextStyle(
            color: Color(0xFF1F2937),
            fontSize: 20,
            fontWeight: FontWeight.w400,
            fontFamily: 'Rubik',
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),

              // Блок подтверждения аккаунта или ввода номера телефона
              _isPhoneVerified
                  ? _buildPhoneVerifiedBlock()
                  : _buildPhoneInputBlock(),

              const SizedBox(height: 24),

              // Заголовок "Вход через социальные сети"
              const Text(
                'Вход через социальные сети',
                style: TextStyle(
                  fontSize: 18,
                  fontFamily: 'Rubik',
                  color: Colors.black,
                  fontWeight: FontWeight.w400,
                ),
              ),

              const SizedBox(height: 16),

              // Кнопки социальных сетей
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildSocialButton(
                    onPressed: _handleSocialLogin,
                    svgPath: 'assets/icons/google.svg',
                  ),
                  _buildSocialButton(
                    onPressed: _handleSocialLogin,
                    svgPath: 'assets/icons/vk.svg',
                  ),
                  _buildSocialButton(
                    onPressed: _handleSocialLogin,
                    svgPath: 'assets/icons/telegram.svg',
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Заголовок "Фотоконтроль"
              const Text(
                'Фотоконтроль',
                style: TextStyle(
                  fontSize: 18,
                  fontFamily: 'Rubik',
                  color: Colors.black,
                  fontWeight: FontWeight.w400,
                ),
              ),

              const SizedBox(height: 16),

              // Блок для фото автомобиля или блок с галочкой для загруженных фото
              _isPhotosUploaded
                  ? _buildPhotosVerifiedBlock()
                  : Column(
                      children: [
                        GestureDetector(
                          onTap: () => _showPhotoOptionsDialog(),
                          child: Container(
                            height: 110,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: const Color(0xFFE5E7EB),
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.camera_alt_outlined, size: 30),
                                const SizedBox(height: 8),
                                const Text(
                                  'Сделать фотографии',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF4B5563),
                                    fontFamily: 'Rubik',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Кнопка для подтверждения загрузки всех фотографий
                        if (_carPhotoFront != null &&
                            _carPhotoBack != null &&
                            _carPhotoSide != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 12.0),
                            child: SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: ElevatedButton(
                                onPressed: () {
                                  _uploadPhotosToDatabase();
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF10B981),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text(
                                  'Загрузить фотографии',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white,
                                    fontFamily: 'Nunito',
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),

              const SizedBox(height: 16),

              // Информация о фото (показываем только если фотографии ещё не загружены)
              _isPhotosUploaded
                  ? Container()
                  : Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline,
                              size: 12, color: Color(0xFF1D4ED8)),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Нужны фотографии, где видно номер и состояние машины',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF1D4ED8),
                                fontFamily: 'Rubik',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

              // Статус проверки (показываем только если фотографии загружены)
              _isPhotosUploaded
                  ? Padding(
                      padding: const EdgeInsets.only(top: 16.0),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _isPhotosVerified
                              ? const Color(
                                  0xFFECFDF5) // Зеленый фон для проверенных
                              : const Color(
                                  0xFFFFFBEB), // Желтый фон для ожидающих
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _isPhotosVerified
                                  ? Icons
                                      .check_circle // Иконка галочки для проверенных
                                  : Icons
                                      .access_time, // Иконка часов для ожидающих
                              size: 16,
                              color: _isPhotosVerified
                                  ? const Color(
                                      0xFF10B981) // Зеленый цвет для проверенных
                                  : const Color(
                                      0xFFB45309), // Коричневый цвет для ожидающих
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _isPhotosVerified
                                  ? 'Проверено' // Текст для проверенных
                                  : 'Ожидает проверки', // Текст для ожидающих
                              style: TextStyle(
                                fontSize: 16,
                                color: _isPhotosVerified
                                    ? const Color(
                                        0xFF10B981) // Зеленый цвет для проверенных
                                    : const Color(
                                        0xFFB45309), // Коричневый цвет для ожидающих
                                fontFamily: 'Rubik',
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),

              const SizedBox(height: 24),

              // Заголовок "Загрузка документов"
              const Text(
                'Загрузка документов',
                style: TextStyle(
                  fontSize: 18,
                  fontFamily: 'Rubik',
                  color: Colors.black,
                  fontWeight: FontWeight.w400,
                ),
              ),

              const SizedBox(height: 16),

              // Блок документов или блок с галочкой для загруженных документов
              _isDocumentsUploaded
                  ? _buildDocumentsVerifiedBlock()
                  : Column(
                      children: [
                        // Кнопка загрузки паспорта
                        _buildDocumentButton(
                          title: 'Паспорт',
                          svgPath: 'assets/icons/passport.svg',
                          isUploaded: kIsWeb
                              ? _passportFileBytes != null
                              : _passportFile != null,
                          isUploading: _isPassportUploading,
                          fileName: _passportFileName,
                          onPressed: () => _pickPdfFile('passport'),
                          onView: (kIsWeb
                                  ? _passportFileBytes != null
                                  : _passportFile != null)
                              ? () => _showPdfPreview('passport')
                              : null,
                        ),

                        const SizedBox(height: 12),

                        // Кнопка загрузки водительского удостоверения
                        _buildDocumentButton(
                          title: 'Водительское удостоверение',
                          svgPath: 'assets/icons/car_id.svg',
                          isUploaded: kIsWeb
                              ? _driverLicenseFileBytes != null
                              : _driverLicenseFile != null,
                          isUploading: _isLicenseUploading,
                          fileName: _driverLicenseFileName,
                          onPressed: () => _pickPdfFile('license'),
                          onView: (kIsWeb
                                  ? _driverLicenseFileBytes != null
                                  : _driverLicenseFile != null)
                              ? () => _showPdfPreview('license')
                              : null,
                        ),

                        const SizedBox(height: 12),

                        // Кнопка для подтверждения загрузки всех документов
                        if ((kIsWeb &&
                                _passportFileBytes != null &&
                                _driverLicenseFileBytes != null) ||
                            (!kIsWeb &&
                                _passportFile != null &&
                                _driverLicenseFile != null))
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              onPressed: () {
                                _uploadDocumentsToDatabase();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF10B981),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text(
                                'Загрузить документы',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                  fontFamily: 'Nunito',
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),

              // Статус проверки документов (показываем только если документы загружены)
              _isDocumentsUploaded
                  ? Padding(
                      padding: const EdgeInsets.only(top: 16.0),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _isDocumentsVerified
                              ? const Color(
                                  0xFFECFDF5) // Зеленый фон для проверенных
                              : const Color(
                                  0xFFFFFBEB), // Желтый фон для ожидающих
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _isDocumentsVerified
                                  ? Icons
                                      .check_circle // Иконка галочки для проверенных
                                  : Icons
                                      .access_time, // Иконка часов для ожидающих
                              size: 16,
                              color: _isDocumentsVerified
                                  ? const Color(
                                      0xFF10B981) // Зеленый цвет для проверенных
                                  : const Color(
                                      0xFFB45309), // Коричневый цвет для ожидающих
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _isDocumentsVerified
                                  ? 'Проверено' // Текст для проверенных
                                  : 'Ожидает проверки', // Текст для ожидающих
                              style: TextStyle(
                                fontSize: 16,
                                color: _isDocumentsVerified
                                    ? const Color(
                                        0xFF10B981) // Зеленый цвет для проверенных
                                    : const Color(
                                        0xFFB45309), // Коричневый цвет для ожидающих
                                fontFamily: 'Rubik',
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),

              const SizedBox(height: 24),

              // Убираем кнопку "Продолжить" отсюда и перемещаем её выше в блок Visibility
              Visibility(
                visible: _isDocumentsVerified &&
                    _isPhotosVerified &&
                    _isPhoneVerified,
                child: Column(
                  children: [
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleContinue,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF654AA),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              )
                            : const Text(
                                'Продолжить',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                  fontFamily: 'Rubik',
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // Блок с галочкой для подтвержденного номера
  Widget _buildPhoneVerifiedBlock() {
    return Container(
      height: 192,
      width: double.infinity,
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Аккаунт подтвержден',
            style: TextStyle(
              fontSize: 24,
              color: Color(0xFF1F2937),
              fontFamily: 'Nunito',
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: 70,
            height: 70,
            decoration: const BoxDecoration(
              color: Color(0xFF53CFC4),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check,
              size: 50,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // Блок ввода номера телефона
  Widget _buildPhoneInputBlock() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Заголовок "Вход по номеру телефона"
        const Text(
          'Вход по номеру телефона',
          style: TextStyle(
            fontSize: 18,
            fontFamily: 'Rubik',
            color: Colors.black,
            fontWeight: FontWeight.w400,
          ),
        ),

        const SizedBox(height: 16),

        // Поле ввода телефона
        Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 13),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            border: Border.all(
              color: const Color(0xFFE5E7EB),
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const Text(
                '+7',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF6B7280),
                  fontFamily: 'Nunito',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: '(999) 123-45-67',
                    hintStyle: TextStyle(
                      color: Color(0xFFADAEBC),
                      fontFamily: 'Nunito',
                    ),
                  ),
                  keyboardType: TextInputType.phone,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Кнопка "Получить код"
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _verifyPhoneNumber,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF654AA),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
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
                : const Text(
                    'Получить код',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.w400,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildSocialButton({
    required VoidCallback onPressed,
    required String svgPath,
  }) {
    return Container(
      width: 100,
      height: 46,
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: SvgPicture.asset(
          svgPath,
          width: 24,
          height: 24,
        ),
      ),
    );
  }

  Widget _buildDocumentButton({
    required String title,
    required String svgPath,
    required VoidCallback onPressed,
    required bool isUploaded,
    required bool isUploading,
    String? fileName,
    VoidCallback? onView,
  }) {
    return InkWell(
      onTap: isUploading ? null : onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(
            color:
                isUploaded ? const Color(0xFF10B981) : const Color(0xFFE5E7EB),
          ),
          borderRadius: BorderRadius.circular(8),
          color: isUploaded ? const Color(0xFFECFDF5) : Colors.white,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SvgPicture.asset(
                  svgPath,
                  width: 18,
                  height: 18,
                  colorFilter: isUploaded
                      ? const ColorFilter.mode(
                          Color(0xFF10B981), BlendMode.srcIn)
                      : null,
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    color: isUploaded ? const Color(0xFF10B981) : Colors.black,
                    fontFamily: 'Rubik',
                    fontWeight: isUploaded ? FontWeight.w500 : FontWeight.w400,
                  ),
                ),
                const Spacer(),
                if (isUploading)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                    ),
                  )
                else if (isUploaded)
                  Row(
                    children: [
                      if (onView != null)
                        IconButton(
                          icon: const Icon(Icons.visibility,
                              size: 18, color: Color(0xFF10B981)),
                          onPressed: onView,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          visualDensity: VisualDensity.compact,
                        ),
                      const SizedBox(width: 8),
                      const Icon(Icons.check_circle,
                          size: 18, color: Color(0xFF10B981)),
                    ],
                  )
                else
                  const Icon(Icons.add, size: 14),
              ],
            ),

            // Показываем название файла, если он загружен
            if (isUploaded && fileName != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0, left: 30),
                child: Text(
                  fileName,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                    fontFamily: 'Rubik',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showPhotoOptionsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Фотографии автомобиля'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                const Text(
                    'Пожалуйста, выберите какое фото вы хотите сделать:'),
                const SizedBox(height: 16),
                _buildPhotoOption('Фото спереди', _carPhotoFront != null, () {
                  Navigator.pop(context);
                  _takePicture(1);
                }),
                _buildPhotoOption('Фото сзади', _carPhotoBack != null, () {
                  Navigator.pop(context);
                  _takePicture(2);
                }),
                _buildPhotoOption('Фото сбоку', _carPhotoSide != null, () {
                  Navigator.pop(context);
                  _takePicture(3);
                }),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Закрыть'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildPhotoOption(String title, bool isCompleted, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFE5E7EB)),
          borderRadius: BorderRadius.circular(8),
          color: isCompleted ? const Color(0xFFEFFBF5) : Colors.white,
        ),
        child: Row(
          children: [
            Icon(
              isCompleted ? Icons.check_circle : Icons.camera_alt,
              color: isCompleted ? Colors.green : Colors.grey,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                color: isCompleted ? Colors.green : Colors.black,
                fontWeight: isCompleted ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Блок с галочкой для загруженных фотографий
  Widget _buildPhotosVerifiedBlock() {
    return Container(
      height: 192,
      width: double.infinity,
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Фотографии загружены',
            style: TextStyle(
              fontSize: 24,
              color: Color(0xFF1F2937),
              fontFamily: 'Nunito',
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: 70,
            height: 70,
            decoration: const BoxDecoration(
              color: Color(0xFF53CFC4),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check,
              size: 50,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // Блок с галочкой для загруженных документов
  Widget _buildDocumentsVerifiedBlock() {
    return Container(
      height: 192,
      width: double.infinity,
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Документы загружены',
            style: TextStyle(
              fontSize: 24,
              color: Color(0xFF1F2937),
              fontFamily: 'Nunito',
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: 70,
            height: 70,
            decoration: const BoxDecoration(
              color: Color(0xFF53CFC4),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check,
              size: 50,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // Добавляем функцию для проверки всех верификаций
  void _checkAllVerifications() {
    if (_isDocumentsVerified && _isPhotosVerified && _isPhoneVerified) {
      // Все проверки пройдены, можно показать кнопку "Продолжить"
      // Этот метод вызывается каждый раз, когда меняется статус любой проверки
    }
  }
}
