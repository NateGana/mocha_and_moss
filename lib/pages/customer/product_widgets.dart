import 'package:flutter/material.dart';

import '../../data/app_store.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../../widgets/drink_art.dart';
import 'product_detail_screen.dart';

void openProduct(BuildContext context, String productId, {CartItem? editing}) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => ProductDetailScreen(productId: productId, editing: editing),
    ),
  );
}

/// The "+" buttons: food and bundles go straight into the cart, drinks open
/// the customization page first.
void quickAdd(BuildContext context, Product p) {
  if (!store.isOrderable(p)) {
    showMessage(context, '${p.name} is currently unavailable.');
    return;
  }
  if (p.isDrink) {
    openProduct(context, p.id);
    return;
  }
  store.addToCart(store.defaultItemFor(p));
  showMessage(context, '${p.name} added to your cart.');
}

String priceLabel(Product p) {
  final from = p.sizes.length > 1 ? 'from ' : '';
  return '$from${store.money(p.startingPrice)}';
}

class _AddCircle extends StatelessWidget {
  const _AddCircle({required this.onTap, required this.enabled});
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Material(
      color: enabled ? colors.cinnamon : colors.line,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: const SizedBox(
          width: 36,
          height: 36,
          child: Icon(Icons.add, size: 20, color: Colors.white),
        ),
      ),
    );
  }
}

/// Vertical card used in horizontal carousels on the home screen.
class ProductCard extends StatelessWidget {
  const ProductCard({
    super.key,
    required this.product,
    this.width = 170,
    this.compact = false,
    this.highlight = false,
  });

  final Product product;
  final double width;
  final bool compact;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final p = product;
    final tags = productTags(context, p);
    return SizedBox(
      width: width,
      child: AppCard(
        padding: EdgeInsets.zero,
        highlight: highlight,
        onTap: () => openProduct(context, p.id),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: compact ? 1.25 : 1.1,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ProductImage(
                      product: p,
                      radius: const BorderRadius.vertical(top: Radius.circular(15)),
                    ),
                  ),
                  if (tags.isNotEmpty) Positioned(left: 8, top: 8, child: tags.first),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 6, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, height: 1.2),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          priceLabel(p),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: kindColor(colors, p.kind),
                            fontWeight: FontWeight.w700,
                            fontSize: 12.5,
                          ),
                        ),
                      ),
                      _AddCircle(
                        enabled: store.isOrderable(p),
                        onTap: () => quickAdd(context, p),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Horizontal carousel of [ProductCard]s with a fixed, overflow-safe height.
class ProductCarousel extends StatelessWidget {
  const ProductCarousel({
    super.key,
    required this.products,
    this.compact = false,
    this.highlight = false,
    this.padding = const EdgeInsets.symmetric(horizontal: 20),
  });

  final List<Product> products;
  final bool compact;
  final bool highlight;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final width = compact ? 140.0 : 170.0;
    final textScale = MediaQuery.textScalerOf(context).scale(1.0).clamp(1.0, 1.4).toDouble();
    final height = (compact ? 210.0 : 258.0) * (0.85 + 0.15 * textScale);
    return SizedBox(
      height: height,
      child: ListView.separated(
        padding: padding,
        scrollDirection: Axis.horizontal,
        itemCount: products.length,
        separatorBuilder: (c, i) => const SizedBox(width: 12),
        itemBuilder: (context, i) => ProductCard(
          product: products[i],
          width: width,
          compact: compact,
          highlight: highlight,
        ),
      ),
    );
  }
}

/// Full-width row used by the menu, favorites and search results.
class ProductRow extends StatelessWidget {
  const ProductRow({super.key, required this.product, this.trailing});
  final Product product;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final p = product;
    final temps = [if (p.hot) 'Hot', if (p.iced) 'Iced'].join(' / ');
    final meta = [
      if (p.sizes.length > 1) p.sizes.map((s) => s.label[0]).join('·'),
      if (p.isDrink && temps.isNotEmpty) temps,
    ].join('  •  ');
    return AppCard(
      padding: const EdgeInsets.all(10),
      highlight: p.isMocha && p.signature,
      margin: const EdgeInsets.only(bottom: 10),
      onTap: () => openProduct(context, p.id),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 88,
            height: 88,
            child: ProductImage(product: p, radius: BorderRadius.circular(12)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        p.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5),
                      ),
                    ),
                    trailing ?? FavoriteButton(productId: p.id, size: 20),
                  ],
                ),
                Text(
                  p.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: colors.oat, fontSize: 11.5, height: 1.3),
                ),
                const SizedBox(height: 6),
                Wrap(spacing: 4, runSpacing: 4, children: productTags(context, p)),
                if (meta.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(meta, style: TextStyle(color: colors.oat, fontSize: 11)),
                ],
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        priceLabel(p),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: kindColor(colors, p.kind),
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    _AddCircle(
                      enabled: store.isOrderable(p),
                      onTap: () => quickAdd(context, p),
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
