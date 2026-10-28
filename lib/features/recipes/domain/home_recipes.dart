import 'package:opennutritracker/core/domain/entity/recipe_entity.dart';

/// The recipes the home page offers (#159), at most [limit]: favourites
/// first, then the ones logged most recently ([recentlyLoggedIds], newest
/// first), then the most recently changed. Ids of recipes that no longer
/// exist are ignored.
List<RecipeEntity> homeRecipes({
  required List<RecipeEntity> recipes,
  required Set<String> favoriteIds,
  required List<String> recentlyLoggedIds,
  int limit = 6,
}) {
  final byId = {for (final recipe in recipes) recipe.id: recipe};
  final newest = [...recipes]
    ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  final ordered = <String, RecipeEntity>{};
  void add(RecipeEntity? recipe) {
    if (recipe != null && ordered.length < limit) {
      ordered.putIfAbsent(recipe.id, () => recipe);
    }
  }

  for (final recipe in newest) {
    if (favoriteIds.contains(recipe.id)) add(recipe);
  }
  for (final id in recentlyLoggedIds) {
    add(byId[id]);
  }
  newest.forEach(add);
  return ordered.values.toList();
}
