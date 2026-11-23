import 'package:flutter/material.dart';

import '../../data/app_store.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../../widgets/drink_art.dart';
import 'product_widgets.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final items = store.cart;
        // Any line whose drink was removed or sold out blocks checkout.
        final blocked = items.any((i) {
          final p = store.productById(i.productId);
          return p == null || !store.isOrderable(p);
        });
        return Scaffold(
          backgroundColor: colors.espresso,
          appBar: AppBar(
            backgroundColor: colors.espresso,
            foregroundColor: colors.latte,
            title: Text('Your Cart', style: AppFonts.serif(fontSize: 22, color: colors.latte)),
            actions: [
              if (items.isNotEmpty)
                TextButton(
                  onPressed: () async {
                    final ok = await confirmDialog(
                      context,
                      title: 'Clear cart?',
                      message: 'Remove everything from your cart?',
                      confirmLabel: 'Clear',
                      destructive: true,
                    );
                    if (ok) store.clearCart();
                  },
                  child: Text('Clear', style: TextStyle(color: colors.oat)),
                ),
            ],
          ),
          body: PhoneFrame(
            child: items.isEmpty
                ? EmptyState(
                    icon: Icons.shopping_bag_outlined,
                    title: 'Your cart is empty',
                    message: 'Add a mocha and it will show up here.',
                    action: AppButton(
                      label: 'Browse the menu',
                      onPressed: () => Navigator.pop(context),
                    ),
                  )
                : Column(
                    children: [
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.all(20),
                          children: [for (final i in items) _CartLine(item: i)],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
                        decoration: BoxDecoration(
                          color: colors.espressoDark,
                          border: Border(top: BorderSide(color: colors.line)),
                        ),
                        child: SafeArea(
                          top: false,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SummaryRow('Subtotal', store.money(store.cartSubtotal)),
                              SummaryRow(
                                'Discounts and fees',
                                'Calculated at checkout',
                              ),
                              const Divider(height: 18),
                              SummaryRow('Estimated total', store.money(store.cartSubtotal), bold: true),
                              const SizedBox(height: 10),
                              if (blocked)
                                const Padding(
                                  padding: EdgeInsets.only(bottom: 8),
                                  child: Text(
                                    'Remove unavailable items to continue.',
                                    style: TextStyle(color: Colors.redAccent, fontSize: 12),
                                  ),
                                ),
                              SizedBox(
                                width: double.infinity,
                                child: AppButton(
                                  label: 'Checkout',
                                  icon: Icons.arrow_forward_rounded,
                                  onPressed: blocked
                                      ? null
                                      : () => Navigator.pushNamed(context, '/checkout'),
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
}

class _CartLine extends StatelessWidget {
  const _CartLine({required this.item});
  final CartItem item;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final p = store.productById(item.productId);
    if (p == null) {
      return AppCard(
        margin: const EdgeInsets.only(bottom: 10),
        child: Row(
          children: [
            const Expanded(child: Text('This item is no longer on the menu.')),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => store.removeFromCart(item.id),
            ),
          ],
        ),
      );
    }
    final summary = store.describeItem(item);
    return AppCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 70,
            height: 70,
            child: ProductImage(product: p, radius: BorderRadius.circular(12)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                if (summary.isNotEmpty)
                  Text(summary, style: TextStyle(color: colors.oat, fontSize: 11.5, height: 1.3)),
                if (item.note.isNotEmpty)
                  Text('Note: ${item.note}',
                      style: TextStyle(color: colors.oat, fontSize: 11.5, fontStyle: FontStyle.italic)),
                if (!store.isOrderable(p))
                  const Text('Currently unavailable',
                      style: TextStyle(color: Colors.redAccent, fontSize: 12)),
                const SizedBox(height: 4),
                Text(
                  '${store.money(store.unitPriceOf(item))} each',
                  style: TextStyle(color: colors.oat, fontSize: 11.5),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    QuantityStepper(
                      value: item.quantity,
                      min: 0,
                      onChanged: (v) => store.setCartQuantity(item.id, v),
                    ),
                    const Spacer(),
                    Text(
                      store.money(store.lineTotal(item)),
                      style: TextStyle(color: colors.gold, fontWeight: FontWeight.w800, fontSize: 15),
                    ),
                  ],
                ),
                Row(
                  children: [
                    if (p.isDrink)
                      TextButton.icon(
                        onPressed: () => openProduct(context, p.id, editing: item),
                        icon: Icon(Icons.edit_outlined, size: 16, color: colors.oat),
                        label: Text('Edit', style: TextStyle(color: colors.oat)),
                      ),
                    TextButton.icon(
                      onPressed: () => store.removeFromCart(item.id),
                      icon: const Icon(Icons.delete_outline, size: 16, color: Colors.redAccent),
                      label: const Text('Remove', style: TextStyle(color: Colors.redAccent)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
