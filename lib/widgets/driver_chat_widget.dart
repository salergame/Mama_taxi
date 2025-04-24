import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/chat_message.dart';
import '../services/firebase_service.dart';

class DriverChatWidget extends StatefulWidget {
  final String driverName;
  final String driverPhoto;
  final String driverId;

  const DriverChatWidget({
    Key? key,
    required this.driverName,
    required this.driverPhoto,
    required this.driverId,
  }) : super(key: key);

  @override
  _DriverChatWidgetState createState() => _DriverChatWidgetState();
}

class _DriverChatWidgetState extends State<DriverChatWidget> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  final FirebaseService _firebaseService = FirebaseService();
  bool _isTyping = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    setState(() {
      _isLoading = true;
    });

    // Получаем сообщения из базы данных
    final messages = await _firebaseService.getChatMessages(widget.driverId);

    setState(() {
      _messages.clear();

      if (messages.isEmpty) {
        // Если сообщений нет, добавляем приветственное сообщение
        final welcomeMessage = ChatMessage.fromDriver(
            'Здравствуйте! Я буду вашим водителем сегодня.');
        _messages.add(welcomeMessage);

        // Сохраняем приветственное сообщение в базу
        _firebaseService.saveMessage(
            widget.driverId, welcomeMessage.text, false);
      } else {
        // Преобразуем сообщения из формата базы данных
        for (final message in messages) {
          _messages.add(ChatMessage.fromDatabase(message));
        }

        // Помечаем сообщения от водителя как прочитанные
        _firebaseService.markMessagesAsRead(widget.driverId);
      }

      _isLoading = false;
    });

    // Прокручиваем к последнему сообщению
    _scrollToBottom();
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    // Создаем сообщение
    final userMessage = ChatMessage.fromUser(text);

    setState(() {
      _messages.add(userMessage);
      _messageController.clear();
      _isTyping = true;
    });

    // Сохраняем сообщение пользователя в базе
    await _firebaseService.saveMessage(widget.driverId, text, true);

    _scrollToBottom();

    // Имитация ответа водителя
    Future.delayed(const Duration(seconds: 2), () async {
      if (mounted) {
        final responseText = _generateResponse(text);
        final driverMessage = ChatMessage.fromDriver(responseText);

        // Сохраняем ответ водителя в базе
        await _firebaseService.saveMessage(
            widget.driverId, responseText, false);

        setState(() {
          _isTyping = false;
          _messages.add(driverMessage);
        });

        _scrollToBottom();
      }
    });
  }

  String _generateResponse(String message) {
    if (message.toLowerCase().contains('время') ||
        message.toLowerCase().contains('прибытие')) {
      return 'Я буду на месте примерно через 5-7 минут.';
    } else if (message.toLowerCase().contains('где') ||
        message.toLowerCase().contains('местоположение')) {
      return 'Я сейчас на улице Ленина, двигаюсь к вам.';
    } else if (message.toLowerCase().contains('спасибо')) {
      return 'Всегда пожалуйста! Рад помочь.';
    } else {
      return 'Я получил ваше сообщение. Скоро буду на месте!';
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildChatHeader(),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _buildMessageList(),
        ),
        if (_isTyping) _buildTypingIndicator(),
        _buildMessageInput(),
      ],
    );
  }

  Widget _buildChatHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            offset: Offset(0, 2),
            blurRadius: 4,
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundImage: widget.driverPhoto.isNotEmpty
                ? NetworkImage(widget.driverPhoto)
                : AssetImage('assets/images/default_driver.png')
                    as ImageProvider,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.driverName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'Онлайн',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.phone, color: Colors.blue),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Звонок водителю...')),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        return _buildMessageBubble(message);
      },
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isFromDriver = message.isFromDriver;
    final timeString = DateFormat.Hm().format(message.timestamp);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment:
            isFromDriver ? MainAxisAlignment.start : MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isFromDriver) ...[
            CircleAvatar(
              radius: 16,
              backgroundImage: widget.driverPhoto.isNotEmpty
                  ? NetworkImage(widget.driverPhoto)
                  : AssetImage('assets/images/default_driver.png')
                      as ImageProvider,
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color:
                    isFromDriver ? Colors.grey.shade200 : Colors.blue.shade100,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.text,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        timeString,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      if (!isFromDriver) ...[
                        const SizedBox(width: 4),
                        Icon(
                          message.isRead ? Icons.done_all : Icons.done,
                          size: 14,
                          color: message.isRead
                              ? Colors.blue
                              : Colors.grey.shade600,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (!isFromDriver) const SizedBox(width: 24),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      alignment: Alignment.centerLeft,
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundImage: widget.driverPhoto.isNotEmpty
                ? NetworkImage(widget.driverPhoto)
                : AssetImage('assets/images/default_driver.png')
                    as ImageProvider,
          ),
          const SizedBox(width: 8),
          const Text(
            'Водитель печатает...',
            style: TextStyle(
              fontSize: 14,
              fontStyle: FontStyle.italic,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            offset: Offset(0, -2),
            blurRadius: 4,
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.attach_file, color: Colors.grey),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Функция вложений в разработке')),
              );
            },
          ),
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                hintText: 'Введите сообщение...',
                border: InputBorder.none,
              ),
              textCapitalization: TextCapitalization.sentences,
              minLines: 1,
              maxLines: 5,
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send, color: Colors.blue),
            onPressed: _sendMessage,
          ),
        ],
      ),
    );
  }
}
