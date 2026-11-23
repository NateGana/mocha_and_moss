import 'package:flutter/material.dart';

import '../../data/app_store.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../widgets/common.dart';
import 'nav.dart';
import 'order_tracking_screen.dart';

class OrdersTab extends StatefulWidget {
  const OrdersTab({super.key});

  @override
  State<OrdersTab> createState() => _OrdersTabState();
}

class _OrdersTabState extends State<OrdersTab> {
  bool _showHistory = false;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final user = store.currentUser;
        final all = user == null ? <CafeOrder>[] : store.ordersFor(user.id);
        final shown = all.where((o) => o.isActive != _showHistory).toList();
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
                      child: Text('Your Orders', style: AppFonts.serif(fontSize: 26, color: colors.latte)),
                    ),
                    const CartButton(),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(value: false, label: Text('Active')),
                    ButtonSegment(value: true, label: Text('History')),
                  ],
                  selected: {_showHistory},
                  onSelectionChanged: (s) => setState(() => _showHistory = s.first),
                ),
              ),
              Expanded(
                child: shown.isEmpty
                    ? EmptyState(
                        icon: Icons.receipt_long_outlined,
                        title: _showHistory ? 'No past orders yet' : 'No active orders',
                        message: _showHistory
                            ? 'Completed and cancelled orders appear here.'
                            : 'Place an order and you can follow it here.',
                        action: _showHistory
                            ? null
                            : AppButton(label: 'Order a mocha', onPressed: () => customerTab.value = 1),
                      )
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
                        children: [for (final o in shown) _OrderCard(order: o)],
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order});
  final CafeOrder order;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final o = order;
    return AppCard(
      margin: const EdgeInsets.only(bottom: 10),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => OrderTrackingScreen(orderId: o.id)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(o.orderNo, style: const TextStyle(fontWeight: FontWeight.w800))),
              StatusChip(o),
            ],
          ),
          const SizedBox(height: 4),
          Text(Fmt.dateTime(o.createdAt), style: TextStyle(color: colors.oat, fontSize: 12)),
          const SizedBox(height: 8),
          Text(
            o.lines.map((l) => '${l.quantity}× ${l.name}').join(', '),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: colors.latte, fontSize: 13),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(store.money(o.total),
                  style: TextStyle(color: colors.gold, fontWeight: FontWeight.w800)),
              const Spacer(),
              TextButton.icon(
                onPressed: () {
                  final skipped = store.reorder(o);
                  showMessage(
                    context,
                    skipped.isEmpty
                        ? 'Items added to your cart.'
                        : 'Added to cart. Unavailable: ${skipped.join(', ')}.',
                  );
                },
                icon: Icon(Icons.replay_rounded, size: 16, color: colors.cinnamon),
                label: Text('Reorder', style: TextStyle(color: colors.cinnamon)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
