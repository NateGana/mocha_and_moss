import 'package:flutter/material.dart';

import '../../data/app_store.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../widgets/common.dart';

/// Order confirmation and live progress tracker. [justPlaced] shows the
/// thank-you banner straight after checkout.
class OrderTrackingScreen extends StatelessWidget {
  const OrderTrackingScreen({super.key, required this.orderId, this.justPlaced = false});
  final String orderId;
  final bool justPlaced;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final o = store.orderById(orderId);
        if (o == null) {
          return Scaffold(
            appBar: AppBar(backgroundColor: colors.espresso),
            body: const EmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'Order not found',
              message: 'We could not find this order on this device.',
            ),
          );
        }
        final review = store.reviewForOrder(o.id);
        final isOwner = store.currentUser?.id == o.userId;
        return Scaffold(
          backgroundColor: colors.espresso,
          appBar: AppBar(
            backgroundColor: colors.espresso,
            foregroundColor: colors.latte,
            title: Text(
              justPlaced ? 'Order placed' : 'Order details',
              style: AppFonts.serif(fontSize: 22, color: colors.latte),
            ),
          ),
          body: PhoneFrame(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
              children: [
                if (justPlaced)
                  AppCard(
                    highlight: true,
                    margin: const EdgeInsets.only(bottom: 14),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle_rounded, color: colors.matcha, size: 32),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Thank you, ${Fmt.firstName(o.customerName)}!',
                                  style: AppFonts.serif(fontSize: 18, color: colors.latte)),
                              Text(
                                o.prepMinutes > 0
                                    ? 'Estimated preparation: about ${o.prepMinutes} min.'
                                    : 'We have received your order.',
                                style: TextStyle(color: colors.oat, fontSize: 12.5),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(o.orderNo,
                                style: AppFonts.serif(fontSize: 20, color: colors.latte)),
                          ),
                          StatusChip(o),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(Fmt.dateTime(o.createdAt), style: TextStyle(color: colors.oat, fontSize: 12)),
                      const SizedBox(height: 14),
                      _Tracker(order: o),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Items', style: AppFonts.serif(fontSize: 18, color: colors.latte)),
                      const SizedBox(height: 10),
                      for (final l in o.lines)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
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
                                    if (l.note.isNotEmpty)
                                      Text('Note: ${l.note}',
                                          style: TextStyle(color: colors.oat, fontSize: 11.5)),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(store.money(l.total)),
                            ],
                          ),
                        ),
                      const Divider(),
                      SummaryRow('Subtotal', store.money(o.subtotal)),
                      if (o.discount > 0)
                        SummaryRow('Promo ${o.promoCode}', '-${store.money(o.discount)}', accent: colors.matcha),
                      if (o.rewardDiscount > 0)
                        SummaryRow('Reward', '-${store.money(o.rewardDiscount)}', accent: colors.matcha),
                      if (o.serviceFee > 0) SummaryRow('Service fee', store.money(o.serviceFee)),
                      if (o.deliveryFee > 0) SummaryRow('Delivery fee', store.money(o.deliveryFee)),
                      SummaryRow('Total', store.money(o.total), bold: true),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _info('Order type', o.fulfillment.label, colors),
                      if (o.fulfillment == Fulfillment.dineIn && o.tableNo.isNotEmpty)
                        _info('Table', o.tableNo, colors),
                      if (o.fulfillment == Fulfillment.pickup) _info('Pickup time', o.pickupTime, colors),
                      if (o.fulfillment == Fulfillment.delivery) _info('Deliver to', o.addressLine, colors),
                      _info('Payment method', o.paymentMethod, colors),
                      _info(
                        'Payment status',
                        o.paid ? 'Received' : 'Not yet confirmed by the café',
                        colors,
                      ),
                      _info('Contact', '${o.customerName} · ${o.phone}', colors),
                    ],
                  ),
                ),
                if (isOwner) ...[
                  const SizedBox(height: 16),
                  if (o.status == OrderStatus.completed) ...[
                    if (review == null)
                      AppButton(
                        label: 'Rate this order',
                        icon: Icons.star_outline_rounded,
                        outlined: true,
                        onPressed: () => _reviewDialog(context, o),
                      )
                    else
                      AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              review.state == ReviewState.approved
                                  ? 'Your review'
                                  : 'Your review (waiting for the café to approve it)',
                              style: TextStyle(color: colors.oat, fontSize: 12),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                for (var i = 0; i < 5; i++)
                                  Icon(
                                    i < review.rating ? Icons.star_rounded : Icons.star_outline_rounded,
                                    color: colors.gold,
                                    size: 18,
                                  ),
                              ],
                            ),
                            if (review.text.isNotEmpty) Text(review.text),
                          ],
                        ),
                      ),
                    const SizedBox(height: 10),
                  ],
                  AppButton(
                    label: 'Reorder',
                    icon: Icons.replay_rounded,
                    onPressed: () {
                      final skipped = store.reorder(o);
                      showMessage(
                        context,
                        skipped.isEmpty
                            ? 'Items added to your cart.'
                            : 'Added to cart. Unavailable: ${skipped.join(', ')}.',
                      );
                      Navigator.pushNamed(context, '/cart');
                    },
                  ),
                  if (o.status == OrderStatus.received) ...[
                    const SizedBox(height: 10),
                    AppButton(
                      label: 'Cancel order',
                      outlined: true,
                      onPressed: () async {
                        final ok = await confirmDialog(
                          context,
                          title: 'Cancel this order?',
                          message: 'You can only cancel before the café confirms it.',
                          confirmLabel: 'Cancel order',
                          destructive: true,
                        );
                        if (!ok || !context.mounted) return;
                        try {
                          store.cancelOwnOrder(o.id);
                        } on OrderException catch (e) {
                          showMessage(context, e.message);
                        }
                      },
                    ),
                  ],
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _info(String label, String value, AppColors colors) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 118, child: Text(label, style: TextStyle(color: colors.oat, fontSize: 12.5))),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
      ],
    ),
  );

  Future<void> _reviewDialog(BuildContext context, CafeOrder o) async {
    var rating = 0;
    final text = TextEditingController();
    final colors = AppColors.of(context);
    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) => AlertDialog(
          title: const Text('Rate your order'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 1; i <= 5; i++)
                    IconButton(
                      onPressed: () => setDialog(() => rating = i),
                      icon: Icon(
                        i <= rating ? Icons.star_rounded : Icons.star_outline_rounded,
                        color: colors.gold,
                        size: 30,
                      ),
                    ),
                ],
              ),
              TextField(
                controller: text,
                maxLines: 3,
                decoration: const InputDecoration(hintText: 'Tell us how it was (optional)'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel', style: TextStyle(color: colors.oat))),
            TextButton(
              onPressed: () {
                final error = store.submitReview(o, rating, text.text);
                if (error != null) {
                  showMessage(context, error);
                  return;
                }
                Navigator.pop(ctx);
                showMessage(context, 'Thanks! Your review will appear once the café approves it.');
              },
              child: Text('Submit', style: TextStyle(color: colors.cinnamon)),
            ),
          ],
        ),
      ),
    );
    text.dispose();
  }
}

