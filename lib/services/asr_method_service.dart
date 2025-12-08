import 'package:shared_preferences/shared_preferences.dart';

class AsrMethodService {
  static const String _key = 'asr_method';
  
  /// Get current Asr method preference ('standard' or 'hanafi')
  static Future<String> getAsrMethod() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_key) ?? 'standard'; // Default to standard
  }
  
  /// Set Asr method preference
  static Future<void> setAsrMethod(String method) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, method);
  }
}