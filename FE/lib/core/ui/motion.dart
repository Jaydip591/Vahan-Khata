import 'package:flutter/material.dart';

import '../haptics.dart';
import '../money.dart';
import '../theme/app_colors.dart';

/// Shrinks a little while the finger is down, like a real button. Does not take over the tap,
/// so the child's own InkWell still works.
/// Bottom sheets rise with a small spring (a light overshoot, then settle).
const kSheetAnimation = AnimationStyle(
  curve: Cubic(0.18, 1.18, 0.4, 1),
  duration: Duration(milliseconds: 380),
  reverseCurve: Curves.easeInCubic,
  reverseDuration: Duration(milliseconds: 220),
);

class PressScale extends StatefulWidget {
  const PressScale({super.key, required this.child, this.scale = 0.97});
  final Widget child;
  final double scale;

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> {
  bool _down = false;

  void _set(bool v) {
    if (_down != v) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) => Listener(
    onPointerDown: (_) => _set(true),
    onPointerUp: (_) => _set(false),
    onPointerCancel: (_) => _set(false),
    child: AnimatedScale(
      scale: _down ? widget.scale : 1,
      duration: const Duration(milliseconds: 90),
      curve: Curves.easeOut,
      child: widget.child,
    ),
  );
}

/// A rupee amount that counts up (or down) to its value instead of jumping.
class CountUpRupees extends StatefulWidget {
  const CountUpRupees(this.value, {super.key, this.style, this.symbol = true, this.prefix = ''});
  final double value;
  final TextStyle? style;
  final bool symbol;
  final String prefix;

  @override
  State<CountUpRupees> createState() => _CountUpRupeesState();
}

class _CountUpRupeesState extends State<CountUpRupees> {
  double _from = 0;

  @override
  void didUpdateWidget(CountUpRupees old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) _from = old.value;
  }

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    key: ValueKey(widget.value),
    tween: Tween(begin: _from, end: widget.value),
    duration: const Duration(milliseconds: 650),
    curve: Curves.easeOutCubic,
    builder: (_, v, _) => Text(
      '${widget.prefix}${formatRupees(v.roundToDouble(), symbol: widget.symbol)}',
      style: widget.style,
    ),
  );
}

/// Fades and slides a list item in, one after another. Only the first few items animate.
class EntryFade extends StatefulWidget {
  const EntryFade({super.key, required this.index, required this.child});
  final int index;
  final Widget child;

  @override
  State<EntryFade> createState() => _EntryFadeState();
}

class _EntryFadeState extends State<EntryFade> with SingleTickerProviderStateMixin {
  static const _maxAnimated = 8;
  late final AnimationController _c;
  late final Animation<double> _a;

  @override
  void initState() {
    super.initState();
    final step = widget.index.clamp(0, _maxAnimated);
    final total = 260 + step * 45;
    _c = AnimationController(vsync: this, duration: Duration(milliseconds: total));
    _a = CurvedAnimation(
      parent: _c,
      curve: Interval(step * 45 / total, 1, curve: Curves.easeOutCubic),
    );
    if (widget.index >= _maxAnimated + 2) {
      _c.value = 1;
    } else {
      _c.forward();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: _a,
    child: SlideTransition(
      position: Tween(begin: const Offset(0, 0.06), end: Offset.zero).animate(_a),
      child: widget.child,
    ),
  );
}

/// Grey cards that pulse while a list loads, instead of a lonely spinner.
class SkeletonList extends StatefulWidget {
  const SkeletonList({super.key, this.count = 5, this.height = 78});
  final int count;
  final double height;

  @override
  State<SkeletonList> createState() => _SkeletonListState();
}

class _SkeletonListState extends State<SkeletonList> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListView(
    physics: const NeverScrollableScrollPhysics(),
    padding: const EdgeInsets.all(16),
    children: [
      for (var i = 0; i < widget.count; i++)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: AnimatedBuilder(
            animation: _c,
            builder: (_, _) => Container(
              height: widget.height,
              decoration: BoxDecoration(
                color: Color.lerp(AppColors.line, AppColors.card, 0.25 + 0.5 * _c.value),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
    ],
  );
}

/// Pull to refresh with a tick of vibration and the app's colours.
class AppRefresh extends StatelessWidget {
  const AppRefresh({super.key, required this.onRefresh, required this.child});
  final Future<void> Function() onRefresh;
  final Widget child;

  @override
  Widget build(BuildContext context) => RefreshIndicator(
    color: AppColors.gold,
    backgroundColor: AppColors.ink,
    onRefresh: () {
      Haptics.tap();
      return onRefresh();
    },
    child: child,
  );
}

/// Big gold tick that pops in the middle of the screen when something is saved.
void showSavedTick(BuildContext context) {
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) return;
  late final OverlayEntry entry;
  entry = OverlayEntry(builder: (_) => _SavedTick(onDone: () => entry.remove()));
  overlay.insert(entry);
}

class _SavedTick extends StatefulWidget {
  const _SavedTick({required this.onDone});
  final VoidCallback onDone;

  @override
  State<_SavedTick> createState() => _SavedTickState();
}

class _SavedTickState extends State<_SavedTick> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void initState() {
    super.initState();
    _c.forward().whenComplete(() {
      if (mounted) widget.onDone();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: Center(
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, _) {
          final pop = Curves.elasticOut.transform((_c.value / 0.5).clamp(0.0, 1.0));
          final fade = _c.value < 0.7 ? 1.0 : 1 - (_c.value - 0.7) / 0.3;
          return Opacity(
            opacity: fade.clamp(0.0, 1.0),
            child: Transform.scale(
              scale: pop,
              child: Container(
                width: 96,
                height: 96,
                decoration: const BoxDecoration(color: AppColors.ink, shape: BoxShape.circle),
                child: const Icon(Icons.check_rounded, color: AppColors.gold, size: 64),
              ),
            ),
          );
        },
      ),
    ),
  );
}
