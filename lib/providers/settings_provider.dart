import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  static const String _apiUrlKey = 'api_url';
  
  // Pointing to your new high-powered Hugging Face server!
  static const String _defaultUrl = 'https://elguduwis-dub-app-backend.hf.space/process';
  
  String _apiUrl = _defaultUrl;
  String get apiUrl => _apiUrl;

  SettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _apiUrl = prefs.getString(_apiUrlKey) ?? _defaultUrl;
    notifyListeners();
  }

  Future<void> setApiUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_apiUrlKey, url);
    _apiUrl = url;
    notifyListeners();
  }
}
