import 'package:equatable/equatable.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

// Класс для представления местоположения пользователя
class UserLocation extends Equatable {
  final String address;
  final double latitude;
  final double longitude;

  const UserLocation({
    required this.address,
    required this.latitude,
    required this.longitude,
  });

  // Получение LatLng из UserLocation
  LatLng toLatLng() => LatLng(latitude, longitude);

  // Создание копии с новыми значениями
  UserLocation copyWith({
    String? address,
    double? latitude,
    double? longitude,
  }) {
    return UserLocation(
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }

  // Сериализация в JSON
  Map<String, dynamic> toJson() {
    return {
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  // Десериализация из JSON
  factory UserLocation.fromJson(Map<String, dynamic> json) {
    return UserLocation(
      address: json['address'] as String,
      latitude: json['latitude'] as double,
      longitude: json['longitude'] as double,
    );
  }

  // Преобразование в строку для отладки
  @override
  String toString() =>
      'UserLocation(address: $address, lat: $latitude, lng: $longitude)';

  @override
  List<Object?> get props => [address, latitude, longitude];
}
