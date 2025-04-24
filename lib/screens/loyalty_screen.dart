import 'package:flutter/material.dart';
import 'package:mama_taxi/services/firebase_service.dart';
import 'package:intl/intl.dart';
import 'package:mama_taxi/mixins/auth_checker_mixin.dart';

class LoyaltyScreen extends StatefulWidget {
  const LoyaltyScreen({Key? key}) : super(key: key);

  @override
  State<LoyaltyScreen> createState() => _LoyaltyScreenState();
}

class _LoyaltyScreenState extends State<LoyaltyScreen> with AuthCheckerMixin {
  final FirebaseService _firebaseService = FirebaseService();
  Map<String, dynamic>? _loyaltyData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final isAuthenticated = await checkAuth();
    if (isAuthenticated) {
      await _loadLoyaltyData();
    }
  }

  Future<void> _loadLoyaltyData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final loyaltyData = await _firebaseService.getUserLoyaltyData();
      setState(() {
        _loyaltyData = loyaltyData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Ошибка загрузки данных лояльности: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          'Программа лояльности',
          style: TextStyle(
            color: Colors.black,
            fontFamily: 'Unbounded',
            fontSize: 16,
          ),
        ),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
            child: Column(
              children: [
            // Баланс баллов и прогресс-бар
                Container(
                  padding: const EdgeInsets.only(top: 24),
              child: Center(
                child: Container(
                  width: 358,
                        height: 188,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFF654AA), Color(0xFF56CDC4)],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Stack(
                          children: [
                      // Фоновая графика (полупрозрачная иконка)
                            Positioned(
                              right: 0,
                              top: 0,
                        child: Opacity(
                          opacity: 0.1,
                              child: Container(
                                width: 96,
                                height: 96,
                                child: const Icon(
                                  Icons.card_giftcard,
                                  size: 60,
                              color: Colors.black,
                            ),
                                ),
                              ),
                            ),

                      // Текст "Текущий баланс баллов"
                      const Positioned(
                        left: 24,
                        top: 25,
                        child: Text(
                                    'Текущий баланс баллов',
                                    style: TextStyle(
                                      fontFamily: 'Unbounded',
                                      fontSize: 14,
                                      color: Colors.white,
                                    ),
                                  ),
                      ),

                      // Кол-во баллов
                      const Positioned(
                        left: 24,
                        top: 49,
                        child: Text(
                          '120',
                          style: TextStyle(
                                      fontFamily: 'Unbounded',
                                      fontSize: 36,
                                      color: Colors.white,
                                    ),
                                  ),
                      ),

                      // Прогресс-бар (фон)
                      Positioned(
                        left: 24,
                        top: 108,
                        child: Container(
                          width: 310,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(9999),
                                        ),
                          child: Stack(
                            children: [
                              // Прогресс-бар (заполнение)
                                      Container(
                                width: 110,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                  borderRadius: BorderRadius.circular(9999),
                                        ),
                                      ),
                                    ],
                                  ),
                        ),
                      ),

                      // Текст под прогресс-баром
                      const Positioned(
                        left: 24,
                        top: 129,
                        child: Text(
                          'Еще 180 баллов – и вы получите скидку 15%!',
                          style: TextStyle(
                                      fontFamily: 'Unbounded',
                                      fontSize: 14,
                                      color: Colors.white,
                                    ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Карточки с уровнями лояльности
            Container(
              padding: const EdgeInsets.only(top: 24),
              child: Center(
                child: SizedBox(
                  width: 358,
                  height: 134,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Карточка 1
                      Container(
                        width: 111.33,
                        height: 134,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: const Color(0xFFF3F4F6)),
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
                          children: const [
                            Padding(
                              padding: EdgeInsets.only(left: 17, top: 14.5),
                              child: Icon(Icons.star_border, size: 20),
                            ),
                            Padding(
                              padding: EdgeInsets.only(left: 17, top: 2.5),
                              child: Text(
                                '5,000',
                                style: TextStyle(
                                  fontFamily: 'Unbounded',
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.only(left: 17),
                              child: Text(
                                'баллов',
                                style: TextStyle(
                                  fontFamily: 'Unbounded',
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.only(left: 17, top: 20),
                              child: Text(
                                'скидка',
                                style: TextStyle(
                                  fontFamily: 'Unbounded',
                                  fontSize: 12,
                                  color: Color(0xFF4B5563),
                                ),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.only(left: 17),
                              child: Text(
                                '10%',
                                style: TextStyle(
                                  fontFamily: 'Unbounded',
                                  fontSize: 12,
                                  color: Color(0xFF4B5563),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Карточка 2
                      Container(
                        width: 111.33,
                        height: 134,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: const Color(0xFFF3F4F6)),
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
                          children: const [
                            Padding(
                              padding: EdgeInsets.only(left: 17, top: 14.5),
                              child: Icon(Icons.star, size: 20),
                            ),
                            Padding(
                              padding: EdgeInsets.only(left: 17, top: 2.5),
                              child: Text(
                                '10,000',
                                style: TextStyle(
                                  fontFamily: 'Unbounded',
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.only(left: 17),
                              child: Text(
                                'баллов',
                                style: TextStyle(
                                  fontFamily: 'Unbounded',
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.only(left: 17, top: 20),
                              child: Text(
                                'скидка',
                                style: TextStyle(
                                  fontFamily: 'Unbounded',
                                  fontSize: 12,
                                  color: Color(0xFF4B5563),
                                ),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.only(left: 17),
                              child: Text(
                                '15%',
                                style: TextStyle(
                                  fontFamily: 'Unbounded',
                                  fontSize: 12,
                                  color: Color(0xFF4B5563),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Карточка 3
                      Container(
                        width: 111.34,
                        height: 134,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: const Color(0xFFF3F4F6)),
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
                          children: const [
                            Padding(
                              padding: EdgeInsets.only(left: 17, top: 14.5),
                              child: Icon(Icons.card_giftcard, size: 20),
                            ),
                            Padding(
                              padding: EdgeInsets.only(left: 17, top: 2.5),
                              child: Text(
                                '20,000',
                                style: TextStyle(
                                  fontFamily: 'Unbounded',
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.only(left: 17),
                              child: Text(
                                'баллов',
                                style: TextStyle(
                                  fontFamily: 'Unbounded',
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.only(left: 17, top: 20),
                              child: Text(
                                '1',
                                style: TextStyle(
                                  fontFamily: 'Unbounded',
                                  fontSize: 12,
                                  color: Color(0xFF4B5563),
                                ),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.only(left: 17),
                              child: Text(
                                'бесплатная',
                                style: TextStyle(
                                  fontFamily: 'Unbounded',
                                  fontSize: 12,
                                  color: Color(0xFF4B5563),
                                ),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.only(left: 17),
                              child: Text(
                                'поездка',
                                style: TextStyle(
                                  fontFamily: 'Unbounded',
                                  fontSize: 12,
                                  color: Color(0xFF4B5563),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                  ),
                ),

                // Секция "Как зарабатывать баллы?"
                Container(
              width: 390,
              margin: const EdgeInsets.only(top: 24),
              padding: const EdgeInsets.symmetric(vertical: 24),
                  color: Colors.white,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                        'Как зарабатывать баллы?',
                        style: TextStyle(
                          fontFamily: 'Unbounded',
                          fontSize: 18,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Способ 1
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                        color: const Color(0xFFDBEAFE),
                            borderRadius: BorderRadius.circular(9999),
                          ),
                          child: const Icon(
                            Icons.directions_car,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              '1 поездка = 10 баллов',
                              style: TextStyle(
                                fontFamily: 'Unbounded',
                                fontSize: 16,
                              ),
                            ),
                            SizedBox(height: 7),
                            Text(
                              'За каждую завершенную поездку',
                              style: TextStyle(
                                fontFamily: 'Unbounded',
                                fontSize: 14,
                                color: Color(0xFF4B5563),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                      ),

                      const SizedBox(height: 16),

                  // Способ 2
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                        color: const Color(0xFFEDE9FE),
                            borderRadius: BorderRadius.circular(9999),
                          ),
                          child: const Icon(
                            Icons.person_add,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Пригласите друга – 20 баллов',
                              style: TextStyle(
                                fontFamily: 'Unbounded',
                                fontSize: 16,
                              ),
                            ),
                            SizedBox(height: 7),
                            Text(
                              'За каждого приглашенного друга',
                              style: TextStyle(
                                fontFamily: 'Unbounded',
                                fontSize: 14,
                                color: Color(0xFF4B5563),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                      ),

                      const SizedBox(height: 16),

                  // Способ 3
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                        color: const Color(0xFFD1FAE5),
                            borderRadius: BorderRadius.circular(9999),
                          ),
                          child: const Icon(
                            Icons.calendar_today,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Предварительный заказ – 5 баллов',
                              style: TextStyle(
                                fontFamily: 'Unbounded',
                                fontSize: 16,
                              ),
                            ),
                            SizedBox(height: 7),
                            Text(
                              'За предварительное бронирование',
                              style: TextStyle(
                                fontFamily: 'Unbounded',
                                fontSize: 14,
                                color: Color(0xFF4B5563),
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

                // Секция "История баллов"
                Container(
              width: 390,
              padding: const EdgeInsets.only(top: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                        'История баллов',
                        style: TextStyle(
                          fontFamily: 'Unbounded',
                          fontSize: 18,
                      ),
                        ),
                      ),
                      const SizedBox(height: 16),

                  // История транзакций
                  Center(
                    child: Container(
                      width: 358,
                      padding: const EdgeInsets.symmetric(
                          vertical: 17, horizontal: 17),
                          decoration: BoxDecoration(
                            color: Colors.white,
                        border: Border.all(color: const Color(0xFFF3F4F6)),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.directions_car, size: 16),
                              const SizedBox(width: 12),
                              Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                    Text(
                                    'Начисление: 100 баллов за поездку',
                                    style: TextStyle(
                                        fontFamily: 'Unbounded',
                                        fontSize: 16,
                                    ),
                                  ),
                                  SizedBox(height: 9),
                                    Text(
                                    '15 марта, 12:00',
                                    style: TextStyle(
                                        fontFamily: 'Unbounded',
                                        fontSize: 14,
                                        color: Color(0xFF4B5563),
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                          const Text(
                            '+120',
                                style: TextStyle(
                                  fontFamily: 'Unbounded',
                                  fontSize: 16,
                              color: Color(0xFF10B981),
                                ),
                              ),
                            ],
                          ),
                    ),
                  ),
                ],
              ),
            ),

            // Нижняя секция со статистикой и кнопкой
                Container(
              width: 390,
              margin: const EdgeInsets.only(top: 24),
              padding: const EdgeInsets.symmetric(vertical: 17),
                  color: Colors.white,
                  child: Column(
                    children: [
                  const Text(
                    'Вы накопили 120 баллов!',
                    style: TextStyle(
                          fontFamily: 'Unbounded',
                          fontSize: 14,
                          color: Color(0xFF4B5563),
                        ),
                        textAlign: TextAlign.center,
                      ),
                  const SizedBox(height: 7),
                  const Text(
                    'Еще 180 баллов, и у вас будет скидка 15%!',
                    style: TextStyle(
                          fontFamily: 'Unbounded',
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                  // Кнопка
                  Center(
                    child: Container(
                      width: 358,
                        height: 56,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFF153AD), Color(0xFF61C5C2)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                        child: ElevatedButton(
                          onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'Эта функция появится в следующем обновлении'),
                              backgroundColor: Colors.green,
                            ),
                          );
                          },
                          style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                              Text(
                                'Заработать больше баллов',
                                style: TextStyle(
                                  fontFamily: 'Unbounded',
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                            SizedBox(width: 14),
                            Icon(
                              Icons.arrow_forward,
                              color: Colors.white,
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Нижний отступ
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _showPointsExchangeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Использование баллов',
          style: TextStyle(
            fontFamily: 'Rubik',
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Вы можете использовать накопленные баллы при оплате вашей следующей поездки.',
              style: TextStyle(
                fontFamily: 'Rubik',
                fontSize: 14,
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Просто выберите опцию "Оплатить баллами" перед оформлением заказа.',
              style: TextStyle(
                fontFamily: 'Rubik',
                fontSize: 14,
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Понятно',
              style: TextStyle(
                color: Color(0xFF53CFC4),
                fontFamily: 'Rubik',
                  fontSize: 16,
              ),
                ),
              ),
            ],
          ),
    );
  }
}
