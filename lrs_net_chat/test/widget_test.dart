import 'package:flutter_test/flutter_test.dart';
import 'package:lrs_net_chat/main.dart';

void main() {
  testWidgets('App renders correctly', (WidgetTester tester) async {
    await tester.pumpWidget(const LrsNetChatApp());
    expect(find.text('LRS-Net Chat'), findsOneWidget);
    expect(find.text('Chat'), findsOneWidget);
    expect(find.text('GPS'), findsOneWidget);
  });
}
