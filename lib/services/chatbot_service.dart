import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ChatbotService {
  final String apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
  final String baseUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-pro:generateContent';

  Future<String> getChatbotResponse(String query) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl?key=$apiKey'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'contents': [
            {
              'parts': [
                {
                  'text': '''You are an AI assistant for farmers. 
                  Help them with farming-related questions about:
                  - Crop selection and management
                  - Pest control and disease management
                  - Weather conditions and their impact
                  - Market prices and trends
                  - Best farming practices
                  
                  User Query: $query'''
                }
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.7,
            'topK': 40,
            'topP': 0.95,
            'maxOutputTokens': 1024,
          },
          'safetySettings': [
            {
              'category': 'HARM_CATEGORY_HARASSMENT',
              'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
            },
            {
              'category': 'HARM_CATEGORY_HATE_SPEECH',
              'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
            },
            {
              'category': 'HARM_CATEGORY_SEXUALLY_EXPLICIT',
              'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
            },
            {
              'category': 'HARM_CATEGORY_DANGEROUS_CONTENT',
              'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['candidates'][0]['content']['parts'][0]['text'];
      } else {
        throw Exception('Failed to get chatbot response');
      }
    } catch (e) {
      print('Error getting chatbot response: $e');
      rethrow;
    }
  }

  String formatResponse(String response) {
    // Add any formatting logic here if needed
    return response.trim();
  }

  bool isGreeting(String query) {
    final greetings = [
      'hi',
      'hello',
      'hey',
      'greetings',
      'good morning',
      'good afternoon',
      'good evening'
    ];
    return greetings.contains(query.toLowerCase().trim());
  }

  String getGreetingResponse() {
    return '''Hello! I'm your farming assistant. I can help you with:
- Crop selection and management
- Pest control and disease management
- Weather conditions and their impact
- Market prices and trends
- Best farming practices

How can I assist you today?''';
  }
} 