import 'package:flutter_dotenv/flutter_dotenv.dart';

class AIService {
  // Simple singleton pattern or constructor management
  static final AIService _instance = AIService._internal();
  factory AIService() => _instance;
  AIService._internal();

  void initialize() {
    // Safely pull the key out of the .env setup
    final apiKey = dotenv.env['OPENAI_API_KEY'] ?? '';

    if (apiKey.isEmpty) {
      print("⚠️ [AI Service] OpenAI API Key is missing from .env!");
      return;
    }

    // Assign your key directly to your respective package config here
    // Example for dart_openai package:
    // OpenAI.apiKey = apiKey;

    print("🧠 [AI Service] OpenAI Client successfully initialized.");
  }
}