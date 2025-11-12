import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class ApiService {
  // OpenFoodFacts API - Search products
  static Future<List<dynamic>> searchProducts(String query) async {
    final url = Uri.parse(
      'https://world.openfoodfacts.org/cgi/search.pl?search_terms=${Uri.encodeComponent(query)}&search_simple=1&action=process&json=1&page_size=20',
    );
    final res = await http.get(url);
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      return data['products'] ?? [];
    }
    return [];
  }

  // Get product by barcode
  static Future<Map<String, dynamic>?> getProductByBarcode(
    String barcode,
  ) async {
    final url = Uri.parse(
      'https://world.openfoodfacts.org/api/v0/product/$barcode.json',
    );
    final res = await http.get(url);
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      if (data['status'] == 1) return data['product'];
    }
    return null;
  }

  // Reverse geocode coordinates to location
  static Future<Map<String, dynamic>?> reverseGeocode(
    double lat,
    double lon,
  ) async {
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=jsonv2&lat=$lat&lon=$lon',
      );
      final res = await http.get(
        url,
        headers: {'User-Agent': 'SnackScanApp/1.0'},
      );
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
    } catch (e) {
      print('Error reverse geocoding: $e');
    }
    return null;
  }

  // =============================================================
  // Tambahan: Fungsi LBS (Location-Based Service)
  // =============================================================

  /// Mengambil lokasi pengguna (koordinat GPS)
  static Future<Position?> getUserLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.deniedForever ||
            permission == LocationPermission.denied) {
          return null;
        }
      }

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      print('Error getting user location: $e');
      return null;
    }
  }

  /// Mengubah nama negara/kota menjadi koordinat
  static Future<Map<String, double>?> getCoordinatesFromPlace(
    String place,
  ) async {
    try {
      final locations = await locationFromAddress(place);
      if (locations.isNotEmpty) {
        return {
          'lat': locations.first.latitude,
          'lon': locations.first.longitude,
        };
      }
    } catch (e) {
      print('Error geocoding place: $e');
    }
    return null;
  }

  /// Menghitung jarak antara pengguna dan lokasi asal produk
  static Future<double?> calculateDistanceToOrigin(String? originPlace) async {
    if (originPlace == null || originPlace.isEmpty) return null;

    try {
      final userPos = await getUserLocation();
      if (userPos == null) return null;

      final originCoords = await getCoordinatesFromPlace(originPlace);
      if (originCoords == null) return null;

      double distanceMeters = Geolocator.distanceBetween(
        userPos.latitude,
        userPos.longitude,
        originCoords['lat']!,
        originCoords['lon']!,
      );

      // Ubah ke kilometer
      return distanceMeters / 1000;
    } catch (e) {
      print('Error calculating distance: $e');
      return null;
    }
  }

  /// Menentukan asal produk dari data OpenFoodFacts (paling akurat)
  static String getProductOrigin(Map<String, dynamic> product) {
    // Prioritas: manufacturing_places > countries_tags > origins
    String? origin = product['manufacturing_places'];
    if (origin != null && origin.isNotEmpty) return origin;

    if (product['countries_tags'] != null &&
        product['countries_tags'] is List &&
        product['countries_tags'].isNotEmpty) {
      return (product['countries_tags'][0] as String)
          .replaceAll('en:', '')
          .toUpperCase();
    }

    if (product['origins'] != null &&
        product['origins'].toString().isNotEmpty) {
      return product['origins'];
    }

    return 'Unknown';
  }
}
