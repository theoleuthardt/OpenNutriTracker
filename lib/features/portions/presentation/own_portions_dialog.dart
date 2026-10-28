import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:opennutritracker/features/portions/domain/own_portion.dart';
import 'package:opennutritracker/generated/l10n.dart';

/// Lets the user set, change and delete their own portions of one food
/// (#164). Resolves with the portions to keep, none when every one was
/// deleted, or null when the dialog was cancelled. [unit] is the food's
/// base unit, `g` or `ml`.
Future<List<OwnPortion>?> showOwnPortionsDialog(
  BuildContext context, {
  required List<OwnPortion> initial,
  required String unit,
}) => showDialog<List<OwnPortion>>(
  context: context,
  builder: (_) => _OwnPortionsDialog(initial: initial, unit: unit),
);

class _OwnPortionsDialog extends StatefulWidget {
  final List<OwnPortion> initial;
  final String unit;

  const _OwnPortionsDialog({required this.initial, required this.unit});

  @override
  State<_OwnPortionsDialog> createState() => _OwnPortionsDialogState();
}

class _Row {
  final TextEditingController label;
  final TextEditingController amount;

  _Row(String label, String amount)
    : label = TextEditingController(text: label),
      amount = TextEditingController(text: amount);

  bool get isEmpty => label.text.trim().isEmpty && amount.text.trim().isEmpty;

  /// The portion this row describes, or null while it is incomplete.
  OwnPortion? get portion {
    final name = label.text.trim();
    final weight = double.tryParse(amount.text.trim().replaceAll(',', '.'));
    if (name.isEmpty || weight == null || weight <= 0) return null;
    return OwnPortion(label: name, amount: weight);
  }

  void dispose() {
    label.dispose();
    amount.dispose();
  }
}

class _OwnPortionsDialogState extends State<_OwnPortionsDialog> {
  late final List<_Row> _rows = [
    for (final portion in widget.initial)
      _Row(portion.label, _formatAmount(portion.amount)),
  ];
  bool _showError = false;

  static String _formatAmount(double amount) => amount == amount.roundToDouble()
      ? amount.toInt().toString()
      : amount.toString();

  @override
  void dispose() {
    for (final row in _rows) {
      row.dispose();
    }
    super.dispose();
  }

  void _add() => setState(() => _rows.add(_Row('', '')));

  void _delete(int index) => setState(() => _rows.removeAt(index).dispose());

  void _save() {
    final filled = _rows.where((row) => !row.isEmpty).toList();
    final portions = [for (final row in filled) row.portion];
    if (portions.contains(null)) {
      setState(() => _showError = true);
      return;
    }
    Navigator.of(context).pop(portions.cast<OwnPortion>());
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return AlertDialog(
      title: Text(s.ownPortionsTitle),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(s.ownPortionsHint),
              const SizedBox(height: 12),
              for (var i = 0; i < _rows.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Semantics(
                          identifier: 'own-portion-label-$i',
                          child: TextField(
                            controller: _rows[i].label,
                            textCapitalization: TextCapitalization.sentences,
                            decoration: InputDecoration(
                              labelText: s.ownPortionLabel,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: Semantics(
                          identifier: 'own-portion-amount-$i',
                          child: TextField(
                            controller: _rows[i].amount,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'^\d*([.,]\d{0,2})?$'),
                              ),
                            ],
                            decoration: InputDecoration(
                              labelText: s.ownPortionAmount(widget.unit),
                            ),
                          ),
                        ),
                      ),
                      Semantics(
                        identifier: 'own-portion-delete-$i',
                        child: IconButton(
                          tooltip: s.ownPortionDelete,
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => _delete(i),
                        ),
                      ),
                    ],
                  ),
                ),
              Semantics(
                identifier: 'own-portions-add',
                child: TextButton.icon(
                  onPressed: _add,
                  icon: const Icon(Icons.add),
                  label: Text(s.ownPortionAdd),
                ),
              ),
              if (_showError)
                Text(
                  s.ownPortionInvalid,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(s.dialogCancelLabel),
        ),
        Semantics(
          identifier: 'own-portions-save',
          child: TextButton(onPressed: _save, child: Text(s.buttonSaveLabel)),
        ),
      ],
    );
  }
}
