// lib/services/distance_unit_service.dart

import 'package:shared_preferences/shared_preferences.dart';

class DistanceUnitService {
  static const String _keyUseKm = 'use_kilometers';

  // Get the current distance unit preference (true = km, false = miles)
  static Future<bool> getUseKilometers() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyUseKm) ?? true; // Default to kilometers
  }

  // Set the distance unit preference
  static Future<void> setUseKilometers(bool useKm) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyUseKm, useKm);
  }

  // Convert kilometers to miles
  static double kmToMiles(double km) {
    return km * 0.621371;
  }

  // Convert miles to kilometers
  static double milesToKm(double miles) {
    return miles / 0.621371;
  }

  // Format distance based on preference
  static String formatDistance(double km, bool useKm) {
    if (useKm) {
      return '${km.toStringAsFixed(1)} km';
    } else {
      final miles = kmToMiles(km);
      return '${miles.toStringAsFixed(1)} mi';
    }
  }
}