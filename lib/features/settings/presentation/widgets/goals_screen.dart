import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:opennutritracker/core/domain/entity/goal_targets.dart';
import 'package:opennutritracker/core/styles/dimens.dart';
import 'package:opennutritracker/core/utils/calc/macro_calc.dart';
import 'package:opennutritracker/core/utils/calc/macro_goal_resolver.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/features/settings/domain/goal_settings_store.dart';
import 'package:opennutritracker/generated/l10n.dart';

/// Settings → Goals (#33): the kcal goal calculated or fixed, the macro
/// goals as a split or in grams. Each mode keeps its own values while the
/// user switches; switching to grams for the first time converts the split.
/// The split itself is edited in the existing split dialog ([onEditSplit]).
class GoalsScreen extends StatefulWidget {
  final GoalSettingsStore? store;
  final Future<void> Function(BuildContext context) onEditSplit;

  const GoalsScreen({super.key, this.store, required this.onEditSplit});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  /// How far the macros' kcal may be off the kcal goal before the screen
  /// points it out.
  static const _kcalMismatchTolerance = 0.1;

  late final GoalSettingsStore _store =
      widget.store ?? locator<GoalSettingsStore>();
  final _fixedKcal = TextEditingController();
  final _carbs = TextEditingController();
  final _fat = TextEditingController();
  final _protein = TextEditingController();

