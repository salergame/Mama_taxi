import 'package:flutter/material.dart';

class ServicesModal extends StatefulWidget {
  final List<Map<String, dynamic>> selectedServices;
  final Function(List<Map<String, dynamic>>) onApply;

  const ServicesModal({
    Key? key,
    required this.selectedServices,
    required this.onApply,
  }) : super(key: key);

  @override
  State<ServicesModal> createState() => _ServicesModalState();
}

class _ServicesModalState extends State<ServicesModal> {
  late List<Map<String, dynamic>> _services;

  @override
  void initState() {
    super.initState();
    _services = [
      {
        'id': 1,
        'title': 'Проводить до входа в квартиру / школу',
        'isSelected': false,
        'imageAsset': 'assets/images/2.png',
      },
      {
        'id': 2,
        'title': 'Встретить ребенка у квартиры / подъезда',
        'isSelected': false,
        'imageAsset': 'assets/images/5.png',
      },
      {
        'id': 3,
        'title': 'Водитель — женщина',
        'isSelected': false,
        'imageAsset': 'assets/images/3.png',
      },
      {
        'id': 4,
        'title': 'Водитель — мужчина',
        'isSelected': false,
        'imageAsset': 'assets/images/4.png',
      },
      {
        'id': 5,
        'title': 'Детское автокресло',
        'isSelected': false,
        'imageAsset': 'assets/images/6.png',
      },
    ];

    // Устанавливаем выбранные услуги, если они есть
    if (widget.selectedServices.isNotEmpty) {
      for (var selectedService in widget.selectedServices) {
        final index =
            _services.indexWhere((s) => s['id'] == selectedService['id']);
        if (index != -1) {
          _services[index]['isSelected'] = true;
        }
      }
    }
  }

  void _toggleService(int index) {
    setState(() {
      _services[index]['isSelected'] = !_services[index]['isSelected'];
    });
  }

  int get _selectedCount {
    return _services.where((s) => s['isSelected'] == true).length;
  }

  String _declOfNum(int number, List<String> titles) {
    List<int> cases = [2, 0, 1, 1, 1, 2];
    return titles[(number % 100 > 4 && number % 100 < 20)
        ? 2
        : cases[number % 10 < 5 ? number % 10 : 5]];
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Container(
        width: 358,
        height: 690,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          children: [
            // Заголовок
            Container(
              width: 358,
              height: 133,
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Color(0xFFF3F4F6), width: 1),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.only(left: 24, right: 24, top: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Выберите дополнительные услуги',
                          style: TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 20,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF111827),
                          ),
                        ),
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'Выбрано: $_selectedCount ${_declOfNum(_selectedCount, [
                            'услуга',
                            'услуги',
                            'услуг'
                          ])}',
                      style: const TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Список услуг
            Container(
              width: 358,
              height: 400,
              padding: const EdgeInsets.only(left: 24, right: 24, top: 16),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: _services.length,
                itemBuilder: (context, index) {
                  final service = _services[index];
                  return Container(
                    width: 310,
                    height: 65,
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: InkWell(
                      onTap: () => _toggleService(index),
                      child: Row(
                        children: [
                          // Изображение (PlaceholderImage, так как у вас будут свои изображения)
                          Container(
                            width: 53,
                            height: 53,
                            margin: const EdgeInsets.only(left: 12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: Colors.grey.shade300,
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: const Icon(Icons.image,
                                  size: 30), // Здесь будет ваше изображение
                            ),
                          ),

                          // Текст услуги
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(left: 12),
                              child: Text(
                                service['title'],
                                style: const TextStyle(
                                  fontFamily: 'Manrope',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w400,
                                  color: Color(0xFF111827),
                                ),
                              ),
                            ),
                          ),

                          // Чекбокс
                          Container(
                            margin: const EdgeInsets.only(right: 16),
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: service['isSelected']
                                  ? const Color(0xFF53CFC4)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: service['isSelected']
                                    ? const Color(0xFF53CFC4)
                                    : const Color(0xFFF654AA),
                                width: 2,
                              ),
                            ),
                            child: service['isSelected']
                                ? const Icon(Icons.check,
                                    color: Colors.white, size: 18)
                                : null,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Кнопки
            Container(
              width: 358,
              height: 157,
              padding: const EdgeInsets.only(left: 24, right: 24, top: 17),
              child: Column(
                children: [
                  // Кнопка "Применить"
                  SizedBox(
                    width: 310,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        final selectedServices = _services
                            .where((s) => s['isSelected'] == true)
                            .toList();
                        widget.onApply(selectedServices);
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF654AA),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Применить',
                        style: TextStyle(
                          fontFamily: 'Manrope',
                          fontWeight: FontWeight.w400,
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Кнопка "Отмена"
                  SizedBox(
                    width: 310,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF53CFC4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Отмена',
                        style: TextStyle(
                          fontFamily: 'Manrope',
                          fontWeight: FontWeight.w400,
                          fontSize: 16,
                          color: Color(0xFF111827),
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
    );
  }
}
