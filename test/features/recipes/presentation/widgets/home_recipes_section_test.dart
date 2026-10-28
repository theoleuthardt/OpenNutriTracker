import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/domain/entity/recipe_entity.dart';
import 'package:opennutritracker/core/utils/energy_unit_provider.dart';
import 'package:opennutritracker/core/utils/navigation_options.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';
import 'package:opennutritracker/features/recipes/presentation/widgets/home_recipes_section.dart';
import 'package:opennutritracker/generated/l10n.dart';
import 'package:provider/provider.dart';

import '../../../../helpers/test_l10n.dart';

RecipeEntity _recipe(String name, {int? servings}) => RecipeEntity(
  id: name,
  name: name,
  description: null,
  ingredients: const [],
  totalWeightG: 800,
  aggregatedNutrimentsPer100: MealNutrimentsEntity(
    energyKcal100: 150,
    carbohydrates100: null,
    fat100: null,
    proteins100: null,
    sugars100: null,
    saturatedFat100: null,
    fiber100: null,
  ),
  createdAt: DateTime(2026, 10, 1),
  updatedAt: DateTime(2026, 10, 1),
  servingsCount: servings,
);

void main() {
  late List<String> logged;
  late List<RouteSettings> pushed;

  Future<void> pump(
    WidgetTester tester,
    ({bool visible, List<RecipeEntity> recipes}) data,
  ) async {
    logged = [];
    pushed = [];
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => EnergyUnitProvider(),
        child: MaterialApp(
          localizationsDelegates: const [
            S.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en')],
          onGenerateRoute: (settings) {
            if (settings.name != '/') pushed.add(settings);
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (_) => settings.name == '/'
                  ? Scaffold(
                      body: HomeRecipesSection(
                        load: () async => data,
                        onLog: (_, recipe) async => logged.add(recipe.id),
                        refreshOn: const [],
                      ),
                    )
                  : const Scaffold(body: Text('pushed')),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows the recipes in the order given, with their energy', (
    tester,
  ) async {
    await pump(tester, (
      visible: true,
      recipes: [_recipe('Porridge', servings: 4), _recipe('Chili')],
    ));

    expect(find.text(l10nEn.recipesLabel), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Porridge')).dx,
      lessThan(tester.getTopLeft(find.text('Chili')).dx),
    );
    expect(find.text(l10nEn.homeRecipesPerServing('300 kcal')), findsOneWidget);
    expect(find.text(l10nEn.homeRecipesPer100g('150 kcal')), findsOneWidget);
  });

  testWidgets('a tap logs the recipe', (tester) async {
    await pump(tester, (visible: true, recipes: [_recipe('Porridge')]));

    await tester.tap(find.bySemanticsIdentifier('home-recipe-Porridge'));
    await tester.pumpAndSettle();

    expect(logged, ['Porridge']);
  });

  testWidgets('without recipes it invites to create one', (tester) async {
    await pump(tester, (visible: true, recipes: const []));

    expect(find.text(l10nEn.homeRecipesEmpty), findsOneWidget);
    await tester.tap(find.bySemanticsIdentifier('home-recipes-from-text'));
    await tester.pumpAndSettle();

    expect(pushed.single.name, NavigationOptions.recipeBuilderRoute);
  });

  testWidgets('"All" opens the recipes', (tester) async {
    await pump(tester, (visible: true, recipes: [_recipe('Porridge')]));

    await tester.tap(find.bySemanticsIdentifier('home-recipes-all'));
    await tester.pumpAndSettle();

    expect(pushed.single.name, NavigationOptions.recipesRoute);
  });

  testWidgets('switched off it shows nothing', (tester) async {
    await pump(tester, (visible: false, recipes: [_recipe('Porridge')]));

    expect(find.text(l10nEn.recipesLabel), findsNothing);
    expect(find.text('Porridge'), findsNothing);
  });
}
