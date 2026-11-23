import 'package:flutter/material.dart';

import '../../data/app_store.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../../widgets/drink_art.dart';
import 'admin_common.dart';

class AdminMenu extends StatefulWidget {
  const AdminMenu({super.key});

  @override
  State<AdminMenu> createState() => _AdminMenuState();
}

class _AdminMenuState extends State<AdminMenu> {
  final _search = TextEditingController();
  String? _category;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final q = _search.text.trim().toLowerCase();
        final items = store.products
            .where((p) =>
                (_category == null || p.category == _category) &&
                (q.isEmpty || p.name.toLowerCase().contains(q)))
            .toList();
        return SafeArea(
          bottom: false,
          child: Stack(
            children: [
              Column(
                children: [
                  AdminHeader(
                    title: 'Menu',
                    actions: [
                      TextButton.icon(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const DrinkOptionsScreen()),
                        ),
                        icon: Icon(Icons.tune_rounded, color: colors.gold, size: 18),
                        label: Text('Options', style: TextStyle(color: colors.gold)),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                    child: TextField(
                      controller: _search,
                      onChanged: (_) => setState(() {}),
                      style: TextStyle(color: colors.latte),
                      decoration: InputDecoration(
                        hintText: 'Search the menu',
                        prefixIcon: Icon(Icons.search, color: colors.oat),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 52,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: const Text('All'),
                            selected: _category == null,
                            onSelected: (_) => setState(() => _category = null),
                          ),
                        ),
                        for (final c in Categories.all)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(c.label),
                              selected: _category == c.id,
                              onSelected: (_) => setState(() => _category = c.id),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 90),
                      children: [
                        for (final p in items)
                          AppCard(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(10),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => ProductEditorScreen(productId: p.id)),
                            ),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 52,
                                  height: 52,
                                  child: ProductImage(product: p, radius: BorderRadius.circular(10)),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(p.name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontWeight: FontWeight.w700)),
                                      Text(
                                        '${Categories.label(p.category)} · ${store.money(p.startingPrice)}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(color: colors.oat, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  children: [
                                    Text(p.available ? 'On' : 'Off',
                                        style: TextStyle(color: colors.oat, fontSize: 10)),
                                    Switch(
                                      value: p.available,
                                      activeThumbColor: colors.matcha,
                                      onChanged: (v) {
                                        p.available = v;
                                        store.saveChanges();
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        if (items.isEmpty)
                          const EmptyState(
                            icon: Icons.search_off_rounded,
                            title: 'No items',
                            message: 'Nothing matches. Add a new item with the + button.',
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              Positioned(
                right: 20,
                bottom: 16,
                child: FloatingActionButton.extended(
                  backgroundColor: colors.cinnamon,
                  foregroundColor: Colors.white,
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ProductEditorScreen()),
                  ),
                  icon: const Icon(Icons.add),
                  label: const Text('Add item'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SizeRow {
  final TextEditingController label;
  final TextEditingController extra;
  _SizeRow(String l, double e)
    : label = TextEditingController(text: l),
      extra = TextEditingController(text: formatNumberField(e));
}

const _artKeys = [
  'mocha_hot', 'mocha_iced', 'mocha_dark', 'mocha_white', 'mocha_spanish',
  'mocha_caramel', 'mocha_hazelnut', 'mocha_vanilla', 'frappe', 'matcha',
  'matcha_iced', 'matcha_strawberry', 'matcha_frappe', 'coffee', 'latte',
  'chocolate', 'brownie', 'cookie', 'croissant', 'roll', 'cake', 'cheesecake',
  'bundle',
];

/// Add or edit one menu item. Everything here is data, so the owner can
/// introduce new mocha or matcha drinks without touching source code.
class ProductEditorScreen extends StatefulWidget {
  const ProductEditorScreen({super.key, this.productId});
  final String? productId;

  @override
  State<ProductEditorScreen> createState() => _ProductEditorScreenState();
}

class _ProductEditorScreenState extends State<ProductEditorScreen> {
  late Product _p;
  late bool _isNewItem;
  final _name = TextEditingController();
  final _desc = TextEditingController();
  final _price = TextEditingController();
  final _ingredients = TextEditingController();
  final _bundle = TextEditingController();
  final _image = TextEditingController();
  final _stock = TextEditingController();
  final _low = TextEditingController();
  final List<_SizeRow> _sizes = [];
  bool _track = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.productId == null ? null : store.productById(widget.productId!);
    _isNewItem = existing == null;
    _p = existing?.copy() ??
        Product(
          id: store.newId('p'),
          name: '',
          description: '',
          category: 'signature',
          kind: Kinds.mocha,
          basePrice: 150,
          sizes: [SizeOption('Small', 0), SizeOption('Medium', 20), SizeOption('Large', 40)],
          signature: true,
          isNew: true,
          optionIds: _defaultOptionsFor(Kinds.mocha),
        );
    _name.text = _p.name;
    _desc.text = _p.description;
    _price.text = formatNumberField(_p.basePrice);
    _ingredients.text = _p.ingredients.join(', ');
    _bundle.text = _p.bundleItems.join('\n');
    _image.text = _p.imageUrl;
    _track = _p.stock != null;
    _stock.text = '${_p.stock ?? 0}';
    _low.text = '${_p.lowStock}';
    for (final s in _p.sizes) {
      _sizes.add(_SizeRow(s.label, s.extra));
    }
  }

  @override
  void dispose() {
    for (final c in [_name, _desc, _price, _ingredients, _bundle, _image, _stock, _low]) {
      c.dispose();
    }
    for (final s in _sizes) {
      s.label.dispose();
      s.extra.dispose();
    }
    super.dispose();
  }

  // Matcha drinks get matcha options; mocha and coffee drinks get espresso,
  // milk and toppings. Food and bundles get none.
  List<String> _defaultOptionsFor(String kind) {
    Iterable<String> groups;
    switch (kind) {
      case Kinds.matcha:
        groups = [AddOnGroups.milk, AddOnGroups.matchaIntensity, AddOnGroups.matchaExtra];
        break;
      case Kinds.mocha:
      case Kinds.coffee:
        groups = [AddOnGroups.milk, AddOnGroups.shot, AddOnGroups.topping];
        break;
      case Kinds.other:
        groups = [AddOnGroups.milk, AddOnGroups.topping];
        break;
      default:
        groups = const [];
    }
    return store.addOns.where((a) => groups.contains(a.group)).map((a) => a.id).toList();
  }

  void _save() {
    final name = _name.text.trim();
    final price = double.tryParse(_price.text.trim());
    if (name.isEmpty) return showMessage(context, 'Please enter a name.');
    if (price == null || price < 0) return showMessage(context, 'Please enter a valid price.');
    final sizes = <SizeOption>[];
    for (final row in _sizes) {
      final label = row.label.text.trim();
      final extra = double.tryParse(row.extra.text.trim());
      if (label.isEmpty || extra == null) {
        return showMessage(context, 'Check the size names and extra prices.');
      }
      sizes.add(SizeOption(label, extra));
    }
    if (sizes.isEmpty) return showMessage(context, 'Add at least one size.');
    if (_p.isDrink && !_p.hot && !_p.iced) {
      return showMessage(context, 'Choose hot, iced or both.');
    }
    _p
      ..name = name
      ..description = _desc.text.trim()
      ..basePrice = price
      ..sizes = sizes
      ..ingredients = _ingredients.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList()
      ..bundleItems = _bundle.text
          .split('\n')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList()
      ..imageUrl = _image.text.trim()
      ..lowStock = int.tryParse(_low.text.trim()) ?? 5
      ..stock = _track ? (int.tryParse(_stock.text.trim()) ?? 0) : null;
    if (!_p.isDrink) {
      _p.hot = false;
      _p.iced = false;
    }
    store.saveProduct(_p);
    Navigator.pop(context);
    showMessage(context, '${_p.name} saved.');
  }

  Future<void> _delete() async {
    final ok = await confirmDialog(
      context,
      title: 'Delete ${_p.name}?',
      message: 'It will disappear from the menu and from customers\' carts and favorites. Past orders keep their records.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!ok || !mounted) return;
    store.deleteProduct(_p.id);
    Navigator.pop(context);
  }

  Widget _title(String t, AppColors colors) => Padding(
    padding: const EdgeInsets.only(top: 20, bottom: 8),
    child: Text(t, style: AppFonts.serif(fontSize: 18, color: colors.latte)),
  );

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return AdminPage(
      title: _isNewItem ? 'New menu item' : 'Edit item',
      actions: [
        if (!_isNewItem)
          IconButton(
            tooltip: 'Delete',
            onPressed: _delete,
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
          ),
      ],
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          SizedBox(
            height: 150,
            child: ProductImage(product: _p, radius: BorderRadius.circular(16)),
          ),
          const SizedBox(height: 16),
          LabeledField(label: 'Name', controller: _name),
          LabeledField(label: 'Description', controller: _desc, maxLines: 3),
          DropdownButtonFormField<String>(
            initialValue: _p.category,
            decoration: const InputDecoration(labelText: 'Category'),
            dropdownColor: colors.espressoDark,
            items: [
              for (final c in Categories.all) DropdownMenuItem(value: c.id, child: Text(c.label)),
            ],
            onChanged: (v) => setState(() => _p.category = v ?? _p.category),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _p.kind,
            decoration: const InputDecoration(
              labelText: 'Item type',
              helperText: 'Controls which customizations apply and how sales are reported',
            ),
            dropdownColor: colors.espressoDark,
            items: [
              for (final k in Kinds.all) DropdownMenuItem(value: k, child: Text(k[0].toUpperCase() + k.substring(1))),
            ],
            onChanged: (v) => setState(() {
              _p.kind = v ?? _p.kind;
              // Pick sensible add-ons for a new item when its type changes.
              if (_isNewItem) _p.optionIds = _defaultOptionsFor(_p.kind);
            }),
          ),
          const SizedBox(height: 12),
          LabeledField(
            label: 'Base price (smallest size)',
            controller: _price,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            suffix: store.settings.currency,
          ),
          _title('Sizes', colors),
          for (var i = 0; i < _sizes.length; i++)
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: LabeledField(label: 'Size name', controller: _sizes[i].label),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: LabeledField(
                    label: 'Extra',
                    controller: _sizes[i].extra,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: IconButton(
                    tooltip: 'Remove size',
                    onPressed: _sizes.length > 1 ? () => setState(() => _sizes.removeAt(i)) : null,
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
                ),
              ],
            ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => setState(() => _sizes.add(_SizeRow('Large', 40))),
              icon: Icon(Icons.add, color: colors.gold),
              label: Text('Add size', style: TextStyle(color: colors.gold)),
            ),
          ),
          if (_p.isDrink) ...[
            _title('Temperature', colors),
            Wrap(
              spacing: 8,
              children: [
                FilterChip(
                  label: const Text('Hot'),
                  selected: _p.hot,
                  onSelected: (v) => setState(() => _p.hot = v),
                ),
                FilterChip(
                  label: const Text('Iced'),
                  selected: _p.iced,
                  onSelected: (v) => setState(() => _p.iced = v),
                ),
              ],
            ),
          ],
          _title('Details', colors),
          LabeledField(
            label: 'Ingredients (comma separated)',
            controller: _ingredients,
            maxLines: 2,
          ),
          if (_p.kind == Kinds.bundle)
            LabeledField(label: 'Bundle contents (one per line)', controller: _bundle, maxLines: 3),
          LabeledField(
            label: 'Photo URL or asset path (optional)',
            controller: _image,
            hint: 'https://… or assets/images/my_drink.jpg',
            onChanged: (v) => setState(() => _p.imageUrl = v.trim()),
          ),
          DropdownButtonFormField<String>(
            initialValue: _artKeys.contains(_p.artKey) ? _p.artKey : 'mocha_hot',
            decoration: const InputDecoration(
              labelText: 'Illustration (used when there is no photo)',
            ),
            dropdownColor: colors.espressoDark,
            items: [for (final k in _artKeys) DropdownMenuItem(value: k, child: Text(k))],
            onChanged: (v) => setState(() => _p.artKey = v ?? _p.artKey),
          ),
          _title('Labels and availability', colors),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Available to order'),
            value: _p.available,
            activeThumbColor: colors.matcha,
            onChanged: (v) => setState(() => _p.available = v),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Bestseller'),
            value: _p.bestSeller,
            activeThumbColor: colors.matcha,
            onChanged: (v) => setState(() => _p.bestSeller = v),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('New arrival'),
            value: _p.isNew,
            activeThumbColor: colors.matcha,
            onChanged: (v) => setState(() => _p.isNew = v),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Mocha specialty label'),
            subtitle: const Text('Shows the gold MOCHA SPECIALTY tag'),
            value: _p.signature,
            activeThumbColor: colors.matcha,
            onChanged: (v) => setState(() => _p.signature = v),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Track stock'),
            value: _track,
            activeThumbColor: colors.matcha,
            onChanged: (v) => setState(() => _track = v),
          ),
          if (_track)
            Row(
              children: [
                Expanded(
                  child: LabeledField(
                    label: 'Quantity',
                    controller: _stock,
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: LabeledField(
                    label: 'Low-stock alert at',
                    controller: _low,
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
          if (_p.isDrink) ...[
            _title('Drink options offered', colors),
            Text(
              'Choose which customizations customers see for this item. '
              'Prices are set in Menu > Options.',
              style: TextStyle(color: colors.oat, fontSize: 12),
            ),
            for (final g in AddOnGroups.all)
              if (store.addOns.any((a) => a.group == g)) ...[
                Padding(
                  padding: const EdgeInsets.only(top: 12, bottom: 4),
                  child: Text(AddOnGroups.label(g), style: TextStyle(color: colors.gold, fontWeight: FontWeight.w700)),
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    for (final a in store.addOns.where((a) => a.group == g))
                      FilterChip(
                        label: Text(a.active ? a.name : '${a.name} (off)'),
                        selected: _p.optionIds.contains(a.id),
                        onSelected: (v) => setState(() {
                          if (v) {
                            _p.optionIds.add(a.id);
                          } else {
                            _p.optionIds.remove(a.id);
                          }
                        }),
                      ),
                  ],
                ),
              ],
          ],
          const SizedBox(height: 24),
          AppButton(label: 'Save item', icon: Icons.check_rounded, onPressed: _save),
        ],
      ),
    );
  }
}

/// Manage sweetness levels and the milk, espresso, topping and matcha
/// choices (names, extra charges, on/off).
class DrinkOptionsScreen extends StatelessWidget {
  const DrinkOptionsScreen({super.key});

  Future<void> _editAddOn(BuildContext context, AddOn? existing, String group) async {
    final name = TextEditingController(text: existing?.name ?? '');
    final price = TextEditingController(text: formatNumberField(existing?.price ?? 0));
    var active = existing?.active ?? true;
    final colors = AppColors.of(context);
    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) => AlertDialog(
          title: Text(existing == null ? 'New ${AddOnGroups.label(group)} option' : 'Edit option'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 6),
              LabeledField(label: 'Name', controller: name),
              LabeledField(
                label: 'Extra charge',
                controller: price,
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
          actions: [
            if (existing != null)
              TextButton(
                onPressed: () {
                  store.deleteAddOn(existing.id);
                  Navigator.pop(ctx);
                },
                child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
              ),
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel', style: TextStyle(color: colors.oat))),
            TextButton(
              onPressed: () {
                final value = double.tryParse(price.text.trim());
                if (name.text.trim().isEmpty || value == null || value < 0) {
                  showMessage(context, 'Enter a name and a valid price.');
                  return;
                }
                if (existing == null) {
                  store.saveAddOn(AddOn(
                    id: store.newId('ao'),
                    group: group,
                    name: name.text.trim(),
                    price: value,
                    active: active,
                  ));
                } else {
                  existing
                    ..name = name.text.trim()
                    ..price = value
                    ..active = active;
                  store.saveAddOn(existing);
                }
                Navigator.pop(ctx);
              },
              child: Text('Save', style: TextStyle(color: colors.cinnamon)),
            ),
          ],
        ),
      ),
    );
    name.dispose();
    price.dispose();
  }

  Future<void> _addSweetness(BuildContext context) async {
    final c = TextEditingController();
    final colors = AppColors.of(context);
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New sweetness level'),
        content: LabeledField(label: 'Percent (0 to 100)', controller: c, keyboardType: TextInputType.number),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel', style: TextStyle(color: colors.oat))),
          TextButton(
            onPressed: () {
              final v = int.tryParse(c.text.trim());
              if (v == null || v < 0 || v > 100) {
                showMessage(context, 'Enter a whole number from 0 to 100.');
                return;
              }
              store.setSweetnessLevels([...store.sweetnessLevels, v]);
              Navigator.pop(ctx);
            },
            child: Text('Add', style: TextStyle(color: colors.cinnamon)),
          ),
        ],
      ),
    );
    c.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return AdminPage(
      title: 'Drink options',
      child: ListenableBuilder(
        listenable: store,
        builder: (context, _) => ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            Text('Sweetness levels', style: AppFonts.serif(fontSize: 20, color: colors.latte)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final s in store.sweetnessLevels)
                  InputChip(
                    label: Text('$s%'),
                    onDeleted: store.sweetnessLevels.length > 1
                        ? () => store.setSweetnessLevels(
                            store.sweetnessLevels.where((e) => e != s).toList(),
                          )
                        : null,
                  ),
                ActionChip(
                  avatar: const Icon(Icons.add, size: 16),
                  label: const Text('Add'),
                  onPressed: () => _addSweetness(context),
                ),
              ],
            ),
            for (final g in AddOnGroups.all) ...[
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(child: Text(AddOnGroups.label(g), style: AppFonts.serif(fontSize: 20, color: colors.latte))),
                  TextButton.icon(
                    onPressed: () => _editAddOn(context, null, g),
                    icon: Icon(Icons.add, color: colors.gold, size: 18),
                    label: Text('Add', style: TextStyle(color: colors.gold)),
                  ),
                ],
              ),
              for (final a in store.addOns.where((a) => a.group == g))
                AppCard(
                  margin: const EdgeInsets.only(bottom: 8),
                  onTap: () => _editAddOn(context, a, g),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(a.name,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: a.active ? colors.latte : colors.oat,
                            )),
                      ),
                      Text(a.price > 0 ? '+${store.money(a.price)}' : 'Free', style: TextStyle(color: colors.oat)),
                      const SizedBox(width: 10),
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
          ],
        ),
      ),
    );
  }
}
