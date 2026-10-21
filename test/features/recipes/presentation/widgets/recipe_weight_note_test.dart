import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/features/recipes/presentation/widgets/recipe_weight_note.dart';
import 'package:opennutritracker/generated/l10n.dart';

Future<void> _pump(
  WidgetTester tester, {
  required double rawWeightG,
  required double cookedWeightG,
  VoidCallback? onReset,
}) => tester.pumpWidget(
  MaterialApp(
    localizationsDelegates: const [
      S.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: const [Locale('en')],
    home: Scaffold(
      body: RecipeWeightNote(
        rawWeightG: rawWeightG,
        cookedWeightG: cookedWeightG,
        onReset: onReset ?? () {},
      ),
    ),
  ),
);

void main() {
  testWidgets('a cooked weight shows next to the raw one', (tester) async {
    var resets = 0;
    await _pump(
      tester,
      rawWeightG: 1000,
      cookedWeightG: 800,
      onReset: () => resets++,
    );

    expect(find.text('Raw: 1000 g · cooked: 800 g'), findsOneWidget);
    await tester.tap(find.text('Use the ingredients\' sum'));
    expect(resets, 1);
  });

  testWidgets('without a cooked weight it names the raw sum', (tester) async {
    await _pump(tester, rawWeightG: 1000, cookedWeightG: 1000);

    expect(find.text('Ingredients raw: 1000 g'), findsOneWidget);
    expect(find.text('Use the ingredients\' sum'), findsNothing);
  });
}
