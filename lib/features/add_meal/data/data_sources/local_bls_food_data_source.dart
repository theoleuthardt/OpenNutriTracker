import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:opennutritracker/core/data/data_source/config_data_source.dart';
import 'package:opennutritracker/core/utils/app_locale.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/features/add_meal/data/data_sources/bls_portions.dart';
import 'package:opennutritracker/features/add_meal/data/data_sources/local_bls_catalog.dart';
import 'package:opennutritracker/features/add_meal/data/data_sources/local_food_catalog.dart';
import 'package:opennutritracker/features/add_meal/data/data_sources/sp_food_data_source.dart';
import 'package:opennutritracker/features/add_meal/data/dto/sp/sp_const.dart';
import 'package:opennutritracker/features/add_meal/data/dto/sp/sp_food_dto.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_portion_entity.dart';

const _assetPath = 'assets/bls/bls_4_0.json.gz';

Future<LocalBlsCatalog> _loadBundledCatalog() async {
  final data = await rootBundle.load(_assetPath);
  return compute(LocalBlsCatalog.decode, data.buffer.asUint8List());
}

Future<bool> _blsSwitchedOn() async {
  final toggles = await locator<ConfigDataSource>().getFoodSourceToggles();
  return toggles?[SPConst.blsSourceCode] ?? true;
}

/// The fork's reference food database: the BLS 4.0 shipped as a local asset
/// (see `tool/bls/`), searched offline. It stands where upstream's Supabase
/// source stood and hands out the same records, so ranking, the meal detail
/// and the BLS source label work unchanged.
///
/// The catalog is decoded once, off the UI isolate, on the first search.
///
/// Portions come from the fork's own table, [blsPortions] (#158): the
/// BLS has none. A counted food carries its first portion as the record's
/// serving, labelled in English like every backend record, and
/// [fetchPortionLabels] puts the German label in its place for a German
/// reader, as the backend's verified translations did.
class LocalBlsFoodDataSource extends SpFoodDataSource {
  /// Keeps BLS ids clear of the backend's numeric food ids.
  static const _idOffset = 900000000000;

  final Future<LocalBlsCatalog> Function() _loadCatalog;
  final Future<bool> Function() _isEnabled;
  final String Function() _localeName;
  Future<LocalBlsCatalog>? _catalog;
  Set<String>? _portionWords;

  LocalBlsFoodDataSource({
    Future<LocalBlsCatalog> Function()? loadCatalog,
    Future<bool> Function()? isEnabled,
    String Function()? localeName,
  }) : _loadCatalog = loadCatalog ?? _loadBundledCatalog,
       _isEnabled = isEnabled ?? _blsSwitchedOn,
       _localeName = localeName ?? (() => AppLocale.localeName);

  @override
  Future<List<SpFoodDTO>> fetchSearchWordResults(
    String searchString, {
    bool forResolution = false,
  }) async {
    if (!await _isEnabled()) return const [];
    final catalog = await (_catalog ??= _loadCatalog());
    final german = _german;
    var foods = catalog.search(searchString, limit: SPConst.maxNumberOfItems);
    if (foods.isEmpty) {
      final withoutPortion = _withoutPortionWords(searchString, catalog);
      if (withoutPortion != null) {
        foods = catalog.search(withoutPortion, limit: SPConst.maxNumberOfItems);
      }
    }
    return [for (final food in foods) _toDto(food, german: german)];
  }

  /// [query] without the words that name a portion, or null when it has
  /// none or nothing else.
  ///
  /// The text parser leaves a portion word in the query ("3 Scheiben
  /// Vollkornbrot", "2 große Eier") for the portion matcher to find, but the
  /// catalog wants every word in the food's name and so finds nothing. Only
  /// asked when the whole query found nothing, so "Eier gekocht" keeps its
  /// word. The words are those of the table's German labels that are in no
  /// name of a food in the table, so "Banane" stays a food and "Scheibe" or
  /// "groß" go, each also with an ending of up to two letters.
  String? _withoutPortionWords(String query, LocalBlsCatalog catalog) {
    final portionWords = _portionWords ??= _portionWordsOf(catalog);
    final words = query.split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
    final kept = [
      for (final word in words)
        if (!portionWords.any((term) => _namesPortion(word, term))) word,
    ];
    if (kept.isEmpty || kept.length == words.length) return null;
    return kept.join(' ');
  }

  static bool _namesPortion(String word, String term) {
    final lower = word.toLowerCase();
    return lower.startsWith(term) && lower.length - term.length <= 2;
  }

  static Set<String> _portionWordsOf(LocalBlsCatalog catalog) {
    final names = [
      for (final food in catalog.foods)
        if (blsPortions.containsKey(food.code)) food.nameDe.toLowerCase(),
    ];
    return {
      for (final food in blsPortions.values)
        for (final portion in food.portions)
          for (final word
              in portion.de
                  .replaceAll(RegExp(r'\([^)]*\)'), ' ')
                  .toLowerCase()
                  .split(RegExp(r'[^\p{L}]+', unicode: true)))
            if (word.length >= 3 && !names.any((name) => name.contains(word)))
              word,
    };
  }

  @override
  Future<Map<int, String>> fetchPortionLabels(List<int> foodIds) async {
    if (!_german) return const {};
    return {
      for (final id in foodIds)
        if (_tableEntry(id) case (final code, final food) when food.counted)
          id: _labelWithAmount(food.portions.first, code, german: true),
    };
  }

  @override
  Future<Map<int, List<MealPortionEntity>>?> fetchPortions(
    List<int> foodIds,
  ) async {
    final german = _german;
    return {
      for (final id in foodIds)
        if (_tableEntry(id) case (_, final food))
          id: [
            for (final portion in food.portions)
              MealPortionEntity(
                label: german ? portion.de : portion.en,
                gramWeight: portion.amount,
                localized: german,
                englishLabel: portion.en,
              ),
          ],
    };
  }

  bool get _german => _localeName().toLowerCase().startsWith('de');

  /// The BLS code behind [id] and its table entry, or null for a food the
  /// table does not know or an id that is not a BLS one.
  static (String, BlsFoodPortions)? _tableEntry(int id) {
    if (id <= _idOffset) return null;
    final code = (id - _idOffset).toRadixString(36).toUpperCase();
    final food = blsPortions[code];
    return food == null ? null : (code, food);
  }

  /// "1 Banane, mittel (118 g)": the label with what the portion weighs, in
  /// millilitres for a drink. The table holds no M2 milk drink, so the code
  /// alone decides that.
  static String _labelWithAmount(
    BlsPortion portion,
    String code, {
    required bool german,
  }) {
    final unit = SPConst.isBlsLiquid(code) ? 'ml' : 'g';
    final amount = portion.amount == portion.amount.roundToDouble()
        ? portion.amount.toInt().toString()
        : german
        ? portion.amount.toString().replaceAll('.', ',')
        : portion.amount.toString();
    return '${german ? portion.de : portion.en} ($amount $unit)';
  }

  static SpFoodDTO _toDto(BlsFood food, {required bool german}) {
    final portions = blsPortions[food.code];
    final serving = portions != null && portions.counted
        ? portions.portions.first
        : null;
    return localFoodDto(
      foodId: _idOffset + int.parse(food.code, radix: 36),
      source: SPConst.blsSourceCode,
      sourceCode: food.code,
      name: food.nameEn ?? food.nameDe,
      localizedName: german ? food.nameDe : null,
      values: food.values,
      servingSize: serving == null
          ? null
          : _labelWithAmount(serving, food.code, german: false),
      servingGramWeight: serving?.amount,
    );
  }
}
