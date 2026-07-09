import 'package:flutter_test/flutter_test.dart';
import 'package:hooptrace/app/hoop_trace_app.dart';
import 'package:hooptrace/app/orientation_shell.dart';
import 'package:hooptrace/features/pregame/pregame_page.dart';

void main() {
  testWidgets('HoopTrace app starts on home route', (tester) async {
    await tester.pumpWidget(const HoopTraceApp());
    await tester.pumpAndSettle();

    expect(find.text('\u5f00\u59cb\u8ba1\u5206'), findsOneWidget);
    expect(find.text('\u590d\u76d8\u5386\u53f2'), findsOneWidget);
  });

  testWidgets('start scoring route enters landscape scoring shell', (
    tester,
  ) async {
    await tester.pumpWidget(const HoopTraceApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('\u5f00\u59cb\u8ba1\u5206'));
    await tester.pumpAndSettle();
    expect(find.byType(PregamePage), findsOneWidget);

    await tester.tap(find.text(pregameStartMatchText));
    await tester.pumpAndSettle();

    expect(find.byType(OrientationShell), findsOneWidget);
  });
}