class _Tracker extends StatelessWidget {
  const _Tracker({required this.order});
  final CafeOrder order;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    if (order.status == OrderStatus.cancelled) {
      return Row(
        children: [
          const Icon(Icons.cancel_outlined, color: Colors.redAccent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'This order was cancelled.',
              style: TextStyle(color: colors.oat),
            ),
          ),
        ],
      );
    }
    final flow = order.flow;
    final current = flow.indexOf(order.status);
    return Column(
      children: [
        for (var i = 0; i < flow.length; i++)
          _step(context, colors, flow[i], i, current, i == flow.length - 1),
      ],
    );
  }

  Widget _step(BuildContext context, AppColors colors, OrderStatus s, int i, int current, bool last) {
    final done = i <= current;
    final active = i == current;
    DateTime? at;
    for (final h in order.history) {
      if (h.status == s) at = h.at;
    }
    final color = done ? colors.matcha : colors.line;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 28,
            child: Column(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: done ? color : Colors.transparent,
                    border: Border.all(color: active ? colors.gold : color, width: 2),
                  ),
                  child: done ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
                ),
                if (!last) Expanded(child: Container(width: 2, color: i < current ? colors.matcha : colors.line)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.labelFor(order.fulfillment),
                    style: TextStyle(
                      fontWeight: active ? FontWeight.w800 : FontWeight.w500,
                      color: done ? colors.latte : colors.oat,
                    ),
                  ),
                  if (at != null)
                    Text(Fmt.dateTime(at), style: TextStyle(color: colors.oat, fontSize: 11)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
