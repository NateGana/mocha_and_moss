import '../models/models.dart';

// Pure pricing / selection helpers. Keeping them free of UI and storage makes
// them easy to unit test.

AddOn? findAddOn(List<AddOn> addOns, String id) {
  for (final a in addOns) {
    if (a.id == id) return a;
  }
  return null;
}

/// Price of one unit: base price + size surcharge + every selected add-on.
double unitPrice(
  Product p,
  List<AddOn> addOns,
  String size,
  List<String> optionIds,
) {
  var total = p.basePrice + p.extraFor(size);
  for (final id in optionIds) {
    final a = findAddOn(addOns, id);
    if (a != null) total += a.price;
  }
  return (total * 100).round() / 100;
}

/// Add-ons the customer may pick for [p] in [group] (active ones only).
List<AddOn> optionsFor(Product p, List<AddOn> addOns, String group) {
  final result = <AddOn>[];
  for (final id in p.optionIds) {
    final a = findAddOn(addOns, id);
    if (a != null && a.active && a.group == group) result.add(a);
  }
  return result;
}

/// Sensible starting choices when a drink page opens.
CartItem defaultSelection(
  Product p,
  List<AddOn> addOns,
  List<int> sweetnessLevels,
  String id,
) {
  var sweet = -1;
  if (p.isDrink && sweetnessLevels.isNotEmpty) {
    sweet = sweetnessLevels.reduce(
      (a, b) => (a - 50).abs() <= (b - 50).abs() ? a : b,
    );
  }
  final options = <String>[];
  if (p.isDrink) {
    for (final g in AddOnGroups.all) {
      if (!AddOnGroups.isSingle(g)) continue;
      final choices = optionsFor(p, addOns, g);
      if (choices.isNotEmpty) options.add(choices.first.id);
    }
  }
  return CartItem(
    id: id,
    productId: p.id,
    size: p.sizes.first.label,
    temp: p.isDrink ? (p.hot ? 'Hot' : 'Iced') : '',
    sweetness: sweet,
    optionIds: options,
  );
}

/// "Medium · Iced · 50% sweet · Oat Milk · Double Shot · + Whipped Cream"
String describeSelection(
  Product p,
  List<AddOn> addOns, {
  required String size,
  required String temp,
  required int sweetness,
  required List<String> optionIds,
}) {
  final parts = <String>[];
  if (p.sizes.length > 1) parts.add(size);
  if (temp.isNotEmpty) parts.add(temp);
  if (sweetness >= 0) parts.add('$sweetness% sweet');
  for (final g in AddOnGroups.all) {
    final names = <String>[];
    for (final id in optionIds) {
      final a = findAddOn(addOns, id);
      if (a != null && a.group == g) names.add(a.name);
    }
    if (names.isEmpty) continue;
    parts.add(AddOnGroups.isSingle(g) ? names.first : '+ ${names.join(', ')}');
  }
  return parts.join(' · ');
}
