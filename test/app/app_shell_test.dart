import 'package:flutter_test/flutter_test.dart';
import 'package:hooptrace/app/hoop_trace_app.dart';

void main() {
  testWidgets('HoopTrace app starts on home route', (tester) async {
    await tester.pumpWidget(const HoopTraceApp());
    await tester.pumpAndSettle();

    expect(find.text('寮€濮嬭鍒?'), findsOneWidget);
    expect(find.text('澶嶇洏鍘嗗彶'), findsOneWidget);
  });
}
