import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/data/repository/recipe_repository.dart';
import 'package:opennutritracker/core/domain/entity/recipe_entity.dart';
import 'package:opennutritracker/core/domain/entity/recipe_ingredient_entity.dart';
import 'package:opennutritracker/core/domain/usecase/compute_recipe_nutrition_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/save_recipe_usecase.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';
import 'package:opennutritracker/features/recipes/presentation/bloc/recipe_builder_bloc.dart';

class _NoRepository implements RecipeRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Unexpected call: ${invocation.memberName}');
}

RecipeEntity _soup() => RecipeEntity(
  id: 'soup',
  name: 'Soup',
  description: null,
  ingredients: [
    RecipeIngredientEntity(
      snapshotMeal: MealEntity(
        code: 'veg',
        name: 'veg',
        url: null,
        mealQuantity: null,
        mealUnit: 'g',
        servingQuantity: null,
        servingUnit: null,
        servingSize: null,
        nutriments: MealNutrimentsEntity(
          energyKcal100: 100,
          carbohydrates100: null,
          fat100: null,
          proteins100: null,
          sugars100: null,
          saturatedFat100: null,
          fiber100: null,
        ),
        source: MealSourceEntity.off,
      ),
      amount: 1000,
      unit: 'g',
      convertedAmountG: 1000,
    ),
  ],
  totalWeightG: 800,
  aggregatedNutrimentsPer100: MealNutrimentsEntity.empty(),
  createdAt: DateTime.utc(2026, 1, 1),
  updatedAt: DateTime.utc(2026, 1, 1),
  servingsCount: null,
);

void main() {
  late RecipeBuilderBloc bloc;

  setUp(() {
    final compute = ComputeRecipeNutritionUseCase();
    bloc = RecipeBuilderBloc(
      compute,
      SaveRecipeUseCase(_NoRepository(), compute),
    );
  });

  tearDown(() => bloc.close());

  test('the raw weight is the sum of the ingredients', () async {
    bloc.add(InitializeBuilderEvent(existing: _soup()));
    await Future<void>.delayed(Duration.zero);

    expect(bloc.state.rawWeightG, 1000);
    expect(bloc.state.totalWeightG, 800);
  });

  test('resetting the cooked weight goes back to the raw weight', () async {
    bloc.add(InitializeBuilderEvent(existing: _soup()));
    bloc.add(const ResetTotalWeightEvent());
    await Future<void>.delayed(Duration.zero);

    expect(bloc.state.totalWeightOverridden, isFalse);
    expect(bloc.state.totalWeightG, 1000);
    expect(
      bloc.state.aggregatedNutrimentsPer100.energyKcal100,
      closeTo(100, 1e-9),
    );
  });
}
