import 'dart:convert';
import 'package:http/http.dart' as http;

class TranslationService {
  static Future<String> translateText(String englishText, String targetLanguage, String apiKey) async {
    final url = Uri.parse('https://api.groq.com/openai/v1/chat/completions');
    
    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': 'llama-3.3-70b-versatile',
        'messages': [
          {
            'role': 'system',
            'content': 'You are an expert localization professional. Translate the following script into pure, highly professional, and idiomatic $targetLanguage. IMPORTANT: The text contains Speaker identities and timestamps (e.g., "Speaker 1, 0.0-2.5s:"). You MUST keep these exact speaker and timestamp tags in English at the beginning of each line. Only translate the spoken dialogue that follows them.'
          },
          {
            'role': 'user',
            'content': englishText
          }
        ],
        'temperature': 0.2,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['choices'][0]['message']['content'].trim();
    } else {
      final errorData = jsonDecode(response.body);
      throw Exception("Translation API Error ${response.statusCode}: ${errorData['error']?['message'] ?? 'Unknown Error'}");
    }
  }
}
