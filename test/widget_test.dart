import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_simple_chatbot/main.dart';

void main() {
  testWidgets('Chatbot app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ChatbotApp());
    expect(find.text('Google Gemini'), findsOneWidget);
  });
}
