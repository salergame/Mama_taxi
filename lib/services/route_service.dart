import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';
import 'package:mama_taxi/screens/home_screen.dart';
import 'package:dio/dio.dart';

class RouteService {
  final Dio _dio = Dio();

  // Метод для получения маршрута между двумя точками
  Future<List<LatLng>> getRoute(
    SimpleLocation start,
    SimpleLocation destination,
  ) async {
    print(
        "Запрашиваем маршрут от ${start.latitude},${start.longitude} до ${destination.latitude},${destination.longitude}");

    try {
      List<LatLng> route = await _getRouteWithGoogleAPI(start, destination);
      print("Получен маршрут с ${route.length} точками через Google API");
      return route;
    } catch (e) {
      print('Ошибка получения маршрута через Google API: $e');

      // Возвращаем прямую линию в случае ошибки
      print("Создаем прямую линию между точками");
      return [
        LatLng(start.latitude, start.longitude),
        LatLng(destination.latitude, destination.longitude),
      ];
    }
  }

  // Получение маршрута с помощью Google Directions API
  Future<List<LatLng>> _getRouteWithGoogleAPI(
    SimpleLocation start,
    SimpleLocation destination,
  ) async {
    const apiKey =
        'AIzaSyAPbtO3t20UTgn_9L87YLHiBnOoMtZJ3YY'; // Замените на ваш ключ

    // URL для запроса
    final String url =
        'https://maps.googleapis.com/maps/api/directions/json?origin=${start.latitude},${start.longitude}&destination=${destination.latitude},${destination.longitude}&region=ru&language=ru&key=$apiKey';

    print("URL запроса: $url");

    try {
      // Выполняем запрос через http вместо dio для надежности
      final response = await http.get(Uri.parse(url));

      print("Статус ответа: ${response.statusCode}");

      // Проверяем статус ответа
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print("Статус API: ${data['status']}");

        if (data['status'] == 'OK') {
          // Получаем точки маршрута из ответа
          final List<LatLng> points = [];
          final routes = data['routes'] as List;

          if (routes.isNotEmpty) {
            print("Получены данные маршрута");

            // Получаем информацию о маршруте
            final legs = routes[0]['legs'] as List;
            if (legs.isNotEmpty) {
              final String distance = legs[0]['distance']['text'];
              final String duration = legs[0]['duration']['text'];
              print("Расстояние: $distance, время в пути: $duration");
            }

            // Получаем закодированную полилинию
            final String encodedPolyline =
                routes[0]['overview_polyline']['points'];
            print(
                "Закодированная полилиния: ${encodedPolyline.substring(0, min(50, encodedPolyline.length))}...");

            // Декодируем полилинию
            final List<LatLng> decodedPoints = _decodePoly(encodedPolyline);
            print("Декодировано ${decodedPoints.length} точек");

            return decodedPoints;
          } else {
            print("Нет маршрутов в ответе");
          }
        } else {
          print(
              "Ошибка API: ${data['status']} - ${data['error_message'] ?? 'Нет описания ошибки'}");
        }
      }

      // Если что-то пошло не так или маршрут не найден, возвращаем пустой список
      throw Exception('Не удалось получить маршрут с Google API');
    } catch (e) {
      print("Исключение при запросе: $e");
      throw e;
    }
  }

  // Улучшенная функция декодирования полилинии
  List<LatLng> _decodePoly(String encoded) {
    List<LatLng> poly = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    try {
      while (index < len) {
        int b, shift = 0, result = 0;
        do {
          b = encoded.codeUnitAt(index++) - 63;
          result |= (b & 0x1f) << shift;
          shift += 5;
        } while (b >= 0x20);
        int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
        lat += dlat;

        shift = 0;
        result = 0;
        do {
          b = encoded.codeUnitAt(index++) - 63;
          result |= (b & 0x1f) << shift;
          shift += 5;
        } while (b >= 0x20);
        int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
        lng += dlng;

        final p = LatLng(lat / 1E5, lng / 1E5);
        poly.add(p);
      }
    } catch (e) {
      print("Ошибка декодирования полилинии: $e");
    }

    return poly;
  }

  // Расчет примерного времени в пути (в минутах)
  Future<int> getEstimatedDuration(
      SimpleLocation start, SimpleLocation destination) async {
    try {
      // Получаем расстояние в километрах
      final double distance = getDistance(start, destination);

      // Средняя скорость 30 км/ч = 0.5 км/мин
      return (distance / 0.5).round();
    } catch (e) {
      print('Error getting duration: $e');

      // В случае ошибки возвращаем примерную оценку по прямой
      final double distance = _calculateHaversineDistance(
        start.latitude,
        start.longitude,
        destination.latitude,
        destination.longitude,
      );

      // Средняя скорость 30 км/ч = 0.5 км/мин
      return (distance / 0.5).round();
    }
  }

  // Расчет расстояния в километрах
  double getDistance(SimpleLocation start, SimpleLocation destination) {
    return _calculateHaversineDistance(
      start.latitude,
      start.longitude,
      destination.latitude,
      destination.longitude,
    );
  }

  // Вычисление расстояния между координатами с использованием формулы гаверсинуса
  double _calculateHaversineDistance(
      double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // Радиус Земли в км
    final double dLat = _degreesToRadians(lat2 - lat1);
    final double dLon = _degreesToRadians(lon2 - lon1);

    final double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) *
            cos(_degreesToRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  // Вспомогательные методы для вычисления расстояния
  double _degreesToRadians(double degrees) {
    return degrees * (pi / 180);
  }
}
