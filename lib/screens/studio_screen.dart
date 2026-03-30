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
  String? _fileName;
  bool _isProcessing = false;
  String _statusText = 'Ready to Process';
  String _sourceTranscript = '';
  String _translatedText = '';
  String _detectedLanguage = 'Unknown';
  String? _error;
  
  String _selectedLanguage = 'Hausa';
  final List<String> _supportedLanguages = ['Hausa', 'Yoruba', 'Igbo', 'Pidgin English', 'Swahili', 'French', 'Arabic'];

  // Map Whisper language codes to full names
  String _mapLanguageCode(String code) {
    const langs = {
      'en': 'English', 'ar': 'Arabic', 'fr': 'French', 'ha': 'Hausa', 
      'yo': 'Yoruba', 'ig': 'Igbo', 'sw': 'Swahili', 'es': 'Spanish', 'pt': 'Portuguese'
    };
    return langs[code] ?? code.toUpperCase();
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.any);
      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedFile = File(result.files.single.path!);
          _fileName = result.files.single.name;
          _sourceTranscript = ''; _translatedText = ''; _error = null;
          _statusText = 'File Selected';
          _detectedLanguage = 'Unknown';
        });
      }
    } catch (e) { setState(() => _error = 'Picker error: $e'); }
  }

  Future<void> _runPipeline() async {
    if (_selectedFile == null) return;
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    
    if (settings.apiKey.isEmpty || settings.geminiKey.isEmpty) {
      setState(() => _error = 'Missing API Keys in Settings');
      return;
    }

    setState(() { _isProcessing = true; _error = null; _statusText = '1/3: Compressing Audio...'; });

    try {
      final tempDir = await getTemporaryDirectory();
      final outPath = '${tempDir.path}/temp_audio.mp3';
      
      final session = await FFmpegKit.execute('-y -i "${_selectedFile!.path}" -vn -ar 16000 -ac 1 -b:a 32k "$outPath"');
      if (!ReturnCode.isSuccess(await session.getReturnCode())) throw Exception("Compression failed.");

      setState(() => _statusText = '2/3: Transcribing Audio...');
      var req = http.MultipartRequest('POST', Uri.parse(settings.apiUrl));
      req.headers['Authorization'] = 'Bearer ${settings.apiKey}';
      req.fields['model'] = 'whisper-large-v3';
      req.fields['response_format'] = 'verbose_json';
      req.files.add(await http.MultipartFile.fromPath('file', outPath));
      
      final res = await http.Response.fromStream(await req.send());
      final data = json.decode(res.body);
      if (res.statusCode != 200) throw Exception(data['error']?['message'] ?? 'Transcription failed');
      
      // Extract Detected Language
      final langCode = data['language']?.toString() ?? 'unknown';
      _detectedLanguage = _mapLanguageCode(langCode);

      StringBuffer transcriptBuffer = StringBuffer();
      if (data['segments'] != null) {
        for (var seg in data['segments']) {
          transcriptBuffer.writeln('[${(seg['start'] as num).toStringAsFixed(1)}s - ${(seg['end'] as num).toStringAsFixed(1)}s] ${seg['text'].toString().trim()}');
        }
      }
      final transcribedText = transcriptBuffer.toString().trim();
      setState(() => _sourceTranscript = transcribedText);

      setState(() => _statusText = '3/3: Translating to $_selectedLanguage...');
      final translated = await TranslationService.translateText(transcribedText, _selectedLanguage, settings.geminiKey);
      setState(() => _translatedText = translated);

      setState(() => _statusText = 'Complete!');
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _showSaveDialog() async {
    if (_sourceTranscript.isEmpty || _translatedText.isEmpty) return;
    TextEditingController titleController = TextEditingController(text: _fileName ?? 'Kaida Dub Project');
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          title: Text('Save Project', style: TextStyle(fontWeight: FontWeight.bold)),
          content: TextField(
            controller: titleController,
            decoration: const InputDecoration(labelText: 'Project Title', border: OutlineInputBorder()),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel', style: TextStyle(color: Colors.grey))),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                DatabaseHelper.instance.create(Project(
                  title: titleController.text,
                  mediaPath: _selectedFile!.path,
                  englishTranscript: _sourceTranscript,
                  translatedText: _translatedText,
                  targetLanguage: _selectedLanguage,
                  createdAt: DateTime.now().toIso8601String(),
                ));
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved!'), backgroundColor: Colors.green));
              },
              style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary, foregroundColor: Theme.of(context).colorScheme.onPrimary),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kaida Dub Studio', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.5))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(Icons.graphic_eq, size: 56, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(height: 20),
                    OutlinedButton.icon(
                      onPressed: _isProcessing ? null : _pickFile, 
                      icon: const Icon(Icons.upload_file), 
                      label: const Text('Select Media File'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        side: BorderSide(color: Theme.of(context).colorScheme.primary.withOpacity(0.5)),
                      ),
                    ),
                    if (_fileName != null) ...[
                      const SizedBox(height: 16),
                      Text(_fileName!, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 24),
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 16)),
                        value: _selectedLanguage,
                        icon: const Icon(Icons.keyboard_arrow_down),
                        items: _supportedLanguages.map((lang) => DropdownMenuItem(value: lang, child: Text('Target: $lang', style: const TextStyle(fontWeight: FontWeight.w500)))).toList(),
                        onChanged: _isProcessing ? null : (val) => setState(() => _selectedLanguage = val!),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity, height: 56,
                        child: ElevatedButton(
                          onPressed: _isProcessing ? null : _runPipeline,
                          style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary, foregroundColor: Theme.of(context).colorScheme.onPrimary, elevation: 0),
                          child: _isProcessing 
                            ? Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                                SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Theme.of(context).colorScheme.onPrimary, strokeWidth: 2)),
                                const SizedBox(width: 12),
                                Flexible(child: Text(_statusText, style: const TextStyle(fontWeight: FontWeight.w600)))
                              ])
                            : const Text('Process Audio', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ]
                  ],
                ),
              ),
            ),
            if (_error != null) Padding(padding: const EdgeInsets.only(top: 20), child: Text(_error!, style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w500))),
            if (_sourceTranscript.isNotEmpty) ...[
              const SizedBox(height: 32),
              _buildResultCard('Original Audio (Detected: $_detectedLanguage)', _sourceTranscript),
              const SizedBox(height: 16),
              _buildResultCard('$_selectedLanguage Translation', _translatedText),
              const SizedBox(height: 24),
              SizedBox(
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _showSaveDialog,
                  icon: const Icon(Icons.bookmark_border), 
                  label: const Text('Save to Projects', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.surface, foregroundColor: Theme.of(context).colorScheme.primary, side: BorderSide(color: Theme.of(context).colorScheme.primary), elevation: 0),
                ),
              )
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard(String title, String content) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Theme.of(context).colorScheme.primary.withOpacity(0.7))),
            const Divider(height: 24),
            SelectableText(content, style: const TextStyle(height: 1.6, fontSize: 15)),
          ],
        ),
      ),
    );
  }
}
