import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_tracker/widgets/lb_kg_fields.dart';

void main() {
  testWidgets('typing lb fills kg and typing kg fills lb', (tester) async {
    double? reported = -1;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LbKgFields(
            valueLb: 66,
            decoration: (unit) => InputDecoration(labelText: unit),
            onChanged: (lb) => reported = lb,
          ),
        ),
      ),
    );
    final fields = find.byType(TextField);
    String text(int i) =>
        tester.widget<TextField>(fields.at(i)).controller!.text;

    expect(text(0), '66');
    expect(text(1), '29.9');

    await tester.enterText(fields.at(0), '100');
    expect(text(1), '45.4');
    expect(reported, 100);

    await tester.enterText(fields.at(1), '50');
    expect(text(0), '110.2');
    expect(reported, closeTo(110.23, 0.01));

    await tester.enterText(fields.at(1), '');
    expect(text(0), '');
    expect(reported, isNull);
  });
}
