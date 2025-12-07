import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

class ApiService {
  // BACKEND URL CONFIGURATION
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:5000/api', // Android emulator
  );
  
  static const Duration timeoutDuration = Duration(seconds: 10);

  static Future<void> init() async {
    debugPrint('📱 ApiService initialized');
  }

  /// Get prayer times with timezone support
  Future<Map<String, dynamic>> getPrayerTimes({
    required double latitude,
    required double longitude,
    required String date,
    String method = 'ISNA',
    String asrMethod = 'standard',
  }) async {
    try {
      // Get device timezone offset in hours
      final timezoneOffset = DateTime.now().timeZoneOffset.inHours;
      
      final response = await http
          .post(
            Uri.parse('$baseUrl/prayer-times'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'latitude': latitude,
              'longitude': longitude,
              'date': date,
              'method': method,
              'asr_method': asrMethod,
              'timezone_offset': timezoneOffset,  // NEW: Send timezone
            }),
          )
          .timeout(timeoutDuration);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('✅ Prayer times fetched successfully');
        return data;
      } else {
        throw Exception('Failed to load prayer times: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Error getting prayer times: $e');
      throw Exception('Error getting prayer times: $e');
    }
  }

  /// Get monthly prayer times with timezone support
  Future<Map<String, dynamic>> getMonthlyPrayerTimes({
    required double latitude,
    required double longitude,
    required int year,
    required int month,
    String method = 'ISNA',
    String asrMethod = 'standard',
  }) async {
    try {
      final timezoneOffset = DateTime.now().timeZoneOffset.inHours;
      
      final response = await http
          .post(
            Uri.parse('$baseUrl/monthly-prayers'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'latitude': latitude,
              'longitude': longitude,
              'year': year,
              'month': month,
              'method': method,
              'asr_method': asrMethod,
              'timezone_offset': timezoneOffset,  // NEW: Send timezone
            }),
          )
          .timeout(timeoutDuration);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('✅ Monthly prayer times fetched');
        return data;
      } else {
        throw Exception('Failed to load monthly prayers: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Error getting monthly prayers: $e');
      throw Exception('Error getting monthly prayers: $e');
    }
  }

  /// Get Ramadan schedule with timezone support
  Future<Map<String, dynamic>> getRamadanSchedule({
    required double latitude,
    required double longitude,
    required int year,
    String method = 'ISNA',
  }) async {
    try {
      final timezoneOffset = DateTime.now().timeZoneOffset.inHours;
      
      final response = await http
          .post(
            Uri.parse('$baseUrl/ramadan'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'latitude': latitude,
              'longitude': longitude,
              'year': year,
              'method': method,
              'timezone_offset': timezoneOffset,  // NEW: Send timezone
            }),
          )
          .timeout(timeoutDuration);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('✅ Ramadan schedule fetched');
        return data;
      } else {
        throw Exception('Failed to load Ramadan schedule: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Error getting Ramadan schedule: $e');
      throw Exception('Error getting Ramadan schedule: $e');
    }
  }

  /// Get Qibla direction
  Future<Map<String, dynamic>> getQiblaDirection({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/qibla'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'latitude': latitude,
              'longitude': longitude,
            }),
          )
          .timeout(timeoutDuration);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('✅ Qibla direction calculated');
        return data;
      } else {
        throw Exception('Failed to get Qibla direction: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Error getting Qibla direction: $e');
      throw Exception('Error getting Qibla direction: $e');
    }
  }

  /// Get nearby mosques
  Future<Map<String, dynamic>> getNearbyMosques({
    required double latitude,
    required double longitude,
    double radius = 10.0,
  }) async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/mosques/nearby?lat=$latitude&lng=$longitude&radius=$radius'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(timeoutDuration);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('✅ Found ${data['count']} mosques nearby');
        return data;
      } else {
        throw Exception('Failed to get nearby mosques: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Error getting nearby mosques: $e');
      throw Exception('Error getting nearby mosques: $e');
    }
  }

  /// Check server health
  Future<bool> checkServerHealth() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/health'))
          .timeout(timeoutDuration);
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('❌ Server health check failed: $e');
      return false;
    }
  }

  /// Helper to parse time string to TimeOfDay
  static TimeOfDay parseTime(String timeStr) {
    final parts = timeStr.split(':');
    return TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
  }

  /// Helper to format date as YYYY-MM-DD
  static String formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}