import 'package:flutter/material.dart';

import '../../data/app_store.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import 'order_tracking_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _table = TextEditingController();
  final _street = TextEditingController();
  final _barangay = TextEditingController();
  final _city = TextEditingController();
  final _province = TextEditingController();
  final _deliveryNotes = TextEditingController();
  final _note = TextEditingController();
  final _promo = TextEditingController();

  late Fulfillment _fulfillment;
  String _pickup = 'ASAP';
  late String _payment;
  String _appliedPromo = '';
  String? _rewardId;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final user = store.currentUser;
    _name.text = user?.name ?? '';
    _email.text = user?.email ?? '';
    _phone.text = user?.phone ?? '';
    final s = store.settings;
    _fulfillment = s.pickupEnabled
        ? Fulfillment.pickup
        : (s.dineInEnabled ? Fulfillment.dineIn : Fulfillment.delivery);
    _payment = _enabledPayments().first;
  }

  List<String> _enabledPayments() {
    final s = store.settings;
    final list = [
      if (s.cashEnabled) PaymentMethods.cash,
      if (s.gcashEnabled) PaymentMethods.gcash,
      if (s.bankEnabled) PaymentMethods.bank,
    ];
    return list.isEmpty ? [PaymentMethods.cash] : list;
  }

  @override
  void dispose() {
    for (final c in [
      _name, _email, _phone, _table, _street, _barangay, _city,
      _province, _deliveryNotes, _note, _promo,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Reward? get _reward {
    for (final r in store.rewards) {
      if (r.id == _rewardId) return r;
    }
    return null;
  }

  String _instructions() {
    final s = store.settings;
    switch (_payment) {
      case PaymentMethods.gcash:
        return s.gcashInstructions;
      case PaymentMethods.bank:
        return s.bankInstructions;
    }
    return s.cashInstructions;
  }

  void _placeOrder() {
    if (_submitting) return;
    setState(() => _submitting = true);
    try {
      final order = store.placeOrder(
        CheckoutRequest(
          name: _name.text,
          email: _email.text,
          phone: _phone.text,
          fulfillment: _fulfillment,
          tableNo: _table.text,
          pickupTime: _pickup,
          street: _street.text,
          barangay: _barangay.text,
          city: _city.text,
          province: _province.text,
          deliveryNotes: _deliveryNotes.text,
          paymentMethod: _payment,
          promoCode: _appliedPromo,
          rewardId: _rewardId,
          note: _note.text,
        ),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => OrderTrackingScreen(orderId: order.id, justPlaced: true),
        ),
      );
    } on OrderException catch (e) {
      setState(() => _submitting = false);
      showMessage(context, e.message);
    }
  }

  Widget _title(String text, AppColors colors) => Padding(
    padding: const EdgeInsets.only(top: 22, bottom: 10),
    child: Text(text, style: AppFonts.serif(fontSize: 20, color: colors.latte)),
  );

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final s = store.settings;
        final user = store.currentUser;
        final fulfillments = [
          if (s.dineInEnabled) Fulfillment.dineIn,
          if (s.pickupEnabled) Fulfillment.pickup,
          if (s.deliveryEnabled) Fulfillment.delivery,
        ];
        if (!fulfillments.contains(_fulfillment) && fulfillments.isNotEmpty) {
          _fulfillment = fulfillments.first;
        }
        final reward = _reward;
        final q = store.quote(
          fulfillment: _fulfillment,
          promoCode: _appliedPromo,
          reward: reward,
        );
        final points = user == null ? 0 : store.pointsFor(user.id);
        final rewardChoices = store.rewards
            .where((r) => r.active && r.pointsCost <= points)
            .toList();
        if (_rewardId != null && reward == null) _rewardId = null;
        final slots = store.pickupSlots();
        if (!slots.contains(_pickup)) _pickup = 'ASAP';

        return Scaffold(
          backgroundColor: colors.espresso,
          appBar: AppBar(
            backgroundColor: colors.espresso,
            foregroundColor: colors.latte,
            title: Text('Checkout', style: AppFonts.serif(fontSize: 22, color: colors.latte)),
          ),
          body: PhoneFrame(
            child: store.cart.isEmpty && !_submitting
                ? const EmptyState(
                    icon: Icons.shopping_bag_outlined,
                    title: 'Your cart is empty',
                    message: 'Add something from the menu first.',
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                    children: [
                      _title('Your details', colors),
                      LabeledField(label: 'Full name', controller: _name),
                      LabeledField(
                        label: 'Email',
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      LabeledField(
                        label: 'Contact number',
                        controller: _phone,
                        keyboardType: TextInputType.phone,
                      ),
                      _title('How would you like it?', colors),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final f in fulfillments)
                            ChoiceChip(
                              label: Text(f.label),
                              selected: _fulfillment == f,
                              onSelected: (_) => setState(() => _fulfillment = f),
                            ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      if (_fulfillment == Fulfillment.dineIn && s.tableService)
                        LabeledField(
                          label: 'Table number or seating reference',
                          controller: _table,
                        ),
                      if (_fulfillment == Fulfillment.pickup) ...[
                        DropdownButtonFormField<String>(
                          initialValue: _pickup,
                          decoration: const InputDecoration(labelText: 'Pickup time'),
                          dropdownColor: colors.espressoDark,
                          items: [
                            for (final t in slots) DropdownMenuItem(value: t, child: Text(t)),
                          ],
                          onChanged: (v) => setState(() => _pickup = v ?? 'ASAP'),
                        ),
                        if (!store.isOpenNow)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              'We are closed right now. Open daily '
                              '${s.openHour}:00 to ${s.closeHour}:00 (24h).',
                              style: TextStyle(color: colors.oat, fontSize: 12),
                            ),
                          ),
                      ],
                      if (_fulfillment == Fulfillment.delivery) ...[
                        if (user != null && user.addresses.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Wrap(
                              spacing: 8,
                              children: [
                                for (final a in user.addresses)
                                  ActionChip(
                                    avatar: const Icon(Icons.place_outlined, size: 16),
                                    label: Text(a.label),
                                    onPressed: () => setState(() {
                                      _street.text = a.street;
                                      _barangay.text = a.barangay;
                                      _city.text = a.city;
                                      _province.text = a.province;
                                    }),
                                  ),
                              ],
                            ),
                          ),
                        LabeledField(label: 'Street address', controller: _street),
                        LabeledField(label: 'Barangay', controller: _barangay),
                        LabeledField(label: 'City / Municipality', controller: _city),
                        LabeledField(label: 'Province', controller: _province),
                        LabeledField(
                          label: 'Delivery instructions (optional)',
                          controller: _deliveryNotes,
                          maxLines: 2,
                        ),
                      ],
                      _title('Payment', colors),
                      for (final m in _enabledPayments())
                        RadioListTile<String>(
                          contentPadding: EdgeInsets.zero,
                          activeColor: colors.cinnamon,
                          title: Text(m),
                          value: m,
                          groupValue: _payment,
                          onChanged: (v) => setState(() => _payment = v ?? m),
                        ),
                      AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_instructions(), style: TextStyle(color: colors.oat, fontSize: 12.5)),
                            const SizedBox(height: 8),
                            Text(
                              'Payment is not taken in this app. The café confirms it '
                              'when they receive it. Never share passwords or OTP codes.',
                              style: TextStyle(color: colors.oat.withValues(alpha: 0.8), fontSize: 11.5),
                            ),
                          ],
                        ),
                      ),
                      _title('Promo and rewards', colors),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _promo,
                              textCapitalization: TextCapitalization.characters,
                              style: TextStyle(color: colors.latte),
                              decoration: const InputDecoration(labelText: 'Promo code'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          AppButton(
                            label: 'Apply',
                            outlined: true,
                            dense: true,
                            onPressed: () => setState(() => _appliedPromo = _promo.text.trim()),
                          ),
                        ],
                      ),
                      if (_appliedPromo.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            q.promoMessage ?? 'Code applied: ${_appliedPromo.toUpperCase()}',
                            style: TextStyle(
                              color: q.promoMessage == null ? colors.matcha : Colors.redAccent,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      if (rewardChoices.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        DropdownButtonFormField<String?>(
                          initialValue: _rewardId,
                          decoration: InputDecoration(
                            labelText: 'Redeem a reward ($points pts available)',
                          ),
                          dropdownColor: colors.espressoDark,
                          items: [
                            const DropdownMenuItem<String?>(value: null, child: Text('No reward')),
                            for (final r in rewardChoices)
                              DropdownMenuItem<String?>(
                                value: r.id,
                                child: Text('${r.name} (${r.pointsCost} pts)'),
                              ),
                          ],
                          onChanged: (v) => setState(() => _rewardId = v),
                        ),
                      ],
                      _title('Order summary', colors),
                      AppCard(
                        child: Column(
                          children: [
                            for (final i in store.cart)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '${i.quantity} × ${store.productById(i.productId)?.name ?? 'Item'}',
                                            style: const TextStyle(fontWeight: FontWeight.w600),
                                          ),
                                          Text(
                                            store.describeItem(i),
                                            style: TextStyle(color: colors.oat, fontSize: 11.5),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(store.money(store.lineTotal(i))),
                                  ],
                                ),
                              ),
                            const Divider(),
                            SummaryRow('Subtotal', store.money(q.subtotal)),
                            if (q.discount > 0)
                              SummaryRow('Promo discount', '-${store.money(q.discount)}', accent: colors.matcha),
                            if (q.rewardDiscount > 0)
                              SummaryRow('Reward', '-${store.money(q.rewardDiscount)}', accent: colors.matcha),
                            if (q.serviceFee > 0) SummaryRow('Service fee', store.money(q.serviceFee)),
                            if (q.deliveryFee > 0) SummaryRow('Delivery fee', store.money(q.deliveryFee)),
                            const Divider(),
                            SummaryRow('Total', store.money(q.total), bold: true),
                            const SizedBox(height: 6),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Estimated preparation: about ${q.prepMinutes} min',
                                style: TextStyle(color: colors.oat, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      LabeledField(label: 'Order note (optional)', controller: _note, maxLines: 2),
                      const SizedBox(height: 6),
                      SizedBox(
                        width: double.infinity,
                        child: AppButton(
                          label: _submitting ? 'Placing order…' : 'Place order · ${store.money(q.total)}',
                          icon: Icons.check_rounded,
                          onPressed: (_submitting || !s.acceptingOrders) ? null : _placeOrder,
                        ),
                      ),
                      if (!s.acceptingOrders)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            'We are not accepting orders right now.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: colors.oat, fontSize: 12),
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
