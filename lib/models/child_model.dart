import 'package:cloud_firestore/cloud_firestore.dart';

class ChildModel {
  final String? id;
  final String userId;
  final String name;
  final String age;
  final String notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ChildModel({
    this.id,
    required this.userId,
    required this.name,
    required this.age,
    this.notes = '',
    this.createdAt,
    this.updatedAt,
  });

  // Создание объекта из JSON
  factory ChildModel.fromJson(Map<String, dynamic> json) {
    return ChildModel(
      id: json['id'],
      userId: json['user_id'] ?? '',
      name: json['name'] ?? '',
      age: json['age'] ?? '',
      notes: json['notes'] ?? '',
      createdAt: (json['created_at'] is Timestamp)
          ? (json['created_at'] as Timestamp).toDate()
          : json['created_at'] != null
              ? DateTime.parse(json['created_at'])
              : null,
      updatedAt: (json['updated_at'] is Timestamp)
          ? (json['updated_at'] as Timestamp).toDate()
          : json['updated_at'] != null
              ? DateTime.parse(json['updated_at'])
              : null,
    );
  }

  // Преобразование в JSON для сохранения
  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'name': name,
      'age': age,
      'notes': notes,
    };
  }

  // Создание копии объекта с новыми полями
  ChildModel copyWith({
    String? id,
    String? userId,
    String? name,
    String? age,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ChildModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      age: age ?? this.age,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
