import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Friendly empty screen: a small drawn picture (soft gold halo, dotted ring, the
/// subject icon in an ink circle, a few sparkles) that floats gently, a title,
/// a hint line and an optional action button.
/// Put it inside a scroll view so pull-to-refresh still works.
class EmptyState extends StatefulWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.hint,
    this.actionLabel,
    this.onAction,
    this.topGap = 56,
  });

  final IconData icon;
  final String title;
  final String? hint;
  final String? actionLabel;
  final VoidCallback? onAction;
  final double topGap;

  @override
  State<EmptyState> createState() => _EmptyStateState();
}

class _EmptyStateState extends State<EmptyState> with SingleTickerProviderStateMixin {
  // Floats up and down twice when it appears, then rests (no endless animation).
  late final AnimationController _float =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))
        ..repeat(reverse: true, count: 4);

  @override
  void dispose() {
    _float.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(24, widget.topGap, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 168,
            height: 168,
            child: AnimatedBuilder(
              animation: _float,
              builder: (_, child) => CustomPaint(
                painter: _HaloPainter(
                  t: Curves.easeInOut.transform(_float.value),
                  halo: AppColors.goldSoft,
                  ring: AppColors.goldLine,
                  sparkle: AppColors.gold,
                ),
                child: Transform.translate(
                  offset: Offset(0, -4 * Curves.easeInOut.transform(_float.value)),
                  child: child,
                ),
              ),
              child: Center(
                child: Container(
                  width: 76,
                  height: 76,
                  decoration: const BoxDecoration(color: AppColors.ink, shape: BoxShape.circle),
                  child: Icon(widget.icon, color: AppColors.gold, size: 38),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(widget.title,
              textAlign: TextAlign.center, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w600)),
          if (widget.hint != null) ...[
            const SizedBox(height: 6),
            Text(widget.hint!, textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: AppColors.muted)),
          ],
          if (widget.actionLabel != null && widget.onAction != null) ...[
            const SizedBox(height: 18),
            SizedBox(
              width: 240,
              child: ElevatedButton.icon(
                onPressed: widget.onAction,
                icon: const Icon(Icons.add_rounded),
                label: Text(widget.actionLabel!),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _HaloPainter extends CustomPainter {
  _HaloPainter({required this.t, required this.halo, required this.ring, required this.sparkle});
  final double t; // 0..1, the float phase
  final Color halo;
  final Color ring;
  final Color sparkle;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2;
    canvas.drawCircle(c, r * (0.78 + 0.03 * t), Paint()..color = halo);
    // dotted ring
    final dot = Paint()..color = ring;
    const n = 28;
    for (var i = 0; i < n; i++) {
      final a = 2 * math.pi * i / n + t * 0.25;
      canvas.drawCircle(c + Offset(math.cos(a), math.sin(a)) * r * 0.95, 2.2, dot);
    }
    // sparkles
    final sp = Paint()..color = sparkle.withValues(alpha: 0.5 + 0.5 * t);
    for (final (dx, dy, s) in const [(0.78, -0.62, 5.0), (-0.8, -0.35, 3.5), (0.62, 0.7, 3.0)]) {
      _star(canvas, c + Offset(dx * r, dy * r), s + 1.5 * t, sp);
    }
  }

  void _star(Canvas canvas, Offset p, double s, Paint paint) {
    final path = Path()
      ..moveTo(p.dx, p.dy - s * 1.6)
      ..quadraticBezierTo(p.dx, p.dy, p.dx + s * 1.6, p.dy)
      ..quadraticBezierTo(p.dx, p.dy, p.dx, p.dy + s * 1.6)
      ..quadraticBezierTo(p.dx, p.dy, p.dx - s * 1.6, p.dy)
      ..quadraticBezierTo(p.dx, p.dy, p.dx, p.dy - s * 1.6);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_HaloPainter old) =>
      old.t != t || old.halo != halo || old.ring != ring || old.sparkle != sparkle;
}
