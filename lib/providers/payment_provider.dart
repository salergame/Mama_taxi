import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:uuid/uuid.dart';
import '../models/payment_model.dart';

class PaymentProvider extends ChangeNotifier {
  List<PaymentMethod> _paymentMethods = [];
  List<PaymentTransaction> _transactions = [];
  bool _isLoading = false;
  String? _error;

  List<PaymentMethod> get paymentMethods => _paymentMethods;
  List<PaymentTransaction> get transactions => _transactions;
  bool get isLoading => _isLoading;
  String? get error => _error;

  PaymentProvider() {
    loadPaymentData();
  }

  Future<void> loadPaymentData() async {
    _setLoading(true);
    try {
      await _loadPaymentMethods();
      await _loadTransactions();
      _setError(null);
    } catch (e) {
      _setError('Ошибка загрузки платежных данных: $e');
    }
    _setLoading(false);
  }

  Future<void> _loadPaymentMethods() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('payment_methods');

    if (data != null) {
      final List<dynamic> jsonList = json.decode(data);
      _paymentMethods =
          jsonList.map((json) => PaymentMethod.fromJson(json)).toList();
    } else {
      _paymentMethods = [];
    }
  }

  Future<void> _loadTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('payment_transactions');

    if (data != null) {
      final List<dynamic> jsonList = json.decode(data);
      _transactions =
          jsonList.map((json) => PaymentTransaction.fromJson(json)).toList();
    } else {
      _transactions = [];
    }
  }

  Future<void> addPaymentMethod(PaymentMethod paymentMethod) async {
    _setLoading(true);
    try {
      // Если новый метод задан как дефолтный, то убираем дефолтный статус с других методов
      if (paymentMethod.isDefault) {
        _paymentMethods = _paymentMethods
            .map((method) => method.copyWith(isDefault: false))
            .toList();
      }

      // Генерируем ID если он не был предоставлен
      final newMethod = paymentMethod.id.isEmpty
          ? paymentMethod.copyWith(id: const Uuid().v4())
          : paymentMethod;

      _paymentMethods.add(newMethod);
      await _savePaymentMethods();
      _setError(null);
    } catch (e) {
      _setError('Ошибка добавления способа оплаты: $e');
    }
    _setLoading(false);
  }

  Future<void> removePaymentMethod(String id) async {
    _setLoading(true);
    try {
      _paymentMethods.removeWhere((method) => method.id == id);

      // Если удалили дефолтный метод и есть другие методы, устанавливаем первый как дефолтный
      if (_paymentMethods.isNotEmpty &&
          !_paymentMethods.any((method) => method.isDefault)) {
        _paymentMethods[0] = _paymentMethods[0].copyWith(isDefault: true);
      }

      await _savePaymentMethods();
      _setError(null);
    } catch (e) {
      _setError('Ошибка удаления способа оплаты: $e');
    }
    _setLoading(false);
  }

  Future<void> setDefaultPaymentMethod(String id) async {
    _setLoading(true);
    try {
      _paymentMethods = _paymentMethods
          .map((method) => method.copyWith(isDefault: method.id == id))
          .toList();

      await _savePaymentMethods();
      _setError(null);
    } catch (e) {
      _setError('Ошибка установки способа оплаты по умолчанию: $e');
    }
    _setLoading(false);
  }

  Future<void> addTransaction(PaymentTransaction transaction) async {
    _setLoading(true);
    try {
      // Генерируем ID если он не был предоставлен
      final newTransaction = transaction.id.isEmpty
          ? transaction.copyWith(id: const Uuid().v4())
          : transaction;

      _transactions.add(newTransaction);
      await _saveTransactions();
      _setError(null);
    } catch (e) {
      _setError('Ошибка добавления транзакции: $e');
    }
    _setLoading(false);
  }

  Future<void> _savePaymentMethods() async {
    final prefs = await SharedPreferences.getInstance();
    final data =
        json.encode(_paymentMethods.map((method) => method.toJson()).toList());
    await prefs.setString('payment_methods', data);
    notifyListeners();
  }

  Future<void> _saveTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    final data = json.encode(
        _transactions.map((transaction) => transaction.toJson()).toList());
    await prefs.setString('payment_transactions', data);
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? errorMessage) {
    _error = errorMessage;
    notifyListeners();
  }

  // Получение способа оплаты по умолчанию
  PaymentMethod? getDefaultPaymentMethod() {
    try {
      return _paymentMethods.firstWhere(
        (method) => method.isDefault,
        orElse: () => _paymentMethods.isNotEmpty
            ? _paymentMethods.first
            : throw Exception(),
      );
    } catch (_) {
      return null;
    }
  }

  // Очистка данных (для логаута)
  Future<void> clearPaymentData() async {
    _setLoading(true);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('payment_methods');
      await prefs.remove('payment_transactions');
      _paymentMethods = [];
      _transactions = [];
      _setError(null);
    } catch (e) {
      _setError('Ошибка очистки платежных данных: $e');
    }
    _setLoading(false);
  }
}
 