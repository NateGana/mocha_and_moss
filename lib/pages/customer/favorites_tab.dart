import 'package:flutter/material.dart';

import '../../data/app_store.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import 'nav.dart';
import 'product_widgets.dart';

class FavoritesTab extends StatelessWidget {
  const FavoritesTab({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final ids = store.currentUser?.favorites ?? <String>[];
        final favorites = <Product>[];
        for (final id in ids) {
          final p = store.productById(id);
          if (p != null) favorites.add(p);
        }
        return SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 8, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text('Favorites', style: AppFonts.serif(fontSize: 26, color: colors.latte)),
                    ),
                    const CartButton(),
                  ],
                ),
              ),
              Expanded(
                child: favorites.isEmpty
                    ? EmptyState(
                        icon: Icons.favorite_border_rounded,
                        title: 'No favorites yet',
                        message: 'Tap the heart on any drink to save it here.',
                        action: AppButton(label: 'Browse the menu', onPressed: () => customerTab.value = 1),
                      )
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                        children: [for (final p in favorites) ProductRow(product: p)],
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
