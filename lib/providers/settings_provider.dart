import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  static const String _apiUrlKey = 'api_url';
  static const String _apiKeyKey = 'api_key';
  static const String _hfKeyKey = 'hf_key'; // New Hugging Face Key
  
  static const String _defaultUrl = 'https://api.groq.com/openai/v1/audio/transcriptions';
  
  String _apiUrl = _defaultUrl;
  String _apiKey = '';
  String _hfKey = '';
  
  String get apiUrl => _apiUrl;
  String get apiKey => _apiKey;
  String get hfKey => _hfKey;

  SettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _apiUrl = prefs.getString(_apiUrlKey) ?? _defaultUrl;
    _apiKey = prefs.getString(_apiKeyKey) ?? '';
    _hfKey = prefs.getString(_hfKeyKey) ?? '';
    notifyListeners();
  }

  Future<void> setSettings(String url, String key, String hf) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_apiUrlKey, url);
    await prefs.setString(_apiKeyKey, key);
    await prefs.setString(_hfKeyKey, hf);
    _apiUrl = url;
    _apiKey = key;
    _hfKey = hf;
    notifyListeners();
  }
}
