import 'package:flutter/material.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({Key? key}) : super(key: key);

  @override
  _SupportScreenState createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  final List<Map<String, dynamic>> _faqItems = [
    {
      'question': 'Как оформить подписку на сервис?',
      'answer':
          'Для оформления подписки перейдите в раздел "Настройки" и выберите подходящий тарифный план. Следуйте инструкциям для завершения оплаты.'
    },
    {
      'question': 'Как добавить ребенка в профиль?',
      'answer':
          'В боковом меню выберите раздел "Мои дети" и нажмите кнопку "Добавить ребенка". Заполните необходимую информацию и сохраните изменения.'
    },
    {
      'question': 'Как работает система безопасности?',
      'answer':
          'Мы используем многоуровневую систему проверки водителей, отслеживание маршрута в реальном времени и возможность экстренной связи с оператором.'
    },
    {
      'question': 'Что делать, если водитель опаздывает?',
      'answer':
          'Вы можете связаться с водителем через чат в приложении или позвонить в службу поддержки, если задержка превышает 15 минут.'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        shadowColor: Colors.black.withOpacity(0.05),
        title: Row(
          children: const [
            Icon(Icons.support_agent, size: 18),
            SizedBox(width: 16),
            Text(
              'Поддержка и помощь',
              style: TextStyle(
                fontFamily: 'Manrope',
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: Colors.black,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: CircleAvatar(
              radius: 16,
              backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=44'),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header section
            _buildHeaderSection(),

            // FAQ section
            _buildFAQSection(),

            // Support contact section
            _buildSupportContactSection(),

            // Request status section
            _buildRequestStatusSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Как мы можем помочь?',
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Поиск по вопросам',
                hintStyle: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 16,
                  color: Colors.grey[500],
                ),
                border: InputBorder.none,
                icon: const Icon(Icons.search),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAQSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Часто задаваемые вопросы',
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          ...List.generate(
            _faqItems.length,
            (index) => _buildFAQItem(_faqItems[index]),
          ),
        ],
      ),
    );
  }

  Widget _buildFAQItem(Map<String, dynamic> item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ExpansionTile(
        title: Text(
          item['question'],
          style: const TextStyle(
            fontFamily: 'Manrope',
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              item['answer'],
              style: const TextStyle(
                fontFamily: 'Manrope',
                fontSize: 14,
                color: Color(0xFF4B5563),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupportContactSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Связаться с поддержкой',
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildContactItem(
                  icon: Icons.chat_bubble_outline,
                  title: 'Написать в чат',
                  subtitle: 'Оператор ответит в течение 5 минут',
                  onTap: () {},
                ),
                const Divider(height: 32),
                _buildContactItem(
                  icon: Icons.phone_outlined,
                  title: 'Позвонить в поддержку',
                  subtitle: '+7 (800) 123-45-67',
                  onTap: () {},
                ),
                const Divider(height: 32),
                _buildContactItem(
                  icon: Icons.email_outlined,
                  title: 'Написать на почту',
                  subtitle: 'support@mamataxi.ru',
                  onTap: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF1D4ED8),
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
                    fontFamily: 'Manrope',
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontFamily: 'Manrope',
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
            color: Color(0xFF9CA3AF),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestStatusSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Статус обращения',
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: const Color(0xFF16A34A),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Заявка #1245 обрабатывается',
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Мы получили ваше обращение и передали специалисту. Ожидаемое время ответа: до 2 часов',
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 14,
                    color: Color(0xFF4B5563),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
