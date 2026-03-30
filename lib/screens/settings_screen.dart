import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../providers/theme_provider.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _keyController = TextEditingController();
  final TextEditingController _geminiController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<SettingsProvider>(context, listen: false);
    _urlController.text = provider.apiUrl;
    _keyController.text = provider.apiKey;
    _geminiController.text = provider.geminiKey;
  }

  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return Scaffold(
      appBar: AppBar(title: Text('Settings', style: TextStyle(fontWeight: FontWeight.bold))),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Card(
            elevation: 4,
            child: SwitchListTile(
              title: Text('Dark Mode', style: TextStyle(fontWeight: FontWeight.bold)),
              secondary: Icon(themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode),
              value: themeProvider.isDarkMode,
              onChanged: (value) => themeProvider.toggleTheme(),
            ),
          ),
          SizedBox(height: 16),
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('API Configuration', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(height: 20),
                  TextField(
                    controller: _keyController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Groq API Key (For Transcription)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.mic),
                    ),
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: _geminiController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Gemini API Key (For Translation)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.translate),
                    ),
                  ),
                  SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      icon: Icon(Icons.save),
                      label: Text('Save Settings'),
                      onPressed: () {
                        settingsProvider.setSettings(_urlController.text, _keyController.text, _geminiController.text);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Saved!'), backgroundColor: Colors.green));
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
