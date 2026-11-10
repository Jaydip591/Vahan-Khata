import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quick_actions/quick_actions.dart';

import '../../../l10n/app_localizations.dart';
import '../../ledger/presentation/payment_sheet.dart';

/// Long-press the app icon: "New trip", "Add expense", "Payment received" open the
/// entry straight away. Labels follow the app language. Phones whose launcher has no
/// shortcuts (Android 7.0 and older, a few custom launchers) simply show none.
final quickActionsProvider = Provider<QuickActions>((ref) => const QuickActions());

const kShortcutTrip = 'new_trip';
const kShortcutExpense = 'add_expense';
const kShortcutPayment = 'payment';

class LauncherShortcuts extends ConsumerStatefulWidget {
  const LauncherShortcuts({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<LauncherShortcuts> createState() => _LauncherShortcutsState();
}

class _LauncherShortcutsState extends ConsumerState<LauncherShortcuts> {
  String? _labelsFor;

  @override
  void initState() {
    super.initState();
    // Also fires when the app was started from a shortcut.
    ref.read(quickActionsProvider).initialize(_open).catchError((_) {});
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final t = AppL10n.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    if (_labelsFor == lang) return;
    _labelsFor = lang;
    ref.read(quickActionsProvider).setShortcutItems([
      ShortcutItem(type: kShortcutTrip, localizedTitle: t.shortcutTrip, icon: 'ic_shortcut_trip'),
      ShortcutItem(type: kShortcutExpense, localizedTitle: t.shortcutExpense, icon: 'ic_shortcut_expense'),
      ShortcutItem(type: kShortcutPayment, localizedTitle: t.shortcutPayment, icon: 'ic_shortcut_payment'),
    ]).catchError((_) {});
  }

  void _open(String type) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      switch (type) {
        case kShortcutTrip:
          context.push('/trip/new');
        case kShortcutExpense:
          context.go('/kharcha');
        case kShortcutPayment:
          context.go('/home');
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) showPaymentSheet(context);
          });
          WidgetsBinding.instance.ensureVisualUpdate();
      }
    });
    // Navigate after the current frame (the handler can fire while the app is starting).
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
