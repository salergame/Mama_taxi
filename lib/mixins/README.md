# Миксины

## AuthCheckerMixin

Миксин для проверки авторизации пользователя. Используется для экранов, которые требуют авторизации.

### Использование

1. Импортировать миксин:
```dart
import 'package:mama_taxi/mixins/auth_checker_mixin.dart';
```

2. Добавить миксин к классу состояния экрана:
```dart
class _YourScreenState extends State<YourScreen> with AuthCheckerMixin {
  // ...
}
```

3. Вызвать метод `checkAuth()` в методе `initState`:
```dart
@override
void initState() {
  super.initState();
  checkAuth().then((isAuthenticated) {
    if (isAuthenticated) {
      // Пользователь авторизован, можно загружать данные
      _loadData();
    }
  });
}
```

### Пример

```dart
import 'package:flutter/material.dart';
import 'package:mama_taxi/mixins/auth_checker_mixin.dart';

class SecureScreen extends StatefulWidget {
  const SecureScreen({Key? key}) : super(key: key);

  @override
  State<SecureScreen> createState() => _SecureScreenState();
}

class _SecureScreenState extends State<SecureScreen> with AuthCheckerMixin {
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _init();
  }
  
  Future<void> _init() async {
    final isAuthenticated = await checkAuth();
    if (isAuthenticated) {
      // Пользователь авторизован, загружаем данные
      await _loadData();
    }
  }

  Future<void> _loadData() async {
    // Загрузка данных...
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Защищенный экран')),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : const Center(child: Text('Доступ разрешен')),
    );
  }
} 