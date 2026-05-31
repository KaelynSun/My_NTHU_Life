import 'package:flutter/foundation.dart';
import 'package:dart_openai/dart_openai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AIService {
  // Singleton pattern so the entire app shares one instance
  static final AIService _instance = AIService._internal();
  factory AIService() => _instance;
  AIService._internal();

  /// Loads the API key safely from the .env file and assigns it to OpenAI
  void initialize() {
    final apiKey = dotenv.env['OPENAI_API_KEY'] ?? '';
    
    if (apiKey.isEmpty || apiKey.startsWith('sk-proj-yourActual')) {
      debugPrint("⚠️ Warning: OpenAI API key is missing from your local .env file!");
    } else {
      OpenAI.apiKey = apiKey;
      debugPrint("🚀 OpenAI Service successfully initialized securely.");
    }
  }

  /// Sends a raw text prompt to GPT and returns its response string.
  Future<String> askAI(String prompt) async {
    if (OpenAI.apiKey.isEmpty) {
      return "AI Error: OpenAI API Key is not initialized. Check your local .env file.";
    }

    try {
      final userMessage = OpenAIChatCompletionChoiceMessageModel(
        content: [
          OpenAIChatCompletionChoiceMessageContentItemModel.text(prompt),
        ],
        role: OpenAIChatMessageRole.user,
      );

      final chatCompletion = await OpenAI.instance.chat.create(
        model: "gpt-4o-mini",
        messages: [userMessage],
      );

      return chatCompletion.choices.first.message.content?.first.text ?? "The AI returned an empty response.";
    } catch (e) {
      debugPrint("OpenAI Engine Exception: $e");
      return "Failed to connect to OpenAI: $e";
    }
  }
}