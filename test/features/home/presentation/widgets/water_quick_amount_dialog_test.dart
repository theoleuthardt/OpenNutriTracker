import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/data/data_source/config_data_source.dart';
import 'package:opennutritracker/core/data/dbo/app_theme_dbo.dart';
import 'package:opennutritracker/core/data/dbo/config_dbo.dart';
import 'package:opennutritracker/features/home/domain/water_quick_amount.dart';
import 'package:opennutritracker/features/home/presentation/widgets/water_quick_amount_dialog.dart';
import 'package:opennutritracker/generated/l10n.dart';

import '../../../../helpers/test_l10n.dart';

class _FakeConfigDataSource implements ConfigDataSource {
  ConfigDBO config = ConfigDBO(false, false, false, AppThemeDBO.system);

  @override
  Future<ConfigDBO> getConfig() async => config;

  @override
  Future<void> addConfig(ConfigDBO configDBO) async => config = configDBO;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Unexpected call: ${invocation.memberName}');
}

void main() {
  testWidgets('saves the typed amount', (tester) async {
    final config = _FakeConfigDataSource();
    final quickAmount = WaterQuickAmount(config);
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en')],
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) =>
                    WaterQuickAmountDialog(quickAmount: quickAmount),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('330'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '600');
    await tester.tap(find.text(l10nEn.dialogOKLabel));
    await tester.pumpAndSettle();

    expect(config.config.waterQuickAmountMl, 600);
    expect(find.byType(WaterQuickAmountDialog), findsNothing);
  });
}
