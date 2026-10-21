import 'package:flutter/material.dart';
import 'package:opennutritracker/core/styles/app_palette.dart';
import 'package:opennutritracker/generated/l10n.dart';

/// The line under the builder's weight field (#55): the ingredients' raw
/// weight, and with a weight after cooking both of them and a button that
/// goes back to the raw sum.
class RecipeWeightNote extends StatelessWidget {
  final double rawWeightG;
  final double cookedWeightG;
  final VoidCallback onReset;

  const RecipeWeightNote({
    super.key,
    required this.rawWeightG,
    required this.cookedWeightG,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final theme = Theme.of(context);
    final palette = theme.brightness == Brightness.dark
        ? AppPalette.dark
        : AppPalette.light;
    final style = theme.textTheme.bodySmall?.copyWith(color: palette.textMuted);
    final raw = rawWeightG.toStringAsFixed(0);
    final cooked = cookedWeightG.toStringAsFixed(0);
    if (raw == cooked) {
      return Text(s.recipeRawWeightLabel(raw), style: style);
    }
    return Row(
      children: [
        Expanded(
          child: Text(
            s.recipeRawAndCookedWeightLabel(raw, cooked),
            style: style,
          ),
        ),
        TextButton(
          onPressed: onReset,
          child: Text(s.recipeUseIngredientSumLabel),
        ),
      ],
    );
  }
}