  bool _loaded = false;
  bool _saving = false;
  KcalGoalMode _kcalMode = KcalGoalMode.calculated;
  MacroGoalMode _macroMode = MacroGoalMode.percent;
  double _calculatedKcal = 0;
  ({double carbs, double fat, double protein}) _split = (
    carbs: 0,
    fat: 0,
    protein: 0,
  );
  String? _kcalError;
  String? _gramsError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final controller in [_fixedKcal, _carbs, _fat, _protein]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    final targets = await _store.loadTargets();
    final split = await _store.loadSplit();
    final calculated = await _store.calculatedKcal();
    if (!mounted) return;
    setState(() {
      _kcalMode = targets.kcalMode;
      _macroMode = targets.macroMode;
      _split = split;
      _calculatedKcal = calculated;
      _fixedKcal.text = _format(targets.fixedKcal);
      _carbs.text = _format(targets.carbsG);
      _fat.text = _format(targets.fatG);
      _protein.text = _format(targets.proteinG);
      _loaded = true;
    });
  }

  static String _format(double? value) {
    if (value == null) return '';
    return value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toString();
  }

  static double? _parse(String text) =>
      double.tryParse(text.trim().replaceAll(',', '.'));

  /// The kcal goal the split and the grams are measured against: the
  /// fixed goal while one is typed in, else the calculated one.
  double get _baseKcal {
    final fixed = _parse(_fixedKcal.text);
    return _kcalMode == KcalGoalMode.fixed && fixed != null && fixed > 0
        ? fixed
        : _calculatedKcal;
  }

  void _onMacroModeChanged(MacroGoalMode mode) {
    setState(() {
      _macroMode = mode;
      _gramsError = null;
      if (mode == MacroGoalMode.grams &&
          [_carbs, _fat, _protein].every((c) => c.text.trim().isEmpty)) {
        final goals = MacroGoalResolver.macros(
          const GoalTargets(),
          kcalGoal: _baseKcal,
          carbsPct: _split.carbs / 100,
          fatPct: _split.fat / 100,
          proteinPct: _split.protein / 100,
        );
        _carbs.text = goals.carbsG.round().toString();
        _fat.text = goals.fatG.round().toString();
        _protein.text = goals.proteinG.round().toString();
      }
    });
  }

  Future<void> _editSplit() async {
    await widget.onEditSplit(context);
    final split = await _store.loadSplit();
    if (mounted) setState(() => _split = split);
  }

  Future<void> _save() async {
    if (_saving) return;
    final s = S.of(context);
    final fixedText = _fixedKcal.text.trim();
    final fixed = _parse(fixedText);
    final grams = [
      _parse(_carbs.text),
      _parse(_fat.text),
      _parse(_protein.text),
    ];
    String? kcalError;
    String? gramsError;
    final fixedValid =
        fixed != null &&
        fixed >= GoalTargets.minFixedKcal &&
        fixed <= GoalTargets.maxFixedKcal;
    if (_kcalMode == KcalGoalMode.fixed && !fixedValid ||
        _kcalMode == KcalGoalMode.calculated &&
            fixedText.isNotEmpty &&
            !fixedValid) {
      kcalError = s.goalsKcalRangeError(
        GoalTargets.minFixedKcal.toInt(),
        GoalTargets.maxFixedKcal.toInt(),
      );
    }
    final gramsGiven = grams.whereType<double>();
    final gramsInRange = gramsGiven.every(
      (g) => g >= 0 && g <= GoalTargets.maxMacroG,
    );
    if (!gramsInRange) {
      gramsError = s.goalsGramsRangeError(GoalTargets.maxMacroG.toInt());
    } else if (_macroMode == MacroGoalMode.grams && gramsGiven.length < 3) {
      gramsError = s.goalsGramsMissing;
    }
    setState(() {
      _kcalError = kcalError;
      _gramsError = gramsError;
    });
    if (kcalError != null || gramsError != null) return;

    setState(() => _saving = true);
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    await _store.save(
      GoalTargets(
        kcalMode: _kcalMode,
        fixedKcal: fixedValid ? fixed : null,
        macroMode: _macroMode,
        carbsG: grams[0],
        fatG: grams[1],
        proteinG: grams[2],
      ),
    );
    if (!mounted) return;
    messenger.showSnackBar(SnackBar(content: Text(s.goalsSaved)));
    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(s.goalsTitle),
        actions: [
          Semantics(
            identifier: 'goals-save',
            child: TextButton(
              onPressed: _loaded && !_saving ? _save : null,
              child: Text(s.buttonSaveLabel),
            ),
          ),
        ],
      ),
      body: !_loaded
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(Dimens.spacing16),
              children: [
                _sectionTitle(context, s.goalsKcalSection),
                _kcalSection(context),
                const SizedBox(height: Dimens.spacing24),
                _sectionTitle(context, s.goalsMacroSection),
                _macroSection(context),
              ],
            ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title) => Padding(
    padding: const EdgeInsets.only(bottom: Dimens.spacing8),
    child: Text(
      title,
      style: Theme.of(
        context,
      ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
    ),
  );

  Widget _kcalSection(BuildContext context) {
    final s = S.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          identifier: 'goals-kcal-mode',
          child: SegmentedButton<KcalGoalMode>(
            segments: [
              ButtonSegment(
                value: KcalGoalMode.calculated,
                label: Text(s.goalsKcalCalculated),
              ),
              ButtonSegment(
                value: KcalGoalMode.fixed,
                label: Text(s.goalsKcalFixed),
              ),
            ],
            selected: {_kcalMode},
            onSelectionChanged: (selection) => setState(() {
              _kcalMode = selection.first;
              _kcalError = null;
            }),
          ),
        ),
        const SizedBox(height: Dimens.spacing12),
        if (_kcalMode == KcalGoalMode.calculated)
          Text(s.goalsKcalCalculatedHint(_calculatedKcal.round()))
        else
          Semantics(
            identifier: 'goals-kcal-fixed',
            child: TextField(
              controller: _fixedKcal,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: s.goalsKcalFixedLabel,
                suffixText: s.kcalLabel,
                helperText: s.goalsKcalFixedHint,
                helperMaxLines: 2,
                errorText: _kcalError,
                border: const OutlineInputBorder(
                  borderRadius: Dimens.borderRadiusM,
                ),
              ),
              onChanged: (_) => setState(() => _kcalError = null),
            ),
          ),
      ],
    );
  }

  Widget _macroSection(BuildContext context) {
    final s = S.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          identifier: 'goals-macro-mode',
          child: SegmentedButton<MacroGoalMode>(
            segments: [
              ButtonSegment(
                value: MacroGoalMode.percent,
                label: Text(s.goalsMacroPercent),
              ),
              ButtonSegment(
                value: MacroGoalMode.grams,
                label: Text(s.goalsMacroGrams),
              ),
            ],
            selected: {_macroMode},
            onSelectionChanged: (selection) =>
                _onMacroModeChanged(selection.first),
          ),
        ),
        const SizedBox(height: Dimens.spacing12),
        if (_macroMode == MacroGoalMode.percent)
          ..._percentRows(context)
        else
          ..._gramFields(context),
      ],
    );
  }

  List<Widget> _percentRows(BuildContext context) {
    final s = S.of(context);
    final base = _baseKcal;
    String grams(double pct, double kcalPerGram) =>
        (base * pct / 100 / kcalPerGram).round().toString();
    final rows = [
      (s.carbsLabel, _split.carbs, MacroCalc.carbsKcalPerGram),
      (s.fatLabel, _split.fat, MacroCalc.fatKcalPerGram),
      (s.proteinLabel, _split.protein, MacroCalc.proteinKcalPerGram),
    ];
    return [
      for (final (label, pct, kcalPerGram) in rows)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: Dimens.spacing4),
          child: Row(
            children: [
              Expanded(child: Text(label)),
              Text('${pct.round()} % ≈ ${grams(pct, kcalPerGram)} g'),
            ],
          ),
        ),
      Align(
        alignment: Alignment.centerRight,
        child: Semantics(
          identifier: 'goals-split-edit',
          child: TextButton.icon(
            icon: const Icon(Icons.pie_chart_rounded),
            label: Text(s.goalsSplitEdit),
            onPressed: _editSplit,
          ),
        ),
      ),
    ];
  }

  List<Widget> _gramFields(BuildContext context) {
    final s = S.of(context);
    final carbs = _parse(_carbs.text);
    final fat = _parse(_fat.text);
    final protein = _parse(_protein.text);
    final split = carbs != null && fat != null && protein != null
        ? MacroGoalResolver.percentOfGrams(
            carbsG: carbs,
            fatG: fat,
            proteinG: protein,
          )
        : null;
    final macroKcal = carbs != null && fat != null && protein != null
        ? MacroGoalResolver.kcalOfGrams(
            carbsG: carbs,
            fatG: fat,
            proteinG: protein,
          )
        : null;
    final base = _baseKcal;
    final mismatch =
        macroKcal != null &&
        base > 0 &&
        (macroKcal - base).abs() > base * _kcalMismatchTolerance;
    final fields = [
      ('goals-carbs-g', s.carbsLabel, _carbs, split?.carbs),
      ('goals-fat-g', s.fatLabel, _fat, split?.fat),
      ('goals-protein-g', s.proteinLabel, _protein, split?.protein),
    ];
    return [
      for (final (id, label, controller, share) in fields)
        Padding(
          padding: const EdgeInsets.only(bottom: Dimens.spacing12),
          child: Semantics(
            identifier: id,
            child: TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: label,
                suffixText: 'g',
                helperText: share == null
                    ? null
                    : '≈ ${(share * 100).round()} %',
                border: const OutlineInputBorder(
                  borderRadius: Dimens.borderRadiusM,
                ),
              ),
              onChanged: (_) => setState(() => _gramsError = null),
            ),
          ),
        ),
      if (_gramsError != null)
        Text(
          _gramsError!,
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
      if (mismatch)
        Text(
          s.goalsGramsKcalHint(macroKcal.round(), base.round()),
          style: Theme.of(context).textTheme.bodySmall,
        ),
    ];
  }
}
