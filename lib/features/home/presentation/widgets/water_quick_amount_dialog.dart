import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:opennutritracker/features/home/domain/water_quick_amount.dart';
import 'package:opennutritracker/generated/l10n.dart';

/// Sets the amount of the third water quick-add button (#29).
class WaterQuickAmountDialog extends StatefulWidget {
  final WaterQuickAmount quickAmount;

  const WaterQuickAmountDialog({super.key, required this.quickAmount});

  @override
  State<WaterQuickAmountDialog> createState() => _WaterQuickAmountDialogState();
}

class _WaterQuickAmountDialogState extends State<WaterQuickAmountDialog> {
  late final _controller = TextEditingController(
    text: widget.quickAmount.amount.value.toString(),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final navigator = Navigator.of(context);
    final parsed = int.tryParse(_controller.text);
    if (parsed != null) await widget.quickAmount.save(parsed);
    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return AlertDialog(
      title: Text(s.waterQuickAmountLabel),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            s.waterQuickAmountDescription,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          Semantics(
            identifier: 'water-quick-amount-input',
            child: TextField(
              controller: _controller,
              autofocus: true,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              textAlign: TextAlign.right,
              decoration: InputDecoration(
                suffixText: s.mlLabel,
                helperText:
                    '${WaterQuickAmount.minMl}–${WaterQuickAmount.maxMl} '
                    '${s.mlLabel}',
                isDense: true,
              ),
              onSubmitted: (_) => _save(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(s.dialogCancelLabel),
        ),
        Semantics(
          identifier: 'water-quick-amount-save',
          child: TextButton(onPressed: _save, child: Text(s.dialogOKLabel)),
        ),
      ],
    );
  }
}
