import 'package:flutter/material.dart';
import 'package:mama_taxi/screens/auth_screen.dart';
import 'package:mama_taxi/screens/home_screen.dart';
import 'package:mama_taxi/services/map_service.dart';
import 'package:mama_taxi/providers/trip_provider.dart';
import 'package:provider/provider.dart';
import 'package:mama_taxi/screens/driver_auth_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Отключаем проверку типа провайдера
  Provider.debugCheckInvalidValueType = null;

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<MapService>(
          create: (_) => MapService(),
        ),
        ChangeNotifierProxyProvider<MapService, TripProvider>(
          create: (context) =>
              TripProvider(Provider.of<MapService>(context, listen: false)),
          update: (context, mapService, previous) =>
              previous ?? TripProvider(mapService),
        ),
      ],
      child: MaterialApp(
        title: 'Мама Такси',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          fontFamily: 'Nunito',
          scaffoldBackgroundColor: Colors.white,
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            elevation: 0,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF654AA),
              foregroundColor: Colors.white,
              textStyle: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 16,
                fontWeight: FontWeight.w400,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: const Color(0xFFF9FAFB),
            hintStyle: const TextStyle(
              fontFamily: 'Nunito',
              fontSize: 16,
              color: Color(0xFFADAEBC),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: Color(0xFFFFABBA),
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: Color(0xFFFFABBA),
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: Color(0xFFFFABBA),
                width: 1,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 13,
              vertical: 13,
            ),
          ),
          textTheme: const TextTheme(
            headlineMedium: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 20,
              fontWeight: FontWeight.w400,
              color: Color(0xFF1F2937),
            ),
            bodyLarge: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 16,
              color: Color(0xFF6B7280),
            ),
            bodyMedium: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 14,
              color: Color(0xFF4B5563),
            ),
          ),
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF4FD8C4),
            primary: const Color(0xFF4FD8C4),
            secondary: const Color(0xFFF654AA),
            surface: Colors.white,
            background: Colors.white,
          ),
          useMaterial3: true,
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => const AuthScreen(),
          '/home': (context) => const HomeScreen(),
          '/driver_auth': (context) => const DriverAuthScreen(),
        },
      ),
    );
  }
}
