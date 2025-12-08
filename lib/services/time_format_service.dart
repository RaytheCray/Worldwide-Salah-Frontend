import 'package:shared_preferences/shared_preferences.dart';

class TimeFormatService {
  static const String _key = 'use_24_hour_format';
  
  /// Get current time format preference
  static Future<bool> get24HourFormat() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key) ?? true; // Default to 24-hour
  }
  
  /// Set time format preference
  static Future<void> set24HourFormat(bool use24Hour) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, use24Hour);
  }
  
  /// Format time string based on preference
  static String formatTime(String time24, bool use24Hour) {
    if (use24Hour) {
      return time24; // Already in 24-hour format
    }
    
    // Convert to 12-hour format
    final parts = time24.split(':');
    if (parts.length != 2) return time24;
    
    int hour = int.tryParse(parts[0]) ?? 0;
    final minute = parts[1];
    
    if (hour == 0) {
      return '12:$minute AM';
    } else if (hour < 12) {
      return '$hour:$minute AM';
    } else if (hour == 12) {
      return '12:$minute PM';
    } else {
      return '${hour - 12}:$minute PM';
    }
  }
}