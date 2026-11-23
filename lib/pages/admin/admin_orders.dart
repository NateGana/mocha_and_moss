import 'package:flutter/material.dart';

import '../../data/app_store.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../widgets/common.dart';
import 'admin_common.dart';

String _nextActionLabel(CafeOrder o) {
  switch (o.nextStatus) {
    case OrderStatus.confirmed:
      return 'Confirm order';
    case OrderStatus.preparing:
      return 'Mark as preparing';
    case OrderStatus.ready:
      return 'Mark as ready';
    case OrderStatus.outForDelivery:
      return 'Out for delivery';
    case OrderStatus.completed:
      return o.fulfillment == Fulfillment.delivery ? 'Mark delivered' : 'Mark completed';
    default:
      return '';
  }
}

/// Runs a status change and reports problems (like unpaid online payments).
void _move(BuildContext context, CafeOrder o, OrderStatus next) {
  try {
    store.setOrderStatus(o.id, next);
  } on OrderException catch (e) {
    showMessage(context, e.message);
  }
}

class AdminOrders extends StatelessWidget {
  const AdminOrders({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        List<CafeOrder> inStates(List<OrderStatus> s) =>
            store.orders.where((o) => s.contains(o.status)).toList();
        final tabs = <String, List<CafeOrder>>{
          'New': inStates([OrderStatus.received, OrderStatus.confirmed]),
          'Preparing': inStates([OrderStatus.preparing]),
          'Ready': inStates([OrderStatus.ready, OrderStatus.outForDelivery]),
          'Done': inStates([OrderStatus.completed, OrderStatus.cancelled]),
        };
        return SafeArea(
          bottom: false,
          child: DefaultTabController(
            length: tabs.length,
            child: Column(
              children: [
                const AdminHeader(title: 'Order Queue'),
                TabBar(
                  labelColor: colors.gold,
                  unselectedLabelColor: colors.oat,
                  indicatorColor: colors.gold,
                  dividerColor: colors.line,
                  tabs: [
                    for (final e in tabs.entries) Tab(text: '${e.key} (${e.value.length})'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      for (final e in tabs.entries)
                        e.value.isEmpty
                            ? const EmptyState(
                                icon: Icons.inbox_outlined,
                                title: 'Nothing here',
                                message: 'Orders in this stage will show up here.',
                              )
                            : ListView(
                                padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
                                children: [for (final o in e.value) _QueueCard(order: o)],
                              ),
                    ],
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

class _QueueCard extends StatelessWidget {
  const _QueueCard({required this.order});
  final CafeOrder order;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final o = order;
    final next = o.nextStatus;
    return AppCard(
      margin: const EdgeInsets.only(bottom: 12),
      onTap: () => _showDetail(context, o.id),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(o.orderNo, style: const TextStyle(fontWeight: FontWeight.w800))),
              StatusChip(o),
            ],
          ),
          const SizedBox(height: 2),
          Text('${o.customerName} · ${o.phone}', style: TextStyle(color: colors.oat, fontSize: 12)),
          Text(
            '${o.fulfillment.label} · ${o.paymentMethod} · ${o.paid ? 'Paid' : 'Unpaid'}',
            style: TextStyle(color: colors.oat, fontSize: 12),
          ),
          Text(Fmt.dateTime(o.createdAt), style: TextStyle(color: colors.oat, fontSize: 12)),
          const Divider(height: 18),
          for (final l in o.lines)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${l.quantity} × ${l.name}', style: const TextStyle(fontWeight: FontWeight.w600)),
                  if (l.summary.isNotEmpty)
                    Text(l.summary, style: TextStyle(color: colors.oat, fontSize: 11.5)),
                  if (l.note.isNotEmpty)
                    Text('Note: ${l.note}', style: TextStyle(color: colors.gold, fontSize: 11.5)),
                ],
              ),
            ),
          const SizedBox(height: 4),
          Text(store.money(o.total),
              style: TextStyle(color: colors.gold, fontWeight: FontWeight.w800, fontSize: 16)),
          if (o.isActive) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (next != null)
                  AppButton(
                    label: _nextActionLabel(o),
                    dense: true,
                    onPressed: () => _move(context, o, next),
                  ),
                if (!o.paid)
                  AppButton(
                    label: 'Mark paid',
                    dense: true,
                    outlined: true,
                    onPressed: () => store.markPaid(o.id, true),
                  ),
                AppButton(
                  label: 'Cancel',
                  dense: true,
                  outlined: true,
                  onPressed: () async {
                    final ok = await confirmDialog(
                      context,
                      title: 'Cancel ${o.orderNo}?',
                      message: 'Stock and any redeemed points will be returned.',
                      confirmLabel: 'Cancel order',
                      destructive: true,
                    );
                    if (ok && context.mounted) _move(context, o, OrderStatus.cancelled);
                  },
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

void _showDetail(BuildContext context, String orderId) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => ListenableBuilder(
      listenable: store,
      builder: (ctx, _) {
        final o = store.orderById(orderId);
        final colors = AppColors.of(ctx);
        if (o == null) return const SizedBox(height: 120);
        Widget row(String a, String b) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 110, child: Text(a, style: TextStyle(color: colors.oat, fontSize: 12.5))),
              Expanded(child: Text(b, style: const TextStyle(fontSize: 13))),
            ],
          ),
        );
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.85),
            child: ListView(
              padding: const EdgeInsets.all(20),
              shrinkWrap: true,
              children: [
                Text(o.orderNo, style: AppFonts.serif(fontSize: 22, color: colors.latte)),
                const SizedBox(height: 8),
                row('Status', o.statusLabel),
                row('Customer', o.customerName),
                row('Contact', '${o.phone}\n${o.email}'),
                row('Order type', o.fulfillment.label),
                if (o.tableNo.isNotEmpty) row('Table', o.tableNo),
                if (o.fulfillment == Fulfillment.pickup) row('Pickup', o.pickupTime),
                if (o.fulfillment == Fulfillment.delivery) row('Address', o.addressLine),
                if (o.deliveryNotes.isNotEmpty) row('Delivery notes', o.deliveryNotes),
                row('Payment', '${o.paymentMethod} (${o.paid ? 'received' : 'not received'})'),
                row('Placed', Fmt.dateTime(o.createdAt)),
                if (o.note.isNotEmpty) row('Order note', o.note),
                const Divider(height: 24),
                for (final l in o.lines)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${l.quantity} × ${l.name}',
                                  style: const TextStyle(fontWeight: FontWeight.w600)),
                              if (l.summary.isNotEmpty)
                                Text(l.summary, style: TextStyle(color: colors.oat, fontSize: 11.5)),
                            ],
                          ),
                        ),
                        Text(store.money(l.total)),
                      ],
                    ),
                  ),
                const Divider(height: 18),
                SummaryRow('Subtotal', store.money(o.subtotal)),
                if (o.discount > 0) SummaryRow('Promo ${o.promoCode}', '-${store.money(o.discount)}'),
                if (o.rewardDiscount > 0) SummaryRow('Reward', '-${store.money(o.rewardDiscount)}'),
                if (o.serviceFee > 0) SummaryRow('Service fee', store.money(o.serviceFee)),
                if (o.deliveryFee > 0) SummaryRow('Delivery fee', store.money(o.deliveryFee)),
                SummaryRow('Total', store.money(o.total), bold: true),
                const SizedBox(height: 16),
                Text('History', style: AppFonts.serif(fontSize: 18, color: colors.latte)),
                for (final h in o.history)
                  Text('${h.status.labelFor(o.fulfillment)} · ${Fmt.dateTime(h.at)}',
                      style: TextStyle(color: colors.oat, fontSize: 12)),
              ],
            ),
          ),
        );
      },
    ),
  );
}
