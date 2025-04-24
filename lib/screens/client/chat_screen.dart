import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mama_taxi/models/chat_message.dart';
import 'package:mama_taxi/widgets/chat_message_bubble.dart';

class ChatScreen extends StatefulWidget {
  final String driverId;
  final String driverName;
  final String? driverPhoto;

  const ChatScreen({
    Key? key,
    required this.driverId,
    required this.driverName,
    this.driverPhoto,
  }) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final _scrollController = ScrollController();
  bool _isAttaching = false;
  File? _selectedImage;

  // Пример списка сообщений, в реальном приложении это будет загружаться из базы данных
  final List<ChatMessage> _messages = [
    ChatMessage(
      text: 'Здравствуйте! Я буду вашим водителем сегодня.',
      timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
      isUser: false,
    ),
    ChatMessage(
      text: 'Привет! Через сколько вы приедете?',
      timestamp: DateTime.now().subtract(const Duration(minutes: 28)),
      isUser: true,
      isRead: true,
    ),
    ChatMessage(
      text: 'Буду через 10 минут, сейчас в пути.',
      timestamp: DateTime.now().subtract(const Duration(minutes: 25)),
      isUser: false,
    ),
    ChatMessage(
      text: 'Хорошо, буду ждать.',
      timestamp: DateTime.now().subtract(const Duration(minutes: 24)),
      isUser: true,
      isRead: true,
    ),
  ];

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 70,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _isAttaching = true;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка при выборе изображения: $e')),
      );
    }
  }

  void _removeSelectedImage() {
    setState(() {
      _selectedImage = null;
      _isAttaching = false;
    });
  }

  void _sendMessage() {
    final text = _messageController.text.trim();

    if ((text.isEmpty && _selectedImage == null) || _isAttaching) return;

    final now = DateTime.now();

    if (_selectedImage != null) {
      // В реальном приложении, нужно загружать изображение и получать URL
      // Для демонстрации просто добавляем вымышленный URL
      _messages.add(
        ChatMessage(
          text: text,
          timestamp: now,
          isUser: true,
          attachmentUrl: 'https://example.com/image.jpg',
          attachmentType: 'image',
        ),
      );
      _removeSelectedImage();
    } else if (text.isNotEmpty) {
      _messages.add(
        ChatMessage(
          text: text,
          timestamp: now,
          isUser: true,
        ),
      );
    }

    _messageController.clear();
    setState(() {});

    // Имитация ответа
    if (text.toLowerCase().contains('привет') ||
        text.toLowerCase().contains('здравствуйте')) {
      _simulateDriverResponse('Здравствуйте! Чем могу помочь?');
    } else if (text.toLowerCase().contains('время') ||
        text.toLowerCase().contains('когда')) {
      _simulateDriverResponse('Я буду через 5-7 минут, уже еду к вам.');
    } else {
      _simulateDriverResponse('Спасибо за информацию! Я все понял.');
    }

    // Прокрутка списка вниз
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  void _simulateDriverResponse(String text) {
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _messages.add(
            ChatMessage(
              text: text,
              timestamp: DateTime.now(),
              isUser: false,
            ),
          );

          // Помечаем предыдущее сообщение пользователя как прочитанное
          for (int i = _messages.length - 2; i >= 0; i--) {
            if (_messages[i].isUser && !_messages[i].isRead) {
              _messages[i] = ChatMessage(
                text: _messages[i].text,
                timestamp: _messages[i].timestamp,
                isUser: true,
                isRead: true,
                attachmentUrl: _messages[i].attachmentUrl,
                attachmentType: _messages[i].attachmentType,
              );
            }
          }

          // Прокрутка списка вниз
          WidgetsBinding.instance
              .addPostFrameCallback((_) => _scrollToBottom());
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            if (widget.driverPhoto != null) ...[
              CircleAvatar(
                radius: 16,
                backgroundImage: NetworkImage(widget.driverPhoto!),
                onBackgroundImageError: (_, __) {},
              ),
              const SizedBox(width: 8),
            ],
            Text(widget.driverName),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.phone),
            onPressed: () {
              // Реализовать звонок
            },
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              // Показать дополнительные опции
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                final showTime = index == _messages.length - 1 ||
                    _messages[index + 1].isUser != message.isUser ||
                    _messages[index + 1]
                            .timestamp
                            .difference(message.timestamp)
                            .inMinutes >
                        5;

                return ChatMessageBubble(
                  message: message,
                  showTime: showTime,
                );
              },
            ),
          ),
          if (_selectedImage != null)
            Container(
              height: 100,
              width: double.infinity,
              color: Colors.grey[200],
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Stack(
                      children: [
                        Image.file(
                          _selectedImage!,
                          height: 80,
                          width: 80,
                          fit: BoxFit.cover,
                        ),
                        Positioned(
                          top: 2,
                          right: 2,
                          child: GestureDetector(
                            onTap: _removeSelectedImage,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.5),
                                shape: BoxShape.circle,
                              ),
                              padding: const EdgeInsets.all(4),
                              child: const Icon(
                                Icons.close,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 2,
                  offset: const Offset(0, -1),
                ),
              ],
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.camera_alt),
                  color: Theme.of(context).primaryColor,
                  onPressed: () => _pickImage(ImageSource.camera),
                ),
                IconButton(
                  icon: const Icon(Icons.photo),
                  color: Theme.of(context).primaryColor,
                  onPressed: () => _pickImage(ImageSource.gallery),
                ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Написать сообщение...',
                      border: InputBorder.none,
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    textCapitalization: TextCapitalization.sentences,
                    keyboardType: TextInputType.multiline,
                    maxLines: 3,
                    minLines: 1,
                    onChanged: (value) {
                      setState(() {});
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  color: Theme.of(context).primaryColor,
                  onPressed: _messageController.text.trim().isNotEmpty ||
                          _selectedImage != null
                      ? _sendMessage
                      : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
