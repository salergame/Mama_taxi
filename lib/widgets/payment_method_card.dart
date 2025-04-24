import 'package:flutter/material.dart';
import 'package:mama_taxi/models/payment_model.dart';

class PaymentMethodCard extends StatelessWidget {
  final PaymentMethod paymentMethod;
  final VoidCallback onSetDefault;
  final VoidCallback onDelete;

  const PaymentMethodCard({
    Key? key,
    required this.paymentMethod,
    required this.onSetDefault,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: paymentMethod.isDefault
              ? const Color(0xFF8B5CF6)
              : const Color(0xFFE5E7EB),
          width: paymentMethod.isDefault ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                // Иконка карты
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: paymentMethod.getCardColor().withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Image.asset(
                      paymentMethod.getCardIcon(),
                      width: 32,
                      height: 32,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          Icons.credit_card,
                          color: paymentMethod.getCardColor(),
                          size: 24,
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Информация о карте
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${paymentMethod.brand} •••• ${paymentMethod.last4}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (paymentMethod.cardHolderName != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          '${paymentMethod.cardHolderName}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                      if (paymentMethod.isDefault) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: const [
                            Icon(
                              Icons.check_circle,
                              color: Color(0xFF8B5CF6),
                              size: 14,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Основной способ оплаты',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF8B5CF6),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                // Меню
                PopupMenuButton(
                  icon: const Icon(Icons.more_vert),
                  itemBuilder: (context) => [
                    if (!paymentMethod.isDefault)
                      PopupMenuItem(
                        value: 'default',
                        child: Row(
                          children: const [
                            Icon(Icons.check_circle_outline),
                            SizedBox(width: 8),
                            Text('Сделать основным'),
                          ],
                        ),
                      ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: const [
                          Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Удалить',
                            style: TextStyle(color: Colors.red),
                          ),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (value) {
                    if (value == 'default') {
                      onSetDefault();
                    } else if (value == 'delete') {
                      onDelete();
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
 