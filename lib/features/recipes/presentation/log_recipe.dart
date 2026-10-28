import 'package:flutter/material.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
import 'package:opennutritracker/core/domain/entity/recipe_entity.dart';
import 'package:opennutritracker/core/domain/usecase/get_config_usecase.dart';
import 'package:opennutritracker/core/styles/app_palette.dart';
import 'package:opennutritracker/core/styles/dimens.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/core/utils/navigation_options.dart';
import 'package:opennutritracker/features/meal_detail/meal_detail_screen.dart';
import 'package:opennutritracker/generated/l10n.dart';

/// Logs [recipe] for today: asks for the meal, then opens the meal detail
/// for the amount, as the recipe detail and the home page do (#159).
Future<void> logRecipe(BuildContext context, RecipeEntity recipe) async {
  final intakeType = await _pickIntakeType(context);
  if (intakeType == null || !context.mounted) return;
  final config = await locator<GetConfigUsecase>().getConfig();
  if (!context.mounted) return;
  Navigator.of(context).pushNamed(
    NavigationOptions.mealDetailRoute,
    arguments: MealDetailScreenArguments(
      recipe.toMealEntity(),
      intakeType,
      DateTime.now(),
      config.usesImperialFoodUnits,
    ),
  );
}

Future<IntakeTypeEntity?> _pickIntakeType(BuildContext context) {
  final s = S.of(context);
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final palette = isDark ? AppPalette.dark : AppPalette.light;
  return showModalBottomSheet<IntakeTypeEntity>(
    context: context,
    builder: (ctx) {
      Widget tile(IntakeTypeEntity type, String label) {
        final accent = Theme.of(ctx).colorScheme.primary;
        return ListTile(
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.14),
              borderRadius: Dimens.borderRadiusS,
            ),
            child: Icon(type.getIconData(), color: accent, size: 22),
          ),
          title: Text(
            label,
            style: Theme.of(
              ctx,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          onTap: () => Navigator.of(ctx).pop(type),
        );
      }

      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: Dimens.spacing12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: palette.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: Dimens.spacing8),
            tile(IntakeTypeEntity.breakfast, s.breakfastLabel),
            tile(IntakeTypeEntity.lunch, s.lunchLabel),
            tile(IntakeTypeEntity.dinner, s.dinnerLabel),
            tile(IntakeTypeEntity.snack, s.snackLabel),
          ],
        ),
      );
    },
  );
}
