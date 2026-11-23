import 'package:flutter/material.dart';

import '../../data/app_store.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../widgets/common.dart';

class LoyaltyScreen extends StatelessWidget {
  const LoyaltyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final u = store.currentUser;
        final points = u == null ? 0 : store.pointsFor(u.id);
        final history = u == null ? <LoyaltyEntry>[] : store.loyaltyFor(u.id);
        final rewards = store.rewards.where((r) => r.active).toList()
          ..sort((a, b) => a.pointsCost.compareTo(b.pointsCost));
        return Scaffold(
          backgroundColor: colors.espresso,
          appBar: AppBar(
            backgroundColor: colors.espresso,
            foregroundColor: colors.latte,
            title: Text('Loyalty Rewards', style: AppFonts.serif(fontSize: 22, color: colors.latte)),
          ),
          body: PhoneFrame(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
              children: [
                AppCard(
                  highlight: true,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Text('$points', style: AppFonts.serif(fontSize: 44, color: colors.gold)),
                      Text('points', style: TextStyle(color: colors.oat)),
                      const SizedBox(height: 8),
                      Text(
                        'Earn 1 point for every ${store.money(store.settings.pesosPerPoint.toDouble())} spent on '
                        'completed, paid orders. Redeem rewards at checkout.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: colors.oat, fontSize: 12.5),
                      ),
                    ],
                  ),
                ),
                const SectionHeader(title: 'Rewards'),
                for (final r in rewards)
                  AppCard(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Icon(Icons.redeem_outlined, color: colors.cinnamon),
                        const SizedBox(width: 12),
                        Expanded(child: Text(r.name, style: const TextStyle(fontWeight: FontWeight.w700))),
                        Tag(
                          '${r.pointsCost} PTS',
                          color: points >= r.pointsCost ? colors.matcha : colors.oat,
                        ),
                      ],
                    ),
                  ),
                if (rewards.isEmpty) Text('No rewards available right now.', style: TextStyle(color: colors.oat)),
                const SectionHeader(title: 'History'),
                if (history.isEmpty)
                  Text('No points activity yet.', style: TextStyle(color: colors.oat)),
                for (final e in history)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(e.reason),
                    subtitle: Text(Fmt.dateTime(e.at), style: TextStyle(color: colors.oat, fontSize: 11.5)),
                    trailing: Text(
                      '${e.points > 0 ? '+' : ''}${e.points}',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: e.points > 0 ? colors.matcha : colors.cinnamon,
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

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final u = store.currentUser;
        final showPromos = u?.notifyPromos ?? true;
        final showOrders = u?.notifyOrders ?? true;
        final news = showPromos ? store.announcements.where((a) => a.active).toList() : <Announcement>[];
        final updates = <MapEntry<CafeOrder, StatusEvent>>[];
        if (u != null && showOrders) {
          for (final o in store.ordersFor(u.id)) {
            if (o.history.isNotEmpty) updates.add(MapEntry(o, o.history.last));
          }
          updates.sort((a, b) => b.value.at.compareTo(a.value.at));
        }
        final empty = news.isEmpty && updates.isEmpty;
        return Scaffold(
          backgroundColor: colors.espresso,
          appBar: AppBar(
            backgroundColor: colors.espresso,
            foregroundColor: colors.latte,
            title: Text('Notifications', style: AppFonts.serif(fontSize: 22, color: colors.latte)),
          ),
          body: PhoneFrame(
            child: empty
                ? const EmptyState(
                    icon: Icons.notifications_none_rounded,
                    title: 'All caught up',
                    message: 'Announcements and order updates show up here.',
                  )
                : ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      for (final e in updates.take(8))
                        AppCard(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Icon(Icons.receipt_long_outlined, color: colors.gold),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('${e.key.orderNo}: ${e.value.status.labelFor(e.key.fulfillment)}',
                                        style: const TextStyle(fontWeight: FontWeight.w700)),
                                    Text(Fmt.dateTime(e.value.at),
                                        style: TextStyle(color: colors.oat, fontSize: 11.5)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      for (final a in news)
                        AppCard(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.campaign_outlined, color: colors.cinnamon),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(a.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                                    Text(a.body, style: TextStyle(color: colors.oat, fontSize: 12.5)),
                                  ],
                                ),
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
