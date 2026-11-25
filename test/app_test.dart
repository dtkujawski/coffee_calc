import 'package:coffee_calc/main.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Pixel 8 screen: 1080x2400 at about 2.6x.
void pixel8(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 2.625;
  addTearDown(tester.view.reset);
}

void main() {
  testWidgets('opens on the date screen, sets roast, swipes to ratio', (tester) async {
    pixel8(tester);
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(CoffeeCalcApp(prefs: prefs));

    expect(find.text('Total'), findsOneWidget);

    await tester.tap(find.text('Roasted'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Today'));
    await tester.pumpAndSettle();
    expect(find.text('entered'), findsOneWidget);
    expect(find.text('0 days'), findsOneWidget);
    expect(prefs.getString('dateInputs'), contains('roasted'));

    await tester.fling(find.byType(PageView), const Offset(-400, 0), 1000);
    await tester.pumpAndSettle();
    expect(find.text('Brew Calculator'), findsOneWidget);
    expect(find.text('255g'), findsOneWidget); // 15g at the default 1:17
  });

  testWidgets('restores the last date inputs', (tester) async {
    SharedPreferences.setMockInitialValues({
      'dateInputs': '{"values":{"rested":12}}',
    });
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(CoffeeCalcApp(prefs: prefs));
    expect(find.text('12 days'), findsOneWidget);
    expect(find.text('entered'), findsOneWidget);
  });
}
