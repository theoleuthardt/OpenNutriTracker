import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/features/add_meal/data/dto/sp/sp_const.dart';
import 'package:opennutritracker/features/add_meal/data/dto/sp/sp_food_dto.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';

MealEntity _bls(String code) => MealEntity.fromSpFood(
  SpFoodDTO(
    foodId: 1,
    name: 'x',
    source: SPConst.blsSourceCode,
    sourceCode: code,
  ),
);

void main() {
  group('BLS foods measured in millilitres (#104)', () {
    for (final (code, name) in [
      ('F603600', 'Orangensaft'),
      ('F516600', 'Mangosaft'),
      ('F508700', 'Maracujanektar'),
      ('F032600', 'Smoothie'),
      ('C660000', 'Haferdrink'),
      ('H841100', 'Sojadrink'),
      ('H800000', 'Mandeldrink'),
      ('M111300', 'Vollmilch'),
      ('M113200', 'H-Milch fettarm'),
      ('M150000', 'Buttermilch'),
      ('M130300', 'Kefir'),
      ('N110000', 'Getränk (Gruppe N)'),
      ('P100000', 'alkoholisches Getränk (Gruppe P)'),
    ]) {
      test('$name ($code) is in ml', () {
        final meal = _bls(code);
        expect(meal.mealUnit, 'ml');
        expect(meal.servingUnit, 'ml');
      });
    }
  });

  group('solid BLS foods stay in grams', () {
    for (final (code, name) in [
      ('F110100', 'Apfel'),
      ('F202100', 'Nektarine'),
      ('F602300', 'Limettensaft Konzentrat'),
      ('M882000', 'Vollmilchpulver'),
      ('M141300', 'Joghurt'),
      ('M052000', 'Salzlakenkäse aus Kuhmilch'),
      ('H844000', 'Soja-Joghurtalternative'),
      ('C130000', 'Haferflocken'),
    ]) {
      test('$name ($code) is in g', () {
        expect(_bls(code).mealUnit, 'g');
      });
    }
  });

  test('the per-100 basis stays the same for liquids', () {
    final meal = MealEntity.fromSpFood(
      SpFoodDTO(
        foodId: 1,
        name: 'Orangensaft',
        source: SPConst.blsSourceCode,
        sourceCode: 'F603600',
        energyKcal100: 45,
      ),
    );

    expect(meal.nutriments.energyKcal100, 45);
  });

  test('other sources are not judged by BLS codes', () {
    expect(
      MealEntity.fromSpFood(
        SpFoodDTO(foodId: 1, name: 'x', source: 'fdc', sourceCode: 'F603600'),
      ).mealUnit,
      'g',
    );
  });
}
