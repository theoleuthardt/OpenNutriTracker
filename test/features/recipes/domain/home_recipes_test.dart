import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/domain/entity/recipe_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';
import 'package:opennutritracker/features/recipes/domain/home_recipes.dart';

RecipeEntity _recipe(String id, {int updatedDay = 1}) => RecipeEntity(
  id: id,
  name: id,
  description: null,
  ingredients: const [],
  totalWeightG: 100,
  aggregatedNutrimentsPer100: MealNutrimentsEntity.empty(),
  createdAt: DateTime(2026, 10, 1),
  updatedAt: DateTime(2026, 10, updatedDay),
  servingsCount: null,
);

List<String> _ids(List<RecipeEntity> recipes) => [
  for (final r in recipes) r.id,
];

void main() {
  test('favourites first, then the recently logged, then the newest', () {
    final ordered = homeRecipes(
      recipes: [
        _recipe('old', updatedDay: 1),
        _recipe('fav', updatedDay: 2),
        _recipe('logged', updatedDay: 3),
        _recipe('new', updatedDay: 9),
      ],
      favoriteIds: {'fav'},
      recentlyLoggedIds: ['logged', 'fav'],
    );

    expect(_ids(ordered), ['fav', 'logged', 'new', 'old']);
  });

  test('the most recently logged leads among the logged', () {
    final ordered = homeRecipes(
      recipes: [_recipe('a'), _recipe('b')],
      favoriteIds: const {},
      recentlyLoggedIds: ['b', 'a', 'b'],
    );

    expect(_ids(ordered), ['b', 'a']);
  });

  test('cut to the limit, each recipe once', () {
    final ordered = homeRecipes(
      recipes: [for (var i = 1; i <= 9; i++) _recipe('r$i', updatedDay: i)],
      favoriteIds: {'r1'},
      recentlyLoggedIds: ['r1', 'r2'],
      limit: 4,
    );

    expect(_ids(ordered), ['r1', 'r2', 'r9', 'r8']);
  });

  test('logs and favourites of deleted recipes are ignored', () {
    final ordered = homeRecipes(
      recipes: [_recipe('a')],
      favoriteIds: {'gone'},
      recentlyLoggedIds: ['gone'],
    );

    expect(_ids(ordered), ['a']);
  });
}
