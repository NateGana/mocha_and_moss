import 'package:flutter/material.dart';

import '../../data/app_store.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../widgets/common.dart';
import 'admin_common.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  final s = store.settings;
  late final Map<String, TextEditingController> _c = {
    'name': TextEditingController(text: s.name),
    'tagline': TextEditingController(text: s.tagline),
    'description': TextEditingController(text: s.description),
    'phone': TextEditingController(text: s.phone),
    'email': TextEditingController(text: s.email),
    'address': TextEditingController(text: s.address),
    'instagram': TextEditingController(text: s.instagram),
    'facebook': TextEditingController(text: s.facebook),
    'currency': TextEditingController(text: s.currency),
    'deliveryFee': TextEditingController(text: formatNumberField(s.deliveryFee)),
    'serviceFee': TextEditingController(text: formatNumberField(s.serviceFeePercent)),
    'cash': TextEditingController(text: s.cashInstructions),
    'gcash': TextEditingController(text: s.gcashInstructions),
    'bank': TextEditingController(text: s.bankInstructions),
    'prepRegular': TextEditingController(text: '${s.prepRegular}'),
    'prepCustom': TextEditingController(text: '${s.prepCustomized}'),
    'prepSpecialty': TextEditingController(text: '${s.prepSpecialty}'),
    'prepLarge': TextEditingController(text: '${s.prepLargeOrder}'),
    'largeQty': TextEditingController(text: '${s.largeOrderQty}'),
  };

  @override
  void dispose() {
    for (final c in _c.values) {
      c.dispose();
    }
    super.dispose();
  }

  Widget _title(String t, AppColors colors) => Padding(
    padding: const EdgeInsets.only(top: 22, bottom: 10),
    child: Text(t, style: AppFonts.serif(fontSize: 20, color: colors.latte)),
  );

  Widget _switch(String label, bool value, ValueChanged<bool> onChanged, AppColors colors) =>
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(label),
        value: value,
        activeThumbColor: colors.matcha,
        onChanged: (v) => setState(() => onChanged(v)),
      );

  Widget _hour(String label, int value, ValueChanged<int> onChanged, AppColors colors) =>
      Expanded(
        child: DropdownButtonFormField<int>(
          initialValue: value,
          decoration: InputDecoration(labelText: label),
          dropdownColor: colors.espressoDark,
          items: [
            for (var h = 0; h <= 23; h++) DropdownMenuItem(value: h, child: Text(Fmt.hourLabel(h))),
          ],
          onChanged: (v) => onChanged(v ?? value),
        ),
      );

  void _save() {
    final delivery = double.tryParse(_c['deliveryFee']!.text.trim());
    final service = double.tryParse(_c['serviceFee']!.text.trim());
    int? mins(String key) => int.tryParse(_c[key]!.text.trim());
    if (_c['name']!.text.trim().isEmpty) return showMessage(context, 'The café name cannot be empty.');
    if (delivery == null || delivery < 0 || service == null || service < 0 || service > 100) {
      return showMessage(context, 'Check the fee amounts.');
    }
    if ([mins('prepRegular'), mins('prepCustom'), mins('prepSpecialty'), mins('prepLarge'), mins('largeQty')]
        .any((v) => v == null || v < 0)) {
      return showMessage(context, 'Preparation times must be whole numbers.');
    }
    if (s.closeHour <= s.openHour) return showMessage(context, 'Closing time must be after opening time.');
    s
      ..name = _c['name']!.text.trim()
      ..tagline = _c['tagline']!.text.trim()
      ..description = _c['description']!.text.trim()
      ..phone = _c['phone']!.text.trim()
      ..email = _c['email']!.text.trim()
      ..address = _c['address']!.text.trim()
      ..instagram = _c['instagram']!.text.trim()
      ..facebook = _c['facebook']!.text.trim()
      ..currency = _c['currency']!.text.trim().isEmpty ? '₱' : _c['currency']!.text.trim()
      ..deliveryFee = delivery
      ..serviceFeePercent = service
      ..cashInstructions = _c['cash']!.text.trim()
      ..gcashInstructions = _c['gcash']!.text.trim()
      ..bankInstructions = _c['bank']!.text.trim()
      ..prepRegular = mins('prepRegular')!
      ..prepCustomized = mins('prepCustom')!
      ..prepSpecialty = mins('prepSpecialty')!
      ..prepLargeOrder = mins('prepLarge')!
      ..largeOrderQty = mins('largeQty')!;
    store.saveChanges();
    showMessage(context, 'Settings saved.');
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return AdminPage(
      title: 'Café settings',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
        children: [
          _title('Café details', colors),
          LabeledField(label: 'Café name', controller: _c['name']!),
          LabeledField(label: 'Tagline', controller: _c['tagline']!),
          LabeledField(label: 'Description', controller: _c['description']!, maxLines: 3),
          LabeledField(label: 'Contact number', controller: _c['phone']!, keyboardType: TextInputType.phone),
          LabeledField(label: 'Email', controller: _c['email']!, keyboardType: TextInputType.emailAddress),
          LabeledField(label: 'Address', controller: _c['address']!, maxLines: 2),
          LabeledField(label: 'Instagram', controller: _c['instagram']!),
          LabeledField(label: 'Facebook', controller: _c['facebook']!),
          LabeledField(label: 'Currency symbol', controller: _c['currency']!),
          Text(
            'The logo is drawn in code (lib/widgets/brand_logo.dart), so it is changed there rather than uploaded.',
            style: TextStyle(color: colors.oat, fontSize: 11.5),
          ),
          _title('Operating hours', colors),
          Row(
            children: [
              _hour('Opens', s.openHour, (v) => setState(() => s.openHour = v), colors),
              const SizedBox(width: 12),
              _hour('Closes', s.closeHour, (v) => setState(() => s.closeHour = v), colors),
            ],
          ),
          _title('Ordering', colors),
          _switch('Accepting orders', s.acceptingOrders, (v) => s.acceptingOrders = v, colors),
          _switch('Dine-in', s.dineInEnabled, (v) => s.dineInEnabled = v, colors),
          _switch('Ask for table number (table service)', s.tableService, (v) => s.tableService = v, colors),
          _switch('Takeout / pickup', s.pickupEnabled, (v) => s.pickupEnabled = v, colors),
          _switch('Local delivery', s.deliveryEnabled, (v) => s.deliveryEnabled = v, colors),
          const SizedBox(height: 8),
          LabeledField(
            label: 'Delivery fee',
            controller: _c['deliveryFee']!,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          LabeledField(
            label: 'Dine-in service fee (%)',
            controller: _c['serviceFee']!,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          _title('Payments', colors),
          Text(
            'Payments are made outside the app. These instructions are shown to customers at checkout.',
            style: TextStyle(color: colors.oat, fontSize: 12),
          ),
          _switch('Cash', s.cashEnabled, (v) => s.cashEnabled = v, colors),
          LabeledField(label: 'Cash instructions', controller: _c['cash']!, maxLines: 2),
          _switch('GCash', s.gcashEnabled, (v) => s.gcashEnabled = v, colors),
          LabeledField(label: 'GCash instructions', controller: _c['gcash']!, maxLines: 3),
          _switch('Bank transfer', s.bankEnabled, (v) => s.bankEnabled = v, colors),
          LabeledField(label: 'Bank transfer instructions', controller: _c['bank']!, maxLines: 3),
          _title('Preparation times (minutes)', colors),
          Row(
            children: [
              Expanded(child: LabeledField(label: 'Regular', controller: _c['prepRegular']!, keyboardType: TextInputType.number)),
              const SizedBox(width: 10),
              Expanded(child: LabeledField(label: 'Customized', controller: _c['prepCustom']!, keyboardType: TextInputType.number)),
            ],
          ),
          Row(
            children: [
              Expanded(child: LabeledField(label: 'Specialty mocha', controller: _c['prepSpecialty']!, keyboardType: TextInputType.number)),
              const SizedBox(width: 10),
              Expanded(child: LabeledField(label: 'Large order', controller: _c['prepLarge']!, keyboardType: TextInputType.number)),
            ],
          ),
          LabeledField(label: 'Large order means this many items or more', controller: _c['largeQty']!, keyboardType: TextInputType.number),
          const SizedBox(height: 16),
          AppButton(label: 'Save settings', icon: Icons.check_rounded, onPressed: _save),
          const SizedBox(height: 8),
          Text(
            'Product availability is managed in Menu and Inventory.',
            textAlign: TextAlign.center,
            style: TextStyle(color: colors.oat, fontSize: 11.5),
          ),
        ],
      ),
    );
  }
}
