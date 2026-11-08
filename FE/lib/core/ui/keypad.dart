import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../money.dart';
import '../theme/app_colors.dart';
import 'app_button.dart';

/// Rounded white bottom sheet used for quick entry (amount, expense, payment).
Future<T?> showAppSheet<T>(BuildContext context, WidgetBuilder builder) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: builder,
  );
}

class SheetHandle extends StatelessWidget {
  const SheetHandle({super.key});
  @override
  Widget build(BuildContext context) => Center(
        child: Container(
          width: 44,
          height: 4,
          decoration: BoxDecoration(color: AppColors.fieldLine, borderRadius: BorderRadius.circular(2)),
        ),
      );
}

/// 3x4 number pad. [decimal] swaps the "00" key for ".".
class KeypadPad extends StatelessWidget {
  const KeypadPad({super.key, required this.onKey, this.decimal = false});
  final ValueChanged<String> onKey;
  final bool decimal;

  @override
  Widget build(BuildContext context) {
    final keys = ['1', '2', '3', '4', '5', '6', '7', '8', '9', decimal ? '.' : '00', '0', '⌫'];
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 2.3,
      children: [
        for (final k in keys)
          Material(
            color: AppColors.ivory,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => onKey(k),
              child: Center(
                child: k == '⌫'
                    ? const Icon(Icons.backspace_outlined, size: 24, semanticLabel: 'Backspace')
                    : Text(k, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w500)),
              ),
            ),
          ),
      ],
    );
  }
}

/// Asks for one whole-rupee amount. Returns null if dismissed.
Future<int?> showAmountSheet(
  BuildContext context, {
  required String title,
  int initial = 0,
  int? max,
}) {
  return showAppSheet<int>(context, (_) => _AmountSheet(title: title, initial: initial, max: max));
}

class _AmountSheet extends StatefulWidget {
  const _AmountSheet({required this.title, required this.initial, this.max});
  final String title;
  final int initial;
  final int? max;

  @override
  State<_AmountSheet> createState() => _AmountSheetState();
}

class _AmountSheetState extends State<_AmountSheet> {
  late String _text = widget.initial > 0 ? widget.initial.toString() : '';
  bool _showError = false;

  int get _value => int.tryParse(_text) ?? 0;

  void _press(String key) {
    var next = applyKey(_text, key);
    final max = widget.max;
    if (max != null && (int.tryParse(next) ?? 0) > max) next = max.toString();
    setState(() {
      _text = next;
      _showError = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SheetHandle(),
          const SizedBox(height: 12),
          Text(widget.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Center(
            child: Text(
              _value > 0 ? formatRupees(_value) : '₹ 0',
              style: const TextStyle(fontSize: 42, fontWeight: FontWeight.w500),
            ),
          ),
          SizedBox(
            height: 22,
            child: _showError
                ? Center(
                    child: Text(t.enterAmount,
                        style: const TextStyle(color: AppColors.expense, fontSize: 14)),
                  )
                : null,
          ),
          KeypadPad(onKey: _press),
          const SizedBox(height: 12),
          AppButton(
            label: t.amountOk,
            onPressed: () {
              if (_value <= 0) {
                setState(() => _showError = true);
                return;
              }
              Navigator.pop(context, _value);
            },
          ),
        ],
      ),
    );
  }
}
