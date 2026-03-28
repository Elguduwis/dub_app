import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _urlController = TextEditingController();
  bool _isValidUrl = true;

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<SettingsProvider>(context, listen: false);
    _urlController.text = provider.apiUrl;
  }

  void _validateUrl(String url) {
    setState(() {
      _isValidUrl = url.startsWith('http://') || url.startsWith('https://');
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SettingsProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Backend API URL',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'The server that processes your videos',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: _urlController,
                      decoration: InputDecoration(
                        labelText: 'API Endpoint',
                        hintText: 'https://your-backend.com/process',
                        border: OutlineInputBorder(),
                        errorText: _isValidUrl ? null : 'Must start with http:// or https://',
                        prefixIcon: Icon(Icons.link),
                      ),
                      onChanged: _validateUrl,
                    ),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _isValidUrl && _urlController.text.isNotEmpty
                          ? () {
                              provider.setApiUrl(_urlController.text);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('API URL saved'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                              Navigator.pop(context);
                            }
                          : null,
                      child: Text('Save Settings'),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current URL',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        provider.apiUrl,
                        style: TextStyle(
                          fontSize: 12,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Default URL will work after deploying backend',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
