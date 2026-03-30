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
import '../services/vibe_voice_service.dart';
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
  
  // Engine Selection
  String _selectedEngine = 'Groq Whisper (Fast, Long Audio)';
  final List<String> _engines = [
    'Groq Whisper (Fast, Long Audio)', 
    'VibeVoice (Multi-Speaker, Short Clips)'
  ];

  // Language Selection
  String _selectedLanguage = 'Hausa';
  final List<String> _supportedLanguages = [
    'Hausa', 'Yoruba', 'Igbo', 'Pidgin English', 'Swahili', 
    'French', 'Arabic', 'Spanish', 'Portuguese'
  ];

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.any);
      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedFile = File(result.files.single.path!);
          _englishTranscript = '';
          _translatedText = '';
          _error = null;
          _statusText = 'File Selected';
        });
      }
    } catch (e) {
      setState(() => _error = 'Picker error: $e');
    }
  }

  Future<void> _runPipeline() async {
    if (_selectedFile == null) return;
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    
    if (settings.apiKey.isEmpty) {
      setState(() => _error = 'Missing Groq API Key in Settings');
      return;
    }
    if (_selectedEngine.contains('VibeVoice') && settings.hfKey.isEmpty) {
      setState(() => _error = 'Missing Hugging Face Key in Settings for VibeVoice');
      return;
    }

    setState(() {
      _isProcessing = true;
      _error = null;
      _statusText = '1/3: Compressing Audio locally...';
    });

    try {
      final tempDir = await getTemporaryDirectory();
      final outPath = '${tempDir.path}/temp_audio.mp3';
      
      final session = await FFmpegKit.execute('-y -i "${_selectedFile!.path}" -vn -ar 16000 -ac 1 -b:a 32k "$outPath"');
      final returnCode = await session.getReturnCode();
      if (!ReturnCode.isSuccess(returnCode)) throw Exception("Audio compression failed.");

      String transcribedText = '';

      // --- DUAL ENGINE ROUTING ---
      if (_selectedEngine.contains('Groq')) {
        setState(() => _statusText = '2/3: Transcribing with Groq Whisper...');
        var req = http.MultipartRequest('POST', Uri.parse(settings.apiUrl));
        req.headers['Authorization'] = 'Bearer ${settings.apiKey}';
        req.fields['model'] = 'whisper-large-v3';
        req.fields['response_format'] = 'verbose_json';
        req.files.add(await http.MultipartFile.fromPath('file', outPath));
        
        final res = await http.Response.fromStream(await req.send());
        final data = json.decode(res.body);
        if (res.statusCode != 200) throw Exception(data['error']?['message'] ?? 'Groq Transcription failed');
        
        StringBuffer transcriptBuffer = StringBuffer();
        if (data['segments'] != null) {
          for (var seg in data['segments']) {
            double start = (seg['start'] as num).toDouble();
            double end = (seg['end'] as num).toDouble();
            String text = seg['text'].toString().trim();
            transcriptBuffer.writeln('[${start.toStringAsFixed(1)}s - ${end.toStringAsFixed(1)}s] $text');
          }
        } else {
          transcriptBuffer.write(data['text']);
        }
        transcribedText = transcriptBuffer.toString().trim();

      } else {
        setState(() => _statusText = '2/3: Transcribing with VibeVoice...');
        transcribedText = await VibeVoiceService.transcribe(outPath, settings.hfKey);
      }
      // ---------------------------

      setState(() => _englishTranscript = transcribedText);

      setState(() => _statusText = '3/3: Generating pure $_selectedLanguage localization...');
      
      final translated = await TranslationService.translateText(transcribedText, _selectedLanguage, settings.apiKey);
      setState(() => _translatedText = translated);

      setState(() => _statusText = 'Complete!');
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _saveProject() async {
    if (_englishTranscript.isEmpty || _translatedText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Cannot save empty project!'), backgroundColor: Colors.red));
      return;
    }
    try {
      final project = Project(
        title: _selectedFile!.path.split('/').last,
        mediaPath: _selectedFile!.path,
        englishTranscript: _englishTranscript,
        translatedText: _translatedText,
        targetLanguage: _selectedLanguage,
        createdAt: DateTime.now().toIso8601String(),
      );
      await DatabaseHelper.instance.create(project);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Project saved successfully!'), backgroundColor: Colors.green));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Database Error: $e'), backgroundColor: Colors.red));
    }
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(Icons.mic_external_on, size: 50, color: Theme.of(context).colorScheme.primary),
                    SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _isProcessing ? null : _pickFile,
                      icon: Icon(Icons.folder),
                      label: Text('Select Media File'),
                    ),
                    if (_selectedFile != null) ...[
                      SizedBox(height: 8),
                      Text(_selectedFile!.path.split('/').last, style: TextStyle(color: Colors.grey), maxLines: 1),
                      SizedBox(height: 16),
                      
                      // ENGINE DROPDOWN
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                        decoration: BoxDecoration(
                          border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.5)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedEngine,
                            isExpanded: true,
                            icon: Icon(Icons.memory, color: Theme.of(context).colorScheme.primary),
                            items: _engines.map((String engine) {
                              return DropdownMenuItem<String>(
                                value: engine,
                                child: Text(engine, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              );
                            }).toList(),
                            onChanged: _isProcessing ? null : (String? newValue) {
                              if (newValue != null) setState(() => _selectedEngine = newValue);
                            },
                          ),
                        ),
                      ),
                      SizedBox(height: 12),
                      
                      // LANGUAGE DROPDOWN
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                        decoration: BoxDecoration(
                          border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.5)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedLanguage,
                            isExpanded: true,
                            icon: Icon(Icons.language, color: Theme.of(context).colorScheme.primary),
                            items: _supportedLanguages.map((String lang) {
                              return DropdownMenuItem<String>(
                                value: lang,
                                child: Text('Translate to: $lang', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              );
                            }).toList(),
                            onChanged: _isProcessing ? null : (String? newValue) {
                              if (newValue != null) setState(() => _selectedLanguage = newValue);
                            },
                          ),
                        ),
                      ),
                      
                      SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isProcessing ? null : _runPipeline,
                          style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary, foregroundColor: Colors.white),
                          child: _isProcessing 
                            ? Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                                SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                                SizedBox(width: 12),
                                Flexible(child: Text(_statusText, overflow: TextOverflow.ellipsis))
                              ])
                            : Text('Start AI Pipeline'),
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
              _buildResultCard('$_selectedEngine Script', _englishTranscript),
              SizedBox(height: 16),
              _buildResultCard('$_selectedLanguage Translation (Professional)', _translatedText),
              SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _saveProject,
                icon: Icon(Icons.save_alt),
                label: Text('Save Project to Database'),
                style: ElevatedButton.styleFrom(padding: EdgeInsets.symmetric(vertical: 16)),
              )
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
            Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Theme.of(context).colorScheme.primary)),
            Divider(),
            SelectableText(content, style: TextStyle(fontSize: 15, height: 1.5)),
          ],
        ),
      ),
    );
  }
}
