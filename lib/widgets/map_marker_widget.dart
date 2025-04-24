import 'package:flutter/material.dart';

class MapMarkerWidget extends StatelessWidget {
  final String title;
  final bool isSelected;
  final bool isOrigin;
  final bool isDestination;

  const MapMarkerWidget({
    Key? key,
    required this.title,
    this.isSelected = false,
    this.isOrigin = false,
    this.isDestination = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Цвета в зависимости от типа маркера
    Color markerColor = isOrigin
        ? const Color(0xFF53CFC4) // цвет отправления
        : isDestination
            ? const Color(0xFFFE9671) // цвет назначения
            : const Color(0xFF2D3142); // цвет обычного маркера

    if (isSelected) {
      markerColor = isOrigin
          ? const Color(0xFF53CFC4).withOpacity(0.8)
          : isDestination
              ? const Color(0xFFFE9671).withOpacity(0.8)
              : const Color(0xFF2D3142).withOpacity(0.8);
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Контейнер с текстом (имя места)
        if (isSelected && title.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              title,
              style: const TextStyle(
                color: Color(0xFF1F2937),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        // Стрелка от информационного окна к маркеру
        if (isSelected && title.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 2, bottom: 4),
            width: 10,
            height: 5,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(10),
                bottomRight: Radius.circular(10),
              ),
            ),
          ),
        // Иконка маркера
        Container(
          width: isSelected ? 32 : 24,
          height: isSelected ? 32 : 24,
          decoration: BoxDecoration(
            color: markerColor,
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: markerColor.withOpacity(0.4),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Icon(
              isOrigin
                  ? Icons.my_location
                  : isDestination
                      ? Icons.location_on
                      : Icons.circle,
              color: Colors.white,
              size: isSelected ? 16 : 12,
            ),
          ),
        ),
      ],
    );
  }
}
