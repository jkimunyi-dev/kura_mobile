import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class UserService {
  static const String _userKey = 'user_data';
  static const String _candidatesKey = 'candidates_data';
  static const String _admissionNumberKey = 'admission_number';
  static const Duration _candidatesCacheDuration = Duration(minutes: 30);

  static Future<void> saveUserData(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, json.encode(userData));
    // Also save admission number separately
    await prefs.setString(
      _admissionNumberKey,
      userData['admissionNumber'] ?? '',
    );
  }

  static Future<Map<String, dynamic>?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString(_userKey);
    if (userData != null) {
      return json.decode(userData);
    }
    return null;
  }

  static Future<void> clearUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
  }

  static Future<void> saveCandidates(
    List<Map<String, dynamic>> candidates,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final data = {'candidates': candidates, 'timestamp': timestamp};
    await prefs.setString(_candidatesKey, json.encode(data));
  }

  static Future<List<Map<String, dynamic>>?> getCachedCandidates() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_candidatesKey);

    if (data != null) {
      final decoded = json.decode(data);
      final timestamp = decoded['timestamp'] as int;
      final now = DateTime.now().millisecondsSinceEpoch;

      // Check if cache is still valid (within 30 minutes)
      if (now - timestamp <= _candidatesCacheDuration.inMilliseconds) {
        return List<Map<String, dynamic>>.from(decoded['candidates']);
      }
    }
    return null;
  }

  static Future<String?> getAdmissionNumber() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_admissionNumberKey);
  }
}
