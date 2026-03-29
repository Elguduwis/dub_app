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
            'content': 'You are an expert linguist and localization professional. Translate the following English text into pure, highly professional, and idiomatic Hausa. Do NOT perform a literal, word-for-word translation. Ensure the syntax, vocabulary, and cultural context sound perfectly natural to a native Hausa speaker. Return ONLY the translated Hausa text with no additional commentary.'
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
      throw Exception('Translation API Error: ${response.statusCode}');
    }
  }
}
