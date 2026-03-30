import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  static const String _apiUrlKey = 'api_url';
  static const String _apiKeyKey = 'api_key';
  static const String _geminiKeyKey = 'gemini_key'; // New Gemini Key
  
  static const String _defaultUrl = 'https://api.groq.com/openai/v1/audio/transcriptions';
  
  String _apiUrl = _defaultUrl;
  String _apiKey = '';
  String _geminiKey = '';
  
  String get apiUrl => _apiUrl;
  String get apiKey => _apiKey;
  String get geminiKey => _geminiKey;

  SettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _apiUrl = prefs.getString(_apiUrlKey) ?? _defaultUrl;
    _apiKey = prefs.getString(_apiKeyKey) ?? '';
    _geminiKey = prefs.getString(_geminiKeyKey) ?? '';
    notifyListeners();
  }

  Future<void> setSettings(String url, String key, String gemini) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_apiUrlKey, url);
    await prefs.setString(_apiKeyKey, key);
    await prefs.setString(_geminiKeyKey, gemini);
    _apiUrl = url;
    _apiKey = key;
    _geminiKey = gemini;
    notifyListeners();
  }
}
