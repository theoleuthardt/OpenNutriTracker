import 'package:flutter/foundation.dart';
import 'package:opennutritracker/core/data/data_source/config_data_source.dart';

/// Whether the home page shows the recipes section (#159). Stored app-wide
/// in the config (field 119), shown unless switched off; [changes] fires
/// after every save.
class HomeRecipesSetting {
  final ConfigDataSource _config;
  final changes = ValueNotifier<int>(0);

  HomeRecipesSetting(this._config);

  Future<bool> visible() async =>
      (await _config.getConfig()).showHomeRecipes ?? true;

  Future<void> save(bool visible) async {
    final config = await _config.getConfig();
    config.showHomeRecipes = visible;
    await _config.addConfig(config);
    changes.value++;
  }
}
