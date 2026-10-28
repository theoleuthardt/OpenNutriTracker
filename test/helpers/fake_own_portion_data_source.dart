import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/features/portions/data/own_portion_data_source.dart';
import 'package:opennutritracker/features/portions/domain/own_portion.dart';

/// In-memory [OwnPortionDataSource] for widget tests of the meal detail.
class FakeOwnPortionDataSource extends Fake implements OwnPortionDataSource {
  final byCode = <String, List<OwnPortion>>{};

  @override
  List<OwnPortion> portionsFor(String code) => byCode[code] ?? const [];

  @override
  Future<void> save(String code, List<OwnPortion> portions) async {
    if (portions.isEmpty) {
      byCode.remove(code);
    } else {
      byCode[code] = portions;
    }
  }
}
