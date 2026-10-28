import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/util/portion_unit.dart';

/// One ingredient read from a typed list (#160) and checked on the bulk add
/// screen: the matched food and its amount in grams or millilitres, as the
/// recipe builder takes it.
class RecipeTextIngredient {
  final MealEntity meal;
  final double amount;

  /// `g` or `ml`.
  final String unit;

  const RecipeTextIngredient({
    required this.meal,
    required this.amount,
    required this.unit,
  });

  /// The unit of an amount that `convertQuantityToBaseUnit` turned from
  /// [rowUnit] into grams or millilitres: millilitres for the liquid units
  /// and for a serving of a liquid, grams otherwise.
  static String baseUnitOf(String rowUnit, MealEntity meal) =>
      switch (storedUnit(rowUnit)) {
        'ml' || 'fl.oz' => 'ml',
        'serving' when meal.isLiquid => 'ml',
        _ => 'g',
      };
}
