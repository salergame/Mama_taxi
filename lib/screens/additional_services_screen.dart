import 'package:flutter/material.dart';

class AdditionalServicesScreen extends StatefulWidget {
  const AdditionalServicesScreen({Key? key}) : super(key: key);

  @override
  State<AdditionalServicesScreen> createState() =>
      _AdditionalServicesScreenState();
}

class _AdditionalServicesScreenState extends State<AdditionalServicesScreen> {
  final List<Map<String, dynamic>> _services = [
    {
      'icon': Icons.child_care,
      'title': 'Детское кресло',
      'subtitle': 'Безопасная поездка для вашего ребенка',
      'price': '150₽',
      'isSelected': false,
    },
    {
      'icon': Icons.fastfood,
      'title': 'Перекус',
      'subtitle': 'Легкая еда и напитки для ребенка',
      'price': '250₽',
      'isSelected': false,
    },
    {
      'icon': Icons.toys,
      'title': 'Игрушки',
      'subtitle': 'Развлечения в дороге',
      'price': '100₽',
      'isSelected': false,
    },
    {
      'icon': Icons.headphones,
      'title': 'Аудиосказки',
      'subtitle': 'Коллекция детских аудиокниг',
      'price': '120₽',
      'isSelected': false,
    },
    {
      'icon': Icons.monitor,
      'title': 'Планшет с мультфильмами',
      'subtitle': 'Подборка мультфильмов для детей',
      'price': '200₽',
      'isSelected': false,
    },
    {
      'icon': Icons.medical_services,
      'title': 'Аптечка для детей',
      'subtitle': 'Базовые медикаменты для детей',
      'price': '100₽',
      'isSelected': false,
    },
  ];

  int _selectedCount = 0;
  int _totalPrice = 0;

  void _toggleService(int index) {
    setState(() {
      _services[index]['isSelected'] = !_services[index]['isSelected'];

      // Обновление счетчика выбранных услуг и общей стоимости
      _selectedCount = 0;
      _totalPrice = 0;
      for (var service in _services) {
        if (service['isSelected']) {
          _selectedCount++;
          _totalPrice +=
              int.parse(service['price'].toString().replaceAll('₽', ''));
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Дополнительные услуги',
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
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _services.length,
              itemBuilder: (context, index) {
                final service = _services[index];
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
                  child: CheckboxListTile(
                    value: service['isSelected'],
                    onChanged: (_) => _toggleService(index),
                    activeColor: const Color(0xFF53CFC4),
                    checkColor: Colors.white,
                    title: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            service['icon'],
                            color: const Color(0xFF2563EB),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                service['title'],
                                style: const TextStyle(
                                  fontFamily: 'Nunito',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                service['subtitle'],
                                style: const TextStyle(
                                  fontFamily: 'Nunito',
                                  fontSize: 14,
                                  color: Color(0xFF6B7280),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          service['price'],
                          style: const TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 2,
                  offset: const Offset(0, -1),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Выбрано: $_selectedCount ${_declOfNum(_selectedCount, [
                            'услуга',
                            'услуги',
                            'услуг'
                          ])}',
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 16,
                        color: Color(0xFF4B5563),
                      ),
                    ),
                    Text(
                      'Итого: $_totalPrice₽',
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop({
                        'selectedServices':
                            _services.where((s) => s['isSelected']).toList(),
                        'totalPrice': _totalPrice,
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF654AA),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Подтвердить',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _declOfNum(int number, List<String> titles) {
    List<int> cases = [2, 0, 1, 1, 1, 2];
    return titles[(number % 100 > 4 && number % 100 < 20)
        ? 2
        : cases[number % 10 < 5 ? number % 10 : 5]];
  }
}
