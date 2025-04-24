import 'package:flutter/material.dart';
import 'package:mama_taxi/models/loyalty_model.dart';
import 'package:mama_taxi/services/firebase_service.dart';

class LoyaltyProvider with ChangeNotifier {
  LoyaltyModel? _loyaltyModel;
  final FirebaseService _firebaseService = FirebaseService();
  bool _isLoading = false;

  LoyaltyModel? get loyaltyModel => _loyaltyModel;
  bool get isLoading => _isLoading;

  /// Инициализирует данные программы лояльности
  Future<void> initLoyalty() async {
    _isLoading = true;
    notifyListeners();

    // Загрузка данных программы лояльности
    await _loadLoyaltyData();

    _isLoading = false;
    notifyListeners();
  }

  /// Загружает данные программы лояльности
  Future<void> _loadLoyaltyData() async {
    try {
      final loyaltyData = await _firebaseService.getUserLoyaltyData();

      if (loyaltyData != null) {
        // Преобразование данных в модель
        final int points = loyaltyData['points'] ?? 0;

        // Получаем все доступные уровни
        final levels = LoyaltyLevel.getLevels();

        // Находим текущий уровень пользователя на основе баллов
        LoyaltyLevel currentLevel = levels.first;

        for (final level in levels) {
          if (points >= level.pointsRequired &&
              level.pointsRequired >= currentLevel.pointsRequired) {
            currentLevel = level;
          }
        }

        // Рассчитываем баллы до следующего уровня
        final currentLevelIndex = levels.indexOf(currentLevel);
        int pointsToNextLevel = 0;

        if (currentLevelIndex < levels.length - 1) {
          final nextLevel = levels[currentLevelIndex + 1];
          pointsToNextLevel = nextLevel.pointsRequired - points;
        }

        // Преобразуем транзакции
        final List<dynamic> transactionsData =
            loyaltyData['transactions'] ?? [];
        final List<LoyaltyTransaction> transactions = transactionsData
            .map<LoyaltyTransaction>((data) => LoyaltyTransaction(
                  id: data['id'],
                  type: data['type'] == 'earned'
                      ? TransactionType.earned
                      : TransactionType.spent,
                  amount: data['amount'],
                  description: data['description'],
                  date: DateTime.parse(data['date']),
                ))
            .toList();

        // Создаем модель лояльности
        _loyaltyModel = LoyaltyModel(
          points: points,
          transactions: transactions,
          levels: levels,
          currentLevel: currentLevel,
          pointsToNextLevel: pointsToNextLevel,
        );
      } else {
        // Если данных нет, используем демо-данные
        _loyaltyModel = LoyaltyModel.demo();
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Ошибка загрузки данных программы лояльности: $e');
      // В случае ошибки используем демо-данные
      _loyaltyModel = LoyaltyModel.demo();
      notifyListeners();
    }
  }

  /// Получает прогресс к следующему уровню (0.0 - 1.0)
  double get progressToNextLevel {
    if (_loyaltyModel == null) return 0.0;

    final currentLevel = _loyaltyModel!.currentLevel;
    final nextLevelIndex = _loyaltyModel!.levels.indexOf(currentLevel) + 1;

    if (nextLevelIndex >= _loyaltyModel!.levels.length) {
      return 1.0; // Максимальный уровень
    }

    final nextLevel = _loyaltyModel!.levels[nextLevelIndex];
    final pointsForNextLevel =
        nextLevel.pointsRequired - currentLevel.pointsRequired;
    final currentProgress = _loyaltyModel!.points - currentLevel.pointsRequired;

    return currentProgress / pointsForNextLevel;
  }

  /// Начисляет баллы за поездку
  Future<void> addPointsForTrip(int points) async {
    if (_loyaltyModel == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      final description = 'Начисление: $points баллов за поездку';

      // Вызываем метод API для начисления баллов
      final success =
          await _firebaseService.addLoyaltyPoints(points, description);

      if (success) {
        // Если успешно, обновляем локальную модель
        final transaction = LoyaltyTransaction(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          type: TransactionType.earned,
          amount: points,
          description: description,
          date: DateTime.now(),
        );

        final newTransactions = [transaction, ..._loyaltyModel!.transactions];
        final newPoints = _loyaltyModel!.points + points;

        // Определяем текущий уровень
        LoyaltyLevel currentLevel = _loyaltyModel!.currentLevel;
        int pointsToNextLevel = _loyaltyModel!.pointsToNextLevel - points;

        // Проверяем, не достиг ли пользователь нового уровня
        for (final level in _loyaltyModel!.levels) {
          if (newPoints >= level.pointsRequired) {
            if (level.pointsRequired > currentLevel.pointsRequired) {
              currentLevel = level;
            }
          }
        }

        // Находим следующий уровень
        final currentLevelIndex = _loyaltyModel!.levels.indexOf(currentLevel);
        if (currentLevelIndex < _loyaltyModel!.levels.length - 1) {
          final nextLevel = _loyaltyModel!.levels[currentLevelIndex + 1];
          pointsToNextLevel = nextLevel.pointsRequired - newPoints;
        } else {
          pointsToNextLevel = 0; // Максимальный уровень
        }

        _loyaltyModel = LoyaltyModel(
          points: newPoints,
          transactions: newTransactions,
          levels: _loyaltyModel!.levels,
          currentLevel: currentLevel,
          pointsToNextLevel: pointsToNextLevel,
        );
      }
    } catch (e) {
      debugPrint('Ошибка начисления баллов: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Списывает баллы за скидку
  Future<void> usePointsForDiscount(int points) async {
    if (_loyaltyModel == null || _loyaltyModel!.points < points) return;

    _isLoading = true;
    notifyListeners();

    try {
      final description = 'Списание: $points баллов за скидку';

      // Вызываем метод API для списания баллов
      final success =
          await _firebaseService.useLoyaltyPoints(points, description);

      if (success) {
        // Если успешно, обновляем локальную модель
        final transaction = LoyaltyTransaction(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          type: TransactionType.spent,
          amount: points,
          description: description,
          date: DateTime.now(),
        );

        final newTransactions = [transaction, ..._loyaltyModel!.transactions];
        final newPoints = _loyaltyModel!.points - points;

        // Определяем текущий уровень
        LoyaltyLevel currentLevel =
            _loyaltyModel!.levels.first; // Базовый уровень

        // Проверяем, какой уровень соответствует текущему количеству баллов
        for (final level in _loyaltyModel!.levels) {
          if (newPoints >= level.pointsRequired) {
            if (level.pointsRequired > currentLevel.pointsRequired) {
              currentLevel = level;
            }
          }
        }

        // Находим следующий уровень
        final currentLevelIndex = _loyaltyModel!.levels.indexOf(currentLevel);
        int pointsToNextLevel = 0;

        if (currentLevelIndex < _loyaltyModel!.levels.length - 1) {
          final nextLevel = _loyaltyModel!.levels[currentLevelIndex + 1];
          pointsToNextLevel = nextLevel.pointsRequired - newPoints;
        }

        _loyaltyModel = LoyaltyModel(
          points: newPoints,
          transactions: newTransactions,
          levels: _loyaltyModel!.levels,
          currentLevel: currentLevel,
          pointsToNextLevel: pointsToNextLevel,
        );
      }
    } catch (e) {
      debugPrint('Ошибка списания баллов: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
