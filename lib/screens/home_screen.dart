import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_selector/file_selector.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import '../providers/settings_provider.dart';
import '../models/transcription.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  File? _selectedFile;
  bool _isUploading = false;
  String _statusText = 'Upload & Extract Speech';
  List<TranscriptionSegment> _segments = [];
  String? _error;

  Future<void> _pickFile() async {
    try {
      // Using Google's official file_selector package
      final XFile? file = await openFile(
        acceptedTypeGroups: <XTypeGroup>[
          XTypeGroup(
            label: 'Media Files',
            extensions: ['mp4', 'mov', 'avi', 'mkv', 'webm', 'mp3', 'wav', 'aac', 'm4a', 'ogg', 'flac'],
          ),
        ],
      );
      
      if (file != null) {
        setState(() {
          _selectedFile = File(file.path);
          _segments = [];
          _error = null;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Could not open file picker: $e';
      });
    }
  }

  Future<void> _processFile() async {
    if (_selectedFile == null) return;
    
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    if (settings.apiKey.isEmpty) {
      setState(() => _error = 'Please enter your API Key in Settings first!');
      return;
    }

    setState(() {
      _isUploading = true;
      _error = null;
      _statusText = 'Compressing audio...';
    });

    try {
      final tempDir = await getTemporaryDirectory();
      final outputPath = '${tempDir.path}/compressed_audio.mp3';
      
      // FFmpeg: Extract audio, convert to mono, 16kHz, low bitrate
      final session = await FFmpegKit.execute('-y -i "${_selectedFile!.path}" -vn -ar 16000 -ac 1 -b:a 32k "$outputPath"');
      final returnCode = await session.getReturnCode();
      
      if (!ReturnCode.isSuccess(returnCode)) {
        throw Exception("Failed to extract audio. Ensure file is a valid media file.");
      }

      setState(() => _statusText = 'Sending to Fast AI...');

      var request = http.MultipartRequest('POST', Uri.parse(settings.apiUrl));
      request.headers['Authorization'] = 'Bearer ${settings.apiKey}';
      request.fields['model'] = 'whisper-large-v3'; 
      request.fields['response_format'] = 'verbose_json'; 
      request.files.add(await http.MultipartFile.fromPath('file', outputPath));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final Map<String, dynamic> data = json.decode(response.body);

      if (response.statusCode == 200) {
        if (data.containsKey('segments')) {
          List<dynamic> segmentsJson = data['segments'];
          setState(() {
            _segments = segmentsJson.map((seg) => TranscriptionSegment.fromJson(seg)).toList();
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Transcription Complete!'), backgroundColor: Colors.green),
          );
        } else {
          throw Exception("API did not return segments.");
        }
      } else {
        throw Exception(data['error']?['message'] ?? 'API Error: ${response.statusCode}');
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() {
        _isUploading = false;
        _statusText = 'Upload & Extract Speech';
      });
    }
  }

  void _copyToClipboard() {
    if (_segments.isEmpty) return;
    StringBuffer buffer = StringBuffer();
    for (int i = 0; i < _segments.length; i++) {
      final seg = _segments[i];
      buffer.writeln('${i + 1}. [${seg.start.toStringAsFixed(1)}s - ${seg.end.toStringAsFixed(1)}s]: ${seg.text}');
    }
    Clipboard.setData(ClipboardData(text: buffer.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Transcription copied!'), backgroundColor: Colors.blue),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dub App'),
        elevation: 0,
        actions: [
          IconButton(icon: Icon(Icons.settings), onPressed: () => Navigator.pushNamed(context, '/settings')),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Icon(Icons.video_library, size: 64, color: Colors.blue),
                    SizedBox(height: 16),
                    Text('Fast AI Transcription', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                    SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _pickFile,
                      icon: Icon(Icons.folder_open),
                      label: Text('Select File'),
                    ),
                    if (_selectedFile != null) ...[
                      SizedBox(height: 12),
                      Text(_selectedFile!.path.split('/').last, maxLines: 2, overflow: TextOverflow.ellipsis),
                    ],
                    SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isUploading || _selectedFile == null ? null : _processFile,
                        style: ElevatedButton.styleFrom(padding: EdgeInsets.symmetric(vertical: 12)),
                        child: _isUploading
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                                  SizedBox(width: 12),
                                  Text(_statusText),
                                ],
                              )
                            : Text(_statusText),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_error != null) ...[
              SizedBox(height: 16),
              Text(_error!, style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            ],
            if (_segments.isNotEmpty) ...[
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Results', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  TextButton.icon(onPressed: _copyToClipboard, icon: Icon(Icons.copy, size: 18), label: Text('Copy All')),
                ],
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: _segments.length,
                  itemBuilder: (context, index) {
                    final seg = _segments[index];
                    return Card(
                      margin: EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(child: Text('${index + 1}')),
                        title: Text(seg.text),
                        subtitle: Text('${seg.start.toStringAsFixed(1)}s - ${seg.end.toStringAsFixed(1)}s'),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
