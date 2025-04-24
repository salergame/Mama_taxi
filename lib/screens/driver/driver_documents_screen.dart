import 'package:flutter/material.dart';

class DriverDocumentsScreen extends StatefulWidget {
  const DriverDocumentsScreen({Key? key}) : super(key: key);

  @override
  State<DriverDocumentsScreen> createState() => _DriverDocumentsScreenState();
}

class _DriverDocumentsScreenState extends State<DriverDocumentsScreen> {
  // Список документов водителя
  final List<Map<String, dynamic>> _documents = [
    {
      'title': 'Водительское удостоверение',
      'status': 'verified', // verified, pending, rejected
      'expiryDate': '12.05.2027',
      'icon': Icons.card_membership,
    },
    {
      'title': 'Паспорт',
      'status': 'verified',
      'expiryDate': 'Бессрочно',
      'icon': Icons.import_contacts,
    },
    {
      'title': 'СТС',
      'status': 'verified',
      'expiryDate': '15.07.2025',
      'icon': Icons.directions_car,
    },
    {
      'title': 'Справка о судимости',
      'status': 'pending',
      'expiryDate': 'На проверке',
      'icon': Icons.assignment,
    },
    {
      'title': 'Медицинская книжка',
      'status': 'verified',
      'expiryDate': '10.03.2024',
      'icon': Icons.medical_services,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Документы и верификация',
          style: TextStyle(
            fontFamily: 'Nunito',
            fontSize: 20,
            fontWeight: FontWeight.w400,
            color: Color(0xFF1F2937),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          // Верхняя информационная карточка
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.info_outline, color: Color(0xFF1D4ED8)),
                    SizedBox(width: 8),
                    Text(
                      'Информация',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF1D4ED8),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Для работы в сервисе "Автоняня" необходимо пройти верификацию. Загрузите документы и дождитесь их проверки.',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 14,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ],
            ),
          ),

          // Индикатор статуса верификации
          Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(16),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Статус верификации',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),

                // Индикатор прогресса
                Stack(
                  children: [
                    Container(
                      width: double.infinity,
                      height: 8,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE5E7EB),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    Container(
                      width: MediaQuery.of(context).size.width * 0.7,
                      height: 8,
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text(
                      '4/5 документов проверено',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 14,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                    Text(
                      '80%',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF10B981),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Заголовок списка документов
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Мои документы',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    // Действие при нажатии на кнопку добавления документа
                  },
                  icon: const Icon(Icons.add, color: Color(0xFF53CFC4)),
                  label: const Text(
                    'Добавить',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 14,
                      color: Color(0xFF53CFC4),
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
          ),

          // Список документов
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _documents.length,
              itemBuilder: (context, index) {
                final document = _documents[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
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
                  child: ListTile(
                    leading: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: document['status'] == 'verified'
                            ? const Color(0xFFD1FAE5)
                            : document['status'] == 'pending'
                                ? const Color(0xFFFEF3C7)
                                : const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        document['icon'] as IconData,
                        color: document['status'] == 'verified'
                            ? const Color(0xFF10B981)
                            : document['status'] == 'pending'
                                ? const Color(0xFFD97706)
                                : const Color(0xFFDC2626),
                      ),
                    ),
                    title: Text(
                      document['title'] as String,
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Row(
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: document['status'] == 'verified'
                                ? const Color(0xFFD1FAE5)
                                : document['status'] == 'pending'
                                    ? const Color(0xFFFEF3C7)
                                    : const Color(0xFFFEE2E2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            document['status'] == 'verified'
                                ? 'Проверено'
                                : document['status'] == 'pending'
                                    ? 'На проверке'
                                    : 'Отклонено',
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 12,
                              color: document['status'] == 'verified'
                                  ? const Color(0xFF10B981)
                                  : document['status'] == 'pending'
                                      ? const Color(0xFFD97706)
                                      : const Color(0xFFDC2626),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'до ${document['expiryDate']}',
                          style: const TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 12,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      // Действие при нажатии на документ
                    },
                  ),
                );
              },
            ),
          ),

          // Кнопка внизу экрана
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  // Действие при запросе верификации
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF53CFC4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Запросить верификацию',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
