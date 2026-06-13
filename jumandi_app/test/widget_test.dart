import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jumandi_app/screens/splash/brand_splash_screen.dart';

void main() {
  testWidgets('Brand splash shows logo image', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: BrandSplashScreen()));
    expect(find.byType(Image), findsOneWidget);
  });
}
