import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/app_store.dart';
import '../../data/report_service.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../widgets/common.dart';
import 'admin_common.dart';

// ---------------------------------------------------------------------------
// Customers
// ---------------------------------------------------------------------------

class CustomersScreen extends StatelessWidget {
  const CustomersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return AdminPage(
      title: 'Customers',
      child: ListenableBuilder(
        listenable: store,
        builder: (context, _) {
          final customers = store.customers;
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
            children: [
              Text(
                'Customer details are for café staff only. Do not share them.',
                style: TextStyle(color: colors.oat, fontSize: 12),
              ),
              const SizedBox(height: 10),
              if (customers.isEmpty)
                const EmptyState(icon: Icons.people_outline, title: 'No customers yet', message: 'Registered customers appear here.'),
              for (final u in customers)
                AppCard(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(u.name, style: const TextStyle(fontWeight: FontWeight.w800)),
                      Text(u.email, style: TextStyle(color: colors.oat, fontSize: 12)),
                      Text(u.phone.isEmpty ? 'No contact number' : u.phone,
                          style: TextStyle(color: colors.oat, fontSize: 12)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(child: Text('${store.orderCountFor(u.id)} orders', style: const TextStyle(fontSize: 12.5))),
                          Expanded(
                            child: Text('${store.money(store.completedSpendingFor(u.id))} spent',
                                style: TextStyle(color: colors.gold, fontWeight: FontWeight.w700, fontSize: 12.5)),
                          ),
                          Text('Joined ${Fmt.shortDate(u.createdAt)}',
                              style: TextStyle(color: colors.oat, fontSize: 11.5)),
                        ],
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Reports
// ---------------------------------------------------------------------------

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  String _range = '7';
  DateTimeRange? _custom;

  (DateTime, DateTime) _bounds() {
    final today = Fmt.dayStart(DateTime.now());
    switch (_range) {
      case '1':
        return (today, today);
      case '7':
        return (today.subtract(const Duration(days: 6)), today);
      case '30':
        return (today.subtract(const Duration(days: 29)), today);
      case 'custom':
        if (_custom != null) return (_custom!.start, _custom!.end);
    }
    return (DateTime(2000), today);
  }

  Future<void> _pickRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: now,
      initialDateRange: _custom,
    );
    if (picked != null) setState(() {
      _custom = picked;
      _range = 'custom';
    });
  }

  Future<void> _exportCsv(SalesReport r) async {
    final csv = r.toCsv();
    final colors = AppColors.of(context);
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Export CSV'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: SelectableText(csv, style: const TextStyle(fontSize: 11, fontFamily: 'monospace')),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Close', style: TextStyle(color: colors.oat))),
          TextButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: csv));
              if (ctx.mounted) Navigator.pop(ctx);
              if (mounted) showMessage(context, 'CSV copied. Paste it into a spreadsheet.');
            },
            child: Text('Copy', style: TextStyle(color: colors.cinnamon)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return AdminPage(
      title: 'Sales reports',
      child: ListenableBuilder(
        listenable: store,
        builder: (context, _) {
          final (from, to) = _bounds();
          final r = SalesReport.build(store.orders, from, to);
          final days = to.difference(from).inDays + 1;
          final chart = days <= 31
              ? [
                  for (var i = days - 1; i >= 0; i--)
                    MapEntry(
                      to.subtract(Duration(days: i)),
                      r.revenueByDay[SalesReport.dayKey(to.subtract(Duration(days: i)))] ?? 0,
                    ),
                ]
              : <MapEntry<DateTime, double>>[];
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final e in {'1': 'Today', '7': '7 days', '30': '30 days', 'all': 'All time'}.entries)
                    ChoiceChip(
                      label: Text(e.value),
                      selected: _range == e.key,
                      onSelected: (_) => setState(() => _range = e.key),
                    ),
                  ChoiceChip(
                    avatar: const Icon(Icons.date_range, size: 16),
                    label: Text(_range == 'custom' && _custom != null
                        ? '${Fmt.shortDate(_custom!.start)} – ${Fmt.shortDate(_custom!.end)}'
                        : 'Custom'),
                    selected: _range == 'custom',
                    onSelected: (_) => _pickRange(),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.5,
                children: [
                  StatCard(label: 'Completed revenue', value: store.money(r.revenue), icon: Icons.payments_outlined),
                  StatCard(label: 'Completed orders', value: '${r.orderCount}', icon: Icons.receipt_long_outlined),
                  StatCard(label: 'Average order', value: store.money(r.averageOrder), icon: Icons.trending_up_rounded),
                  StatCard(label: 'Mocha sales', value: store.money(r.mochaSales), icon: Icons.coffee_rounded),
                  StatCard(label: 'Matcha sales', value: store.money(r.matchaSales), icon: Icons.eco_outlined, accent: colors.matcha),
                  StatCard(label: 'Dessert sales', value: store.money(r.dessertSales), icon: Icons.cake_outlined, accent: colors.cinnamon),
                ],
              ),
              if (chart.isNotEmpty) ...[
                const SectionHeader(title: 'Daily sales'),
                AppCard(
                  child: SalesBarChart(
                    data: chart,
                    format: (v) => v >= 1000 ? '${(v / 1000).toStringAsFixed(1)}k' : v.toStringAsFixed(0),
                  ),
                ),
              ],
              const SectionHeader(title: 'Top-selling products'),
              AppCard(
                child: r.topProducts.isEmpty
                    ? Text('No completed orders in this period.', style: TextStyle(color: colors.oat))
                    : Column(
                        children: [
                          for (final e in r.topProducts.take(8))
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  Expanded(child: Text(e.key, maxLines: 1, overflow: TextOverflow.ellipsis)),
                                  Text('${e.value} sold', style: TextStyle(color: colors.oat)),
                                ],
                              ),
                            ),
                        ],
                      ),
              ),
              const SizedBox(height: 18),
              AppButton(
                label: 'Export CSV',
                icon: Icons.download_rounded,
                outlined: true,
                onPressed: r.orderCount == 0 ? null : () => _exportCsv(r),
              ),
              const SizedBox(height: 8),
              Text(
                'Only completed orders count as revenue. Cancelled and open orders are excluded.',
                textAlign: TextAlign.center,
                style: TextStyle(color: colors.oat, fontSize: 11.5),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Promotions
// ---------------------------------------------------------------------------

class PromotionsScreen extends StatelessWidget {
  const PromotionsScreen({super.key});

  Future<void> _edit(BuildContext context, Promo? existing) async {
    final code = TextEditingController(text: existing?.code ?? '');
    final title = TextEditingController(text: existing?.title ?? '');
    final value = TextEditingController(text: formatNumberField(existing?.value ?? 10));
    final min = TextEditingController(text: formatNumberField(existing?.minPurchase ?? 0));
    var percent = existing?.percent ?? true;
    var scope = existing?.scope ?? 'all';
    var active = existing?.active ?? true;
    DateTime? expires = existing?.expiresAt;
    final colors = AppColors.of(context);
    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) => AlertDialog(
          title: Text(existing == null ? 'New promotion' : 'Edit promotion'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 6),
                LabeledField(label: 'Code (customers type this)', controller: code),
                LabeledField(label: 'Title shown to customers', controller: title),
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(value: true, label: Text('Percent')),
                    ButtonSegment(value: false, label: Text('Fixed')),
                  ],
                  selected: {percent},
                  onSelectionChanged: (s) => setDialog(() => percent = s.first),
                ),
                const SizedBox(height: 12),
                LabeledField(
                  label: percent ? 'Discount (%)' : 'Discount amount',
                  controller: value,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
                LabeledField(
                  label: 'Minimum purchase',
                  controller: min,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
                DropdownButtonFormField<String>(
                  initialValue: scope,
                  decoration: const InputDecoration(labelText: 'Applies to'),
                  dropdownColor: colors.espressoDark,
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('Everything')),
                    DropdownMenuItem(value: 'mocha', child: Text('Mocha drinks')),
                    DropdownMenuItem(value: 'matcha', child: Text('Matcha drinks')),
                    DropdownMenuItem(value: 'dessert', child: Text('Desserts')),
                  ],
                  onChanged: (v) => setDialog(() => scope = v ?? 'all'),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(expires == null ? 'No expiry' : 'Expires ${Fmt.date(expires!)}',
                          style: TextStyle(color: colors.oat)),
                    ),
                    TextButton(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: ctx,
                          initialDate: expires ?? DateTime.now().add(const Duration(days: 30)),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 730)),
                        );
                        // End of the chosen day, so the code works all day.
                        if (picked != null) {
                          setDialog(() => expires = DateTime(picked.year, picked.month, picked.day, 23, 59));
                        }
                      },
                      child: Text('Set date', style: TextStyle(color: colors.gold)),
                    ),
                    if (expires != null)
                      TextButton(
                        onPressed: () => setDialog(() => expires = null),
                        child: Text('Clear', style: TextStyle(color: colors.oat)),
                      ),
                  ],
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Active'),
                  value: active,
                  activeThumbColor: colors.matcha,
                  onChanged: (v) => setDialog(() => active = v),
                ),
              ],
            ),
          ),
          actions: [
            if (existing != null)
              TextButton(
                onPressed: () {
                  store.deletePromo(existing.id);
                  Navigator.pop(ctx);
                },
                child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
              ),
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel', style: TextStyle(color: colors.oat))),
            TextButton(
              onPressed: () {
                final v = double.tryParse(value.text.trim());
                final m = double.tryParse(min.text.trim());
                final c = code.text.trim().toUpperCase();
                if (c.isEmpty || title.text.trim().isEmpty || v == null || v <= 0 || m == null || m < 0) {
                  showMessage(context, 'Enter a code, a title and valid numbers.');
                  return;
                }
                if (percent && v > 100) {
                  showMessage(context, 'A percentage cannot be more than 100.');
                  return;
                }
                final clash = store.promos.any((p) => p.code.toUpperCase() == c && p.id != existing?.id);
                if (clash) {
                  showMessage(context, 'That code is already used.');
                  return;
                }
                store.savePromo(Promo(
                  id: existing?.id ?? store.newId('pr'),
                  code: c,
                  title: title.text.trim(),
                  percent: percent,
                  value: v,
                  minPurchase: m,
                  scope: scope,
                  expiresAt: expires,
                  active: active,
                ));
                Navigator.pop(ctx);
              },
              child: Text('Save', style: TextStyle(color: colors.cinnamon)),
            ),
          ],
        ),
      ),
    );
    code.dispose();
    title.dispose();
    value.dispose();
    min.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return AdminPage(
      title: 'Promotions',
      fab: FloatingActionButton.extended(
        backgroundColor: colors.cinnamon,
        foregroundColor: Colors.white,
        onPressed: () => _edit(context, null),
        icon: const Icon(Icons.add),
        label: const Text('New'),
      ),
      child: ListenableBuilder(
        listenable: store,
        builder: (context, _) => ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 90),
          children: [
            Text(
              'Drink-and-dessert combos are created as items in Menu (category Bundles & Combos).',
              style: TextStyle(color: colors.oat, fontSize: 12),
            ),
            const SizedBox(height: 10),
            if (store.promos.isEmpty)
              const EmptyState(icon: Icons.local_offer_outlined, title: 'No promotions', message: 'Create a discount code with the New button.'),
            for (final p in store.promos)
              AppCard(
                margin: const EdgeInsets.only(bottom: 8),
                onTap: () => _edit(context, p),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(p.code, style: const TextStyle(fontWeight: FontWeight.w800)),
                              const SizedBox(width: 8),
                              Tag(p.valueLabel.toUpperCase(), color: colors.cinnamon),
                            ],
                          ),
                          Text(p.title, style: TextStyle(color: colors.oat, fontSize: 12.5)),
                          Text(
                            '${p.scope == 'all' ? 'Everything' : p.scope} · '
                            'min ${store.money(p.minPurchase)}'
                            '${p.expiresAt != null ? ' · ${p.expired ? 'expired' : 'until'} ${Fmt.shortDate(p.expiresAt!)}' : ''}',
                            style: TextStyle(color: colors.oat, fontSize: 11.5),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: p.active,
                      activeThumbColor: colors.matcha,
                      onChanged: (v) {
                        p.active = v;
                        store.saveChanges();
                      },
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

// ---------------------------------------------------------------------------
// Loyalty
// ---------------------------------------------------------------------------

class LoyaltyAdminScreen extends StatefulWidget {
  const LoyaltyAdminScreen({super.key});

  @override
  State<LoyaltyAdminScreen> createState() => _LoyaltyAdminScreenState();
}

class _LoyaltyAdminScreenState extends State<LoyaltyAdminScreen> {
  late final TextEditingController _rate =
      TextEditingController(text: '${store.settings.pesosPerPoint}');

  @override
  void dispose() {
    _rate.dispose();
    super.dispose();
  }

  Future<void> _editReward(Reward? existing) async {
    final name = TextEditingController(text: existing?.name ?? '');
    final cost = TextEditingController(text: '${existing?.pointsCost ?? 50}');
    final value = TextEditingController(text: formatNumberField(existing?.value ?? 20));
    var active = existing?.active ?? true;
    final colors = AppColors.of(context);
    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) => AlertDialog(
          title: Text(existing == null ? 'New reward' : 'Edit reward'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 6),
                LabeledField(label: 'Reward name', controller: name),
                LabeledField(label: 'Points cost', controller: cost, keyboardType: TextInputType.number),
                LabeledField(
                  label: 'Discount value',
                  controller: value,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Active'),
                  value: active,
                  activeThumbColor: colors.matcha,
                  onChanged: (v) => setDialog(() => active = v),
                ),
              ],
            ),
          ),
          actions: [
            if (existing != null)
              TextButton(
                onPressed: () {
                  store.deleteReward(existing.id);
                  Navigator.pop(ctx);
                },
                child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
              ),
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel', style: TextStyle(color: colors.oat))),
            TextButton(
              onPressed: () {
                final c = int.tryParse(cost.text.trim());
                final v = double.tryParse(value.text.trim());
                if (name.text.trim().isEmpty || c == null || c <= 0 || v == null || v <= 0) {
                  showMessage(context, 'Enter a name and valid numbers.');
                  return;
                }
                store.saveReward(Reward(
                  id: existing?.id ?? store.newId('r'),
                  name: name.text.trim(),
                  pointsCost: c,
                  value: v,
                  active: active,
                ));
                Navigator.pop(ctx);
              },
              child: Text('Save', style: TextStyle(color: colors.cinnamon)),
            ),
          ],
        ),
      ),
    );
    name.dispose();
    cost.dispose();
    value.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return AdminPage(
      title: 'Loyalty',
      fab: FloatingActionButton.extended(
        backgroundColor: colors.cinnamon,
        foregroundColor: Colors.white,
        onPressed: () => _editReward(null),
        icon: const Icon(Icons.add),
        label: const Text('Reward'),
      ),
      child: ListenableBuilder(
        listenable: store,
        builder: (context, _) => ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 90),
          children: [
            Text('Earning rule', style: AppFonts.serif(fontSize: 20, color: colors.latte)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: LabeledField(
                    label: 'Spend this much to earn 1 point',
                    controller: _rate,
                    keyboardType: TextInputType.number,
                    suffix: store.settings.currency,
                  ),
                ),
                const SizedBox(width: 10),
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: AppButton(
                    label: 'Save',
                    dense: true,
                    onPressed: () {
                      final v = int.tryParse(_rate.text.trim());
                      if (v == null || v <= 0) {
                        showMessage(context, 'Enter a whole number above zero.');
                        return;
                      }
                      store.settings.pesosPerPoint = v;
                      store.saveChanges();
                      showMessage(context, 'Earning rule saved.');
                    },
                  ),
                ),
              ],
            ),
            Text(
              'Points are only awarded when an order is completed and paid. Cancelled or unpaid orders earn nothing.',
              style: TextStyle(color: colors.oat, fontSize: 12),
            ),
            const SectionHeader(title: 'Rewards'),
            for (final r in store.rewards)
              AppCard(
                margin: const EdgeInsets.only(bottom: 8),
                onTap: () => _editReward(r),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(r.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                          Text('${r.pointsCost} points · ${store.money(r.value)} off',
                              style: TextStyle(color: colors.oat, fontSize: 12)),
                        ],
                      ),
                    ),
                    if (!r.active) const Tag('OFF', color: Colors.grey),
                  ],
                ),
              ),
            const SectionHeader(title: 'Customer balances'),
            for (final u in store.customers)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(u.name),
                trailing: Text('${store.pointsFor(u.id)} pts',
                    style: TextStyle(color: colors.gold, fontWeight: FontWeight.w700)),
              ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Announcements
