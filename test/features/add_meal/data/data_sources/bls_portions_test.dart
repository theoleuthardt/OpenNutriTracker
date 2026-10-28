import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/features/add_meal/data/data_sources/bls_portions.dart';
import 'package:opennutritracker/features/add_meal/data/data_sources/local_bls_catalog.dart';
import 'package:opennutritracker/features/add_meal/data/data_sources/local_bls_food_data_source.dart';
import 'package:opennutritracker/features/add_meal/data/data_sources/local_reference_food_data_source.dart';
import 'package:opennutritracker/features/add_meal/data/data_sources/off_data_source.dart';
import 'package:opennutritracker/features/add_meal/data/repository/products_repository.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/usecase/resolve_parsed_meals_usecase.dart';
import 'package:opennutritracker/features/add_meal/domain/usecase/search_products_usecase.dart';
import 'package:opennutritracker/features/add_meal/presentation/bloc/bulk_add_bloc.dart';
import 'package:opennutritracker/features/add_meal/util/portion_label.dart';
import 'package:opennutritracker/features/meal_detail/util/meal_quantity_converter.dart';

import '../../../../unit_test/bulk_add_bloc_test.dart'
    show parserOnlyReader, photoReaderWithoutKey, parse;

class _NoOff implements OFFDataSource {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// The resolver's search over the real BLS asset, through the repository
/// that attaches the portions, so the test sees what the app sees.
class _BlsSearch implements SearchProductsUseCase {
  final ProductsRepository repository;

  _BlsSearch(this.repository);

  @override
  Future<SearchProductsResult> searchOFFProductsByString(
    String searchString, {
    bool skipRemote = false,
  }) async => const SearchProductsResult(meals: [], remoteSourceEmpty: false);

  @override
  Future<SearchProductsResult> searchFDCFoodByString(
    String searchString, {
    bool skipRemote = false,
    bool forResolution = false,
  }) async => SearchProductsResult(
    meals: await repository.getSupabaseFoodsByString(
      searchString,
      forResolution: forResolution,
    ),
    remoteSourceEmpty: false,
  );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  final catalog = LocalBlsCatalog.decode(
    File('assets/bls/bls_4_0.json.gz').readAsBytesSync(),
  );
  final codes = {for (final food in catalog.foods) food.code};

  LocalBlsFoodDataSource source({String locale = 'de_DE'}) =>
      LocalBlsFoodDataSource(
        loadCatalog: () async => catalog,
        isEnabled: () async => true,
        localeName: () => locale,
      );

  group('the portion table', () {
    test('covers at least 80 foods, all of them in the BLS', () {
      expect(blsPortions.length, greaterThanOrEqualTo(80));
      expect(blsPortions.keys.where((code) => !codes.contains(code)), isEmpty);
    });

    test('every portion has a weight and both labels', () {
      for (final MapEntry(key: code, value: food) in blsPortions.entries) {
        expect(food.portions, isNotEmpty, reason: code);
        for (final portion in food.portions) {
          expect(portion.amount, greaterThan(0), reason: code);
          expect(portion.de, startsWith('1 '), reason: code);
          expect(portion.en, startsWith('1 '), reason: code);
        }
      }
    });

    test('every German label fits the unit dropdown', () {
      for (final food in blsPortions.values) {
        for (final portion in food.portions) {
          expect(
            householdPortionLabel(
              portion.de,
              languageCode: 'de',
              textIsLocalized: true,
            ),
            isNotNull,
            reason: portion.de,
          );
        }
      }
    });

    test('eggs come in S, M, L and XL, with M as the default', () {
      for (final code in [
        'E111100',
        'E111132',
        'Y710142',
        'Y710162',
        'Y720143',
        'Y720163',
        'Y740162',
        'Y740342',
        'E107122',
        'Y740842',
        'E111182',
      ]) {
        final portions = blsPortions[code]!.portions;
        expect(
          [for (final p in portions) p.de],
          [
            '1 Ei, mittel (M)',
            '1 Ei, klein (S)',
            '1 Ei, groß (L)',
            '1 Ei, sehr groß (XL)',
          ],
          reason: code,
        );
      }
      expect(
        [for (final p in blsPortions['E111100']!.portions) p.amount],
        [50, 44, 56, 63],
      );
    });

    test('bananas and apples come in small, medium and large', () {
      for (final code in ['F503100', 'F110100']) {
        final portions = blsPortions[code]!.portions;
        expect(portions, hasLength(3), reason: code);
        expect(portions.first.en, contains('medium'), reason: code);
      }
      expect(blsPortions['F503100']!.portions.first.amount, 118);
    });
  });

