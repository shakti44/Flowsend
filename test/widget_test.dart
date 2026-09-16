import 'package:flutter_test/flutter_test.dart';
import 'package:flowsend/main.dart';

void main() {
  testWidgets('FlowSend app launches and shows home screen', (tester) async {
    await tester.pumpWidget(const FlowSendApp());
    await tester.pump(const Duration(milliseconds: 100));
    // Home screen should show the "FlowSend" title
    expect(find.text('FlowSend'), findsWidgets);
  });
}
