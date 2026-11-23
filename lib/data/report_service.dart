import '../models/models.dart';
import '../utils/format.dart';

/// Sales numbers calculated from saved orders. Only completed orders count as
/// revenue, so cancelled and still-open orders never inflate the totals.
class SalesReport {
  final DateTime from;
  final DateTime to; // inclusive end of day
  final List<CafeOrder> completed;
  final double revenue;
  final double mochaSales;
  final double matchaSales;
  final double dessertSales;
  final Map<String, int> unitsByProduct;
  final Map<String, double> revenueByDay; // key: yyyy-mm-dd

  SalesReport._(
    this.from,
    this.to,
    this.completed,
    this.revenue,
    this.mochaSales,
    this.matchaSales,
    this.dessertSales,
    this.unitsByProduct,
    this.revenueByDay,
  );

  int get orderCount => completed.length;
  double get averageOrder => orderCount == 0 ? 0 : revenue / orderCount;

  /// Product names sorted by units sold, best first.
  List<MapEntry<String, int>> get topProducts {
    final list = unitsByProduct.entries.toList();
    list.sort((a, b) => b.value.compareTo(a.value));
    return list;
  }

  factory SalesReport.build(List<CafeOrder> orders, DateTime from, DateTime to) {
    final start = Fmt.dayStart(from);
    final end = Fmt.dayStart(to).add(const Duration(days: 1));
    final done = orders
        .where(
          (o) =>
              o.status == OrderStatus.completed &&
              !o.createdAt.isBefore(start) &&
              o.createdAt.isBefore(end),
        )
        .toList();
    var revenue = 0.0, mocha = 0.0, matcha = 0.0, dessert = 0.0;
    final units = <String, int>{};
    final byDay = <String, double>{};
    for (final o in done) {
      revenue += o.total;
      final key = dayKey(o.createdAt);
      byDay[key] = (byDay[key] ?? 0) + o.total;
      for (final l in o.lines) {
        units[l.name] = (units[l.name] ?? 0) + l.quantity;
        if (l.kind == Kinds.mocha) mocha += l.total;
        if (l.kind == Kinds.matcha) matcha += l.total;
        if (l.kind == Kinds.dessert) dessert += l.total;
      }
    }
    return SalesReport._(
      start,
      end.subtract(const Duration(milliseconds: 1)),
      done,
      revenue,
      mocha,
      matcha,
      dessert,
      units,
      byDay,
    );
  }

  static String dayKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// Revenue for each of the last [days] days, oldest first.
  static List<MapEntry<DateTime, double>> lastDays(
    List<CafeOrder> orders,
    int days, {
    DateTime? now,
  }) {
    final today = Fmt.dayStart(now ?? DateTime.now());
    final report = SalesReport.build(
      orders,
      today.subtract(Duration(days: days - 1)),
      today,
    );
    return [
      for (var i = days - 1; i >= 0; i--)
        MapEntry(
          today.subtract(Duration(days: i)),
          report.revenueByDay[dayKey(today.subtract(Duration(days: i)))] ?? 0,
        ),
    ];
  }

  /// Plain CSV of the completed orders in this report.
  String toCsv() {
    String esc(String v) => '"${v.replaceAll('"', '""')}"';
    final b = StringBuffer(
      'Order No,Date,Customer,Fulfillment,Payment,Items,Subtotal,Discount,Total\n',
    );
    for (final o in completed) {
      final items = o.lines.map((l) => '${l.quantity}x ${l.name}').join('; ');
      b.writeln(
        [
          esc(o.orderNo),
          esc(Fmt.dateTime(o.createdAt)),
          esc(o.customerName),
          esc(o.fulfillment.label),
          esc(o.paymentMethod),
          esc(items),
          o.subtotal.toStringAsFixed(2),
          (o.discount + o.rewardDiscount).toStringAsFixed(2),
          o.total.toStringAsFixed(2),
        ].join(','),
      );
    }
    return b.toString();
  }
}
