// ============================================
// Location Service — Geocoding & Routing (Free APIs)
// ============================================

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

class LocationService {
  // Nominatim Search URL (OpenStreetMap Geocoding)
  static const String _nominatimUrl = 'https://nominatim.openstreetmap.org/search';
  
  // OSRM Routing URL
  static const String _osrmUrl = 'http://router.project-osrm.org/route/v1/driving';

  /// Get current GPS location
  static Future<LatLng?> getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }

    if (permission == LocationPermission.deniedForever) return null;

    final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    
    // Override Android Emulator's default USA location to Dhaka for testing
    // USA roughly is lat > 24 and lng < -60
    if (pos.latitude > 24.0 && pos.longitude < -60.0) {
      return const LatLng(23.8103, 90.4125); // Dhaka, Bangladesh
    }

    return LatLng(pos.latitude, pos.longitude);
  }

  /// Search for a location using Nominatim API
  static Future<List<Map<String, dynamic>>> searchLocation(String query) async {
    if (query.isEmpty) return [];

    try {
      final url = Uri.parse('$_nominatimUrl?q=$query&format=json&addressdetails=1&limit=5&countrycodes=bd');
      final response = await http.get(url, headers: {
        'User-Agent': 'RideShareAI/1.0',
      });

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.map((e) => {
          'name': e['display_name'],
          'lat': double.parse(e['lat']),
          'lng': double.parse(e['lon']),
        }).toList();
      }
    } catch (e) {
      print('Geocoding error: $e');
    }
    return [];
  }

  /// Get Reverse Geocoding (Lat/Lng to Address Name)
  static Future<String> getAddressFromLatLng(LatLng point) async {
    try {
      final url = Uri.parse('https://nominatim.openstreetmap.org/reverse?lat=${point.latitude}&lon=${point.longitude}&format=json');
      final response = await http.get(url, headers: {'User-Agent': 'RideShareAI/1.0'});
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['display_name'] ?? 'Selected Location';
      }
    } catch (e) {
      print('Reverse Geocode error: $e');
    }
    return '${point.latitude.toStringAsFixed(4)}, ${point.longitude.toStringAsFixed(4)}';
  }

  /// Get Route using OSRM API
  static Future<Map<String, dynamic>?> getRoute(LatLng start, LatLng end) async {
    try {
      final url = Uri.parse('$_osrmUrl/${start.longitude},${start.latitude};${end.longitude},${end.latitude}?overview=full&geometries=geojson');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['routes'] != null && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final geometry = route['geometry']['coordinates'] as List;
          
          List<LatLng> polylinePoints = geometry.map((coord) {
            return LatLng(coord[1].toDouble(), coord[0].toDouble());
          }).toList();

          return {
            'distance': route['distance'], // in meters
            'duration': route['duration'], // in seconds
            'points': polylinePoints,
          };
        }
      }
    } catch (e) {
      print('Routing error: $e');
    }
    return null;
  }
}
