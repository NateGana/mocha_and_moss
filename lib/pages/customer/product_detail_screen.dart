import 'package:flutter/material.dart';

import '../../data/app_store.dart';
import '../../data/pricing.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../../widgets/drink_art.dart';
import 'product_widgets.dart';

/// Product page with every drink customization. When [editing] is set the
/// page changes an existing cart line instead of adding a new one.
class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({super.key, required this.productId, this.editing});
  final String productId;
  final CartItem? editing;

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  CartItem? _sel;
  final _note = TextEditingController();

  @override
  void initState() {
    super.initState();
    final p = store.productById(widget.productId);
    if (p != null) {
      _sel = widget.editing?.copy() ?? store.defaultItemFor(p);
      _note.text = _sel!.note;
    }
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  void _toggleOption(AddOn a) {
    final sel = _sel!;
    setState(() {
      if (AddOnGroups.isSingle(a.group)) {
        sel.optionIds.removeWhere((id) => store.addOnById(id)?.group == a.group);
        sel.optionIds.add(a.id);
      } else if (!sel.optionIds.remove(a.id)) {
        sel.optionIds.add(a.id);
      }
    });
  }

  void _submit(Product p) {
    final sel = _sel!;
    sel.note = _note.text.trim();
    if (widget.editing != null) {
      store.updateCartItem(widget.editing!.id, sel);
      showMessage(context, 'Cart updated.');
    } else {
      store.addToCart(sel);
      showMessage(context, '${p.name} added to your cart.');
    }
    Navigator.pop(context);
  }

  Widget _label(String text, AppColors colors, {String? hint}) => Padding(
    padding: const EdgeInsets.only(top: 20, bottom: 8),
    child: Row(
      children: [
        Text(text, style: AppFonts.serif(fontSize: 18, color: colors.latte)),
        if (hint != null) ...[
          const SizedBox(width: 8),
          Text(hint, style: TextStyle(color: colors.oat, fontSize: 11)),
        ],
      ],
    ),
  );

  String _plus(double v) => v > 0 ? ' +${store.money(v)}' : '';

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final p = store.productById(widget.productId);
        final sel = _sel;
        if (p == null || sel == null) {
          return Scaffold(
            appBar: AppBar(backgroundColor: colors.espresso),
            body: const EmptyState(
              icon: Icons.coffee_outlined,
              title: 'Item not found',
              message: 'This item is no longer on the menu.',
            ),
          );
        }
        final orderable = store.isOrderable(p);
        final unit = store.unitPriceOf(sel);
        final accent = kindColor(colors, p.kind);

        final related = store.products
            .where((o) => o.id != p.id && o.category == p.category && store.isOrderable(o))
            .take(6)
            .toList();

        return Scaffold(
          backgroundColor: colors.espresso,
          appBar: AppBar(
            backgroundColor: colors.espresso,
            foregroundColor: colors.latte,
            elevation: 0,
            title: Text(
              widget.editing != null ? 'Edit your drink' : '',
              style: AppFonts.serif(fontSize: 18, color: colors.latte),
            ),
            actions: [FavoriteButton(productId: p.id), const CartButton()],
          ),
          body: PhoneFrame(
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    children: [
                      AspectRatio(
                        aspectRatio: 1.35,
                        child: ProductImage(product: p, radius: BorderRadius.circular(22)),
                      ),
                      const SizedBox(height: 16),
                      Wrap(spacing: 6, runSpacing: 6, children: productTags(context, p)),
                      const SizedBox(height: 8),
                      Text(p.name, style: AppFonts.serif(fontSize: 28, color: colors.latte)),
                      const SizedBox(height: 4),
                      Text(
                        store.money(unit),
                        style: TextStyle(color: accent, fontSize: 20, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 10),
                      Text(p.description, style: TextStyle(color: colors.oat, height: 1.45)),
                      if (p.ingredients.isNotEmpty) ...[
                        _label('Ingredients', colors),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            for (final i in p.ingredients)
                              Chip(
                                label: Text(i, style: const TextStyle(fontSize: 12)),
                                backgroundColor: colors.espressoDark,
                                side: BorderSide(color: colors.line),
                                visualDensity: VisualDensity.compact,
                              ),
                          ],
                        ),
                      ],
                      if (p.kind == Kinds.bundle && p.bundleItems.isNotEmpty) ...[
                        _label('Includes', colors),
                        for (final item in p.bundleItems)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              children: [
                                Icon(Icons.check_circle_outline, size: 16, color: colors.matcha),
                                const SizedBox(width: 8),
                                Expanded(child: Text(item)),
                              ],
                            ),
                          ),
                      ],
                      if (p.sizes.length > 1) ...[
                        _label('Size', colors),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final s in p.sizes)
                              ChoiceChip(
                                label: Text('${s.label} · ${store.money(p.basePrice + s.extra)}'),
                                selected: sel.size == s.label,
                                onSelected: (_) => setState(() => sel.size = s.label),
                              ),
                          ],
                        ),
                      ],
                      if (p.isDrink && p.hot && p.iced) ...[
                        _label('Temperature', colors),
                        Wrap(
                          spacing: 8,
                          children: [
                            for (final t in ['Hot', 'Iced'])
                              ChoiceChip(
                                avatar: Icon(
                                  t == 'Hot' ? Icons.local_fire_department_outlined : Icons.ac_unit,
                                  size: 16,
                                ),
                                label: Text(t),
                                selected: sel.temp == t,
                                onSelected: (_) => setState(() => sel.temp = t),
                              ),
                          ],
                        ),
                      ] else if (p.isDrink) ...[
                        _label('Temperature', colors),
                        Text(
                          p.hot ? 'Served hot' : 'Served iced',
                          style: TextStyle(color: colors.oat),
                        ),
                      ],
                      if (p.isDrink) ...[
                        _label('Sweetness', colors),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final s in store.sweetnessLevels)
                              ChoiceChip(
                                label: Text('$s%'),
                                selected: sel.sweetness == s,
                                onSelected: (_) => setState(() => sel.sweetness = s),
                              ),
                          ],
                        ),
                      ],
                      // Only the option groups this product offers are shown, so
                      // matcha drinks never get mocha-only choices (and vice versa).
                      if (p.isDrink)
                        for (final g in AddOnGroups.all)
                          ..._group(p, g, sel, colors),
                      _label('Quantity', colors),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: QuantityStepper(
                          value: sel.quantity,
                          onChanged: (v) => setState(() => sel.quantity = v),
                        ),
                      ),
                      _label('Special instructions', colors),
                      TextField(
                        controller: _note,
                        maxLines: 2,
                        maxLength: 120,
                        style: TextStyle(color: colors.latte, fontSize: 14),
                        decoration: const InputDecoration(hintText: 'Anything we should know?'),
                      ),
                      if (related.isNotEmpty) ...[
                        _label('You might also like', colors),
                        ProductCarousel(
                          products: related,
                          compact: true,
                          padding: EdgeInsets.zero,
                        ),
                      ],
                    ],
                  ),
                ),
                // Sticky total + add button
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                  decoration: BoxDecoration(
                    color: colors.espressoDark,
                    border: Border(top: BorderSide(color: colors.line)),
                  ),
                  child: SafeArea(
                    top: false,
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('Total', style: TextStyle(color: colors.oat, fontSize: 11)),
                              Text(
                                store.money(unit * sel.quantity),
                                style: AppFonts.serif(fontSize: 22, color: colors.latte),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: AppButton(
                            label: !orderable
                                ? 'Currently unavailable'
                                : (widget.editing != null ? 'Update cart' : 'Add to cart'),
                            icon: Icons.shopping_bag_outlined,
                            onPressed: orderable ? () => _submit(p) : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<Widget> _group(Product p, String group, CartItem sel, AppColors colors) {
    final options = optionsFor(p, store.addOns, group);
    if (options.isEmpty) return const [];
    final single = AddOnGroups.isSingle(group);
    return [
      _label(AddOnGroups.label(group), colors, hint: single ? 'Choose one' : 'Choose any'),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final a in options)
            single
                ? ChoiceChip(
                    label: Text('${a.name}${_plus(a.price)}'),
                    selected: sel.optionIds.contains(a.id),
                    onSelected: (_) => _toggleOption(a),
                  )
                : FilterChip(
                    label: Text('${a.name}${_plus(a.price)}'),
                    selected: sel.optionIds.contains(a.id),
                    onSelected: (_) => _toggleOption(a),
                  ),
        ],
      ),
    ];
  }
}
