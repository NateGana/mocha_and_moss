class Fmt {
  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  /// 145 -> "145", 14.5 -> "14.50"
  static String number(double v) {
    final rounded = (v * 100).round() / 100;
    return rounded == rounded.roundToDouble()
        ? rounded.toStringAsFixed(0)
        : rounded.toStringAsFixed(2);
  }

  static String money(double v, [String currency = '₱']) {
    final sign = v < 0 ? '-' : '';
    final abs = v.abs();
    final text = number(abs);
    // Add thousands separators to the whole-number part.
    final parts = text.split('.');
    final whole = parts[0].replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (m) => ',',
    );
    return '$sign$currency${parts.length > 1 ? '$whole.${parts[1]}' : whole}';
  }

  static String time(DateTime d) {
    final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final m = d.minute.toString().padLeft(2, '0');
    return '$h:$m ${d.hour >= 12 ? 'PM' : 'AM'}';
  }

  static String date(DateTime d) => '${_months[d.month - 1]} ${d.day}, ${d.year}';

  static String dateTime(DateTime d) => '${date(d)} · ${time(d)}';

  static String shortDate(DateTime d) => '${_months[d.month - 1]} ${d.day}';

  static String hourLabel(int hour) {
    final h = hour % 12 == 0 ? 12 : hour % 12;
    return '$h ${hour >= 12 && hour < 24 ? 'PM' : 'AM'}';
  }

  static String greeting([DateTime? now]) {
    final h = (now ?? DateTime.now()).hour;
    if (h < 12) return 'Good morning';
    if (h < 18) return 'Good afternoon';
    return 'Good evening';
  }

  static String firstName(String full) {
    final t = full.trim();
    if (t.isEmpty) return 'Friend';
    return t.split(RegExp(r'\s+')).first;
  }

  static DateTime dayStart(DateTime d) => DateTime(d.year, d.month, d.day);
}
