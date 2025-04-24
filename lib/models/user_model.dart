import 'package:flutter/foundation.dart';

class UserModel {
  final String? id;
  final String? name;
  final String? surname;
  final String? phone;
  final String? email;
  final String? birthDate;
  final String? gender;
  final String? city;
  final double? rating;
  final bool? isVerified;
  final bool isProfileCompleted;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  UserModel({
    this.id,
    this.name,
    this.surname,
    this.phone,
    this.email,
    this.birthDate,
    this.gender,
    this.city,
    this.rating,
    this.isVerified,
    this.isProfileCompleted = false,
    this.createdAt,
    this.updatedAt,
  });

  /// Создание экземпляра из JSON
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      name: json['name'],
      surname: json['surname'],
      phone: json['phone'],
      email: json['email'],
      birthDate: json['birthDate'],
      gender: json['gender'],
      city: json['city'],
      rating: json['rating'] != null ? json['rating'].toDouble() : null,
      isVerified: json['isVerified'] ?? false,
      isProfileCompleted: json['isProfileCompleted'] ?? false,
      createdAt:
          json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt:
          json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  /// Преобразование в JSON для сохранения
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'surname': surname,
      'phone': phone,
      'email': email,
      'birthDate': birthDate,
      'gender': gender,
      'city': city,
      'rating': rating,
      'isVerified': isVerified,
      'isProfileCompleted': isProfileCompleted,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  /// Создание копии с обновленными полями
  UserModel copyWith({
    String? id,
    String? name,
    String? surname,
    String? phone,
    String? email,
    String? birthDate,
    String? gender,
    String? city,
    double? rating,
    bool? isVerified,
    bool? isProfileCompleted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      surname: surname ?? this.surname,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      birthDate: birthDate ?? this.birthDate,
      gender: gender ?? this.gender,
      city: city ?? this.city,
      rating: rating ?? this.rating,
      isVerified: isVerified ?? this.isVerified,
      isProfileCompleted: isProfileCompleted ?? this.isProfileCompleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'UserModel{id: $id, name: $name, surname: $surname, phone: $phone, email: $email}';
  }
}