// ---------------------------------------------------------------------------

class AnnouncementsScreen extends StatelessWidget {
  const AnnouncementsScreen({super.key});

  Future<void> _edit(BuildContext context, Announcement? existing) async {
    final title = TextEditingController(text: existing?.title ?? '');
    final body = TextEditingController(text: existing?.body ?? '');
    var active = existing?.active ?? true;
    final colors = AppColors.of(context);
    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) => AlertDialog(
          title: Text(existing == null ? 'New announcement' : 'Edit announcement'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 6),
                LabeledField(label: 'Title', controller: title),
                LabeledField(label: 'Message', controller: body, maxLines: 3),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Show on home page'),
                  value: active,
                  activeThumbColor: colors.matcha,
                  onChanged: (v) => setDialog(() => active = v),
                ),
              ],
            ),
          ),
          actions: [
            if (existing != null)
              TextButton(
                onPressed: () {
                  store.deleteAnnouncement(existing.id);
                  Navigator.pop(ctx);
                },
                child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
              ),
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel', style: TextStyle(color: colors.oat))),
            TextButton(
              onPressed: () {
                if (title.text.trim().isEmpty) {
                  showMessage(context, 'Please enter a title.');
                  return;
                }
                store.saveAnnouncement(Announcement(
                  id: existing?.id ?? store.newId('a'),
                  title: title.text.trim(),
                  body: body.text.trim(),
                  active: active,
                  createdAt: existing?.createdAt,
                ));
                Navigator.pop(ctx);
              },
              child: Text('Save', style: TextStyle(color: colors.cinnamon)),
            ),
          ],
        ),
      ),
    );
    title.dispose();
    body.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return AdminPage(
      title: 'Announcements',
      fab: FloatingActionButton.extended(
        backgroundColor: colors.cinnamon,
        foregroundColor: Colors.white,
        onPressed: () => _edit(context, null),
        icon: const Icon(Icons.add),
        label: const Text('New'),
      ),
      child: ListenableBuilder(
        listenable: store,
        builder: (context, _) => ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 90),
          children: [
            if (store.announcements.isEmpty)
              const EmptyState(icon: Icons.campaign_outlined, title: 'No announcements', message: 'Share a new flavor, holiday hours or a promo.'),
            for (final a in store.announcements)
              AppCard(
                margin: const EdgeInsets.only(bottom: 8),
                onTap: () => _edit(context, a),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(a.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                          Text(a.body, maxLines: 2, overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: colors.oat, fontSize: 12)),
                        ],
                      ),
                    ),
                    Switch(
                      value: a.active,
                      activeThumbColor: colors.matcha,
                      onChanged: (v) {
                        a.active = v;
                        store.saveChanges();
                      },
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

// ---------------------------------------------------------------------------
// Reviews
// ---------------------------------------------------------------------------

class ReviewsAdminScreen extends StatelessWidget {
  const ReviewsAdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return AdminPage(
      title: 'Reviews',
      child: ListenableBuilder(
        listenable: store,
        builder: (context, _) {
          final reviews = store.reviews;
          if (reviews.isEmpty) {
            return const EmptyState(
              icon: Icons.reviews_outlined,
              title: 'No reviews yet',
              message: 'Customers can rate completed orders. Their reviews appear here for approval.',
            );
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
            children: [
              for (final r in reviews)
                AppCard(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          for (var i = 0; i < 5; i++)
                            Icon(i < r.rating ? Icons.star_rounded : Icons.star_outline_rounded,
                                size: 18, color: colors.gold),
                          const Spacer(),
                          Tag(r.state.name.toUpperCase(),
                              color: r.state == ReviewState.approved
                                  ? colors.matcha
                                  : (r.state == ReviewState.hidden ? Colors.grey : colors.cinnamon)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text('${r.userName} · ${r.orderNo}', style: TextStyle(color: colors.oat, fontSize: 12)),
                      if (r.text.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 4), child: Text(r.text)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: [
                          if (r.state != ReviewState.approved)
                            AppButton(
                              label: 'Approve',
                              dense: true,
                              onPressed: () => store.setReviewState(r.id, ReviewState.approved),
                            ),
                          if (r.state != ReviewState.hidden)
                            AppButton(
                              label: 'Hide',
                              dense: true,
                              outlined: true,
                              onPressed: () => store.setReviewState(r.id, ReviewState.hidden),
                            ),
                          AppButton(
                            label: 'Delete',
                            dense: true,
                            outlined: true,
                            onPressed: () => store.deleteReview(r.id),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
