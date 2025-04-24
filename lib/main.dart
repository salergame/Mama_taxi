import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:mama_taxi/providers/user_provider.dart';
import 'package:mama_taxi/providers/payment_provider.dart';
import 'package:mama_taxi/screens/driver/driver_home_screen.dart';
import 'package:mama_taxi/screens/driver/auth_screen.dart' as driver;
import 'package:mama_taxi/screens/client/auth_screen.dart';
import 'package:mama_taxi/screens/profile_edit_screen.dart';
import 'package:mama_taxi/screens/client/home_screen.dart' as client;
import 'package:mama_taxi/screens/driver/verification_screen.dart'
    as driver_docs;
import 'package:mama_taxi/services/firebase_service.dart';
import 'package:mama_taxi/services/map_service.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Инициализация SharedPreferences для хранения данных
  await SharedPreferences.getInstance();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => PaymentProvider()),
        ChangeNotifierProvider(create: (_) => MapService()),
      ],
      child: MaterialApp(
        title: 'Mama Taxi',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          primaryColor: const Color(0xFFF654AA), // Для клиентов
          colorScheme: ColorScheme.fromSwatch().copyWith(
            secondary: const Color(0xFF53CFC4), // Для водителей
          ),
          fontFamily: 'Roboto',
        ),
        home: const InitScreen(),
        routes: {
          '/auth': (context) => const ClientAuthScreen(),
          '/auth_driver': (context) => const driver.DriverAuthScreen(),
          '/home': (context) => const client.HomeScreen(),
          '/driver_home': (context) => const DriverHomeScreen(),
          '/profile_edit': (context) => const ProfileEditScreen(),
          '/driver_documents': (context) =>
              const driver_docs.VerificationScreen(),
          '/payment': (context) =>
              const PlaceholderScreen(title: 'Оплата и счета'),
          '/settings': (context) => const PlaceholderScreen(title: 'Настройки'),
          '/support': (context) =>
              const PlaceholderScreen(title: 'Поддержка и помощь'),
          '/loyalty': (context) =>
              const PlaceholderScreen(title: 'Программа лояльности'),
        },
      ),
    );
  }
}

class InitScreen extends StatefulWidget {
  const InitScreen({Key? key}) : super(key: key);

  @override
  State<InitScreen> createState() => _InitScreenState();
}

class _InitScreenState extends State<InitScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    try {
      // Проверяем, авторизован ли пользователь
      final prefs = await SharedPreferences.getInstance();
      final isAuthenticated = prefs.getBool('isAuthenticated') ?? false;
      final isDriver = prefs.getBool('isDriver') ?? false;

      if (isAuthenticated) {
        if (isDriver) {
          // Если пользователь - водитель
          Navigator.of(context).pushReplacementNamed('/driver_home');
        } else {
          // Если пользователь - клиент
          Navigator.of(context).pushReplacementNamed('/home');
        }
      } else {
        // Если пользователь не авторизован
        Navigator.of(context).pushReplacementNamed('/auth');
      }
    } catch (e) {
      // В случае ошибки перенаправляем на страницу авторизации
      Navigator.of(context).pushReplacementNamed('/auth');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _isLoading
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Лого приложения
                  Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(75),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.3),
                          spreadRadius: 2,
                          blurRadius: 5,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(75),
                      child: Image.asset(
                        'assets/images/logo.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  const CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Color(0xFFF654AA)),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Загрузка...',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF4B5563),
                    ),
                  ),
                ],
              )
            : Container(),
      ),
    );
  }
}

// Простой экран-заглушка для недостающих экранов
class PlaceholderScreen extends StatelessWidget {
  final String title;

  const PlaceholderScreen({Key? key, required this.title}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: const Color(0xFF53CFC4),
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.construction,
              size: 80,
              color: Color(0xFF53CFC4),
            ),
            const SizedBox(height: 20),
            Text(
              'Экран "$title" находится в разработке',
              style: const TextStyle(
                fontSize: 20,
                fontFamily: 'Rubik',
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            const Text(
              'Данный раздел будет доступен в ближайшее время',
              style: TextStyle(
                fontSize: 16,
                fontFamily: 'Rubik',
                color: Color(0xFF6B7280),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF53CFC4),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Вернуться назад'),
            ),
          ],
        ),
      ),
    );
  }
}
