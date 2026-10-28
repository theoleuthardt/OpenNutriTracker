import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/features/portions/domain/own_portion.dart';
import 'package:opennutritracker/features/portions/presentation/own_portions_dialog.dart';
import 'package:opennutritracker/generated/l10n.dart';

Finder _byId(String id) => find.byWidgetPredicate(
  (widget) => widget is Semantics && widget.properties.identifier == id,
);

Finder _field(String id) =>
    find.descendant(of: _byId(id), matching: find.byType(TextField));

class _Opened {
  late Future<List<OwnPortion>?> result;
}

Future<_Opened> _open(
  WidgetTester tester, {
  List<OwnPortion> initial = const [],
}) async {
  final opened = _Opened();
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: const [S.delegate],
      supportedLocales: S.supportedLocales,
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => opened.result = showOwnPortionsDialog(
              context,
              initial: initial,
              unit: 'g',
            ),
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return opened;
}

void main() {
  testWidgets('lists the portions already set', (tester) async {
    await _open(
      tester,
      initial: const [OwnPortion(label: 'Riegel', amount: 25)],
    );

    expect(
      tester.widget<TextField>(_field('own-portion-label-0')).controller!.text,
      'Riegel',
    );
    expect(
      tester.widget<TextField>(_field('own-portion-amount-0')).controller!.text,
      '25',
    );
  });

  testWidgets('adds a portion and saves it', (tester) async {
    final opened = await _open(tester);

    await tester.tap(_byId('own-portions-add'));
    await tester.pumpAndSettle();
    await tester.enterText(_field('own-portion-label-0'), 'Stück');
    await tester.enterText(_field('own-portion-amount-0'), '120,5');
    await tester.tap(_byId('own-portions-save'));
    await tester.pumpAndSettle();

    expect(await opened.result, const [
      OwnPortion(label: 'Stück', amount: 120.5),
    ]);
  });

  testWidgets('changes and deletes portions', (tester) async {
    final opened = await _open(
      tester,
      initial: const [
        OwnPortion(label: 'Riegel', amount: 25),
        OwnPortion(label: 'Packung', amount: 150),
      ],
    );

    await tester.enterText(_field('own-portion-amount-0'), '30');
    await tester.tap(_byId('own-portion-delete-1'));
    await tester.pumpAndSettle();
    await tester.tap(_byId('own-portions-save'));
    await tester.pumpAndSettle();

    expect(await opened.result, const [
      OwnPortion(label: 'Riegel', amount: 30),
    ]);
  });

  testWidgets('deleting every portion saves none', (tester) async {
    final opened = await _open(
      tester,
      initial: const [OwnPortion(label: 'Riegel', amount: 25)],
    );

    await tester.tap(_byId('own-portion-delete-0'));
    await tester.pumpAndSettle();
    await tester.tap(_byId('own-portions-save'));
    await tester.pumpAndSettle();

    expect(await opened.result, isEmpty);
  });

  testWidgets('an incomplete portion is not saved', (tester) async {
    final opened = await _open(tester);

    await tester.tap(_byId('own-portions-add'));
    await tester.pumpAndSettle();
    await tester.enterText(_field('own-portion-label-0'), 'Stück');
    await tester.tap(_byId('own-portions-save'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text('Enter a name and a weight above zero'), findsOneWidget);

    await tester.enterText(_field('own-portion-amount-0'), '0');
    await tester.tap(_byId('own-portions-save'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);

    await tester.tap(find.text('CANCEL'));
    await tester.pumpAndSettle();
    expect(await opened.result, isNull);
  });

  testWidgets('an empty row is left out', (tester) async {
    final opened = await _open(
      tester,
      initial: const [OwnPortion(label: 'Riegel', amount: 25)],
    );

    await tester.tap(_byId('own-portions-add'));
    await tester.pumpAndSettle();
    await tester.tap(_byId('own-portions-save'));
    await tester.pumpAndSettle();

    expect(await opened.result, const [
      OwnPortion(label: 'Riegel', amount: 25),
    ]);
  });
}
