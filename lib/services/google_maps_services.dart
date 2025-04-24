import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class GoogleMapsServices {
  Future<String> getRouteCoordinates(LatLng origin, LatLng destination) async {
    String url =
        "https://maps.googleapis.com/maps/api/directions/json?origin=${origin.latitude},${origin.longitude}&destination=${destination.latitude},${destination.longitude}&key=AIzaSyAPbtO3t20UTgn_9L87YLHiBnOoMtZJ3YY";

    http.Response response = await http.get(Uri.parse(url));
    Map<String, dynamic> values = jsonDecode(response.body);

    return values["routes"][0]["overview_polyline"]["points"];
  }
}
