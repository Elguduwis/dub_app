import 'dart:convert';
import 'package:http/http.dart' as http;

class TranslationService {
  static Future<String> translateToHausa(String englishText, String apiKey) async {
    final url = Uri.parse('https://api.groq.com/openai/v1/chat/completions');
    
    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': 'llama3-70b-8192',
        'messages': [
          {
            'role': 'system',
            'content': 'You are a professional linguist and localization expert. Translate the following English text into pure, idiomatic Hausa. Do NOT do a literal word-for-word translation. Ensure the grammar, tone, and vocabulary sound entirely natural to a native Hausa speaker. Only return the translated text, nothing else.'
          },
          {
            'role': 'user',
            'content': englishText
          }
        ],
        'temperature': 0.3, // Low temperature for focused, accurate translation
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['choices'][0]['message']['content'].trim();
    } else {
      throw Exception('Failed to translate: ${response.body}');
    }
  }
}
