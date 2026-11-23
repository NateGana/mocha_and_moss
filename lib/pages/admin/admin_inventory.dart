import 'package:flutter/material.dart';

import '../../data/app_store.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import 'admin_common.dart';

class AdminInventory extends StatelessWidget {
  const AdminInventory({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final lowProducts = store.products.where((p) => p.lowOnStock).length;
        final lowIngredients = store.ingredients.where((i) => i.low).length;
        return SafeArea(
          bottom: false,
          child: DefaultTabController(
            length: 2,
            child: Column(
              children: [
                const AdminHeader(title: 'Inventory'),
                if (lowProducts + lowIngredients > 0)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                    child: AppCard(
                      highlight: true,
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Low stock: $lowProducts menu item${lowProducts == 1 ? '' : 's'}, '
                              '$lowIngredients ingredient${lowIngredients == 1 ? '' : 's'}',
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                TabBar(
                  labelColor: colors.gold,
                  unselectedLabelColor: colors.oat,
                  indicatorColor: colors.gold,
                  dividerColor: colors.line,
                  tabs: const [Tab(text: 'Menu items'), Tab(text: 'Ingredients')],
                ),
                const Expanded(
                  child: TabBarView(children: [_ProductStock(), _IngredientStock()]),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ProductStock extends StatelessWidget {
  const _ProductStock();

  Future<void> _edit(BuildContext context, Product p) async {
    var track = p.stock != null;
    var available = p.available;
    final qty = TextEditingController(text: '${p.stock ?? 0}');
    final low = TextEditingController(text: '${p.lowStock}');
    final colors = AppColors.of(context);
    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) => AlertDialog(
          title: Text(p.name),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Track stock'),
                  subtitle: const Text('Made-to-order drinks usually are not tracked'),
                  value: track,
                  activeThumbColor: colors.matcha,
                  onChanged: (v) => setDialog(() => track = v),
                ),
                if (track) ...[
                  LabeledField(label: 'Quantity available', controller: qty, keyboardType: TextInputType.number),
                  LabeledField(label: 'Low-stock threshold', controller: low, keyboardType: TextInputType.number),
                ],
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Available to order'),
                  value: available,
                  activeThumbColor: colors.matcha,
                  onChanged: (v) => setDialog(() => available = v),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel', style: TextStyle(color: colors.oat))),
            TextButton(
              onPressed: () {
                p.stock = track ? (int.tryParse(qty.text.trim()) ?? 0).clamp(0, 100000).toInt() : null;
                p.lowStock = int.tryParse(low.text.trim()) ?? p.lowStock;
                p.available = available;
                store.saveChanges();
                Navigator.pop(ctx);
              },
              child: Text('Save', style: TextStyle(color: colors.cinnamon)),
            ),
          ],
        ),
      ),
    );
    qty.dispose();
    low.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final items = [...store.products]
      ..sort((a, b) {
        // Low and tracked items first so problems are easy to spot.
        int rank(Product p) => p.lowOnStock ? 0 : (p.stock != null ? 1 : 2);
        return rank(a).compareTo(rank(b));
      });
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
      children: [
        for (final p in items)
          AppCard(
            margin: const EdgeInsets.only(bottom: 8),
            onTap: () => _edit(context, p),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                      Text(
                        p.stock == null
                            ? 'Not tracked'
                            : 'In stock: ${p.stock} · alert at ${p.lowStock}',
                        style: TextStyle(color: colors.oat, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                if (p.lowOnStock)
                  Tag(p.stock == 0 ? 'OUT' : 'LOW', color: p.stock == 0 ? Colors.redAccent : Colors.orangeAccent),
                if (!p.available) const Padding(padding: EdgeInsets.only(left: 6), child: Tag('OFF', color: Colors.grey)),
                Icon(Icons.chevron_right, color: colors.oat),
              ],
            ),
          ),
      ],
    );
  }
}

class _IngredientStock extends StatelessWidget {
  const _IngredientStock();

  Future<void> _edit(BuildContext context, StockItem? item) async {
    final name = TextEditingController(text: item?.name ?? '');
    final unit = TextEditingController(text: item?.unit ?? 'pcs');
    final qty = TextEditingController(text: formatNumberField(item?.quantity ?? 0));
    final threshold = TextEditingController(text: formatNumberField(item?.threshold ?? 0));
    final colors = AppColors.of(context);
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(item == null ? 'New ingredient' : 'Update ${item.name}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 6),
              LabeledField(label: 'Name', controller: name),
              LabeledField(label: 'Unit (kg, L, pcs…)', controller: unit),
              LabeledField(
                label: 'Quantity on hand',
                controller: qty,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              LabeledField(
                label: 'Low-stock threshold',
                controller: threshold,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
            ],
          ),
        ),
        actions: [
          if (item != null)
            TextButton(
              onPressed: () {
                store.deleteStockItem(item.id);
                Navigator.pop(ctx);
              },
              child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
            ),
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel', style: TextStyle(color: colors.oat))),
          TextButton(
            onPressed: () {
              final q = double.tryParse(qty.text.trim());
              final t = double.tryParse(threshold.text.trim());
              if (name.text.trim().isEmpty || q == null || t == null || q < 0 || t < 0) {
                showMessage(context, 'Enter a name and valid numbers.');
                return;
              }
              store.saveStockItem(StockItem(
                id: item?.id ?? store.newId('i'),
                name: name.text.trim(),
                unit: unit.text.trim().isEmpty ? 'pcs' : unit.text.trim(),
                quantity: q,
                threshold: t,
              ));
              Navigator.pop(ctx);
            },
            child: Text('Save', style: TextStyle(color: colors.cinnamon)),
          ),
        ],
      ),
    );
    name.dispose();
    unit.dispose();
    qty.dispose();
    threshold.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 90),
          children: [
            Text(
              'Ingredient counts are updated by hand. Nothing is deducted automatically, '
              'because no recipes are set up.',
              style: TextStyle(color: colors.oat, fontSize: 12),
            ),
            const SizedBox(height: 10),
            for (final i in store.ingredients)
              AppCard(
                margin: const EdgeInsets.only(bottom: 8),
                onTap: () => _edit(context, i),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(i.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                          Text(
                            '${formatNumberField(i.quantity)} ${i.unit} · alert at ${formatNumberField(i.threshold)}',
                            style: TextStyle(color: colors.oat, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    if (i.low) const Tag('LOW', color: Colors.orangeAccent),
                    Icon(Icons.edit_outlined, color: colors.oat, size: 18),
                  ],
                ),
              ),
          ],
        ),
        Positioned(
          right: 20,
          bottom: 16,
          child: FloatingActionButton.extended(
            backgroundColor: colors.cinnamon,
            foregroundColor: Colors.white,
            onPressed: () => _edit(context, null),
            icon: const Icon(Icons.add),
            label: const Text('Add'),
          ),
        ),
      ],
    );
  }
}
