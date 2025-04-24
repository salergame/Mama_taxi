import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

class TripReviewScreen extends StatefulWidget {
  const TripReviewScreen({Key? key}) : super(key: key);

  @override
  State<TripReviewScreen> createState() => _TripReviewScreenState();
}

class _TripReviewScreenState extends State<TripReviewScreen> {
  double _rating = 5.0;
  bool _childSafetyRating = true;
  bool _punctualityRating = true;
  bool _cleanlinessRating = true;
  bool _kidFriendlyRating = true;
  final TextEditingController _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Оценка поездки',
          style: TextStyle(
            fontFamily: 'Nunito',
            fontSize: 20,
            fontWeight: FontWeight.w400,
            color: Color(0xFF1F2937),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Информация о поездке
            Container(
              width: double.infinity,
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
                  Row(
                    children: [
                      // Фото водителя
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFFDFE1E6),
                            width: 2,
                          ),
                          image: const DecorationImage(
                            image: NetworkImage(
                                'https://i.pravatar.cc/150?img=32'),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Имя водителя и информация
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Елена Петрова',
                              style: TextStyle(
                                fontFamily: 'Nunito',
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: const [
                                Icon(Icons.star,
                                    color: Color(0xFFFFC107), size: 16),
                                SizedBox(width: 4),
                                Text(
                                  '4.87',
                                  style: TextStyle(
                                    fontFamily: 'Nunito',
                                    fontSize: 14,
                                    color: Color(0xFF6B7280),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: const [
                                Icon(Icons.verified_user,
                                    color: Color(0xFF53CFC4), size: 16),
                                SizedBox(width: 4),
                                Text(
                                  'Автоняня',
                                  style: TextStyle(
                                    fontFamily: 'Nunito',
                                    fontSize: 14,
                                    color: Color(0xFF53CFC4),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),

                  // Маршрут
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 32,
                            color: const Color(0xFF3B82F6),
                          ),
                          Container(
                            width: 12,
                            height: 12,
                            decoration: const BoxDecoration(
                              color: Color(0xFFF654AA),
                              shape: BoxShape.rectangle,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'ул. Ленина, 25',
                              style: TextStyle(
                                fontFamily: 'Nunito',
                                fontSize: 16,
                              ),
                            ),
                            SizedBox(height: 24),
                            Text(
                              'Школа №1234, ул. Пушкина, 10',
                              style: TextStyle(
                                fontFamily: 'Nunito',
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Статистика поездки
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatisticsItem(
                          icon: Icons.access_time,
                          title: 'Время',
                          value: '15 мин',
                        ),
                      ),
                      Expanded(
                        child: _buildStatisticsItem(
                          icon: Icons.map,
                          title: 'Расстояние',
                          value: '7.5 км',
                        ),
                      ),
                      Expanded(
                        child: _buildStatisticsItem(
                          icon: Icons.payments_outlined,
                          title: 'Стоимость',
                          value: '450₽',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Секция оценки
            const Text(
              'Оцените поездку',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),

            const SizedBox(height: 16),

            // Звезды рейтинга
            Center(
              child: Column(
                children: [
                  RatingBar.builder(
                    initialRating: _rating,
                    minRating: 1,
                    direction: Axis.horizontal,
                    allowHalfRating: true,
                    itemCount: 5,
                    itemSize: 48,
                    itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
                    itemBuilder: (context, _) => const Icon(
                      Icons.star,
                      color: Color(0xFFFFC107),
                    ),
                    onRatingUpdate: (rating) {
                      setState(() {
                        _rating = rating;
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_rating.toString()} / 5',
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Дополнительные параметры оценки
            const Text(
              'Что понравилось?',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),

            const SizedBox(height: 16),

            // Чекбоксы для разных параметров
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildRatingChip(
                  title: 'Безопасность ребенка',
                  isSelected: _childSafetyRating,
                  onSelected: (selected) {
                    setState(() {
                      _childSafetyRating = selected;
                    });
                  },
                ),
                _buildRatingChip(
                  title: 'Пунктуальность',
                  isSelected: _punctualityRating,
                  onSelected: (selected) {
                    setState(() {
                      _punctualityRating = selected;
                    });
                  },
                ),
                _buildRatingChip(
                  title: 'Чистота в салоне',
                  isSelected: _cleanlinessRating,
                  onSelected: (selected) {
                    setState(() {
                      _cleanlinessRating = selected;
                    });
                  },
                ),
                _buildRatingChip(
                  title: 'Дружелюбие к детям',
                  isSelected: _kidFriendlyRating,
                  onSelected: (selected) {
                    setState(() {
                      _kidFriendlyRating = selected;
                    });
                  },
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Поле для комментариев
            const Text(
              'Комментарий',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),

            const SizedBox(height: 12),

            TextField(
              controller: _commentController,
              decoration: InputDecoration(
                hintText:
                    'Расскажите подробнее о вашем опыте использования сервиса...',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFDFE1E6)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFDFE1E6)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF53CFC4)),
                ),
              ),
              maxLines: 4,
            ),

            const SizedBox(height: 32),

            // Кнопка отправки отзыва
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  // Отправка отзыва и возврат на главный экран
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Спасибо за ваш отзыв!'),
                      backgroundColor: Color(0xFF53CFC4),
                    ),
                  );
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    '/home',
                    (route) => false,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF53CFC4),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Отправить отзыв',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Кнопка пропуска
            SizedBox(
              width: double.infinity,
              height: 56,
              child: TextButton(
                onPressed: () {
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    '/home',
                    (route) => false,
                  );
                },
                child: const Text(
                  'Пропустить',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsItem({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF6B7280), size: 24),
        const SizedBox(height: 8),
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'Nunito',
            fontSize: 14,
            color: Color(0xFF6B7280),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'Nunito',
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildRatingChip({
    required String title,
    required bool isSelected,
    required Function(bool) onSelected,
  }) {
    return FilterChip(
      label: Text(
        title,
        style: TextStyle(
          color: isSelected ? Colors.white : const Color(0xFF1F2937),
          fontFamily: 'Nunito',
        ),
      ),
      selected: isSelected,
      onSelected: onSelected,
      backgroundColor: Colors.white,
      selectedColor: const Color(0xFF53CFC4),
      checkmarkColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? const Color(0xFF53CFC4) : const Color(0xFFDFE1E6),
        ),
      ),
    );
  }
}
