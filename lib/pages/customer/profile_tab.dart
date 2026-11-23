import 'package:flutter/material.dart';

import '../../data/app_store.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../widgets/app_widgets.dart';
import '../../widgets/common.dart';
import 'nav.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final u = store.currentUser;
        if (u == null) return const SizedBox.shrink();
        final points = store.pointsFor(u.id);
        final initials = u.name.trim().isEmpty
            ? '?'
            : u.name.trim().split(RegExp(r'\s+')).take(2).map((w) => w[0].toUpperCase()).join();
        return SafeArea(
          bottom: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text('Profile', style: AppFonts.serif(fontSize: 26, color: colors.latte)),
                  ),
                  ThemeToggleButton(isDark: isDark),
                ],
              ),
              const SizedBox(height: 16),
              AppCard(
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: colors.gold.withValues(alpha: 0.2),
                      child: Text(initials,
                          style: AppFonts.serif(fontSize: 22, color: colors.gold)),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(u.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
                          Text(u.email,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: colors.oat, fontSize: 12.5)),
                          Text(u.phone.isEmpty ? 'No contact number' : u.phone,
                              style: TextStyle(color: colors.oat, fontSize: 12.5)),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Edit profile',
                      onPressed: () => _editProfile(context, u),
                      icon: Icon(Icons.edit_outlined, color: colors.gold),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              AppCard(
                highlight: true,
                onTap: () => Navigator.pushNamed(context, '/loyalty'),
                child: Row(
                  children: [
                    Icon(Icons.workspace_premium_outlined, color: colors.gold, size: 30),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('$points points',
                              style: AppFonts.serif(fontSize: 20, color: colors.latte)),
                          Text('Loyalty rewards and history',
                              style: TextStyle(color: colors.oat, fontSize: 12)),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right, color: colors.oat),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _tile(context, Icons.receipt_long_outlined, 'Order history',
                  '${store.ordersFor(u.id).length} orders', () => customerTab.value = 3),
              _tile(context, Icons.favorite_border_rounded, 'Favorite drinks',
                  '${u.favorites.length} saved', () => customerTab.value = 2),
              _tile(context, Icons.notifications_none_rounded, 'Notifications', 'Announcements and order updates',
                  () => Navigator.pushNamed(context, '/notifications')),
              const SectionHeader(title: 'Saved addresses'),
              if (u.addresses.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text('No saved addresses yet.', style: TextStyle(color: colors.oat)),
                ),
              for (final a in u.addresses)
                AppCard(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Icon(Icons.place_outlined, color: colors.gold),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(a.label, style: const TextStyle(fontWeight: FontWeight.w700)),
                            Text(a.line, style: TextStyle(color: colors.oat, fontSize: 12)),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Remove address',
                        onPressed: () => store.removeAddress(a),
                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                      ),
                    ],
                  ),
                ),
              AppButton(
                label: 'Add address',
                icon: Icons.add_location_alt_outlined,
                outlined: true,
                dense: true,
                onPressed: () => _addAddress(context),
              ),
              const SectionHeader(title: 'Settings'),
              AppCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text('Order updates'),
                      subtitle: const Text('Status changes for your orders'),
                      value: u.notifyOrders,
                      activeThumbColor: colors.cinnamon,
                      onChanged: (v) => store.setNotificationPrefs(orders: v),
                    ),
                    SwitchListTile(
                      title: const Text('Promotions'),
                      subtitle: const Text('New offers and announcements'),
                      value: u.notifyPromos,
                      activeThumbColor: colors.cinnamon,
                      onChanged: (v) => store.setNotificationPrefs(promos: v),
                    ),
                    ListTile(
                      leading: Icon(Icons.lock_outline, color: colors.gold),
                      title: const Text('Change password'),
                      onTap: () => _changePassword(context),
                    ),
                  ],
                ),
              ),
              const SectionHeader(title: 'Visit us'),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(store.settings.name, style: const TextStyle(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text(store.settings.address, style: TextStyle(color: colors.oat, fontSize: 12.5)),
                    Text(
                      'Open ${Fmt.hourLabel(store.settings.openHour)} to ${Fmt.hourLabel(store.settings.closeHour)} daily',
                      style: TextStyle(color: colors.oat, fontSize: 12.5),
                    ),
                    Text('${store.settings.phone} · ${store.settings.email}',
                        style: TextStyle(color: colors.oat, fontSize: 12.5)),
                    Text('${store.settings.instagram}  ${store.settings.facebook}',
                        style: TextStyle(color: colors.oat, fontSize: 12.5)),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              AppButton(
                label: 'Sign out',
                icon: Icons.logout_rounded,
                outlined: true,
                onPressed: () {
                  store.logout();
                  customerTab.value = 0;
                  Navigator.pushNamedAndRemoveUntil(context, '/login', (r) => false);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _tile(BuildContext context, IconData icon, String title, String subtitle, VoidCallback onTap) {
    final colors = AppColors.of(context);
    return AppCard(
      margin: const EdgeInsets.only(bottom: 8),
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: colors.gold),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
                Text(subtitle, style: TextStyle(color: colors.oat, fontSize: 12)),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: colors.oat),
        ],
      ),
    );
  }

  Future<void> _editProfile(BuildContext context, AppUser u) async {
    final name = TextEditingController(text: u.name);
    final phone = TextEditingController(text: u.phone);
    final email = TextEditingController(text: u.email);
    final colors = AppColors.of(context);
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit profile'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 6),
              LabeledField(label: 'Full name', controller: name),
              LabeledField(label: 'Email', controller: email, keyboardType: TextInputType.emailAddress),
              LabeledField(label: 'Contact number', controller: phone, keyboardType: TextInputType.phone),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel', style: TextStyle(color: colors.oat))),
          TextButton(
            onPressed: () {
              store.updateProfile(name: name.text, phone: phone.text, email: email.text);
              Navigator.pop(ctx);
            },
            child: Text('Save', style: TextStyle(color: colors.cinnamon)),
          ),
        ],
      ),
    );
    name.dispose();
    phone.dispose();
    email.dispose();
  }

  Future<void> _addAddress(BuildContext context) async {
    final label = TextEditingController(text: 'Home');
    final street = TextEditingController();
    final barangay = TextEditingController();
    final city = TextEditingController();
    final province = TextEditingController();
    final colors = AppColors.of(context);
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New address'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 6),
              LabeledField(label: 'Label (Home, Work…)', controller: label),
              LabeledField(label: 'Street address', controller: street),
              LabeledField(label: 'Barangay', controller: barangay),
              LabeledField(label: 'City / Municipality', controller: city),
              LabeledField(label: 'Province', controller: province),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel', style: TextStyle(color: colors.oat))),
          TextButton(
            onPressed: () {
              if (street.text.trim().isEmpty || city.text.trim().isEmpty) {
                showMessage(context, 'Please enter at least a street and city.');
                return;
              }
              store.addAddress(SavedAddress(
                label: label.text.trim().isEmpty ? 'Address' : label.text.trim(),
                street: street.text.trim(),
                barangay: barangay.text.trim(),
                city: city.text.trim(),
                province: province.text.trim(),
              ));
              Navigator.pop(ctx);
            },
            child: Text('Save', style: TextStyle(color: colors.cinnamon)),
          ),
        ],
      ),
    );
    label.dispose();
    street.dispose();
    barangay.dispose();
    city.dispose();
    province.dispose();
  }

  Future<void> _changePassword(BuildContext context) async {
    final current = TextEditingController();
    final next = TextEditingController();
    final colors = AppColors.of(context);
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Change password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 6),
            TextField(
              controller: current,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Current password'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: next,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'New password'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel', style: TextStyle(color: colors.oat))),
          TextButton(
            onPressed: () {
              final error = store.changePassword(current.text, next.text);
              if (error != null) {
                showMessage(context, error);
                return;
              }
              Navigator.pop(ctx);
              showMessage(context, 'Password updated.');
            },
            child: Text('Update', style: TextStyle(color: colors.cinnamon)),
          ),
        ],
      ),
    );
    current.dispose();
    next.dispose();
  }
}
