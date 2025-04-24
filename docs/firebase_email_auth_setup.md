# Настройка аутентификации через Email и пароль в Firebase

## Шаг 1: Создание проекта Firebase

1. Перейдите на [Firebase Console](https://console.firebase.google.com/).
2. Нажмите кнопку "Добавить проект".
3. Введите название проекта, например "MamaTaxi".
4. Следуйте инструкциям на экране для создания проекта.

## Шаг 2: Добавление приложения в проект Firebase

### Для Android:

1. В консоли Firebase выберите свой проект.
2. Нажмите на значок Android, чтобы добавить Android-приложение.
3. Введите имя пакета вашего приложения (например, `com.example.mama_taxi`). Это значение должно совпадать со значением `applicationId` в файле `build.gradle` вашего приложения.
4. (По желанию) Введите имя приложения и SHA-1 сертификата подписи.
5. Нажмите "Зарегистрировать приложение".
6. Скачайте файл `google-services.json` и поместите его в директорию `android/app` вашего проекта Flutter.

### Для iOS:

1. В консоли Firebase выберите свой проект.
2. Нажмите на значок iOS, чтобы добавить iOS-приложение.
3. Введите Bundle ID вашего приложения (например, `com.example.mamaTaxi`). Это значение должно совпадать со значением в файле `Info.plist` вашего iOS-приложения.
4. (По желанию) Введите имя приложения.
5. Нажмите "Зарегистрировать приложение".
6. Скачайте файл `GoogleService-Info.plist` и добавьте его в проект Xcode (открыть проект можно командой `open ios/Runner.xcworkspace`).

## Шаг 3: Настройка аутентификации по Email и паролю

1. В консоли Firebase выберите "Authentication" в левом меню.
2. Перейдите на вкладку "Sign-in method".
3. В списке провайдеров найдите "Email/Password".
4. Нажмите на этот провайдер и включите его.
5. Убедитесь, что опция "Email/Password" имеет статус "Enabled".
6. Также вы можете включить опцию "Email link (passwordless sign-in)" для входа без пароля (по ссылке).
7. Нажмите "Сохранить".

## Шаг 4: Настройка Firestore Database

1. В консоли Firebase выберите "Firestore Database" в левом меню.
2. Нажмите "Создать базу данных".
3. Выберите режим запуска ("тестовый режим" для разработки или "режим с правилами" для продакшена).
4. Выберите регион для размещения базы данных (ближайший к вашим пользователям).
5. Нажмите "Включить".

### Правила безопасности для Firestore

Настройте правила безопасности для вашей базы данных:

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Пользователь может прочитать/записать свои данные
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Правила для других коллекций
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

## Шаг 5: Настройка проекта Flutter

1. Добавьте необходимые зависимости в файл `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  firebase_core: ^2.15.0
  firebase_auth: ^4.7.2
  cloud_firestore: ^4.8.4
  shared_preferences: ^2.2.0
```

2. Обновите зависимости:

```bash
flutter pub get
```

## Шаг 6: Инициализация Firebase в приложении

Убедитесь, что в файле `main.dart` у вас есть инициализация Firebase:

```dart
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(MyApp());
}
```

## Шаг 7: Тестирование аутентификации

1. Создайте нескольких тестовых пользователей:
   - В консоли Firebase перейдите в "Authentication" > "Users".
   - Нажмите "Add User" и введите email и пароль для тестового пользователя.

2. Проверьте функции аутентификации в вашем приложении:
   - Регистрация нового пользователя
   - Вход по email и паролю
   - Сброс пароля
   - Выход из системы

## Шаг 8: Отладка

Если возникают проблемы:

1. Проверьте логи в Firebase Console (Functions > Logs).
2. Проверьте консоль разработчика в приложении Flutter.
3. Убедитесь, что у вас правильно настроены SHA-1 сертификаты (для Android).
4. Проверьте правила безопасности в Firestore Database.

## Шаг 9: Дополнительные настройки (по необходимости)

### Верификация email

Чтобы включить верификацию email:

1. В Firebase Console перейдите в Authentication > Templates > Email verification.
2. Настройте шаблон email для верификации.
3. В вашем коде после регистрации нового пользователя:

```dart
await FirebaseAuth.instance.currentUser?.sendEmailVerification();
```

### Сброс пароля

Чтобы включить сброс пароля:

1. В Firebase Console перейдите в Authentication > Templates > Password reset.
2. Настройте шаблон email для сброса пароля.
3. В вашем коде для отправки сброса пароля:

```dart
await FirebaseAuth.instance.sendPasswordResetEmail(email: 'user@example.com');
```

## Полезные ссылки

- [Документация по Firebase Authentication](https://firebase.google.com/docs/auth)
- [FlutterFire Authentication](https://firebase.flutter.dev/docs/auth/overview)
- [Firebase Firestore](https://firebase.google.com/docs/firestore)
- [FlutterFire Firestore](https://firebase.flutter.dev/docs/firestore/overview) 