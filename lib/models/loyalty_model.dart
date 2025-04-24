class LoyaltyModel {
  final int points;
  final List<LoyaltyTransaction> transactions;
  final List<LoyaltyLevel> levels;
  final LoyaltyLevel currentLevel;
  final int pointsToNextLevel;

  LoyaltyModel({
    required this.points,
    required this.transactions,
    required this.levels,
    required this.currentLevel,
    required this.pointsToNextLevel,
  });

  factory LoyaltyModel.demo() {
    final levels = [
      LoyaltyLevel(
        id: '1',
        name: 'Базовый',
        pointsRequired: 0,
        discount: 0,
        icon: 'assets/images/loyalty/basic.png',
      ),
      LoyaltyLevel(
        id: '2',
        name: 'Серебряный',
        pointsRequired: 5000,
        discount: 10,
        icon: 'assets/images/loyalty/silver.png',
      ),
      LoyaltyLevel(
        id: '3',
        name: 'Золотой',
        pointsRequired: 10000,
        discount: 15,
        icon: 'assets/images/loyalty/gold.png',
      ),
      LoyaltyLevel(
        id: '4',
        name: 'Платиновый',
        pointsRequired: 20000,
        benefits: 'Бесплатная поездка',
        icon: 'assets/images/loyalty/platinum.png',
      ),
    ];

    final transactions = [
      LoyaltyTransaction(
        id: '1',
        type: TransactionType.earned,
        amount: 120,
        description: 'Начисление: 100 баллов за поездку',
        date: DateTime.now().subtract(const Duration(days: 3)),
      ),
      LoyaltyTransaction(
        id: '2',
        type: TransactionType.earned,
        amount: 20,
        description: 'Начисление: 20 баллов за приглашенного друга',
        date: DateTime.now().subtract(const Duration(days: 15)),
      ),
      LoyaltyTransaction(
        id: '3',
        type: TransactionType.spent,
        amount: 20,
        description: 'Списание: 20 баллов за заказ',
        date: DateTime.now().subtract(const Duration(days: 30)),
      ),
    ];

    final currentLevel = levels[0]; // Базовый уровень
    final currentPoints = 120;
    final nextLevel = levels[1]; // Серебряный
    final pointsToNextLevel = nextLevel.pointsRequired - currentPoints;

    return LoyaltyModel(
      points: currentPoints,
      transactions: transactions,
      levels: levels,
      currentLevel: currentLevel,
      pointsToNextLevel: pointsToNextLevel,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'points': points,
      'transactions': transactions.map((t) => t.toJson()).toList(),
      'levels': levels.map((l) => l.toJson()).toList(),
      'currentLevel': currentLevel.toJson(),
      'pointsToNextLevel': pointsToNextLevel,
    };
  }

  factory LoyaltyModel.fromJson(Map<String, dynamic> json) {
    return LoyaltyModel(
      points: json['points'] ?? 0,
      transactions: (json['transactions'] as List?)
              ?.map((t) => LoyaltyTransaction.fromJson(t))
              .toList() ??
          [],
      levels: (json['levels'] as List?)
              ?.map((l) => LoyaltyLevel.fromJson(l))
              .toList() ??
          [],
      currentLevel: json['currentLevel'] != null
          ? LoyaltyLevel.fromJson(json['currentLevel'])
          : LoyaltyLevel(
              id: '1',
              name: 'Базовый',
              pointsRequired: 0,
              discount: 0,
              icon: 'assets/images/loyalty/basic.png',
            ),
      pointsToNextLevel: json['pointsToNextLevel'] ?? 5000,
    );
  }
}

class LoyaltyLevel {
  final String id;
  final String name;
  final int pointsRequired;
  final int discount;
  final String? benefits;
  final String icon;

  LoyaltyLevel({
    required this.id,
    required this.name,
    required this.pointsRequired,
    this.discount = 0,
    this.benefits,
    required this.icon,
  });

  /// Возвращает список всех доступных уровней лояльности
  static List<LoyaltyLevel> getLevels() {
    return [
      LoyaltyLevel(
        id: '1',
        name: 'Базовый',
        pointsRequired: 0,
        discount: 0,
        icon: 'assets/images/loyalty/basic.png',
      ),
      LoyaltyLevel(
        id: '2',
        name: 'Серебряный',
        pointsRequired: 5000,
        discount: 10,
        icon: 'assets/images/loyalty/silver.png',
      ),
      LoyaltyLevel(
        id: '3',
        name: 'Золотой',
        pointsRequired: 10000,
        discount: 15,
        icon: 'assets/images/loyalty/gold.png',
      ),
      LoyaltyLevel(
        id: '4',
        name: 'Платиновый',
        pointsRequired: 20000,
        benefits: 'Бесплатная поездка',
        icon: 'assets/images/loyalty/platinum.png',
      ),
    ];
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'pointsRequired': pointsRequired,
      'discount': discount,
      'benefits': benefits,
      'icon': icon,
    };
  }

  factory LoyaltyLevel.fromJson(Map<String, dynamic> json) {
    return LoyaltyLevel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      pointsRequired: json['pointsRequired'] ?? 0,
      discount: json['discount'] ?? 0,
      benefits: json['benefits'],
      icon: json['icon'] ?? '',
    );
  }
}

enum TransactionType { earned, spent }

class LoyaltyTransaction {
  final String id;
  final TransactionType type;
  final int amount;
  final String description;
  final DateTime date;

  LoyaltyTransaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.description,
    required this.date,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.toString(),
      'amount': amount,
      'description': description,
      'date': date.toIso8601String(),
    };
  }

  factory LoyaltyTransaction.fromJson(Map<String, dynamic> json) {
    return LoyaltyTransaction(
      id: json['id'] ?? '',
      type: json['type'] == 'TransactionType.earned'
          ? TransactionType.earned
          : TransactionType.spent,
      amount: json['amount'] ?? 0,
      description: json['description'] ?? '',
      date:
          json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
    );
  }
}
