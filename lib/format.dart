import 'dart:math';

/// Красивые числа: 1.23K, 4.56M, 7.89B ...
String fmtNum(double v) {
  if (v.isNaN || v.isInfinite) return '0';
  final neg = v < 0;
  var x = v.abs();
  String s;
  if (x < 1000) {
    s = x < 10 ? x.toStringAsFixed(2) : (x < 100 ? x.toStringAsFixed(1) : x.toStringAsFixed(0));
  } else {
    const suf = ['K', 'M', 'B', 'T', 'Qa', 'Qi'];
    var i = -1;
    while (x >= 1000 && i < suf.length - 1) {
      x /= 1000;
      i++;
    }
    final digits = x < 10 ? x.toStringAsFixed(2) : (x < 100 ? x.toStringAsFixed(1) : x.toStringAsFixed(0));
    s = digits + suf[i];
  }
  return neg ? '-$s' : s;
}

String money(double v) {
  if (v < 0) return '-\$${fmtNum(-v)}';
  return '\$${fmtNum(v)}';
}

String rate(double v) {
  final sign = v >= 0 ? '+' : '-';
  return '$sign\$${fmtNum(v.abs())}/с';
}

String stars(double r) {
  final full = min(5, max(0, r.round()));
  return '★' * full + '☆' * (5 - full);
}

String pct(double v) => '${(v * 100).round()}%';
