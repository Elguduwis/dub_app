import 'dart:convert';
import 'package:http/http.dart' as http;

class TranslationService {
  static Future<String> translateText(String englishText, String targetLanguage, String apiKey) async {
    final url = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$apiKey');
    
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "systemInstruction": {
          "parts": [
            {"text": "You are a professional linguist and localization expert from Nigeria. Translate the provided English transcript into extremely pure, professional, and idiomatic $targetLanguage. Do NOT use word-for-word translation. Make it sound completely natural to a native speaker. The text contains timestamps (e.g., [0.0s - 2.5s]). You MUST preserve these exact timestamp brackets at the beginning of each translated line."}
          ]
        },
        "contents": [
          {
            "parts": [{"text": englishText}]
          }
        ],
        "generationConfig": {
          "temperature": 0.2
        }
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['candidates'][0]['content']['parts'][0]['text'].trim();
    } else {
      final errorData = jsonDecode(response.body);
      throw Exception("Gemini API Error: ${errorData['error']?['message'] ?? 'Unknown Error'}");
    }
  }
}
