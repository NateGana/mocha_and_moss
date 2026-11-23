import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/models.dart';
import '../utils/format.dart';
import 'pricing.dart';
import 'seed_data.dart';

class OrderException implements Exception {
  final String message;
  OrderException(this.message);
  @override
  String toString() => message;
}

/// Everything the customer typed on the checkout screen.
class CheckoutRequest {
  String name;
  String email;
  String phone;
  Fulfillment fulfillment;
  String tableNo;
  String pickupTime;
  String street;
  String barangay;
  String city;
  String province;
  String deliveryNotes;
  String paymentMethod;
  String promoCode;
  String? rewardId;
  String note;

  CheckoutRequest({
    required this.name,
    required this.email,
    required this.phone,
    required this.fulfillment,
    this.tableNo = '',
    this.pickupTime = 'ASAP',
    this.street = '',
    this.barangay = '',
    this.city = '',
    this.province = '',
    this.deliveryNotes = '',
    required this.paymentMethod,
    this.promoCode = '',
    this.rewardId,
    this.note = '',
  });
}

class OrderQuote {
  final double subtotal;
  final double discount;
  final double rewardDiscount;
  final double serviceFee;
  final double deliveryFee;
  final double total;
  final String? promoMessage; // set when a typed promo code cannot be used
  final int prepMinutes;
  const OrderQuote({
    required this.subtotal,
    required this.discount,
    required this.rewardDiscount,
    required this.serviceFee,
    required this.deliveryFee,
    required this.total,
    required this.promoMessage,
    required this.prepMinutes,
  });
}

double _round2(double v) => (v * 100).round() / 100;

class AppStore extends ChangeNotifier {
  static const _prefsKey = 'mocha_moss_state';
  static const schemaVersion = 1;

  SharedPreferences? _prefs;
  bool ready = false;
  bool onboardingSeen = false;
  String? currentUserId;

  List<Product> products = [];
  List<AddOn> addOns = [];
  List<int> sweetnessLevels = [0, 25, 50, 75, 100];
  List<AppUser> users = [];
  Map<String, List<CartItem>> carts = {};
  List<CafeOrder> orders = [];
  List<Promo> promos = [];
  List<Announcement> announcements = [];
  List<Review> reviews = [];
  List<Reward> rewards = [];
  List<LoyaltyEntry> loyalty = [];
  List<StockItem> ingredients = [];
  CafeSettings settings = CafeSettings();
  int orderCounter = 0;
  int _idSeq = 0;

