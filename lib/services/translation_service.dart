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
        'model': 'llama-3.3-70b-versatile',
        'messages': [
          {
            'role': 'system',
            'content': 'You are an expert localization professional. Translate the following English transcript into pure, highly professional, and idiomatic Hausa. IMPORTANT: The text contains timestamps (e.g., [0.0s - 2.5s]). You MUST keep these exact timestamp brackets at the beginning of each line. Only translate the text following the timestamps.'
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
