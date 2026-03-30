import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

class VibeVoiceService {
  static Future<String> transcribe(String audioPath, String hfKey) async {
    final url = Uri.parse('https://api-inference.huggingface.co/models/microsoft/VibeVoice-ASR');
    final fileBytes = await File(audioPath).readAsBytes();
    
    int maxRetries = 5;
    for (int i = 0; i < maxRetries; i++) {
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $hfKey',
          'Content-Type': 'audio/mpeg',
        },
        body: fileBytes,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Hugging Face typically returns a list or a map for ASR
        if (data is Map && data.containsKey('text')) {
          return data['text'].toString();
        } else if (data is List && data.isNotEmpty && data[0] is Map && data[0].containsKey('text')) {
          return data[0]['text'].toString();
        }
        return response.body; 
      } else if (response.statusCode == 503) {
        // Model is asleep/loading. Read the estimated time and wait.
        final data = jsonDecode(response.body);
        final waitTime = (data['estimated_time'] ?? 15.0).toDouble();
        await Future.delayed(Duration(seconds: waitTime.ceil()));
      } else {
        final error = jsonDecode(response.body);
        throw Exception('VibeVoice API Error ${response.statusCode}: ${error['error'] ?? 'Unknown Error'}');
      }
    }
    throw Exception('Hugging Face model failed to load after multiple attempts. Please try again.');
  }
}
