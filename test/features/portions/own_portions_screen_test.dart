import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:opennutritracker/core/data/data_source/remote_search_cache_data_source.dart';
import 'package:opennutritracker/core/domain/entity/app_theme_entity.dart';
import 'package:opennutritracker/core/domain/entity/config_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
import 'package:opennutritracker/core/domain/entity/tracked_day_entity.dart';
import 'package:opennutritracker/core/domain/usecase/add_intake_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/add_tracked_day_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_config_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_intake_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_kcal_goal_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_macro_goal_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_tracked_day_usecase.dart';
import 'package:opennutritracker/core/utils/energy_unit_provider.dart';
import 'package:opennutritracker/core/utils/navigation_options.dart';
import 'package:opennutritracker/features/add_meal/data/repository/products_repository.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';
import 'package:opennutritracker/features/diary/presentation/bloc/calendar_day_bloc.dart';
import 'package:opennutritracker/features/diary/presentation/bloc/diary_bloc.dart';
import 'package:opennutritracker/features/home/presentation/bloc/home_bloc.dart';
import 'package:opennutritracker/features/meal_detail/meal_detail_screen.dart';
import 'package:opennutritracker/features/meal_detail/presentation/bloc/meal_detail_bloc.dart';
import 'package:opennutritracker/generated/l10n.dart';
import 'package:provider/provider.dart';
import 'package:opennutritracker/features/favorites/domain/favorites_usecase.dart';
import 'package:opennutritracker/features/portions/data/own_portion_data_source.dart';
import 'package:opennutritracker/features/portions/domain/own_portion.dart';
import '../../helpers/fake_favorites_usecase.dart';
import '../../helpers/fake_own_portion_data_source.dart';

// The own portions of a food (#164) in the real [MealDetailScreen]: read
// on open, set through the dialog, and the selection that follows.

const _nutriments = MealNutrimentsEntity(
  energyKcal100: 100,
  carbohydrates100: 10,
  fat100: 5,
  proteins100: 5,
  sugars100: 2,
  saturatedFat100: 1,
  fiber100: 1,
);

