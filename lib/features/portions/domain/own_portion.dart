import 'package:equatable/equatable.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_portion_entity.dart';

/// A portion the user set for one food (#164): "1 Stück = 25 g". [label]
/// is the measure without the count ("Stück", "Riegel"), [amount] what one
/// weighs in the food's base unit (grams, or millilitres for a drink).
class OwnPortion extends Equatable {
  final String label;
  final double amount;

  const OwnPortion({required this.label, required this.amount});

  /// Throws a [FormatException] for a portion that cannot scale an amount:
  /// no label, or no positive weight.
  factory OwnPortion.fromJson(Map<String, dynamic> json) {
    final label = json['label'];
    final amount = json['amount'];
    if (label is! String || label.trim().isEmpty) {
      throw const FormatException('An own portion needs a label');
    }
    if (amount is! num || amount <= 0) {
      throw const FormatException('An own portion needs a positive amount');
    }
    return OwnPortion(label: label.trim(), amount: amount.toDouble());
  }

  Map<String, dynamic> toJson() => {'label': label, 'amount': amount};

  @override
  List<Object?> get props => [label, amount];
}

/// [meal] with the user's own [portions] after the portions it already has.
///
/// The portion list's first entry is what the plain `serving` unit scales
/// by, so a food whose serving was not yet a portion gets it as the first
/// one and keeps opening on it. A food with no serving at all takes the
/// first own portion as its serving, which is what makes a bare count
/// ("2 Müsliriegel") a count of it in the bulk add.
MealEntity withOwnPortions(MealEntity meal, List<OwnPortion> portions) {
  if (portions.isEmpty) return meal;
  final own = [
    for (final portion in portions)
      MealPortionEntity(
        label: '1 ${portion.label}',
        gramWeight: portion.amount,
        localized: true,
      ),
  ];
  final serving = meal.scalableServingQuantity;
  if (meal.portions.isNotEmpty) {
    return meal.withPortions([...meal.portions, ...own]);
  }
  if (serving != null) {
    final servingSize = meal.servingSize?.trim();
    return meal.withPortions([
      MealPortionEntity(
        label: servingSize == null || servingSize.isEmpty
            ? '${_format(serving)} ${meal.servingUnit ?? 'g'}'
            : servingSize,
        gramWeight: serving,
        localized: meal.servingSizeIsLocalized,
      ),
      ...own,
    ]);
  }
  final first = portions.first;
  return MealEntity(
    code: meal.code,
    name: meal.name,
    brands: meal.brands,
    thumbnailImageUrl: meal.thumbnailImageUrl,
    mainImageUrl: meal.mainImageUrl,
    url: meal.url,
    mealQuantity: meal.mealQuantity,
    mealUnit: meal.mealUnit,
    servingQuantity: first.amount,
    servingUnit: meal.mealUnit,
    servingSize:
        '1 ${first.label} (${_format(first.amount)} ${meal.isLiquid ? 'ml' : 'g'})',
    nutriments: meal.nutriments,
    source: meal.source,
    backendSource: meal.backendSource,
    machineTranslatedName: meal.machineTranslatedName,
    servingSizeIsLocalized: true,
    portions: own,
    portionsUnavailable: meal.portionsUnavailable,
    localImagePath: meal.localImagePath,
    detailed: meal.detailed,
  );
}

String _format(double amount) => amount == amount.roundToDouble()
    ? amount.toInt().toString()
    : amount.toString();