  group('LocalBlsFoodDataSource', () {
    final bananaId = 900000000000 + int.parse('F503100', radix: 36);
    final oilId = 900000000000 + int.parse('Q120000', radix: 36);
    final unknownId = 900000000000 + int.parse('C131000', radix: 36);

    test('hands out the portions of the foods in the table', () async {
      final portions = await source().fetchPortions([bananaId, unknownId, 42]);

      expect(portions!.keys, [bananaId]);
      final banana = portions[bananaId]!;
      expect(
        [for (final p in banana) p.label],
        ['1 Banane, mittel', '1 Banane, klein', '1 Banane, groß'],
      );
      expect([for (final p in banana) p.gramWeight], [118, 101, 136]);
      expect(banana.first.localized, isTrue);
      expect(banana.first.englishLabel, '1 medium banana');
    });

    test('labels the portions in English outside German', () async {
      final banana = (await source(
        locale: 'en_US',
      ).fetchPortions([bananaId]))![bananaId]!;

      expect(banana.first.label, '1 medium banana');
      expect(banana.first.localized, isFalse);
    });

    test('a counted food defaults to its first portion', () async {
      final dto = (await source().fetchSearchWordResults('Banane')).first;
      expect(dto.sourceCode, 'F503100');

      final meal = MealEntity.fromSpFood(dto);
      expect(meal.servingQuantity, 118);
      expect(meal.servingSize, '1 medium banana (118 g)');
    });

    test('names the default portion in German', () async {
      final labels = await source().fetchPortionLabels([bananaId, unknownId]);

      expect(labels, {bananaId: '1 Banane, mittel (118 g)'});
      expect(
        await source(locale: 'en_US').fetchPortionLabels([bananaId]),
        isEmpty,
      );
    });

    test('a drink states its portion in millilitres', () async {
      final dto = (await source().fetchSearchWordResults(
        'Cola',
      )).firstWhere((dto) => dto.sourceCode == 'N330000');

      expect(MealEntity.fromSpFood(dto).servingSize, '1 glass (200 ml)');
    });

    test('a food measured by the spoon keeps grams as its default', () async {
      final dto = (await source().fetchSearchWordResults('Olivenöl')).first;
      expect(dto.sourceCode, 'Q120000');

      expect(MealEntity.fromSpFood(dto).servingQuantity, isNull);
      final oil = (await source().fetchPortions([oilId]))![oilId]!;
      expect(oil.first.label, '1 Esslöffel');
    });
  });

  group('a search naming a portion', () {
    Future<String?> firstCode(String query) async =>
        (await source().fetchSearchWordResults(query)).firstOrNull?.sourceCode;

    test('drops the portion words when nothing matches them', () async {
      expect(await firstCode('Scheiben Vollkornbrot'), 'B101000');
      expect(await firstCode('große Bananen'), 'F503100');
      expect(await firstCode('Esslöffel Olivenöl'), 'Q120000');
    });

    test('keeps every word when the full query matches', () async {
      expect(await firstCode('Eier gekocht'), 'Y740162');
    });

    test('finds nothing when only portion words are left', () async {
      expect(await firstCode('große Scheibe'), isNull);
    });
  });

  group('bulk add over the BLS', () {
    BulkAddBloc bloc() => BulkAddBloc(
      ResolveParsedMealsUseCase(
        _BlsSearch(
          ProductsRepository(
            _NoOff(),
            LocalReferenceFoodDataSource([source()]),
            countryTag: () async => null,
          ),
        ),
      ),
      parserOnlyReader(),
      photoReaderWithoutKey(),
    );

    double grams(BulkAddRow row) => convertQuantityToBaseUnit(
      double.parse(row.amountText),
      row.unit,
      row.meal!,
    );

    test('"2 Eier" are two medium eggs', () async {
      final row = (await parse(bloc(), '2 Eier')).rows.single;

      expect(grams(row), 100);
      expect(row.amountNeedsCheck, isFalse);
      expect(
        kcalForQuantity(double.parse(row.amountText), row.unit, row.meal!),
        closeTo(100 * row.meal!.nutriments.energyPerUnit!, 1e-9),
      );
    });

    test('"2 große Eier" are two large eggs', () async {
      final row = (await parse(bloc(), '2 große Eier')).rows.single;

      expect(grams(row), 112);
    });

    test('"1 Banane" is one medium banana', () async {
      final row = (await parse(bloc(), '1 Banane')).rows.single;

      expect(grams(row), 118);
    });

    test('"3 Scheiben Vollkornbrot" are three slices', () async {
      final row = (await parse(bloc(), '3 Scheiben Vollkornbrot')).rows.single;

      expect(grams(row), 150);
    });

    test('"2 Esslöffel Olivenöl" are two tablespoons', () async {
      final row = (await parse(bloc(), '2 Esslöffel Olivenöl')).rows.single;

      expect(grams(row), 27);
    });
  });
}