void main() {
  final getIt = GetIt.instance;
  MealDetailBloc? bloc;
  late FakeOwnPortionDataSource ownPortions;

  setUp(() {
    bloc = null;
    getIt.registerLazySingleton<MealDetailBloc>(
      () => bloc = MealDetailBloc(
        _FakeAddIntakeUsecase(),
        _FakeAddTrackedDayUsecase(),
        _FakeGetKcalGoalUsecase(),
        _FakeGetMacroGoalUsecase(),
        _FakeGetTrackedDayUsecase(),
        _FakeProductsRepository(),
        _FakeRemoteSearchCacheDataSource(),
      ),
    );
    getIt.registerLazySingleton<GetConfigUsecase>(_FakeGetConfigUsecase.new);
    getIt.registerLazySingleton<GetIntakeUsecase>(_FakeGetIntakeUsecase.new);
    getIt.registerLazySingleton<CacheManager>(_FakeCacheManager.new);
    getIt.registerLazySingleton<FavoritesUsecase>(FakeFavoritesUsecase.new);
    ownPortions = FakeOwnPortionDataSource();
    getIt.registerSingleton<OwnPortionDataSource>(ownPortions);
    getIt.registerLazySingleton<HomeBloc>(_FakeHomeBloc.new);
    getIt.registerLazySingleton<DiaryBloc>(_FakeDiaryBloc.new);
    getIt.registerLazySingleton<CalendarDayBloc>(_FakeCalendarDayBloc.new);
  });

  tearDown(() async {
    await getIt.reset();
  });

  Future<void> pumpMealDetail(WidgetTester tester, MealEntity meal) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final navigatorKey = GlobalKey<NavigatorState>();
    Route<void> routeFor(RouteSettings settings) {
      return MaterialPageRoute<void>(
        settings: settings,
        builder: (_) => const MealDetailScreen(),
      );
    }

    await tester.pumpWidget(
      ChangeNotifierProvider<EnergyUnitProvider>(
        create: (_) => EnergyUnitProvider(),
        child: MaterialApp(
          navigatorKey: navigatorKey,
          localizationsDelegates: const [S.delegate],
          supportedLocales: S.supportedLocales,
          initialRoute: NavigationOptions.mealDetailRoute,
          onGenerateInitialRoutes: (_) => [
            routeFor(
              RouteSettings(
                name: NavigationOptions.mealDetailRoute,
                arguments: MealDetailScreenArguments(
                  meal,
                  IntakeTypeEntity.breakfast,
                  DateTime(2026, 10, 28),
                  false,
                ),
              ),
            ),
          ],
          onGenerateRoute: routeFor,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  MealEntity bar() => MealEntity(
    code: '4001234567890',
    name: 'Müsliriegel',
    url: null,
    mealQuantity: null,
    mealUnit: 'g',
    servingQuantity: null,
    servingUnit: 'g',
    servingSize: null,
    nutriments: _nutriments,
    source: MealSourceEntity.custom,
  );

  Finder byId(String id) => find.byWidgetPredicate(
    (w) => w is Semantics && w.properties.identifier == id,
  );

  testWidgets('a food with an own portion opens on it (#164)', (tester) async {
    ownPortions.byCode['4001234567890'] = const [
      OwnPortion(label: 'Riegel', amount: 25),
    ];

    await pumpMealDetail(tester, bar());

    expect(bloc!.state.selectedUnit, 'serving');
    expect(bloc!.state.totalQuantityConverted, '25.0');
    expect(find.text('1 Riegel · 25 g'), findsOneWidget);
  });

  testWidgets('a portion set in the dialog is saved and offered', (
    tester,
  ) async {
    await pumpMealDetail(tester, bar());
    expect(bloc!.state.selectedUnit, 'g');

    await tester.tap(byId('meal-detail-own-portions'));
    await tester.pumpAndSettle();
    await tester.tap(byId('own-portions-add'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.descendant(
        of: byId('own-portion-label-0'),
        matching: find.byType(TextField),
      ),
      'Riegel',
    );
    await tester.enterText(
      find.descendant(
        of: byId('own-portion-amount-0'),
        matching: find.byType(TextField),
      ),
      '25',
    );
    await tester.tap(byId('own-portions-save'));
    await tester.pumpAndSettle();

    expect(ownPortions.portionsFor('4001234567890'), const [
      OwnPortion(label: 'Riegel', amount: 25),
    ]);
    expect(bloc!.state.selectedUnit, 'serving');
    expect(bloc!.state.totalQuantityConverted, '25.0');
  });

  testWidgets('deleting the selected own portion goes back to grams', (
    tester,
  ) async {
    ownPortions.byCode['4001234567890'] = const [
      OwnPortion(label: 'Riegel', amount: 25),
    ];
    await pumpMealDetail(tester, bar());

    await tester.tap(byId('meal-detail-own-portions'));
    await tester.pumpAndSettle();
    await tester.tap(byId('own-portion-delete-0'));
    await tester.pumpAndSettle();
    await tester.tap(byId('own-portions-save'));
    await tester.pumpAndSettle();

    expect(ownPortions.byCode, isEmpty);
    expect(bloc!.state.selectedUnit, 'g');
    expect(find.text('1 Riegel · 25 g'), findsNothing);
  });
}

class _FakeGetConfigUsecase implements GetConfigUsecase {
  @override
  Future<ConfigEntity> getConfig() async =>
      const ConfigEntity(true, true, false, AppThemeEntity.system);

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Unexpected call: ${invocation.memberName}');
}

class _FakeAddIntakeUsecase implements AddIntakeUsecase {
  @override
  Future<void> addIntake(IntakeEntity intakeEntity) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Unexpected call: ${invocation.memberName}');
}

class _FakeAddTrackedDayUsecase implements AddTrackedDayUsecase {
  @override
  Future<bool> hasTrackedDay(DateTime day) async => true;

  @override
  Future<void> addDayCaloriesTracked(DateTime day, double kcal) async {}

  @override
  Future<void> addDayMacrosTracked(
    DateTime day, {
    double? carbsTracked,
    double? fatTracked,
    double? proteinTracked,
  }) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Unexpected call: ${invocation.memberName}');
}

class _FakeGetKcalGoalUsecase implements GetKcalGoalUsecase {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Unexpected call: ${invocation.memberName}');
}

class _FakeGetMacroGoalUsecase implements GetMacroGoalUsecase {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Unexpected call: ${invocation.memberName}');
}

class _FakeGetTrackedDayUsecase implements GetTrackedDayUsecase {
  @override
  Future<TrackedDayEntity?> getTrackedDay(DateTime day) async =>
      TrackedDayEntity(
        day: day,
        calorieGoal: 2200,
        caloriesTracked: 800,
        carbsGoal: 250,
        carbsTracked: 100,
        fatGoal: 70,
        fatTracked: 30,
        proteinGoal: 120,
        proteinTracked: 50,
      );

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Unexpected call: ${invocation.memberName}');
}

class _FakeProductsRepository implements ProductsRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Unexpected call: ${invocation.memberName}');
}

class _FakeRemoteSearchCacheDataSource implements RemoteSearchCacheDataSource {
  @override
  Future<void> touch(String barcode) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Unexpected call: ${invocation.memberName}');
}

class _FakeGetIntakeUsecase implements GetIntakeUsecase {
  @override
  Future<List<IntakeEntity>> getBreakfastIntakeByDay(
    DateTime day, {
    int dayStartOffsetHours = 0,
    int dayStartOffsetMinutes = 0,
  }) async => [];

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Unexpected call: ${invocation.memberName}');
}

class _FakeHomeBloc implements HomeBloc {
  @override
  void add(HomeEvent event) {}

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Unexpected call: ${invocation.memberName}');
}

class _FakeDiaryBloc implements DiaryBloc {
  @override
  void add(DiaryEvent event) {}

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Unexpected call: ${invocation.memberName}');
}

class _FakeCalendarDayBloc implements CalendarDayBloc {
  @override
  void add(CalendarDayEvent event) {}

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Unexpected call: ${invocation.memberName}');
}

class _FakeCacheManager implements CacheManager {
  @override
  Stream<FileResponse> getFileStream(
    String url, {
    String? key,
    Map<String, String>? headers,
    bool withProgress = false,
  }) => const Stream<FileResponse>.empty();

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Unexpected call: ${invocation.memberName}');
}
