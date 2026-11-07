import 'dart:math';

import 'package:flutter/cupertino.dart';

const kBg = Color(0xFF0F1117);
const kPanel = Color(0xFF1A1D27);
const kPanel2 = Color(0xFF2A2F3E);
const kAccent = Color(0xFFFF9F0A);
const kGreen = Color(0xFF30D158);
const kRed = Color(0xFFFF453A);
const kBlue = Color(0xFF0A84FF);
const kGrey = Color(0xFF8E8E93);

/// Карточка-панель.
class Panel extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final Color color;
  final VoidCallback? onTap;

  const Panel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.color = kPanel,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final box = Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: padding,
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(16)),
      child: child,
    );
    if (onTap == null) return box;
    return GestureDetector(onTap: onTap, behavior: HitTestBehavior.opaque, child: box);
  }
}

class SectionTitle extends StatelessWidget {
  final String text;
  const SectionTitle(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(color: kGrey, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.6),
      ),
    );
  }
}

class Pill extends StatelessWidget {
  final String text;
  final Color color;
  const Pill(this.text, {super.key, this.color = kBlue});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withAlpha(50), borderRadius: BorderRadius.circular(8)),
      child: Text(text, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}

class BarMeter extends StatelessWidget {
  final double value;
  final Color color;
  final double height;
  const BarMeter({super.key, required this.value, this.color = kAccent, this.height = 8});

  @override
  Widget build(BuildContext context) {
    final v = value.isNaN ? 0.0 : value.clamp(0.0, 1.0).toDouble();
    return ClipRRect(
      borderRadius: BorderRadius.circular(height / 2),
      child: Container(
        height: height,
        color: kPanel2,
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(widthFactor: v, child: Container(color: color)),
      ),
    );
  }
}

/// Кнопка-действие с подписью (например, с ценой).
class ActionButton extends StatelessWidget {
  final String label;
  final String? sub;
  final bool enabled;
  final VoidCallback onTap;
  final Color color;

  const ActionButton({
    super.key,
    required this.label,
    required this.onTap,
    this.sub,
    this.enabled = true,
    this.color = kBlue,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: enabled ? color : kPanel2,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: enabled ? CupertinoColors.white : kGrey,
              ),
            ),
            if (sub != null)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  sub!,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: enabled ? const Color(0xCCFFFFFF) : kGrey),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Мини-график.
class Sparkline extends StatelessWidget {
  final List<double> values;
  final double height;
  const Sparkline({super.key, required this.values, this.height = 70});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(painter: _SparkPainter(List<double>.from(values))),
    );
  }
}

class _SparkPainter extends CustomPainter {
  final List<double> v;
  _SparkPainter(this.v);

  @override
  void paint(Canvas canvas, Size size) {
    if (v.length < 2) return;
    var lo = v.reduce(min);
    var hi = v.reduce(max);
    if (hi - lo < 1e-9) {
      hi = lo + 1;
    }
    final path = Path();
    for (var i = 0; i < v.length; i++) {
      final x = size.width * i / (v.length - 1);
      final y = size.height - (v[i] - lo) / (hi - lo) * size.height * 0.9 - size.height * 0.05;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = kGreen
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant _SparkPainter oldDelegate) => true;
}

class StatLine extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;
  const StatLine(this.label, this.value, {super.key, this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: kGrey, fontSize: 15)),
          Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }
}
