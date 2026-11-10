import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/locale_controller.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_mode_controller.dart';
import 'l10n/app_localizations.dart';

class VahanKhataApp extends ConsumerWidget {
  const VahanKhataApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);
    final isDark = switch (mode) {
      ThemeMode.dark => true,
      ThemeMode.light => false,
      ThemeMode.system => MediaQuery.platformBrightnessOf(context) == Brightness.dark,
    };
    AppColors.dark = isDark;
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      onGenerateTitle: (c) => AppL10n.of(c).appName,
      theme: isDark ? AppTheme.dark() : AppTheme.light(),
      themeAnimationDuration: Duration.zero,
      locale: ref.watch(localeProvider),
      localizationsDelegates: AppL10n.localizationsDelegates,
      supportedLocales: AppL10n.supportedLocales,
      routerConfig: ref.watch(routerProvider),
      builder: (_, child) => _ThemeRepaint(dark: isDark, child: child ?? const SizedBox.shrink()),
    );
  }
}

/// Widgets read colour tokens straight from [AppColors], so when the theme flips every
/// widget below is rebuilt once (their state is kept).
class _ThemeRepaint extends StatefulWidget {
  const _ThemeRepaint({required this.dark, required this.child});
  final bool dark;
  final Widget child;

  @override
  State<_ThemeRepaint> createState() => _ThemeRepaintState();
}

class _ThemeRepaintState extends State<_ThemeRepaint> {
  @override
  void didUpdateWidget(_ThemeRepaint old) {
    super.didUpdateWidget(old);
    if (old.dark == widget.dark) return;
    SystemChrome.setSystemUIOverlayStyle(kInkStatusBar);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      void mark(Element e) {
        e.markNeedsBuild();
        e.visitChildren(mark);
      }

      (context as Element).visitChildren(mark);
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
