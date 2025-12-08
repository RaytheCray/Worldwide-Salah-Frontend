import 'package:shared_preferences/shared_preferences.dart';

class TimeFormatService {
  static const String _key = 'use_24_hour_format';
  
  /// Get current time format preference (true = 24-hour, false = 12-hour)
  static Future<bool> get24HourFormat() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key) ?? true; // Default to 24-hour
  }
  
  /// Set time format preference
  static Future<void> set24HourFormat(bool use24Hour) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, use24Hour);
  }
  
  /// Format time string (HH:MM) based on preference
  /// 
  /// Examples:
  /// - formatTime("13:30", true) -> "13:30"
  /// - formatTime("13:30", false) -> "1:30 PM"
  /// - formatTime("07:05", false) -> "7:05 AM"
  /// - formatTime("00:15", false) -> "12:15 AM"
  static String formatTime(String time24, bool use24Hour) {
    if (use24Hour) {
      return time24; // Already in 24-hour format
    }
    
    // Convert to 12-hour format
    final parts = time24.split(':');
    if (parts.length != 2) return time24; // Invalid format, return as-is
    
    int hour = int.tryParse(parts[0]) ?? 0;
    final minute = parts[1];
    
    String period = 'AM';
    int hour12 = hour;
    
    if (hour == 0) {
      hour12 = 12;
      period = 'AM';
    } else if (hour < 12) {
      hour12 = hour;
      period = 'AM';
    } else if (hour == 12) {
      hour12 = 12;
      period = 'PM';
    } else {
      hour12 = hour - 12;
      period = 'PM';
    }
    
    return '$hour12:$minute $period';
  }
}