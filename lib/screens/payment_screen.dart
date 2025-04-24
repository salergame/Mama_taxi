import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mama_taxi/models/payment_model.dart';
import 'package:mama_taxi/providers/payment_provider.dart';
import 'package:mama_taxi/providers/user_provider.dart';
import 'package:mama_taxi/widgets/payment_method_card.dart';
import 'package:mama_taxi/widgets/transaction_item.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({Key? key}) : super(key: key);

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  int _selectedIndex = 0;
  bool _isLoading = false;

  // Заглушка для демо режима - данные будут загружаться из провайдера
  final List<String> _tabs = [
    'Способы оплаты',
    'История платежей',
    'Лояльность'
  ];

  @override
  void initState() {
    super.initState();
    _loadPaymentData();
  }

  Future<void> _loadPaymentData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Инициализация данных из провайдера
      await Provider.of<PaymentProvider>(context, listen: false)
          .loadPaymentData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка загрузки платежных данных: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _addNewPaymentMethod() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _AddPaymentMethodBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Оплата',
          style: TextStyle(
            fontFamily: 'Manrope',
            fontSize: 18,
            fontWeight: FontWeight.w400,
            color: Colors.black,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Табы
                Container(
                  color: Colors.white,
                  child: TabBar(
                    onTap: (index) {
                      setState(() {
                        _selectedIndex = index;
                      });
                    },
                    labelColor: const Color(0xFF8B5CF6),
                    unselectedLabelColor: const Color(0xFF6B7280),
                    indicatorColor: const Color(0xFF8B5CF6),
                    tabs: _tabs
                        .map((tab) => Tab(
                              text: tab,
                            ))
                        .toList(),
                  ),
                ),
                Expanded(
                  child: IndexedStack(
                    index: _selectedIndex,
                    children: [
                      _buildPaymentMethodsTab(),
                      _buildPaymentHistoryTab(),
                      _buildLoyaltyTab(),
                    ],
                  ),
                ),
              ],
            ),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton(
              onPressed: _addNewPaymentMethod,
              backgroundColor: const Color(0xFF8B5CF6),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildPaymentMethodsTab() {
    return Consumer<PaymentProvider>(
      builder: (context, paymentProvider, child) {
        final paymentMethods = paymentProvider.paymentMethods;

        if (paymentMethods.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.credit_card,
                  size: 64,
                  color: Color(0xFFD1D5DB),
                ),
                const SizedBox(height: 16),
                const Text(
                  'У вас еще нет способов оплаты',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF374151),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Добавьте карту или другой способ оплаты',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _addNewPaymentMethod,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B5CF6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Text(
                      'Добавить способ оплаты',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: paymentMethods.length,
          itemBuilder: (context, index) {
            final method = paymentMethods[index];
            return PaymentMethodCard(
              paymentMethod: method,
              onSetDefault: () {
                paymentProvider.setDefaultPaymentMethod(method.id);
              },
              onDelete: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Удалить способ оплаты?'),
                    content: const Text(
                        'Вы уверены, что хотите удалить этот способ оплаты?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Отмена'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          paymentProvider.removePaymentMethod(method.id);
                        },
                        child: const Text(
                          'Удалить',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildPaymentHistoryTab() {
    return Consumer<PaymentProvider>(
      builder: (context, paymentProvider, child) {
        final transactions = paymentProvider.transactions;

        if (transactions.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(
                  Icons.receipt_long,
                  size: 64,
                  color: Color(0xFFD1D5DB),
                ),
                SizedBox(height: 16),
                Text(
                  'У вас еще нет платежей',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF374151),
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'История ваших платежей появится здесь',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: transactions.length,
          itemBuilder: (context, index) {
            final transaction = transactions[index];
            return TransactionItem(transaction: transaction);
          },
        );
      },
    );
  }

  Widget _buildLoyaltyTab() {
    // Уровни лояльности
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ваши баллы
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 0,
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ваши баллы',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEDE9FE),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.star,
                        color: Color(0xFF8B5CF6),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          '250 баллов',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF8B5CF6),
                          ),
                        ),
                        Text(
                          'Серебряный уровень',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: FractionallySizedBox(
                    widthFactor: 0.5, // 50% прогресса
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF8B5CF6),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Еще 250 баллов до Золотого уровня',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Уровни лояльности
          const Text(
            'Уровни лояльности',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),

          // Бронзовый уровень
          _buildLoyaltyLevelCard(
            title: 'Бронзовый уровень',
            points: '0-100 баллов',
            benefits: ['5% кэшбэк баллами', 'Скидка 3% на поездки с детьми'],
            color: const Color(0xFFD97706),
            isActive: false,
          ),

          const SizedBox(height: 16),

          // Серебряный уровень
          _buildLoyaltyLevelCard(
            title: 'Серебряный уровень',
            points: '100-500 баллов',
            benefits: [
              '7% кэшбэк баллами',
              'Скидка 5% на поездки с детьми',
              'Бесплатная отмена поездки'
            ],
            color: const Color(0xFF9CA3AF),
            isActive: true,
          ),

          const SizedBox(height: 16),

          // Золотой уровень
          _buildLoyaltyLevelCard(
            title: 'Золотой уровень',
            points: '500+ баллов',
            benefits: [
              '10% кэшбэк баллами',
              'Скидка 10% на поездки с детьми',
              'Бесплатная отмена поездки',
              'Приоритетная поддержка',
              'Бесплатные услуги сопровождения'
            ],
            color: const Color(0xFFFBBF24),
            isActive: false,
          ),
        ],
      ),
    );
  }

  Widget _buildLoyaltyLevelCard({
    required String title,
    required String points,
    required List<String> benefits,
    required Color color,
    required bool isActive,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? color : Colors.transparent,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.emoji_events,
                  color: color,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    points,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              if (isActive)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: color,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Текущий',
                        style: TextStyle(
                          fontSize: 12,
                          color: color,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Преимущества:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          ...benefits.map((benefit) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.check,
                      color: color,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      benefit,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

class _AddPaymentMethodBottomSheet extends StatefulWidget {
  @override
  _AddPaymentMethodBottomSheetState createState() =>
      _AddPaymentMethodBottomSheetState();
}

class _AddPaymentMethodBottomSheetState
    extends State<_AddPaymentMethodBottomSheet> {
  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _expiryDateController = TextEditingController();
  final TextEditingController _cvvController = TextEditingController();
  final TextEditingController _cardHolderController = TextEditingController();
  bool _isDefault = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryDateController.dispose();
    _cvvController.dispose();
    _cardHolderController.dispose();
    super.dispose();
  }

  Future<void> _addPaymentMethod() async {
    // Упрощенная проверка валидности формы
    if (_cardNumberController.text.length < 16 ||
        _expiryDateController.text.length < 5 ||
        _cvvController.text.length < 3 ||
        _cardHolderController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Пожалуйста, заполните все поля корректно'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Извлекаем последние 4 цифры карты
      final String last4 = _cardNumberController.text
          .substring(_cardNumberController.text.length - 4);

      // Определяем бренд карты по первым цифрам (очень простая реализация)
      String brand = 'Неизвестно';
      final firstDigit = _cardNumberController.text.substring(0, 1);
      if (firstDigit == '4') {
        brand = 'Visa';
      } else if (firstDigit == '5') {
        brand = 'MasterCard';
      } else if (firstDigit == '2') {
        brand = 'Mir';
      }

      // Создаем новый объект способа оплаты
      final paymentMethod = PaymentMethod(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: 'card',
        last4: last4,
        brand: brand,
        isDefault: _isDefault,
        cardHolderName: _cardHolderController.text,
        expiryDate: _expiryDateController.text,
      );

      // Добавляем способ оплаты через провайдер
      await Provider.of<PaymentProvider>(context, listen: false)
          .addPaymentMethod(paymentMethod);

      // Закрываем окно
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Способ оплаты успешно добавлен'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Ошибка при добавлении способа оплаты: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка при добавлении способа оплаты: $e'),
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
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Добавить карту',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Номер карты
            TextField(
              controller: _cardNumberController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Номер карты',
                hintText: '1234 5678 9012 3456',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.credit_card),
              ),
              maxLength: 16,
            ),
            const SizedBox(height: 16),
            // Срок действия и CVV
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _expiryDateController,
                    keyboardType: TextInputType.datetime,
                    decoration: const InputDecoration(
                      labelText: 'Срок действия',
                      hintText: 'ММ/ГГ',
                      border: OutlineInputBorder(),
                    ),
                    maxLength: 5,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _cvvController,
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'CVV',
                      hintText: '123',
                      border: OutlineInputBorder(),
                    ),
                    maxLength: 3,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Имя владельца
            TextField(
              controller: _cardHolderController,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'Имя владельца',
                hintText: 'IVAN IVANOV',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            // Сделать картой по умолчанию
            SwitchListTile(
              title: const Text('Сделать основным способом оплаты'),
              value: _isDefault,
              onChanged: (value) {
                setState(() {
                  _isDefault = value;
                });
              },
              activeColor: const Color(0xFF8B5CF6),
            ),
            const SizedBox(height: 24),
            // Кнопка добавления
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _addPaymentMethod,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B5CF6),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Добавить',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
