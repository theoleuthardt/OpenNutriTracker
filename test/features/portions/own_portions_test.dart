import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_portion_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/usecase/resolve_parsed_meals_usecase.dart';
import 'package:opennutritracker/features/add_meal/domain/usecase/search_products_usecase.dart';
import 'package:opennutritracker/features/add_meal/presentation/bloc/bulk_add_bloc.dart';
import 'package:opennutritracker/features/add_meal/util/portion_unit.dart';
import 'package:opennutritracker/features/meal_detail/util/meal_quantity_converter.dart';
import 'package:opennutritracker/features/portions/data/own_portion_data_source.dart';
import 'package:opennutritracker/features/portions/domain/own_portion.dart';

import '../../helpers/fake_hive_db_provider.dart';
import '../../unit_test/bulk_add_bloc_test.dart'
    show parse, parserOnlyReader, photoReaderWithoutKey;

class _OffSearch implements SearchProductsUseCase {
  final List<MealEntity> meals;

  _OffSearch(this.meals);

  @override
  Future<SearchProductsResult> searchOFFProductsByString(
    String searchString, {
    bool skipRemote = false,
  }) async => SearchProductsResult(meals: meals, remoteSourceEmpty: false);

  @override
  Future<SearchProductsResult> searchFDCFoodByString(
    String searchString, {
    bool skipRemote = false,
    bool forResolution = false,
  }) async => const SearchProductsResult(meals: [], remoteSourceEmpty: false);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

MealEntity _meal({
  String? code = '4001234567890',
  double? servingQuantity,
  String? servingSize,
  List<MealPortionEntity> portions = const [],
}) => MealEntity(
  code: code,
  name: 'Müsliriegel',
  url: null,
  mealQuantity: null,
  mealUnit: 'g',
  servingQuantity: servingQuantity,
  servingUnit: 'g',
  servingSize: servingSize,
  source: MealSourceEntity.off,
  nutriments: MealNutrimentsEntity.empty(),
  portions: portions,
);

void main() {
  group('OwnPortionDataSource', () {
    late Directory dir;
    late OwnPortionDataSource source;

    setUp(() async {
      dir = await Directory.systemTemp.createTemp('own_portions_test');
      Hive.init(dir.path);
      final box = await Hive.openBox<String>('own_portions');
      source = OwnPortionDataSource(FakeHiveDBProvider(ownPortionBox: box));
    });

    tearDown(() async {
      await Hive.close();
      await dir.delete(recursive: true);
    });

    test('keeps the portions of a food across reads', () async {
      await source.save('4001234567890', const [
        OwnPortion(label: 'Stück', amount: 25),
        OwnPortion(label: 'Packung', amount: 150),
      ]);

      expect(source.portionsFor('4001234567890'), const [
        OwnPortion(label: 'Stück', amount: 25),
        OwnPortion(label: 'Packung', amount: 150),
      ]);
      expect(source.portionsFor('other'), isEmpty);
      expect(source.all(), {
        '4001234567890': const [
          OwnPortion(label: 'Stück', amount: 25),
          OwnPortion(label: 'Packung', amount: 150),
        ],
      });
    });

    test('saving none forgets the food', () async {
      await source.save('a', const [OwnPortion(label: 'Stück', amount: 25)]);

      await source.save('a', const []);

      expect(source.all(), isEmpty);
    });

    test('putAll adds to what is there', () async {
      await source.save('a', const [OwnPortion(label: 'Stück', amount: 25)]);

      await source.putAll({
        'b': const [OwnPortion(label: 'Scheibe', amount: 20)],
      });

      expect(source.all().keys, unorderedEquals(['a', 'b']));
    });

    test('an unreadable entry is skipped', () async {
      await source.save('a', const [OwnPortion(label: 'Stück', amount: 25)]);
      await Hive.box<String>('own_portions').put('b', 'not json');

      expect(source.all().keys, ['a']);
      expect(source.portionsFor('b'), isEmpty);
    });
  });

  group('OwnPortion', () {
    test('round-trips through JSON', () {
      const portion = OwnPortion(label: 'Stück', amount: 25.5);

      expect(OwnPortion.fromJson(portion.toJson()), portion);
    });

    test('rejects a portion that cannot scale an amount', () {
      expect(
        () => OwnPortion.fromJson({'label': 'Stück', 'amount': 0}),
        throwsFormatException,
      );
      expect(
        () => OwnPortion.fromJson({'label': ' ', 'amount': 25}),
        throwsFormatException,
      );
    });
  });

  group('withOwnPortions', () {
    const bar = OwnPortion(label: 'Riegel', amount: 25);

    test('leaves a food without own portions alone', () {
      final meal = _meal(servingQuantity: 30);

      expect(identical(withOwnPortions(meal, const []), meal), isTrue);
    });

    test('adds them after the portions the food already has', () {
      const slice = MealPortionEntity(
        label: '1 Scheibe',
        gramWeight: 50,
        localized: true,
      );
      final meal = withOwnPortions(
        _meal(servingQuantity: 50, portions: const [slice]),
        const [bar],
      );

      expect(meal.portions, const [
        slice,
        MealPortionEntity(label: '1 Riegel', gramWeight: 25, localized: true),
      ]);
      expect(meal.servingQuantity, 50);
    });

    test('keeps the food\'s own serving as the first portion', () {
      final meal = withOwnPortions(
        _meal(servingQuantity: 30, servingSize: '1 bar (30 g)'),
        const [bar],
      );

      expect(
        [for (final p in meal.portions) p.label],
        ['1 bar (30 g)', '1 Riegel'],
      );
      expect(meal.portions.first.gramWeight, 30);
      expect(convertQuantityToBaseUnit(2, portionUnit(0), meal), 60);
      expect(convertQuantityToBaseUnit(2, portionUnit(1), meal), 50);
    });

    test('a food without a serving takes the first own portion as one', () {
      final meal = withOwnPortions(_meal(), const [bar]);

      expect(meal.servingQuantity, 25);
      expect(meal.servingSize, '1 Riegel (25 g)');
      expect(meal.portions, const [
        MealPortionEntity(label: '1 Riegel', gramWeight: 25, localized: true),
      ]);
      expect(convertQuantityToBaseUnit(3, portionUnit(0), meal), 75);
    });
  });

  group('bulk add', () {
    BulkAddBloc bloc(Map<String, List<OwnPortion>> own) => BulkAddBloc(
      ResolveParsedMealsUseCase(
        _OffSearch([_meal()]),
        ownPortions: (code) => own[code] ?? const [],
      ),
      parserOnlyReader(),
      photoReaderWithoutKey(),
    );

    double grams(BulkAddRow row) => convertQuantityToBaseUnit(
      double.parse(row.amountText),
      row.unit,
      row.meal!,
    );

    test('a bare count is a count of the own portion', () async {
      final row = (await parse(
        bloc({
          '4001234567890': const [OwnPortion(label: 'Riegel', amount: 25)],
        }),
        '2 Müsliriegel',
      )).rows.single;

      expect(grams(row), 50);
      expect(row.amountNeedsCheck, isFalse);
    });

    test('a named own portion is found by its word', () async {
      final row = (await parse(
        bloc({
          '4001234567890': const [
            OwnPortion(label: 'Riegel', amount: 25),
            OwnPortion(label: 'Packung', amount: 150),
          ],
        }),
        '1 Packung Müsliriegel',
      )).rows.single;

      expect(grams(row), 150);
    });

    test('without own portions the count is still flagged', () async {
      final row = (await parse(bloc(const {}), '2 Müsliriegel')).rows.single;

      expect(row.amountNeedsCheck, isTrue);
    });
  });
}
