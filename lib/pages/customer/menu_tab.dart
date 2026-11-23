import 'package:flutter/material.dart';

import '../../data/app_store.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import 'nav.dart';
import 'product_widgets.dart';

enum MenuSort { featured, newest, priceLow, priceHigh, popular }

String _sortLabel(MenuSort s) {
  switch (s) {
    case MenuSort.featured:
      return 'Featured';
    case MenuSort.newest:
      return 'Newest';
    case MenuSort.priceLow:
      return 'Price: low to high';
    case MenuSort.priceHigh:
      return 'Price: high to low';
    case MenuSort.popular:
      return 'Most popular';
  }
}

class MenuTab extends StatefulWidget {
  const MenuTab({super.key});

  @override
  State<MenuTab> createState() => _MenuTabState();
}

class _MenuTabState extends State<MenuTab> {
  final _search = TextEditingController();
  String? _category; // null = all categories
  String? _temp; // 'Hot', 'Iced' or null
  RangeValues _price = const RangeValues(0, 400);
  bool _bestOnly = false;
  bool _newOnly = false;
  bool _availableOnly = false;
  MenuSort _sort = MenuSort.featured;

  @override
  void initState() {
    super.initState();
    menuCategoryRequest.addListener(_applyRequest);
    _applyRequest();
  }

  // The home screen can ask the menu to open on a specific category.
  void _applyRequest() {
    final request = menuCategoryRequest.value;
    if (request != null) {
      setState(() => _category = request);
      menuCategoryRequest.value = null;
    }
  }

  @override
  void dispose() {
    menuCategoryRequest.removeListener(_applyRequest);
    _search.dispose();
    super.dispose();
  }

  bool get _filtersActive =>
      _temp != null ||
      _bestOnly ||
      _newOnly ||
      _availableOnly ||
      _price.start > 0 ||
      _price.end < 400;

  List<Product> _filtered() {
    final q = _search.text.trim().toLowerCase();
    final sold = store.soldCounts();
    final result = store.products.where((p) {
      if (_category != null && p.category != _category) return false;
      if (q.isNotEmpty) {
        final haystack = [
          p.name,
          p.description,
          Categories.label(p.category),
          ...p.ingredients,
        ].join(' ').toLowerCase();
        if (!haystack.contains(q)) return false;
      }
      if (_temp == 'Hot' && !p.hot) return false;
      if (_temp == 'Iced' && !p.iced) return false;
      if (_bestOnly && !p.bestSeller) return false;
      if (_newOnly && !p.isNew) return false;
      if (_availableOnly && !store.isOrderable(p)) return false;
      if (p.startingPrice < _price.start || p.startingPrice > _price.end) return false;
      return true;
    }).toList();

    switch (_sort) {
      case MenuSort.featured:
        break; // keep menu order, signature mocha first
      case MenuSort.newest:
        result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case MenuSort.priceLow:
        result.sort((a, b) => a.startingPrice.compareTo(b.startingPrice));
        break;
      case MenuSort.priceHigh:
        result.sort((a, b) => b.startingPrice.compareTo(a.startingPrice));
        break;
      case MenuSort.popular:
        result.sort((a, b) => (sold[b.id] ?? 0).compareTo(sold[a.id] ?? 0));
        break;
    }
    return result;
  }

