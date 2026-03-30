import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import '../providers/settings_provider.dart';
import '../services/translation_service.dart';
import '../services/database_helper.dart';
import '../models/project.dart';

class StudioScreen extends StatefulWidget {
  @override
  _StudioScreenState createState() => _StudioScreenState();
}

class _StudioScreenState extends State<StudioScreen> {
  File? _selectedFile;
  bool _isProcessing = false;
  String _statusText = 'Ready to Process';
  String _englishTranscript = '';
  String _translatedText = '';
  String? _error;
  
  String _selectedLanguage = 'Hausa';
  final List<String> _supportedLanguages = ['Hausa', 'Yoruba', 'Igbo', 'Pidgin English', 'Swahili', 'French', 'Arabic'];

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.any);
      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedFile = File(result.files.single.path!);
          _englishTranscript = ''; _translatedText = ''; _error = null;
          _statusText = 'File Selected';
        });
      }
    } catch (e) { setState(() => _error = 'Picker error: $e'); }
  }

  Future<void> _runPipeline() async {
    if (_selectedFile == null) return;
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    
    if (settings.apiKey.isEmpty || settings.geminiKey.isEmpty) {
      setState(() => _error = 'Missing Groq or Gemini API Keys in Settings');
      return;
    }

    setState(() { _isProcessing = true; _error = null; _statusText = '1/3: Compressing Audio...'; });

    try {
      final tempDir = await getTemporaryDirectory();
      final outPath = '${tempDir.path}/temp_audio.mp3';
      
      final session = await FFmpegKit.execute('-y -i "${_selectedFile!.path}" -vn -ar 16000 -ac 1 -b:a 32k "$outPath"');
      if (!ReturnCode.isSuccess(await session.getReturnCode())) throw Exception("Compression failed.");

      setState(() => _statusText = '2/3: Transcribing with Groq Whisper...');
      var req = http.MultipartRequest('POST', Uri.parse(settings.apiUrl));
      req.headers['Authorization'] = 'Bearer ${settings.apiKey}';
      req.fields['model'] = 'whisper-large-v3';
      req.fields['response_format'] = 'verbose_json';
      req.files.add(await http.MultipartFile.fromPath('file', outPath));
      
      final res = await http.Response.fromStream(await req.send());
      final data = json.decode(res.body);
      if (res.statusCode != 200) throw Exception(data['error']?['message'] ?? 'Transcription failed');
      
      StringBuffer transcriptBuffer = StringBuffer();
      if (data['segments'] != null) {
        for (var seg in data['segments']) {
          transcriptBuffer.writeln('[${(seg['start'] as num).toStringAsFixed(1)}s - ${(seg['end'] as num).toStringAsFixed(1)}s] ${seg['text'].toString().trim()}');
        }
      }
      final transcribedText = transcriptBuffer.toString().trim();
      setState(() => _englishTranscript = transcribedText);

      setState(() => _statusText = '3/3: Generating pure $_selectedLanguage via Gemini...');
      final translated = await TranslationService.translateText(transcribedText, _selectedLanguage, settings.geminiKey);
      setState(() => _translatedText = translated);

      setState(() => _statusText = 'Complete!');
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _saveProject() async {
    if (_englishTranscript.isEmpty || _translatedText.isEmpty) return;
    try {
      await DatabaseHelper.instance.create(Project(
        title: _selectedFile!.path.split('/').last,
        mediaPath: _selectedFile!.path,
        englishTranscript: _englishTranscript,
        translatedText: _translatedText,
        targetLanguage: _selectedLanguage,
        createdAt: DateTime.now().toIso8601String(),
      ));
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Saved!'), backgroundColor: Colors.green));
    } catch (e) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red)); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Localization Studio', style: TextStyle(fontWeight: FontWeight.bold))),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 6,
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(Icons.mic_external_on, size: 50, color: Theme.of(context).colorScheme.primary),
                    SizedBox(height: 16),
                    ElevatedButton.icon(onPressed: _isProcessing ? null : _pickFile, icon: Icon(Icons.folder), label: Text('Select File')),
                    if (_selectedFile != null) ...[
                      SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        decoration: InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12)),
                        value: _selectedLanguage,
                        items: _supportedLanguages.map((lang) => DropdownMenuItem(value: lang, child: Text('Translate to: $lang'))).toList(),
                        onChanged: _isProcessing ? null : (val) => setState(() => _selectedLanguage = val!),
                      ),
                      SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity, height: 50,
                        child: ElevatedButton(
                          onPressed: _isProcessing ? null : _runPipeline,
                          style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary, foregroundColor: Colors.white),
                          child: _isProcessing ? CircularProgressIndicator(color: Colors.white) : Text('Start AI Pipeline'),
                        ),
                      ),
                    ]
                  ],
                ),
              ),
            ),
            if (_error != null) Padding(padding: EdgeInsets.only(top: 16), child: Text(_error!, style: TextStyle(color: Colors.red))),
            if (_englishTranscript.isNotEmpty) ...[
              SizedBox(height: 20),
              _buildResultCard('Groq Whisper (English)', _englishTranscript),
              SizedBox(height: 16),
              _buildResultCard('$_selectedLanguage via Gemini', _translatedText),
              SizedBox(height: 20),
              ElevatedButton.icon(onPressed: _saveProject, icon: Icon(Icons.save), label: Text('Save Project'))
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard(String title, String content) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
            Divider(),
            SelectableText(content, style: TextStyle(height: 1.5)),
          ],
        ),
      ),
    );
  }
}
