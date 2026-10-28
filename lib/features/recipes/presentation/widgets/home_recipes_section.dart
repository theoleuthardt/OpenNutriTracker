import 'package:flutter/material.dart';
import 'package:opennutritracker/core/data/repository/recipe_repository.dart';
import 'package:opennutritracker/core/domain/entity/recipe_entity.dart';
import 'package:opennutritracker/core/domain/usecase/get_intake_usecase.dart';
import 'package:opennutritracker/core/presentation/widgets/app_card.dart';
import 'package:opennutritracker/core/styles/app_palette.dart';
import 'package:opennutritracker/core/styles/dimens.dart';
import 'package:opennutritracker/core/utils/energy_display.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/core/utils/navigation_options.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/favorites/domain/favorites_usecase.dart';
import 'package:opennutritracker/features/recipes/domain/home_recipes.dart';
import 'package:opennutritracker/features/recipes/domain/home_recipes_setting.dart';
import 'package:opennutritracker/features/recipes/presentation/log_recipe.dart';
import 'package:opennutritracker/features/recipes/presentation/screens/recipe_builder_screen.dart';
import 'package:opennutritracker/generated/l10n.dart';

/// Whether the section shows and the recipes it offers.
typedef HomeRecipesData = ({bool visible, List<RecipeEntity> recipes});

Future<HomeRecipesData> _loadFromApp() async {
  if (!await locator<HomeRecipesSetting>().visible()) {
    return (visible: false, recipes: const <RecipeEntity>[]);
  }
  final recipes = locator<RecipeRepository>().getAllRecipes();
  final favorites = locator<FavoritesUsecase>();
  final recent = await locator<GetIntakeUsecase>().getRecentIntake();
  recent.sort((a, b) => b.dateTime.compareTo(a.dateTime));
  return (
    visible: true,
    recipes: homeRecipes(
      recipes: recipes,
      favoriteIds: {
        for (final recipe in recipes)
          if (favorites.isRecipeFavorite(recipe.id)) recipe.id,
      },
      recentlyLoggedIds: [
        for (final intake in recent)
          if (intake.meal.source == MealSourceEntity.recipe &&
              intake.meal.code != null)
            intake.meal.code!,
      ],
    ),
  );
}

/// The recipes section of the home page (#159): the recipes from
/// [homeRecipes] as cards that log with one tap, "All", and new recipes from
/// scratch or from a typed list. Hidden with the setting.
class HomeRecipesSection extends StatefulWidget {
  final Future<HomeRecipesData> Function() load;
  final Future<void> Function(BuildContext context, RecipeEntity recipe) onLog;

  /// What makes the section load again; the setting and the recipes when
  /// null.
  final List<Listenable>? refreshOn;

  const HomeRecipesSection({
    super.key,
    this.load = _loadFromApp,
    this.onLog = logRecipe,
    this.refreshOn,
  });

  @override
  State<HomeRecipesSection> createState() => _HomeRecipesSectionState();
}

class _HomeRecipesSectionState extends State<HomeRecipesSection> {
  HomeRecipesData? _data;
  late final List<Listenable> _sources =
      widget.refreshOn ??
      [
        locator<HomeRecipesSetting>().changes,
        locator<RecipeRepository>().changes,
      ];

  @override
  void initState() {
    super.initState();
    for (final source in _sources) {
      source.addListener(_reload);
    }
    _reload();
  }

  @override
  void didUpdateWidget(HomeRecipesSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    _reload();
  }

  @override
  void dispose() {
    for (final source in _sources) {
      source.removeListener(_reload);
    }
    super.dispose();
  }

  Future<void> _reload() async {
    final data = await widget.load();
    if (mounted) setState(() => _data = data);
  }

  Future<void> _open(String route, {Object? arguments}) async {
    await Navigator.of(context).pushNamed(route, arguments: arguments);
    await _reload();
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;
    if (data == null || !data.visible) return const SizedBox.shrink();
    final s = S.of(context);
    final theme = Theme.of(context);
    final palette = theme.brightness == Brightness.dark
        ? AppPalette.dark
        : AppPalette.light;

    Widget newButton({required bool fromText}) => Semantics(
      identifier: fromText ? 'home-recipes-from-text' : 'home-recipes-new',
      child: TextButton.icon(
        onPressed: () => _open(
          NavigationOptions.recipeBuilderRoute,
          arguments: RecipeBuilderArguments(startFromText: fromText),
        ),
        icon: Icon(fromText ? Icons.notes_rounded : Icons.add_rounded),
        label: Text(fromText ? s.recipeNewFromTextAction : s.createRecipeTitle),
      ),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Dimens.spacing16,
        Dimens.spacing8,
        Dimens.spacing16,
        Dimens.spacing8,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  s.recipesLabel,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (data.recipes.isNotEmpty)
                PopupMenuButton<bool>(
                  tooltip: s.createRecipeTitle,
                  icon: const Icon(Icons.add_rounded),
                  onSelected: (fromText) => _open(
                    NavigationOptions.recipeBuilderRoute,
                    arguments: RecipeBuilderArguments(startFromText: fromText),
                  ),
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: false,
                      child: Text(s.createRecipeTitle),
                    ),
                    PopupMenuItem(
                      value: true,
                      child: Text(s.recipeNewFromTextAction),
                    ),
                  ],
                ),
              Semantics(
                identifier: 'home-recipes-all',
                child: TextButton(
                  onPressed: () => _open(NavigationOptions.recipesRoute),
                  child: Text(s.homeRecipesAll),
                ),
              ),
            ],
          ),
          if (data.recipes.isEmpty)
            AppCard(
              padding: const EdgeInsets.all(Dimens.spacing16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.homeRecipesEmpty,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: palette.textMuted,
                    ),
                  ),
                  Wrap(
                    spacing: Dimens.spacing8,
                    children: [
                      newButton(fromText: false),
                      newButton(fromText: true),
                    ],
                  ),
                ],
              ),
            )
          else
            SizedBox(
              height: 92,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: data.recipes.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(width: Dimens.spacing8),
                itemBuilder: (context, index) => _RecipeCard(
                  recipe: data.recipes[index],
                  onTap: () => widget.onLog(context, data.recipes[index]),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _RecipeCard extends StatelessWidget {
  final RecipeEntity recipe;
  final VoidCallback onTap;

  const _RecipeCard({required this.recipe, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final theme = Theme.of(context);
    final palette = theme.brightness == Brightness.dark
        ? AppPalette.dark
        : AppPalette.light;
    final per100 = recipe.aggregatedNutrimentsPer100.energyKcal100;
    final servings = recipe.servingsCount ?? 0;
    final String? energy = per100 == null
        ? null
        : servings > 0
        ? s.homeRecipesPerServing(
            EnergyDisplay.formatWithUnit(
              context,
              per100 * recipe.totalWeightG / servings / 100,
            ),
          )
        : s.homeRecipesPer100g(EnergyDisplay.formatWithUnit(context, per100));
    return Semantics(
      identifier: 'home-recipe-${recipe.id}',
      button: true,
      child: SizedBox(
        width: 160,
        child: AppCard(
          padding: const EdgeInsets.all(Dimens.spacing12),
          child: InkWell(
            onTap: onTap,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  recipe.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (energy != null)
                  Text(
                    energy,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: palette.textMuted,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
