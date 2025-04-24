import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PaymentMethod {
  final String id;
  final String type; // card, cash, etc.
  final String last4;
  final String brand;
  final bool isDefault;
  final String? cardHolderName;
  final String? expiryDate;

  const PaymentMethod({
    required this.id,
    required this.type,
    required this.last4,
    required this.brand,
    this.isDefault = false,
    this.cardHolderName,
    this.expiryDate,
  });

  PaymentMethod copyWith({
    String? id,
    String? type,
    String? last4,
    String? brand,
    bool? isDefault,
    String? cardHolderName,
    String? expiryDate,
  }) {
    return PaymentMethod(
      id: id ?? this.id,
      type: type ?? this.type,
      last4: last4 ?? this.last4,
      brand: brand ?? this.brand,
      isDefault: isDefault ?? this.isDefault,
      cardHolderName: cardHolderName ?? this.cardHolderName,
      expiryDate: expiryDate ?? this.expiryDate,
    );
  }

  factory PaymentMethod.fromJson(Map<String, dynamic> json) {
    return PaymentMethod(
      id: json['id'] ?? '',
      type: json['type'] ?? '',
      last4: json['last4'] ?? '',
      brand: json['brand'] ?? '',
      isDefault: json['isDefault'] ?? false,
      cardHolderName: json['cardHolderName'],
      expiryDate: json['expiryDate'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'last4': last4,
      'brand': brand,
      'isDefault': isDefault,
      'cardHolderName': cardHolderName,
      'expiryDate': expiryDate,
    };
  }

  String getCardIcon() {
    switch (brand.toLowerCase()) {
      case 'visa':
        return 'assets/icons/visa.png';
      case 'mastercard':
        return 'assets/icons/mastercard.png';
      case 'mir':
        return 'assets/icons/mir.png';
      default:
        return 'assets/icons/card.png';
    }
  }

  Color getCardColor() {
    switch (brand.toLowerCase()) {
      case 'visa':
        return Colors.blue.shade800;
      case 'mastercard':
        return Colors.orange.shade700;
      case 'mir':
        return Colors.green.shade700;
      default:
        return Colors.grey.shade700;
    }
  }
}

class PaymentTransaction {
  final String id;
  final DateTime date;
  final double amount;
  final String status; // completed, pending, failed
  final String destination;
  final String? paymentMethodId;
  final String? description;

  const PaymentTransaction({
    required this.id,
    required this.date,
    required this.amount,
    required this.status,
    required this.destination,
    this.paymentMethodId,
    this.description,
  });

  PaymentTransaction copyWith({
    String? id,
    DateTime? date,
    double? amount,
    String? status,
    String? destination,
    String? paymentMethodId,
    String? description,
  }) {
    return PaymentTransaction(
      id: id ?? this.id,
      date: date ?? this.date,
      amount: amount ?? this.amount,
      status: status ?? this.status,
      destination: destination ?? this.destination,
      paymentMethodId: paymentMethodId ?? this.paymentMethodId,
      description: description ?? this.description,
    );
  }

  factory PaymentTransaction.fromJson(Map<String, dynamic> json) {
    return PaymentTransaction(
      id: json['id'] ?? '',
      date:
          json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
      amount: json['amount']?.toDouble() ?? 0.0,
      status: json['status'] ?? 'completed',
      destination: json['destination'] ?? '',
      paymentMethodId: json['paymentMethodId'],
      description: json['description'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'amount': amount,
      'status': status,
      'destination': destination,
      'paymentMethodId': paymentMethodId,
      'description': description,
    };
  }

  String getFormattedDate() {
    return DateFormat('dd.MM.yyyy HH:mm').format(date);
  }

  String getFormattedAmount() {
    return '${amount.toStringAsFixed(2)} ₽';
  }

  Color getStatusColor() {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'failed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData getStatusIcon() {
    switch (status.toLowerCase()) {
      case 'completed':
        return Icons.check_circle;
      case 'pending':
        return Icons.access_time;
      case 'failed':
        return Icons.error;
      default:
        return Icons.info;
    }
  }
}
