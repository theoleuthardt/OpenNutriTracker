import 'dart:convert';

import 'package:logging/logging.dart';
import 'package:opennutritracker/core/utils/hive_db_provider.dart';
import 'package:opennutritracker/features/portions/domain/own_portion.dart';

/// The user's own portions (#164) in `OwnPortionBox`, one JSON list per
/// food keyed by the food's code. Shared by every profile like the custom
/// meals: a food weighs the same for everyone.
class OwnPortionDataSource {
  static final _log = Logger('OwnPortionDataSource');

  final HiveDBProvider _db;

  OwnPortionDataSource(this._db);

  /// The portions set for the food [code], none when there are none or the
  /// entry cannot be read.
  List<OwnPortion> portionsFor(String code) {
    final raw = _db.ownPortionBox.get(code);
    if (raw == null) return const [];
    return _decode(code, raw) ?? const [];
  }

  /// Every food with own portions; an unreadable entry is skipped.
  Map<String, List<OwnPortion>> all() => {
    for (final code in _db.ownPortionBox.keys.cast<String>())
      code: ?_decode(code, _db.ownPortionBox.get(code)!),
  };

  /// Replaces the portions of the food [code]; none forgets the food.
  Future<void> save(String code, List<OwnPortion> portions) => portions.isEmpty
      ? _db.ownPortionBox.delete(code)
      : _db.ownPortionBox.put(code, _encode(portions));

  Future<void> putAll(Map<String, List<OwnPortion>> byCode) =>
      _db.ownPortionBox.putAll({
        for (final MapEntry(key: code, value: portions) in byCode.entries)
          code: _encode(portions),
      });

  static String _encode(List<OwnPortion> portions) =>
      jsonEncode([for (final portion in portions) portion.toJson()]);

  static List<OwnPortion>? _decode(String code, String raw) {
    try {
      return [
        for (final json in jsonDecode(raw) as List<dynamic>)
          OwnPortion.fromJson(json as Map<String, dynamic>),
      ];
    } on Object catch (error) {
      _log.warning('Skipping unreadable own portions of $code', error);
      return null;
    }
  }
}
