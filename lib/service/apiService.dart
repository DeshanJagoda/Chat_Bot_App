import 'package:google_generative_ai/google_generative_ai.dart';

class ApiService {
  final String apiKey;
  final String modelName;

  ApiService({required this.apiKey, this.modelName = 'Model_Name'});

  // Method to generate content using the Generative AI model
  Future<String?> generateContent(String prompt) async {
    try {
      final model = GenerativeModel(model: modelName, apiKey: apiKey);
      final response = await model.generateContent([Content.text(prompt)]);
      return response.text;
    } catch (e) {
      print('Error generating content: $e');
      return null;
    }
  }
}
