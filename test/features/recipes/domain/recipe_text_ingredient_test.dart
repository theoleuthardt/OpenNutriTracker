import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';
import 'package:opennutritracker/features/recipes/domain/recipe_text_ingredient.dart';

MealEntity _food(String unit) => MealEntity(
  code: unit,
  name: unit,
  url: null,
  mealQuantity: null,
  mealUnit: unit,
  servingQuantity: 250,
  servingUnit: unit,
  servingSize: null,
  nutriments: MealNutrimentsEntity.empty(),
  source: MealSourceEntity.off,
);

void main() {
  test('liquid units stay millilitres, the rest is grams', () {
    final solid = _food('g');
    expect(RecipeTextIngredient.baseUnitOf('g', solid), 'g');
    expect(RecipeTextIngredient.baseUnitOf('oz', solid), 'g');
    expect(RecipeTextIngredient.baseUnitOf('ml', solid), 'ml');
    expect(RecipeTextIngredient.baseUnitOf('fl.oz', solid), 'ml');
  });

  test('a serving follows the food', () {
    expect(RecipeTextIngredient.baseUnitOf('serving', _food('g')), 'g');
    expect(RecipeTextIngredient.baseUnitOf('serving', _food('ml')), 'ml');
    expect(RecipeTextIngredient.baseUnitOf('serving#1', _food('ml')), 'ml');
  });
}