  Future<void> _openFilters() async {
    var temp = _temp;
    var price = _price;
    var best = _bestOnly;
    var fresh = _newOnly;
    var available = _availableOnly;
    final colors = AppColors.of(context);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Filters', style: AppFonts.serif(fontSize: 22, color: colors.latte)),
                const SizedBox(height: 16),
                Text('Temperature', style: TextStyle(color: colors.oat)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final t in <String?>[null, 'Hot', 'Iced'])
                      ChoiceChip(
                        label: Text(t ?? 'Any'),
                        selected: temp == t,
                        onSelected: (_) => setSheet(() => temp = t),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Price: ${store.money(price.start)} to ${store.money(price.end)}',
                  style: TextStyle(color: colors.oat),
                ),
                RangeSlider(
                  values: price,
                  min: 0,
                  max: 400,
                  divisions: 40,
                  activeColor: colors.cinnamon,
                  onChanged: (v) => setSheet(() => price = v),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Best sellers only'),
                  value: best,
                  activeThumbColor: colors.cinnamon,
                  onChanged: (v) => setSheet(() => best = v),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('New arrivals only'),
                  value: fresh,
                  activeThumbColor: colors.cinnamon,
                  onChanged: (v) => setSheet(() => fresh = v),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Available now only'),
                  value: available,
                  activeThumbColor: colors.cinnamon,
                  onChanged: (v) => setSheet(() => available = v),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        label: 'Reset',
                        outlined: true,
                        onPressed: () => setSheet(() {
                          temp = null;
                          price = const RangeValues(0, 400);
                          best = false;
                          fresh = false;
                          available = false;
                        }),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppButton(
                        label: 'Apply',
                        onPressed: () {
                          setState(() {
                            _temp = temp;
                            _price = price;
                            _bestOnly = best;
                            _newOnly = fresh;
                            _availableOnly = available;
                          });
                          Navigator.pop(ctx);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final items = _filtered();
        final sectioned = _category == null && _search.text.trim().isEmpty;
        return SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 8, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text('Our Menu', style: AppFonts.serif(fontSize: 26, color: colors.latte)),
                    ),
                    const CartButton(),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 12, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _search,
                        onChanged: (_) => setState(() {}),
                        style: TextStyle(color: colors.latte, fontSize: 14),
                        cursorColor: colors.gold,
                        decoration: InputDecoration(
                          hintText: 'Search drinks, ingredients, categories',
                          prefixIcon: Icon(Icons.search, color: colors.oat),
                          suffixIcon: _search.text.isEmpty
                              ? null
                              : IconButton(
                                  icon: Icon(Icons.close, color: colors.oat, size: 18),
                                  onPressed: () => setState(_search.clear),
                                ),
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Filters',
                      onPressed: _openFilters,
                      icon: Badge(
                        isLabelVisible: _filtersActive,
                        smallSize: 8,
                        backgroundColor: colors.cinnamon,
                        child: Icon(Icons.tune_rounded, color: colors.gold),
                      ),
                    ),
                    PopupMenuButton<MenuSort>(
                      tooltip: 'Sort',
                      icon: Icon(Icons.sort_rounded, color: colors.gold),
                      onSelected: (s) => setState(() => _sort = s),
                      itemBuilder: (context) => [
                        for (final s in MenuSort.values)
                          CheckedPopupMenuItem<MenuSort>(
                            value: s,
                            checked: s == _sort,
                            child: Text(_sortLabel(s)),
                          ),
                      ],
                    ),
                  ],
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
                          selectedColor: c.id == 'matcha'
                              ? colors.matcha.withValues(alpha: 0.35)
                              : colors.gold.withValues(alpha: 0.30),
                          onSelected: (_) => setState(() => _category = c.id),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: items.isEmpty
                    ? const EmptyState(
                        icon: Icons.search_off_rounded,
                        title: 'Nothing found',
                        message: 'Try a different search or clear your filters.',
                      )
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                        children: sectioned && _sort == MenuSort.featured
                            ? _sections(context, items)
                            : [for (final p in items) ProductRow(product: p)],
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  // With no search or category chosen, drinks are grouped by category and the
  // signature mocha group is shown first with a stronger header.
  List<Widget> _sections(BuildContext context, List<Product> items) {
    final colors = AppColors.of(context);
    final widgets = <Widget>[];
    for (final c in Categories.all) {
      final inCat = items.where((p) => p.category == c.id).toList();
      if (inCat.isEmpty) continue;
      final isSignature = c.id == 'signature';
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(top: 14, bottom: 10),
          child: isSignature
              ? Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: colors.gold.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: colors.gold.withValues(alpha: 0.6)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Tag('MOCHA SPECIALTY'),
                      const SizedBox(height: 6),
                      Text(c.label, style: AppFonts.serif(fontSize: 24, color: colors.latte)),
                      Text(
                        'Chocolate-forward drinks, made to order.',
                        style: TextStyle(color: colors.oat, fontSize: 12),
                      ),
                    ],
                  ),
                )
              : Text(
                  c.label,
                  style: AppFonts.serif(
                    fontSize: 20,
                    color: c.id == 'matcha' ? colors.matcha : colors.latte,
                  ),
                ),
        ),
      );
      for (final p in inCat) {
        widgets.add(ProductRow(product: p));
      }
    }
    return widgets;
  }
}
