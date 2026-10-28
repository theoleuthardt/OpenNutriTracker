import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/data/data_source/remote_search_cache_data_source.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
import 'package:opennutritracker/core/domain/usecase/add_intake_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/add_tracked_day_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_kcal_goal_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_macro_goal_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_tracked_day_usecase.dart';
import 'package:opennutritracker/features/add_meal/data/repository/products_repository.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_portion_entity.dart';
import 'package:opennutritracker/features/meal_detail/presentation/bloc/meal_detail_bloc.dart';
import 'package:opennutritracker/features/meal_detail/presentation/widgets/meal_detail_bottom_sheet.dart';
import 'package:opennutritracker/generated/l10n.dart';

class _RecordingAddIntakeUsecase extends Fake implements AddIntakeUsecase {
  final added = <IntakeEntity>[];

  @override
  Future<void> addIntake(IntakeEntity intakeEntity) async =>
      added.add(intakeEntity);
}

class _TrackedDayAlreadyThere extends Fake implements AddTrackedDayUsecase {
  @override
  Future<bool> hasTrackedDay(DateTime day) async => true;

  @override
  Future<void> addDayCaloriesTracked(DateTime day, double addCalories) async {}

  @override
  Future<void> addDayMacrosTracked(
    DateTime day, {
    double? carbsTracked,
    double? fatTracked,
    double? proteinTracked,
  }) async {}
}

class _FakeGetKcalGoalUsecase extends Fake implements GetKcalGoalUsecase {}

class _FakeGetMacroGoalUsecase extends Fake implements GetMacroGoalUsecase {}

class _FakeGetTrackedDayUsecase extends Fake implements GetTrackedDayUsecase {}

class _FakeProductsRepository extends Fake implements ProductsRepository {}

class _FakeRemoteSearchCacheDataSource extends Fake
    implements RemoteSearchCacheDataSource {
  @override
  Future<void> touch(String code) async {}
}

MealDetailBloc _buildBloc({AddIntakeUsecase? addIntake}) => MealDetailBloc(
  addIntake ?? _RecordingAddIntakeUsecase(),
  _TrackedDayAlreadyThere(),
  _FakeGetKcalGoalUsecase(),
  _FakeGetMacroGoalUsecase(),
  _FakeGetTrackedDayUsecase(),
  _FakeProductsRepository(),
  _FakeRemoteSearchCacheDataSource(),
);

const _nutriments = MealNutrimentsEntity(
  energyKcal100: 140,
  carbohydrates100: 1,
  fat100: 10,
  proteins100: 12,
  sugars100: 1,
  saturatedFat100: 3,
  fiber100: 0,
);

const _eggPortions = [
  MealPortionEntity(label: '1 Ei, mittel (M)', gramWeight: 50, localized: true),
  MealPortionEntity(label: '1 Ei, klein (S)', gramWeight: 44, localized: true),
  MealPortionEntity(label: '1 Ei, groß (L)', gramWeight: 56, localized: true),
];

MealEntity _egg({List<MealPortionEntity> portions = _eggPortions}) =>
    MealEntity(
      code: '930537146448',
      name: 'Hühnerei roh',
      url: null,
      mealQuantity: null,
      mealUnit: 'g',
      servingQuantity: 50,
      servingUnit: 'g',
      servingSize: '1 Ei, mittel (M) (50 g)',
      nutriments: _nutriments,
      source: MealSourceEntity.fdc,
      backendSource: 'bls',
      portions: portions,
    );

Future<void> _pumpSheet(
  WidgetTester tester, {
  required MealEntity product,
  required void Function(String?, String?) onChanged,
  MealDetailBloc? bloc,
  String selectedUnit = 'serving',
  VoidCallback? onEditOwnPortions,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: const [S.delegate],
      supportedLocales: S.supportedLocales,
      home: Scaffold(
        body: MealDetailBottomSheet(
          product: product,
          day: DateTime(2026, 10, 28),
          intakeTypeEntity: IntakeTypeEntity.breakfast,
          quantityTextController: TextEditingController(text: '2'),
          mealDetailBloc: bloc ?? _buildBloc(),
          selectedUnit: selectedUnit,
          onQuantityOrUnitChanged: onChanged,
          onEditOwnPortions: onEditOwnPortions,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _openUnitDropdown(WidgetTester tester) async {
  await tester.tap(find.byType(DropdownButtonFormField<String>));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('offers every portion of the food with its weight (#158)', (
    tester,
  ) async {
    await _pumpSheet(tester, product: _egg(), onChanged: (_, _) {});
    await _openUnitDropdown(tester);

    expect(find.text('1 Ei, mittel (M) · 50 g'), findsWidgets);
    expect(find.text('1 Ei, klein (S) · 44 g'), findsOneWidget);
    expect(find.text('1 Ei, groß (L) · 56 g'), findsOneWidget);
  });

  testWidgets('picking a portion reports its own unit', (tester) async {
    String? unit;
    await _pumpSheet(
      tester,
      product: _egg(),
      onChanged: (_, picked) => unit = picked,
    );
    await _openUnitDropdown(tester);

    await tester.tap(find.text('1 Ei, groß (L) · 56 g'));
    await tester.pumpAndSettle();

    expect(unit, 'serving#2');
  });

  testWidgets('a food without portions keeps its single serving', (
    tester,
  ) async {
    await _pumpSheet(
      tester,
      product: _egg(portions: const []),
      onChanged: (_, _) {},
    );
    await _openUnitDropdown(tester);

    expect(find.textContaining('· 50 g'), findsNothing);
    expect(find.textContaining('1 Ei, mittel (M) (50 g)'), findsWidgets);
  });

  testWidgets('logging a portion stores the plain serving unit', (
    tester,
  ) async {
    final addIntake = _RecordingAddIntakeUsecase();
    final bloc = _buildBloc(addIntake: addIntake);
    await _pumpSheet(
      tester,
      product: _egg(),
      onChanged: (_, _) {},
      bloc: bloc,
      selectedUnit: 'serving#2',
    );
    final context = tester.element(find.byType(MealDetailBottomSheet));

    await bloc.addIntake(
      context,
      'serving#2',
      '112',
      IntakeTypeEntity.breakfast,
      _egg(),
      DateTime(2026, 10, 28),
    );

    expect(addIntake.added.single.unit, 'serving');
    expect(addIntake.added.single.amount, 112);
  });

  testWidgets('offers to set own portions when the screen can (#164)', (
    tester,
  ) async {
    var opened = 0;
    await _pumpSheet(
      tester,
      product: _egg(),
      onChanged: (_, _) {},
      onEditOwnPortions: () => opened++,
    );

    await tester.tap(find.text('Set portion'));
    await tester.pumpAndSettle();

    expect(opened, 1);
  });

  testWidgets('without a way to save them there is no button', (tester) async {
    await _pumpSheet(tester, product: _egg(), onChanged: (_, _) {});

    expect(find.text('Set portion'), findsNothing);
  });

  testWidgets('a portion label that states its weight is not repeated', (
    tester,
  ) async {
    await _pumpSheet(
      tester,
      product: _egg(
        portions: const [
          MealPortionEntity(
            label: '1 slice (38 g)',
            gramWeight: 38,
            localized: false,
          ),
          MealPortionEntity(label: '1 Riegel', gramWeight: 25, localized: true),
        ],
      ),
      onChanged: (_, _) {},
    );
    await _openUnitDropdown(tester);

    expect(find.textContaining('(38 g) ·'), findsNothing);
    expect(find.text('1 Riegel · 25 g'), findsOneWidget);
  });
}
