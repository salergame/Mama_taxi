import 'package:google_maps_flutter/google_maps_flutter.dart';

enum TripStatus {
  searching, // Поиск автомобиля
  confirmed, // Автомобиль подтвержден и направляется к точке отправления
  arriving, // Автомобиль приближается к точке отправления
  waiting, // Автомобиль ожидает клиента
  inProgress, // Поездка в процессе
  completed, // Поездка завершена
  cancelled // Поездка отменена
}

class TripModel {
  final String id;
  final String originAddress;
  final String destinationAddress;
  final LatLng? originPosition;
  final LatLng? destinationPosition;
  final String tariffName;
  final double price;
  final String distance;
  final String duration;
  final String? driverName;
  final String? driverPhone;
  final String? carInfo;
  final String? carPlate;
  final TripStatus status;
  final DateTime createdAt;
  final DateTime? estimatedArrival;

  TripModel({
    required this.id,
    required this.originAddress,
    required this.destinationAddress,
    this.originPosition,
    this.destinationPosition,
    required this.tariffName,
    required this.price,
    required this.distance,
    required this.duration,
    this.driverName,
    this.driverPhone,
    this.carInfo,
    this.carPlate,
    required this.status,
    DateTime? createdAt,
    this.estimatedArrival,
  }) : this.createdAt = createdAt ?? DateTime.now();

  // Создание копии с измененными свойствами
  TripModel copyWith({
    String? id,
    String? originAddress,
    String? destinationAddress,
    LatLng? originPosition,
    LatLng? destinationPosition,
    String? tariffName,
    double? price,
    String? distance,
    String? duration,
    String? driverName,
    String? driverPhone,
    String? carInfo,
    String? carPlate,
    TripStatus? status,
    DateTime? createdAt,
    DateTime? estimatedArrival,
  }) {
    return TripModel(
      id: id ?? this.id,
      originAddress: originAddress ?? this.originAddress,
      destinationAddress: destinationAddress ?? this.destinationAddress,
      originPosition: originPosition ?? this.originPosition,
      destinationPosition: destinationPosition ?? this.destinationPosition,
      tariffName: tariffName ?? this.tariffName,
      price: price ?? this.price,
      distance: distance ?? this.distance,
      duration: duration ?? this.duration,
      driverName: driverName ?? this.driverName,
      driverPhone: driverPhone ?? this.driverPhone,
      carInfo: carInfo ?? this.carInfo,
      carPlate: carPlate ?? this.carPlate,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      estimatedArrival: estimatedArrival ?? this.estimatedArrival,
    );
  }

  // Фабричный метод для создания демо-поездки
  factory TripModel.demo({
    required String originAddress,
    required String destinationAddress,
    required LatLng originPosition,
    required LatLng destinationPosition,
  }) {
    return TripModel(
      id: 'demo-${DateTime.now().millisecondsSinceEpoch}',
      originAddress: originAddress,
      destinationAddress: destinationAddress,
      originPosition: originPosition,
      destinationPosition: destinationPosition,
      tariffName: 'Мама такси',
      price: 450,
      distance: '2.5 км',
      duration: '10 мин',
      driverName: 'Алексей',
      driverPhone: '+7 (999) 123-45-67',
      carInfo: 'Tesla Model Y',
      carPlate: 'А123БВ77',
      status: TripStatus.inProgress,
      createdAt: DateTime.now(),
      estimatedArrival: DateTime.now().add(const Duration(minutes: 3)),
    );
  }

  // Преобразование статуса в строку для отображения
  String getStatusText() {
    switch (status) {
      case TripStatus.searching:
        return 'Поиск автомобиля';
      case TripStatus.confirmed:
        return 'Автомобиль найден';
      case TripStatus.arriving:
        return 'Водитель в пути';
      case TripStatus.waiting:
        return 'Водитель ожидает';
      case TripStatus.inProgress:
        return 'Поездка в процессе';
      case TripStatus.completed:
        return 'Поездка завершена';
      case TripStatus.cancelled:
        return 'Поездка отменена';
      default:
        return 'Неизвестный статус';
    }
  }
}
