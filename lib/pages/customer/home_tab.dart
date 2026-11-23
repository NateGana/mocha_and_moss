import 'package:flutter/material.dart';

import '../../data/app_store.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../widgets/brand_logo.dart';
import '../../widgets/common.dart';
import '../../widgets/drink_art.dart';
import 'nav.dart';
import 'product_widgets.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final user = store.currentUser;
        List<Product> pick(bool Function(Product) f) =>
            store.products.where((p) => store.isOrderable(p) && f(p)).toList();

        final signature = pick((p) => p.isMocha);
        final matcha = pick((p) => p.isMatcha);
        final others = pick((p) => p.kind == Kinds.coffee || p.kind == Kinds.other);
        final best = pick((p) => p.bestSeller);
        final fresh = pick((p) => p.isNew);
        final bundles = pick((p) => p.kind == Kinds.bundle);
        final offers = store.promos.where((p) => p.usable).toList();
        final recommended = store.recommendedFor(user);
        final news = store.announcements.where((a) => a.active).toList();
        final reviews = store.approvedReviews.take(3).toList();

        return SafeArea(
          bottom: false,
          child: ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              // Welcome header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 8, 0),
                child: Row(
                  children: [
                    const BrandMark(size: 34),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${Fmt.greeting()}, ${Fmt.firstName(user?.name ?? '')}.',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppFonts.serif(fontSize: 20, color: colors.latte),
                          ),
                          Text(
                            'Your next favorite mocha is waiting.',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: colors.oat, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Notifications',
                      onPressed: () => Navigator.pushNamed(context, '/notifications'),
                      icon: Icon(Icons.notifications_none_rounded, color: colors.gold),
                    ),
                    const CartButton(),
                    IconButton(
                      tooltip: 'Profile',
                      onPressed: () => customerTab.value = 4,
                      icon: Icon(Icons.person_outline_rounded, color: colors.gold),
                    ),
                  ],
                ),
              ),

              if (!store.settings.acceptingOrders)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                  child: AppCard(
                    highlight: true,
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: colors.gold),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text('We are not taking orders right now. Please check back soon.'),
                        ),
                      ],
                    ),
                  ),
                ),

              // Hero banner
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: _Hero(onExplore: () {
                  menuCategoryRequest.value = 'signature';
                  customerTab.value = 1;
                }),
              ),

              // Owner announcements
              for (final a in news.take(2))
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: AppCard(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.campaign_outlined, color: colors.gold),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(a.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                              const SizedBox(height: 2),
                              Text(a.body, style: TextStyle(color: colors.oat, fontSize: 12.5)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // The signature collection gets the strongest treatment.
              if (signature.isNotEmpty) ...[
                SectionHeader(
                  title: 'Signature Mocha',
                  subtitle: 'Our specialty. Rich chocolate, smooth espresso.',
                  actionLabel: 'See all',
                  onAction: () {
                    menuCategoryRequest.value = 'signature';
                    customerTab.value = 1;
                  },
                ),
                ProductCarousel(products: signature, highlight: true),
              ],

              if (matcha.isNotEmpty) ...[
                SectionHeader(
                  title: 'Matcha Corner',
                  subtitle: 'A little green to go with the chocolate.',
                  accent: colors.matcha,
                  actionLabel: 'See all',
                  onAction: () {
                    menuCategoryRequest.value = 'matcha';
                    customerTab.value = 1;
                  },
                ),
                ProductCarousel(products: matcha, compact: true),
              ],

              if (others.isNotEmpty) ...[
                const SectionHeader(title: 'Other Café Drinks'),
                ProductCarousel(products: others, compact: true),
              ],

              if (best.isNotEmpty) ...[
                const SectionHeader(title: 'Best Sellers'),
                ProductCarousel(products: best, compact: true),
              ],

              if (fresh.isNotEmpty) ...[
                const SectionHeader(title: 'New Arrivals'),
                ProductCarousel(products: fresh, compact: true),
              ],

              if (offers.isNotEmpty || bundles.isNotEmpty)
                const SectionHeader(
                  title: 'Special Offers',
                  subtitle: 'Promo codes and drink-and-dessert bundles.',
                ),
              for (final o in offers)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                  child: AppCard(
                    highlight: true,
                    child: Row(
                      children: [
                        Icon(Icons.local_offer_outlined, color: colors.cinnamon),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(o.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                              Text(
                                'Code ${o.code}'
                                '${o.minPurchase > 0 ? ' · min ${store.money(o.minPurchase)}' : ''}'
                                '${o.expiresAt != null ? ' · until ${Fmt.shortDate(o.expiresAt!)}' : ''}',
                                style: TextStyle(color: colors.oat, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (bundles.isNotEmpty) ProductCarousel(products: bundles, compact: true),

              if (recommended.isNotEmpty) ...[
                SectionHeader(
                  title: 'Recommended for You',
                  subtitle: user != null && (user.favorites.isNotEmpty || store.ordersFor(user.id).isNotEmpty)
                      ? 'Based on your favorites and past orders.'
                      : 'Popular picks to start with.',
                ),
                ProductCarousel(products: recommended, compact: true),
              ],

              if (reviews.isNotEmpty) ...[
                const SectionHeader(title: 'What Guests Say'),
                for (final r in reviews)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                    child: AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              for (var i = 0; i < 5; i++)
                                Icon(
                                  i < r.rating ? Icons.star_rounded : Icons.star_outline_rounded,
                                  size: 16,
                                  color: colors.gold,
                                ),
                              const SizedBox(width: 8),
                              Text(r.userName, style: TextStyle(color: colors.oat, fontSize: 12)),
                            ],
                          ),
                          if (r.text.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(r.text, style: const TextStyle(fontSize: 13)),
                          ],
                        ],
                      ),
                    ),
                  ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.onExplore});
  final VoidCallback onExplore;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: SizedBox(
        height: 230,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Local café photo; falls back to the illustration if it is missing.
            Image.asset(
              'assets/images/home_background.jpg',
              fit: BoxFit.cover,
              errorBuilder: (c, e, s) => const DrinkArt(artKey: 'mocha_dark'),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    const Color(0xFF1B110D).withValues(alpha: 0.92),
                    const Color(0xFF1B110D).withValues(alpha: 0.35),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Tag('MOCHA SPECIALTY'),
                  const SizedBox(height: 10),
                  Text(
                    'MOCHA MOMENTS.',
                    style: AppFonts.serif(
                      fontSize: 30,
                      color: const Color(0xFFF1E4D5),
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const SizedBox(
                    width: 230,
                    child: Text(
                      'Rich chocolate meets smooth espresso. Find your perfect cup.',
                      style: TextStyle(color: Color(0xFFD8C6B2), fontSize: 13, height: 1.35),
                    ),
                  ),
                  const SizedBox(height: 14),
                  AppButton(label: 'Explore Mocha', onPressed: onExplore, dense: true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
