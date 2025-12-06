import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

class ApiService {
  // BACKEND URL CONFIGURATION
  // Android Emulator: use 10.0.2.2 instead of localhost
  // iOS Simulator: use localhost
  // Physical Device: use your computer's IP address
  
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    // defaultValue: 'http://localhost:5000/api',
    defaultValue: 'http://10.0.2.2:5000/api', // Default for Android emulator
  );
  
  // For iOS simulator, use: 'http://localhost:5000/api'
  // For physical device, use: 'http://YOUR_COMPUTER_IP:5000/api'
  // Example: 'http://192.168.1.100:5000/api'
  
  static const Duration timeoutDuration = Duration(seconds: 10);

  /// Initialize API service (for compatibility with existing code)
  static Future<void> init() async {
    // No initialization needed for now
    // This method exists for compatibility with code that calls ApiService.init()
    debugPrint('📱 ApiService initialized');
  }

  /// Get prayer times for a specific date
  /// Returns: { 'success': bool, 'date': string, 'times': {...}, 'method': string }
  Future<Map<String, dynamic>> getPrayerTimes({
    required double latitude,
    required double longitude,
    required String date, // Format: YYYY-MM-DD
    String method = 'ISNA',
    String asrMethod = 'standard',
  }) async {
    // Get device timezone offset in hours
    final timezoneOffset = DateTime.now().timeZoneOffset.inHours;
    try {
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
              'timezone_offset': timezoneOffset,
            }),
          )
          .timeout(timeoutDuration);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('✅ Prayer times fetched successfully');
        return data;
      } else {
        throw Exception(
            'Failed to load prayer times: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ Error getting prayer times: $e');
      throw Exception('Error getting prayer times: $e');
    }
  }

  /// Get monthly prayer timetable
  /// Returns: { 'success': bool, 'month': int, 'year': int, 'days': [...] }
  Future<Map<String, dynamic>> getMonthlyPrayerTimes({
    required double latitude,
    required double longitude,
    required int year,
    required int month,
    String method = 'ISNA',
    String asrMethod = 'standard',
  }) async {
    try {
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
            }),
          )
          .timeout(timeoutDuration);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('✅ Monthly prayer times fetched');
        return data;
      } else {
        throw Exception(
            'Failed to load monthly prayers: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Error getting monthly prayers: $e');
      throw Exception('Error getting monthly prayers: $e');
    }
  }

  /// Get Ramadan fasting schedule for a year
  /// Returns: { 'success': bool, 'year': int, 'start_date': string, 'end_date': string, 'fasting_schedule': [...] }
  Future<Map<String, dynamic>> getRamadanSchedule({
    required double latitude,
    required double longitude,
    required int year,
    String method = 'ISNA',
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/ramadan'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'latitude': latitude,
              'longitude': longitude,
              'year': year,
              'method': method,
            }),
          )
          .timeout(timeoutDuration);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('✅ Ramadan schedule fetched');
        return data;
      } else {
        throw Exception(
            'Failed to load Ramadan schedule: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Error getting Ramadan schedule: $e');
      throw Exception('Error getting Ramadan schedule: $e');
    }
  }

  /// Get Qibla direction (bearing in degrees)
  /// Returns: { 'success': bool, 'qibla_direction': double, 'latitude': double, 'longitude': double }
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
        debugPrint('✅ Qibla direction calculated: ${data['qibla_direction']}°');
        return data;
      } else {
        throw Exception(
            'Failed to get Qibla direction: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Error getting Qibla direction: $e');
      throw Exception('Error getting Qibla direction: $e');
    }
  }

  /// Get nearby mosques
  /// Returns: { 'success': bool, 'mosques': [...], 'count': int }
  Future<Map<String, dynamic>> getNearbyMosques({
    required double latitude,
    required double longitude,
    double radius = 10.0, // in kilometers
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
        throw Exception(
            'Failed to get nearby mosques: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Error getting nearby mosques: $e');
      throw Exception('Error getting nearby mosques: $e');
    }
  }

  /// Get available calculation methods
  /// Returns: { 'success': bool, 'methods': {...} }
  Future<Map<String, dynamic>> getCalculationMethods() async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/calculation-methods'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(timeoutDuration);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('✅ Calculation methods fetched');
        return data;
      } else {
        throw Exception(
            'Failed to get calculation methods: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Error getting calculation methods: $e');
      throw Exception('Error getting calculation methods: $e');
    }
  }

  /// Health check - Test if backend is running
  /// Returns: true if server is healthy, false otherwise
  Future<bool> checkServerHealth() async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/health'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(timeoutDuration);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final isHealthy = data['success'] == true && data['status'] == 'running';
        if (isHealthy) {
          debugPrint('✅ Backend server is healthy');
          debugPrint('   Database: ${data['database']}');
        }
        return isHealthy;
      }
      return false;
    } catch (e) {
      debugPrint('❌ Cannot connect to backend server');
      debugPrint('   Make sure Flask is running on $baseUrl');
      return false;
    }
  }

  /// Test connection with detailed message
  Future<String> testConnection() async {
    try {
      debugPrint('🔍 Testing connection to $baseUrl...');
      final isHealthy = await checkServerHealth();
      if (isHealthy) {
        return '✅ Successfully connected to backend\n🌐 Server: $baseUrl';
      } else {
        return '⚠️ Server responded but health check failed\n🌐 Server: $baseUrl';
      }
    } catch (e) {
      return '❌ Cannot connect to server\n🌐 Server: $baseUrl\n\n'
          'Make sure:\n'
          '1. Flask backend is running (python app.py)\n'
          '2. Backend URL is correct\n'
          '3. No firewall blocking connection\n\n'
          'Error: $e';
    }
  }

  /// Helper: Format date for API (YYYY-MM-DD)
  static String formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Helper: Parse time string from API (HH:MM) to TimeOfDay
  static TimeOfDay parseTime(String timeString) {
    try {
      final parts = timeString.split(':');
      return TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      );
    } catch (e) {
      debugPrint('❌ Error parsing time: $timeString');
      return const TimeOfDay(hour: 0, minute: 0);
    }
  }
}