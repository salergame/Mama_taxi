import 'package:mama_taxi/screens/home_screen.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

enum TripStatus {
  pending, // Ожидание подтверждения водителем
  confirmed, // Подтверждено водителем
  driverArrived, // Водитель прибыл
  inProgress, // В процессе
  completed, // Завершено
  cancelled // Отменено
}

class TripLocation {
  final double latitude;
  final double longitude;
  final String? address;

  TripLocation({
    required this.latitude,
    required this.longitude,
    this.address,
  });

  LatLng toLatLng() => LatLng(latitude, longitude);

  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
        'address': address,
      };

  factory TripLocation.fromJson(Map<String, dynamic> json) {
    return TripLocation(
      latitude: json['latitude'],
      longitude: json['longitude'],
      address: json['address'],
    );
  }
}

class TripModel {
  final String id;
  final String userId;
  final String? driverId;
  final List<String>? childrenIds;
  final TripLocation origin;
  final TripLocation destination;
  final DateTime scheduledTime;
  final DateTime? startTime;
  final DateTime? endTime;
  final TripStatus status;
  final double price;
  final double? distance;
  final int? duration;
  final String? notes;
  final bool isRecurring;
  final String? recurringId;
  final DateTime createdAt;
  final DateTime updatedAt;

  TripModel({
    required this.id,
    required this.userId,
    this.driverId,
    this.childrenIds,
    required this.origin,
    required this.destination,
    required this.scheduledTime,
    this.startTime,
    this.endTime,
    required this.status,
    required this.price,
    this.distance,
    this.duration,
    this.notes,
    this.isRecurring = false,
    this.recurringId,
    required this.createdAt,
    required this.updatedAt,
  });

  // Фабричный метод для создания демо-поездки
  factory TripModel.demo({
    required String originAddress,
    required String destinationAddress,
    required SimpleLocation originPosition,
    required SimpleLocation destinationPosition,
  }) {
    return TripModel(
      id: 'demo-${DateTime.now().millisecondsSinceEpoch}',
      userId: '',
      driverId: null,
      childrenIds: null,
      origin: TripLocation(
        latitude: originPosition.latitude,
        longitude: originPosition.longitude,
        address: originAddress,
      ),
      destination: TripLocation(
        latitude: destinationPosition.latitude,
        longitude: destinationPosition.longitude,
        address: destinationAddress,
      ),
      scheduledTime: DateTime.now(),
      startTime: null,
      endTime: null,
      status: TripStatus.pending,
      price: 450.0,
      distance: 5.2,
      duration: 15,
      notes: null,
      isRecurring: false,
      recurringId: null,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  TripModel copyWith({
    String? id,
    String? userId,
    String? driverId,
    List<String>? childrenIds,
    TripLocation? origin,
    TripLocation? destination,
    DateTime? scheduledTime,
    DateTime? startTime,
    DateTime? endTime,
    TripStatus? status,
    double? price,
    double? distance,
    int? duration,
    String? notes,
    bool? isRecurring,
    String? recurringId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TripModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      driverId: driverId ?? this.driverId,
      childrenIds: childrenIds ?? this.childrenIds,
      origin: origin ?? this.origin,
      destination: destination ?? this.destination,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      status: status ?? this.status,
      price: price ?? this.price,
      distance: distance ?? this.distance,
      duration: duration ?? this.duration,
      notes: notes ?? this.notes,
      isRecurring: isRecurring ?? this.isRecurring,
      recurringId: recurringId ?? this.recurringId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory TripModel.fromJson(Map<String, dynamic> json) {
    return TripModel(
      id: json['id'],
      userId: json['userId'],
      driverId: json['driverId'],
      childrenIds: json['childrenIds'] != null
          ? List<String>.from(json['childrenIds'])
          : null,
      origin: TripLocation.fromJson(json['origin']),
      destination: TripLocation.fromJson(json['destination']),
      scheduledTime: DateTime.parse(json['scheduledTime']),
      startTime:
          json['startTime'] != null ? DateTime.parse(json['startTime']) : null,
      endTime: json['endTime'] != null ? DateTime.parse(json['endTime']) : null,
      status: TripStatus.values.firstWhere(
          (e) => e.toString().split('.').last == json['status'],
          orElse: () => TripStatus.pending),
      price: json['price'].toDouble(),
      distance: json['distance']?.toDouble(),
      duration: json['duration'],
      notes: json['notes'],
      isRecurring: json['isRecurring'] ?? false,
      recurringId: json['recurringId'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'driverId': driverId,
      'childrenIds': childrenIds,
      'origin': origin.toJson(),
      'destination': destination.toJson(),
      'scheduledTime': scheduledTime.toIso8601String(),
      'startTime': startTime?.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'status': status.toString().split('.').last,
      'price': price,
      'distance': distance,
      'duration': duration,
      'notes': notes,
      'isRecurring': isRecurring,
      'recurringId': recurringId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'TripModel{id: $id, status: $status, origin: ${origin.address}, destination: ${destination.address}}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is TripModel &&
        other.id == id &&
        other.userId == userId &&
        other.driverId == driverId &&
        listEquals(other.childrenIds, childrenIds) &&
        other.origin.latitude == origin.latitude &&
        other.origin.longitude == origin.longitude &&
        other.destination.latitude == destination.latitude &&
        other.destination.longitude == destination.longitude &&
        other.status == status;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        userId.hashCode ^
        driverId.hashCode ^
        childrenIds.hashCode ^
        origin.hashCode ^
        destination.hashCode ^
        status.hashCode;
  }

  // Преобразование статуса в строку для отображения
  String getStatusText() {
    switch (status) {
      case TripStatus.pending:
        return 'Ожидание подтверждения водителем';
      case TripStatus.confirmed:
        return 'Подтверждено водителем';
      case TripStatus.driverArrived:
        return 'Водитель прибыл';
      case TripStatus.inProgress:
        return 'В процессе';
      case TripStatus.completed:
        return 'Завершено';
      case TripStatus.cancelled:
        return 'Отменено';
      default:
        return 'Неизвестный статус';
    }
  }
}