  // -------------------------------------------------------------------------
  // Loading and saving
  // -------------------------------------------------------------------------

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    var loaded = false;
    final raw = _prefs!.getString(_prefsKey);
    if (raw != null) {
      try {
        _load(jsonDecode(raw) as Map<String, dynamic>);
        loaded = true;
      } catch (e) {
        // A corrupt or outdated save should never stop the app from opening.
        debugPrint('Saved data could not be read, using sample data: $e');
      }
    }
    if (!loaded) {
      _seed();
      await _persistNow();
    }
    ready = true;
    notifyListeners();
  }

  /// Wipes everything back to the sample menu, accounts and orders.
  Future<void> resetDemoData() async {
    _seed();
    ready = true;
    await _persistNow();
    notifyListeners();
  }

  void _seed() {
    final prefsOnboarding = onboardingSeen;
    products = seedProducts();
    addOns = seedAddOns();
    sweetnessLevels = [0, 25, 50, 75, 100];
    users = seedUsers();
    carts = {};
    promos = seedPromos();
    announcements = seedAnnouncements();
    reviews = [];
    rewards = seedRewards();
    ingredients = seedIngredients();
    settings = CafeSettings();
    currentUserId = null;
    onboardingSeen = prefsOnboarding;
    final history = seedDemoHistory(products, addOns, users, settings);
    orders = history.orders;
    loyalty = history.loyalty;
    orderCounter = history.lastOrderNumber;
    orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  void _load(Map<String, dynamic> j) {
    if (j['v'] != schemaVersion) throw StateError('schema changed');
    List<T> list<T>(String key, T Function(Map<String, dynamic>) f) =>
        (j[key] as List)
            .map((e) => f(Map<String, dynamic>.from(e as Map)))
            .toList();

    products = list('products', Product.fromJson);
    addOns = list('addOns', AddOn.fromJson);
    sweetnessLevels = List<int>.from(j['sweetness'] as List);
    users = list('users', AppUser.fromJson);
    promos = list('promos', Promo.fromJson);
    announcements = list('announcements', Announcement.fromJson);
    reviews = list('reviews', Review.fromJson);
    rewards = list('rewards', Reward.fromJson);
    loyalty = list('loyalty', LoyaltyEntry.fromJson);
    ingredients = list('ingredients', StockItem.fromJson);
    orders = list('orders', CafeOrder.fromJson);
    settings = CafeSettings.fromJson(
      Map<String, dynamic>.from(j['settings'] as Map),
    );
    carts = {};
    (j['carts'] as Map).forEach((key, value) {
      carts[key as String] = (value as List)
          .map((e) => CartItem.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    });
    onboardingSeen = j['onboardingSeen'] as bool;
    currentUserId = j['currentUserId'] as String?;
    orderCounter = j['orderCounter'] as int;
    orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Map<String, dynamic> _toJson() => {
    'v': schemaVersion,
    'onboardingSeen': onboardingSeen,
    'currentUserId': currentUserId,
    'orderCounter': orderCounter,
    'products': products.map((e) => e.toJson()).toList(),
    'addOns': addOns.map((e) => e.toJson()).toList(),
    'sweetness': sweetnessLevels,
    'users': users.map((e) => e.toJson()).toList(),
    'carts': carts.map(
      (k, v) => MapEntry(k, v.map((e) => e.toJson()).toList()),
    ),
    'orders': orders.map((e) => e.toJson()).toList(),
    'promos': promos.map((e) => e.toJson()).toList(),
    'announcements': announcements.map((e) => e.toJson()).toList(),
    'reviews': reviews.map((e) => e.toJson()).toList(),
    'rewards': rewards.map((e) => e.toJson()).toList(),
    'loyalty': loyalty.map((e) => e.toJson()).toList(),
    'ingredients': ingredients.map((e) => e.toJson()).toList(),
    'settings': settings.toJson(),
  };

  Future<void> _persistNow() async {
    await _prefs?.setString(_prefsKey, jsonEncode(_toJson()));
  }

  /// Notify listeners and save. Screens that edit an object in place (such as
  /// the settings form) call [saveChanges] when they are done.
  void _commit() {
    notifyListeners();
    unawaited(_persistNow());
  }

  void saveChanges() => _commit();

  String newId(String prefix) =>
      '$prefix${DateTime.now().microsecondsSinceEpoch}_${_idSeq++}';

  String money(double v) => Fmt.money(v, settings.currency);

  void markOnboardingSeen() {
    onboardingSeen = true;
    _commit();
  }

  // -------------------------------------------------------------------------
  // Accounts
  // -------------------------------------------------------------------------

  AppUser? get currentUser {
    for (final u in users) {
      if (u.id == currentUserId) return u;
    }
    return null;
  }

  bool get isLoggedIn => currentUser != null;
  bool get isAdmin => currentUser?.isAdmin ?? false;

  /// Returns an error message, or null when the sign-in worked.
  String? login(String identifier, String password) {
    final id = identifier.trim().toLowerCase();
    for (final u in users) {
      final email = u.email.toLowerCase();
      if (email == id || email.split('@').first == id) {
        if (u.password != password) return 'Incorrect password.';
        currentUserId = u.id;
        _commit();
        return null;
      }
    }
    return 'Account does not exist. Please sign up first.';
  }

  String? register({
    required String name,
    required String email,
    required String password,
    String phone = '',
  }) {
    final e = email.trim().toLowerCase();
    for (final u in users) {
      if (u.email.toLowerCase() == e) {
        return 'An account with this email already exists.';
      }
    }
    final user = AppUser(
      id: newId('u'),
      name: name.trim(),
      email: email.trim(),
      phone: phone.trim(),
      password: password,
    );
    users.add(user);
    currentUserId = user.id;
    _commit();
    return null;
  }

  void logout() {
    currentUserId = null;
    _commit();
  }

  void updateProfile({String? name, String? phone, String? email}) {
    final u = currentUser;
    if (u == null) return;
    if (name != null && name.trim().isNotEmpty) u.name = name.trim();
    if (phone != null) u.phone = phone.trim();
    if (email != null && email.trim().isNotEmpty) u.email = email.trim();
    _commit();
  }

  String? changePassword(String current, String next) {
    final u = currentUser;
    if (u == null) return 'You are not signed in.';
    if (u.password != current) return 'Current password is incorrect.';
    if (next.length < 6) return 'New password must be at least 6 characters.';
    u.password = next;
    _commit();
    return null;
  }

  void addAddress(SavedAddress a) {
    currentUser?.addresses.add(a);
    _commit();
  }

  void removeAddress(SavedAddress a) {
    currentUser?.addresses.remove(a);
    _commit();
  }

  void setNotificationPrefs({bool? orders, bool? promos}) {
    final u = currentUser;
    if (u == null) return;
    if (orders != null) u.notifyOrders = orders;
    if (promos != null) u.notifyPromos = promos;
    _commit();
  }

  // -------------------------------------------------------------------------
  // Menu helpers
  // -------------------------------------------------------------------------

  Product? productById(String id) {
    for (final p in products) {
      if (p.id == id) return p;
    }
    return null;
  }

  AddOn? addOnById(String id) => findAddOn(addOns, id);

  bool isOrderable(Product p) =>
      p.available && (p.stock == null || p.stock! > 0);

  Map<String, int> soldCounts() {
    final map = <String, int>{};
    for (final o in orders) {
      if (o.status == OrderStatus.cancelled) continue;
      for (final l in o.lines) {
        map[l.productId] = (map[l.productId] ?? 0) + l.quantity;
      }
    }
    return map;
  }

  List<Product> get orderableProducts =>
      products.where(isOrderable).toList();

  List<Product> productsInCategory(String category) =>
      products.where((p) => p.category == category).toList();

  List<Product> get mochaProducts =>
      products.where((p) => p.isMocha).toList();

  /// Suggestions based on what this customer favors and has ordered before.
  List<Product> recommendedFor(AppUser? user, {int limit = 6}) {
    final affinity = <String, int>{}; // kind -> score
    final owned = <String>{};
    if (user != null) {
      for (final id in user.favorites) {
        final p = productById(id);
        if (p != null) {
          affinity[p.kind] = (affinity[p.kind] ?? 0) + 2;
          owned.add(p.id);
        }
      }
      for (final o in orders.where((o) => o.userId == user.id)) {
        for (final l in o.lines) {
          affinity[l.kind] = (affinity[l.kind] ?? 0) + 1;
          owned.add(l.productId);
        }
      }
    }
    final candidates = products
        .where((p) => isOrderable(p) && p.kind != Kinds.bundle)
        .toList();
    final sold = soldCounts();
    int score(Product p) =>
        (affinity[p.kind] ?? 0) * 10 +
        (owned.contains(p.id) ? 0 : 5) +
        (p.bestSeller ? 3 : 0) +
        (sold[p.id] ?? 0);
    candidates.sort((a, b) => score(b).compareTo(score(a)));
    return candidates.take(limit).toList();
  }

  // -------------------------------------------------------------------------
  // Favorites
  // -------------------------------------------------------------------------

  bool isFavorite(String productId) =>
      currentUser?.favorites.contains(productId) ?? false;

  void toggleFavorite(String productId) {
    final u = currentUser;
    if (u == null) return;
    if (!u.favorites.remove(productId)) u.favorites.add(productId);
    _commit();
  }

  // -------------------------------------------------------------------------
  // Cart
  // -------------------------------------------------------------------------

  List<CartItem> get cart => carts.putIfAbsent(currentUserId ?? 'guest', () => []);

  int get cartCount => cart.fold(0, (a, i) => a + i.quantity);

  double unitPriceOf(CartItem i) {
    final p = productById(i.productId);
    if (p == null) return 0;
    return unitPrice(p, addOns, i.size, i.optionIds);
  }

  double lineTotal(CartItem i) => _round2(unitPriceOf(i) * i.quantity);

  double get cartSubtotal => _round2(cart.fold(0.0, (a, i) => a + lineTotal(i)));

  String describeItem(CartItem i) {
    final p = productById(i.productId);
    if (p == null) return '';
    return describeSelection(
      p,
      addOns,
      size: i.size,
      temp: i.temp,
      sweetness: i.sweetness,
      optionIds: i.optionIds,
    );
  }

  CartItem defaultItemFor(Product p) =>
      defaultSelection(p, addOns, sweetnessLevels, newId('c'));

  // Keep the selected drink size when the customer updates their cart: an
  // identical drink is merged into the existing line instead of duplicated.
  void addToCart(CartItem item) {
    final list = cart;
    for (final existing in list) {
      if (existing.signatureKey == item.signatureKey) {
        existing.quantity += item.quantity;
        _commit();
        return;
      }
    }
    list.add(item);
    _commit();
  }

  void updateCartItem(String oldId, CartItem updated) {
    cart.removeWhere((c) => c.id == oldId);
    addToCart(updated);
  }

  void setCartQuantity(String id, int quantity) {
    final list = cart;
    final index = list.indexWhere((c) => c.id == id);
    if (index < 0) return;
    if (quantity <= 0) {
      list.removeAt(index);
    } else {
      list[index].quantity = quantity.clamp(1, 99).toInt();
    }
    _commit();
  }

  void removeFromCart(String id) => setCartQuantity(id, 0);

  void clearCart() {
    cart.clear();
    _commit();
  }

  /// Re-adds a past order's items. Returns names that could not be added.
  List<String> reorder(CafeOrder o) {
    final skipped = <String>[];
    for (final l in o.lines) {
      final p = productById(l.productId);
      if (p == null || !isOrderable(p)) {
        skipped.add(l.name);
        continue;
      }
      final stillValid = l.optionIds
          .where((id) => addOnById(id)?.active ?? false)
          .toList();
      addToCart(
        CartItem(
          id: newId('c'),
          productId: p.id,
          size: p.sizes.any((s) => s.label == l.size)
              ? l.size
              : p.sizes.first.label,
          temp: l.temp,
          sweetness: l.sweetness,
          optionIds: stillValid,
          quantity: l.quantity,
          note: l.note,
        ),
      );
    }
    return skipped;
  }

  // -------------------------------------------------------------------------
  // Promotions and totals
  // -------------------------------------------------------------------------

  Promo? findPromo(String code) {
    final c = code.trim().toUpperCase();
    if (c.isEmpty) return null;
    for (final p in promos) {
      if (p.code.toUpperCase() == c) return p;
    }
    return null;
  }

  bool _scopeMatches(String scope, String kind) {
    switch (scope) {
      case 'mocha':
        return kind == Kinds.mocha;
      case 'matcha':
        return kind == Kinds.matcha;
      case 'dessert':
        return kind == Kinds.dessert;
    }
    return true;
  }

  double _eligibleSubtotal(Promo promo, List<CartItem> items) {
    var sum = 0.0;
    for (final i in items) {
      final p = productById(i.productId);
      if (p != null && _scopeMatches(promo.scope, p.kind)) sum += lineTotal(i);
    }
    return sum;
  }

  /// Why [promo] cannot be used for the current cart, or null if it can.
  String? promoProblem(Promo promo, List<CartItem> items, double subtotal) {
    if (!promo.active) return 'This code is not active.';
    if (promo.expired) return 'This code has expired.';
    if (subtotal < promo.minPurchase) {
      return 'Spend at least ${money(promo.minPurchase)} to use this code.';
    }
    if (_eligibleSubtotal(promo, items) <= 0) {
      return 'This code does not apply to the drinks in your cart.';
    }
    return null;
  }

  int estimatePrepMinutes(List<CartItem> items) {
    var minutes = 0;
    var qty = 0;
    for (final i in items) {
      final p = productById(i.productId);
      if (p == null) continue;
      qty += i.quantity;
      var m = p.isMocha ? settings.prepSpecialty : settings.prepRegular;
      final defaults = defaultSelection(p, addOns, sweetnessLevels, 'x');
      final sameOptions =
          ([...i.optionIds]..sort()).join(',') ==
          ([...defaults.optionIds]..sort()).join(',');
      final customized =
          !sameOptions ||
          i.sweetness != defaults.sweetness ||
          i.note.trim().isNotEmpty;
      if (p.isDrink && customized && settings.prepCustomized > m) {
        m = settings.prepCustomized;
      }
      if (!p.isDrink) m = 2;
      if (m > minutes) minutes = m;
    }
    if (qty >= settings.largeOrderQty && settings.prepLargeOrder > minutes) {
      minutes = settings.prepLargeOrder;
    }
    return minutes;
  }

  OrderQuote quote({
    Fulfillment? fulfillment,
    String promoCode = '',
    Reward? reward,
  }) {
    final items = cart;
    final subtotal = cartSubtotal;
    var discount = 0.0;
    String? message;
    if (promoCode.trim().isNotEmpty) {
      final promo = findPromo(promoCode);
      if (promo == null) {
        message = 'Promo code not found.';
      } else {
        message = promoProblem(promo, items, subtotal);
        if (message == null) {
          final eligible = _eligibleSubtotal(promo, items);
          discount = promo.percent
              ? _round2(eligible * promo.value / 100)
              : (promo.value < eligible ? promo.value : eligible);
        }
      }
    }
    var after = subtotal - discount;
    var rewardDiscount = 0.0;
    if (reward != null) {
      rewardDiscount = reward.value < after ? reward.value : after;
      after -= rewardDiscount;
    }
    final service = fulfillment == Fulfillment.dineIn
        ? _round2(after * settings.serviceFeePercent / 100)
        : 0.0;
    final delivery =
        fulfillment == Fulfillment.delivery ? settings.deliveryFee : 0.0;
    return OrderQuote(
      subtotal: subtotal,
      discount: discount,
      rewardDiscount: rewardDiscount,
      serviceFee: service,
      deliveryFee: delivery,
      total: _round2(after + service + delivery),
      promoMessage: message,
      prepMinutes: estimatePrepMinutes(items),
    );
  }

  // -------------------------------------------------------------------------
  // Checkout and order lifecycle
  // -------------------------------------------------------------------------

  bool get isOpenNow {
    final h = DateTime.now().hour;
    return h >= settings.openHour && h < settings.closeHour;
  }

  /// Pickup time choices in 15-minute steps while the café is open.
  List<String> pickupSlots() {
    final now = DateTime.now();
    final opening = DateTime(now.year, now.month, now.day, settings.openHour);
    final closing = DateTime(now.year, now.month, now.day, settings.closeHour);
    var start = now.add(Duration(minutes: estimatePrepMinutes(cart) + 5));
    if (start.isBefore(opening)) start = opening;
    final rem = start.minute % 15;
    if (rem != 0) start = start.add(Duration(minutes: 15 - rem));
    final slots = <String>['ASAP'];
    var t = DateTime(start.year, start.month, start.day, start.hour, start.minute);
    while (t.isBefore(closing) && slots.length < 25) {
      slots.add(Fmt.time(t));
      t = t.add(const Duration(minutes: 15));
    }
    return slots;
  }

  int pointsFor(String userId) =>
      loyalty.where((e) => e.userId == userId).fold(0, (a, e) => a + e.points);

  List<LoyaltyEntry> loyaltyFor(String userId) {
    final list = loyalty.where((e) => e.userId == userId).toList();
    list.sort((a, b) => b.at.compareTo(a.at));
    return list;
  }

  CafeOrder placeOrder(CheckoutRequest r) {
    final user = currentUser;
    if (user == null) throw OrderException('Please sign in to place an order.');
    if (!settings.acceptingOrders) {
      throw OrderException('We are not accepting orders right now.');
    }
    final items = [...cart];
    // A second tap on "Place order" finds an empty cart, so it cannot create a
    // duplicate order.
    if (items.isEmpty) throw OrderException('Your cart is empty.');

    final name = r.name.trim();
    final email = r.email.trim();
    final phone = r.phone.trim();
    if (name.isEmpty) throw OrderException('Please enter your full name.');
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      throw OrderException('Please enter a valid email address.');
    }
    if (phone.replaceAll(RegExp(r'\D'), '').length < 10) {
      throw OrderException('Please enter a valid contact number.');
    }

    switch (r.fulfillment) {
      case Fulfillment.dineIn:
        if (!settings.dineInEnabled) {
          throw OrderException('Dine-in is not available right now.');
        }
        if (settings.tableService && r.tableNo.trim().isEmpty) {
          throw OrderException('Please enter your table number.');
        }
        break;
      case Fulfillment.pickup:
        if (!settings.pickupEnabled) {
          throw OrderException('Pickup is not available right now.');
        }
        break;
      case Fulfillment.delivery:
        if (!settings.deliveryEnabled) {
          throw OrderException('Delivery is not available right now.');
        }
        if (r.street.trim().isEmpty ||
            r.barangay.trim().isEmpty ||
            r.city.trim().isEmpty ||
            r.province.trim().isEmpty) {
          throw OrderException('Please complete your delivery address.');
        }
        break;
    }

    final paymentOk =
        (r.paymentMethod == PaymentMethods.cash && settings.cashEnabled) ||
        (r.paymentMethod == PaymentMethods.gcash && settings.gcashEnabled) ||
        (r.paymentMethod == PaymentMethods.bank && settings.bankEnabled);
    if (!paymentOk) throw OrderException('Please choose a payment method.');

    // Prices and stock are always re-read from the menu here, never trusted
    // from whatever the cart remembered.
    final lines = <OrderLine>[];
    final needed = <String, int>{};
    for (final item in items) {
      final p = productById(item.productId);
      if (p == null) {
        throw OrderException('An item in your cart is no longer on the menu.');
      }
      if (!isOrderable(p)) {
        throw OrderException('${p.name} is currently unavailable.');
      }
      final problem = _itemProblem(p, item);
      if (problem != null) throw OrderException(problem);
      needed[p.id] = (needed[p.id] ?? 0) + item.quantity;
      if (p.stock != null && needed[p.id]! > p.stock!) {
        throw OrderException('Only ${p.stock} left of ${p.name}.');
      }
      lines.add(
        OrderLine(
          productId: p.id,
          name: p.name,
          kind: p.kind,
          category: p.category,
          size: item.size,
          temp: item.temp,
          sweetness: item.sweetness,
          optionIds: [...item.optionIds],
          note: item.note.trim(),
          summary: describeItem(item),
          quantity: item.quantity,
          unitPrice: unitPrice(p, addOns, item.size, item.optionIds),
        ),
      );
    }

    Reward? reward;
    if (r.rewardId != null) {
      for (final rw in rewards) {
        if (rw.id == r.rewardId) reward = rw;
      }
      if (reward == null || !reward.active) {
        throw OrderException('That reward is no longer available.');
      }
      if (pointsFor(user.id) < reward.pointsCost) {
        throw OrderException('You do not have enough points for that reward.');
      }
    }

    final q = quote(
      fulfillment: r.fulfillment,
      promoCode: r.promoCode,
      reward: reward,
    );
    if (q.promoMessage != null) throw OrderException(q.promoMessage!);

    // Everything checks out: take stock, then save the order.
    for (final entry in needed.entries) {
      final p = productById(entry.key)!;
      if (p.stock != null) p.stock = p.stock! - entry.value;
    }
    orderCounter++;
    final now = DateTime.now();
    final stamp =
        '${now.year % 100}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    final order = CafeOrder(
      id: newId('o'),
      orderNo: 'MM-$stamp-${orderCounter.toString().padLeft(4, '0')}',
      userId: user.id,
      customerName: name,
      email: email,
      phone: phone,
      lines: lines,
      fulfillment: r.fulfillment,
      tableNo: r.tableNo.trim(),
      pickupTime: r.pickupTime,
      street: r.street.trim(),
      barangay: r.barangay.trim(),
      city: r.city.trim(),
      province: r.province.trim(),
      deliveryNotes: r.deliveryNotes.trim(),
      paymentMethod: r.paymentMethod,
      paid: false, // payment is confirmed by staff, never by the app
      promoCode: q.discount > 0 ? r.promoCode.trim().toUpperCase() : '',
      subtotal: q.subtotal,
      discount: q.discount,
      rewardDiscount: q.rewardDiscount,
      rewardPointsUsed: reward?.pointsCost ?? 0,
      serviceFee: q.serviceFee,
      deliveryFee: q.deliveryFee,
      total: q.total,
      prepMinutes: q.prepMinutes,
      history: [StatusEvent(OrderStatus.received, now)],
      createdAt: now,
      note: r.note.trim(),
    );
    orders.insert(0, order);
    if (reward != null) {
      loyalty.add(
        LoyaltyEntry(
          id: newId('l'),
          userId: user.id,
          points: -reward.pointsCost,
          reason: 'Redeemed ${reward.name}',
          at: now,
        ),
      );
    }
    cart.clear();
    _commit();
    return order;
  }

  /// Returns a message when this cart line is no longer valid for the menu.
  String? _itemProblem(Product p, CartItem item) {
    final fix = 'Please update ${p.name} in your cart.';
    if (!p.sizes.any((s) => s.label == item.size)) return fix;
    if (p.isDrink) {
      if (item.temp == 'Hot' && !p.hot) return fix;
      if (item.temp == 'Iced' && !p.iced) return fix;
      if (item.temp.isEmpty) return fix;
      if (!sweetnessLevels.contains(item.sweetness)) return fix;
    }
    final perGroup = <String, int>{};
    for (final id in item.optionIds) {
      final a = addOnById(id);
      if (a == null || !a.active || !p.optionIds.contains(id)) return fix;
      perGroup[a.group] = (perGroup[a.group] ?? 0) + 1;
      if (AddOnGroups.isSingle(a.group) && perGroup[a.group]! > 1) return fix;
    }
    return null;
  }

  CafeOrder? orderById(String id) {
    for (final o in orders) {
      if (o.id == id) return o;
    }
    return null;
  }

  List<CafeOrder> ordersFor(String userId) =>
      orders.where((o) => o.userId == userId).toList();

  /// Staff action. Orders move forward one step at a time or get cancelled.
  void setOrderStatus(String orderId, OrderStatus next) {
    final o = orderById(orderId);
    if (o == null) throw OrderException('Order not found.');
    if (!o.isActive) {
      throw OrderException('This order is already ${o.statusLabel}.');
    }
    if (next == OrderStatus.cancelled) {
      _releaseOrder(o);
    } else {
      if (o.nextStatus != next) {
        final expected = o.nextStatus;
        throw OrderException(
          expected == null
              ? 'This order cannot move to ${next.labelFor(o.fulfillment)}.'
              : 'Move this order to "${expected.labelFor(o.fulfillment)}" next.',
        );
      }
      if (next == OrderStatus.completed && !o.paid) {
        if (o.paymentMethod == PaymentMethods.cash) {
          o.paid = true; // cash is collected when the order is handed over
        } else {
          throw OrderException(
            'Mark the ${o.paymentMethod} payment as received before completing.',
          );
        }
      }
    }
    o.status = next;
    o.history.add(StatusEvent(next, DateTime.now()));
    if (next == OrderStatus.completed) _awardPoints(o);
    _commit();
  }

  /// A customer may cancel their own order until staff confirm it.
  void cancelOwnOrder(String orderId) {
    final o = orderById(orderId);
    if (o == null) throw OrderException('Order not found.');
    if (o.status != OrderStatus.received) {
      throw OrderException('This order is already being handled. Please contact the café.');
    }
    setOrderStatus(orderId, OrderStatus.cancelled);
  }

  void markPaid(String orderId, bool paid) {
    final o = orderById(orderId);
    if (o == null) return;
    o.paid = paid;
    _commit();
  }

  // Restores stock and refunds reward points when an order is cancelled.
  void _releaseOrder(CafeOrder o) {
    for (final l in o.lines) {
      final p = productById(l.productId);
      if (p != null && p.stock != null) p.stock = p.stock! + l.quantity;
    }
    if (o.rewardPointsUsed > 0) {
      loyalty.add(
        LoyaltyEntry(
          id: newId('l'),
          userId: o.userId,
          points: o.rewardPointsUsed,
          reason: 'Refund for cancelled order ${o.orderNo}',
          at: DateTime.now(),
        ),
      );
    }
  }

  // Points are only earned by completed, paid orders.
  void _awardPoints(CafeOrder o) {
    if (o.pointsAwarded || !o.paid || settings.pesosPerPoint <= 0) return;
    final eligible = o.subtotal - o.discount - o.rewardDiscount;
    final pts = (eligible / settings.pesosPerPoint).floor();
    o.pointsAwarded = true;
    if (pts > 0) {
      loyalty.add(
        LoyaltyEntry(
          id: newId('l'),
          userId: o.userId,
          points: pts,
          reason: 'Order ${o.orderNo}',
          at: DateTime.now(),
        ),
      );
    }
  }

  // -------------------------------------------------------------------------
  // Reviews
  // -------------------------------------------------------------------------

  Review? reviewForOrder(String orderId) {
    for (final r in reviews) {
      if (r.orderId == orderId) return r;
    }
    return null;
  }

  String? submitReview(CafeOrder order, int rating, String text) {
    if (order.status != OrderStatus.completed) {
      return 'You can review an order after it is completed.';
    }
    if (reviewForOrder(order.id) != null) return 'You already reviewed this order.';
    if (rating < 1 || rating > 5) return 'Please choose a star rating.';
    reviews.insert(
      0,
      Review(
        id: newId('rv'),
        orderId: order.id,
        orderNo: order.orderNo,
        userId: order.userId,
        userName: order.customerName,
        rating: rating,
        text: text.trim(),
        createdAt: DateTime.now(),
      ),
    );
    _commit();
    return null;
  }

  List<Review> get approvedReviews =>
      reviews.where((r) => r.state == ReviewState.approved).toList();

  void setReviewState(String id, ReviewState state) {
    for (final r in reviews) {
      if (r.id == id) r.state = state;
    }
    _commit();
  }

  void deleteReview(String id) {
    reviews.removeWhere((r) => r.id == id);
    _commit();
  }

  // -------------------------------------------------------------------------
  // Admin: menu, options, promos, announcements, rewards, stock
  // -------------------------------------------------------------------------

  void saveProduct(Product p) {
    final i = products.indexWhere((e) => e.id == p.id);
    if (i >= 0) {
      products[i] = p;
    } else {
      products.add(p);
    }
    _commit();
  }

  void deleteProduct(String id) {
    products.removeWhere((p) => p.id == id);
    for (final u in users) {
      u.favorites.remove(id);
    }
    for (final list in carts.values) {
      list.removeWhere((c) => c.productId == id);
    }
    _commit();
  }

  void saveAddOn(AddOn a) {
    final i = addOns.indexWhere((e) => e.id == a.id);
    if (i >= 0) {
      addOns[i] = a;
    } else {
      addOns.add(a);
    }
    _commit();
  }

  void deleteAddOn(String id) {
    addOns.removeWhere((a) => a.id == id);
    for (final p in products) {
      p.optionIds.remove(id);
    }
    for (final list in carts.values) {
      for (final c in list) {
        c.optionIds.remove(id);
      }
    }
    _commit();
  }

  void setSweetnessLevels(List<int> levels) {
    final cleaned = levels.where((l) => l >= 0 && l <= 100).toSet().toList()
      ..sort();
    if (cleaned.isEmpty) return;
    sweetnessLevels = cleaned;
    _commit();
  }

  void savePromo(Promo p) {
    final i = promos.indexWhere((e) => e.id == p.id);
    if (i >= 0) {
      promos[i] = p;
    } else {
      promos.add(p);
    }
    _commit();
  }

  void deletePromo(String id) {
    promos.removeWhere((p) => p.id == id);
    _commit();
  }

  void saveAnnouncement(Announcement a) {
    final i = announcements.indexWhere((e) => e.id == a.id);
    if (i >= 0) {
      announcements[i] = a;
    } else {
      announcements.insert(0, a);
    }
    _commit();
  }

  void deleteAnnouncement(String id) {
    announcements.removeWhere((a) => a.id == id);
    _commit();
  }

  void saveReward(Reward r) {
    final i = rewards.indexWhere((e) => e.id == r.id);
    if (i >= 0) {
      rewards[i] = r;
    } else {
      rewards.add(r);
    }
    _commit();
  }

  void deleteReward(String id) {
    rewards.removeWhere((r) => r.id == id);
    _commit();
  }

  void saveStockItem(StockItem s) {
    final i = ingredients.indexWhere((e) => e.id == s.id);
    if (i >= 0) {
      ingredients[i] = s;
    } else {
      ingredients.add(s);
    }
    _commit();
  }

  void deleteStockItem(String id) {
    ingredients.removeWhere((s) => s.id == id);
    _commit();
  }

  // -------------------------------------------------------------------------
  // Admin: customers
  // -------------------------------------------------------------------------

  List<AppUser> get customers => users.where((u) => !u.isAdmin).toList();

  int orderCountFor(String userId) =>
      orders.where((o) => o.userId == userId).length;

  double completedSpendingFor(String userId) => orders
      .where((o) => o.userId == userId && o.status == OrderStatus.completed)
      .fold(0.0, (a, o) => a + o.total);
}

/// App-wide store, in the same spirit as the original global theme notifier.
final AppStore store = AppStore();
