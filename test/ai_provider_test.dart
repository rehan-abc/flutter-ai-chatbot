import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_simple_chatbot/models/ai_provider.dart';

void main() {
  test('AiProvider enum lists all 4 supported providers', () {
    expect(AiProvider.values.length, 4);
    expect(AiProvider.gemini.displayName, 'Google Gemini');
    expect(AiProvider.openai.displayName, 'OpenAI');
    expect(AiProvider.groq.displayName, 'Groq (Fast)');
    expect(AiProvider.openrouter.displayName, 'OpenRouter');
  });
}
