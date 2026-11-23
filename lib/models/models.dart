import '../config/brand.dart';

// ---------------------------------------------------------------------------
// Menu structure
// ---------------------------------------------------------------------------

class MenuCategory {
  final String id;
  final String label;
  const MenuCategory(this.id, this.label);
}

class Categories {
  // Signature Mocha is intentionally first: it is the café's identity.
  static const List<MenuCategory> all = [
    MenuCategory('signature', 'Signature Mocha'),
    MenuCategory('iced', 'Iced Mocha'),
    MenuCategory('hot_coffee', 'Hot Coffee'),
    MenuCategory('matcha', 'Matcha'),
    MenuCategory('non_coffee', 'Non-Coffee Drinks'),
    MenuCategory('desserts', 'Café Desserts'),
    MenuCategory('bundles', 'Bundles & Combos'),
  ];

  static String label(String id) {
    for (final c in all) {
      if (c.id == id) return c.label;
    }
    return id;
  }
}

/// Product kinds drive reports (mocha / matcha / dessert sales) and which
/// customization sections make sense.
class Kinds {
  static const mocha = 'mocha';
  static const matcha = 'matcha';
  static const coffee = 'coffee';
  static const other = 'other'; // non-coffee drinks
  static const dessert = 'dessert';
  static const bundle = 'bundle';
  static const all = [mocha, matcha, coffee, other, dessert, bundle];
}

class SizeOption {
  String label;
  double extra; // added on top of the product's base price
  SizeOption(this.label, this.extra);

  Map<String, dynamic> toJson() => {'label': label, 'extra': extra};
  factory SizeOption.fromJson(Map<String, dynamic> j) =>
      SizeOption(j['label'] as String, (j['extra'] as num).toDouble());
}

class AddOnGroups {
  static const milk = 'milk';
  static const shot = 'shot';
  static const topping = 'topping';
  static const matchaIntensity = 'matcha_intensity';
  static const matchaExtra = 'matcha_extra';

  // Display order on the product page.
  static const all = [milk, shot, matchaIntensity, topping, matchaExtra];

  static String label(String g) {
    switch (g) {
      case milk:
        return 'Milk';
      case shot:
        return 'Espresso';
      case topping:
        return 'Toppings';
      case matchaIntensity:
        return 'Matcha intensity';
      case matchaExtra:
        return 'Matcha extras';
    }
    return g;
  }

  // Single-choice groups behave like radio buttons, the rest are multi-select.
  static bool isSingle(String g) =>
      g == milk || g == shot || g == matchaIntensity;
}

/// One selectable customization (a milk, a topping, an extra shot...).
class AddOn {
  String id;
  String group;
  String name;
  double price;
  bool active;
  AddOn({
    required this.id,
    required this.group,
    required this.name,
    this.price = 0,
    this.active = true,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'group': group,
    'name': name,
    'price': price,
    'active': active,
  };
  factory AddOn.fromJson(Map<String, dynamic> j) => AddOn(
    id: j['id'] as String,
    group: j['group'] as String,
    name: j['name'] as String,
    price: (j['price'] as num).toDouble(),
    active: j['active'] as bool,
  );
}

class Product {
  String id;
  String name;
  String description;
  String category;
  String kind;
  double basePrice;
  List<SizeOption> sizes;
  bool hot;
  bool iced;
  List<String> ingredients;
  List<String> optionIds; // which add-ons this product offers
  List<String> bundleItems; // plain-text contents for bundles
  bool bestSeller;
  bool isNew;
  bool signature;
  bool available;
  int? stock; // null = stock is not tracked for this item
  int lowStock;
  String imageUrl; // optional http(s) URL or asset path
  String artKey; // drives the built-in illustration fallback
  DateTime createdAt;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.kind,
    required this.basePrice,
    List<SizeOption>? sizes,
    this.hot = true,
    this.iced = true,
    List<String>? ingredients,
    List<String>? optionIds,
    List<String>? bundleItems,
    this.bestSeller = false,
    this.isNew = false,
    this.signature = false,
    this.available = true,
    this.stock,
    this.lowStock = 5,
    this.imageUrl = '',
    this.artKey = 'mocha_hot',
    DateTime? createdAt,
  }) : sizes = sizes ?? [SizeOption('Regular', 0)],
       ingredients = ingredients ?? [],
       optionIds = optionIds ?? [],
       bundleItems = bundleItems ?? [],
       createdAt = createdAt ?? DateTime.now();

  bool get isDrink => kind != Kinds.dessert && kind != Kinds.bundle;
  bool get isMocha => kind == Kinds.mocha;
  bool get isMatcha => kind == Kinds.matcha;
  bool get lowOnStock => stock != null && stock! <= lowStock;

  /// Price of the smallest size, used for "from" labels and price filters.
  double get startingPrice => basePrice + extraFor(sizes.first.label);

  double extraFor(String size) {
    for (final s in sizes) {
      if (s.label == size) return s.extra;
    }
    return 0;
  }

  Product copy() => Product.fromJson(toJson());

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'category': category,
    'kind': kind,
    'basePrice': basePrice,
    'sizes': sizes.map((s) => s.toJson()).toList(),
    'hot': hot,
    'iced': iced,
    'ingredients': ingredients,
    'optionIds': optionIds,
    'bundleItems': bundleItems,
    'bestSeller': bestSeller,
    'isNew': isNew,
    'signature': signature,
    'available': available,
    'stock': stock,
    'lowStock': lowStock,
    'imageUrl': imageUrl,
    'artKey': artKey,
    'createdAt': createdAt.toIso8601String(),
  };

  factory Product.fromJson(Map<String, dynamic> j) => Product(
    id: j['id'] as String,
    name: j['name'] as String,
    description: j['description'] as String,
    category: j['category'] as String,
    kind: j['kind'] as String,
    basePrice: (j['basePrice'] as num).toDouble(),
    sizes: (j['sizes'] as List)
        .map((e) => SizeOption.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList(),
    hot: j['hot'] as bool,
    iced: j['iced'] as bool,
    ingredients: List<String>.from(j['ingredients'] as List),
    optionIds: List<String>.from(j['optionIds'] as List),
    bundleItems: List<String>.from(j['bundleItems'] as List),
    bestSeller: j['bestSeller'] as bool,
    isNew: j['isNew'] as bool,
    signature: j['signature'] as bool,
    available: j['available'] as bool,
    stock: j['stock'] as int?,
    lowStock: j['lowStock'] as int,
    imageUrl: j['imageUrl'] as String,
    artKey: j['artKey'] as String,
    createdAt: DateTime.parse(j['createdAt'] as String),
  );
}

// ---------------------------------------------------------------------------
// Cart
// ---------------------------------------------------------------------------

class CartItem {
  String id;
  String productId;
  String size;
  String temp; // 'Hot', 'Iced' or '' for food
  int sweetness; // percent, -1 when not applicable
  List<String> optionIds;
  int quantity;
  String note;

  CartItem({
    required this.id,
    required this.productId,
    required this.size,
    this.temp = '',
    this.sweetness = -1,
    List<String>? optionIds,
    this.quantity = 1,
    this.note = '',
  }) : optionIds = optionIds ?? [];

  /// Two items are "the same drink" when every choice matches.
  String get signatureKey {
    final sorted = [...optionIds]..sort();
    return '$productId|$size|$temp|$sweetness|${sorted.join(',')}|${note.trim()}';
  }

  CartItem copy() => CartItem.fromJson(toJson());

  Map<String, dynamic> toJson() => {
    'id': id,
    'productId': productId,
    'size': size,
    'temp': temp,
    'sweetness': sweetness,
    'optionIds': optionIds,
    'quantity': quantity,
    'note': note,
  };
  factory CartItem.fromJson(Map<String, dynamic> j) => CartItem(
    id: j['id'] as String,
    productId: j['productId'] as String,
    size: j['size'] as String,
    temp: j['temp'] as String,
    sweetness: j['sweetness'] as int,
    optionIds: List<String>.from(j['optionIds'] as List),
    quantity: j['quantity'] as int,
    note: j['note'] as String,
  );
}

// ---------------------------------------------------------------------------
// Orders
// ---------------------------------------------------------------------------

enum Fulfillment { dineIn, pickup, delivery }

extension FulfillmentX on Fulfillment {
  String get label {
    switch (this) {
      case Fulfillment.dineIn:
        return 'Dine-in';
      case Fulfillment.pickup:
        return 'Takeout / Pickup';
      case Fulfillment.delivery:
        return 'Local Delivery';
    }
  }
}

enum OrderStatus {
  received,
  confirmed,
  preparing,
  ready,
  outForDelivery,
  completed,
  cancelled,
}

extension OrderStatusX on OrderStatus {
  String labelFor(Fulfillment f) {
    switch (this) {
      case OrderStatus.received:
        return 'Order Received';
      case OrderStatus.confirmed:
        return 'Confirmed';
      case OrderStatus.preparing:
        return 'Preparing';
      case OrderStatus.ready:
        return f == Fulfillment.dineIn
            ? 'Ready to Serve'
            : 'Ready for Pickup';
      case OrderStatus.outForDelivery:
        return 'Out for Delivery';
      case OrderStatus.completed:
        return f == Fulfillment.delivery ? 'Delivered' : 'Completed';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }
}

class OrderLine {
  String productId;
  String name;
  String kind;
  String category;
  String size;
  String temp;
  int sweetness;
  List<String> optionIds;
  String note;
  String summary; // human-readable customizations at the time of ordering
  int quantity;
  double unitPrice;

  OrderLine({
    required this.productId,
    required this.name,
    required this.kind,
    required this.category,
    required this.size,
    required this.temp,
    required this.sweetness,
    required this.optionIds,
    required this.note,
    required this.summary,
    required this.quantity,
    required this.unitPrice,
  });

  double get total => unitPrice * quantity;

  Map<String, dynamic> toJson() => {
    'productId': productId,
    'name': name,
    'kind': kind,
    'category': category,
    'size': size,
    'temp': temp,
    'sweetness': sweetness,
    'optionIds': optionIds,
    'note': note,
    'summary': summary,
    'quantity': quantity,
    'unitPrice': unitPrice,
  };
  factory OrderLine.fromJson(Map<String, dynamic> j) => OrderLine(
    productId: j['productId'] as String,
    name: j['name'] as String,
    kind: j['kind'] as String,
    category: j['category'] as String,
    size: j['size'] as String,
    temp: j['temp'] as String,
    sweetness: j['sweetness'] as int,
    optionIds: List<String>.from(j['optionIds'] as List),
    note: j['note'] as String,
    summary: j['summary'] as String,
    quantity: j['quantity'] as int,
    unitPrice: (j['unitPrice'] as num).toDouble(),
  );
}

class StatusEvent {
  final OrderStatus status;
  final DateTime at;
  StatusEvent(this.status, this.at);
  Map<String, dynamic> toJson() => {'status': status.name, 'at': at.toIso8601String()};
  factory StatusEvent.fromJson(Map<String, dynamic> j) => StatusEvent(
    OrderStatus.values.byName(j['status'] as String),
    DateTime.parse(j['at'] as String),
  );
}

class PaymentMethods {
  static const cash = 'Cash';
  static const gcash = 'GCash';
  static const bank = 'Bank Transfer';
  static const all = [cash, gcash, bank];
}

class CafeOrder {
  String id;
  String orderNo;
  String userId;
  String customerName;
  String email;
  String phone;
  List<OrderLine> lines;
  Fulfillment fulfillment;
  String tableNo;
  String pickupTime; // 'ASAP' or a clock label
  String street;
  String barangay;
  String city;
  String province;
  String deliveryNotes;
  String paymentMethod;
  bool paid;
  String promoCode;
  double subtotal;
  double discount;
  double rewardDiscount;
  int rewardPointsUsed;
  double serviceFee;
  double deliveryFee;
  double total;
  int prepMinutes;
  OrderStatus status;
  List<StatusEvent> history;
  DateTime createdAt;
  bool pointsAwarded;
  String note;

  CafeOrder({
    required this.id,
    required this.orderNo,
    required this.userId,
    required this.customerName,
    required this.email,
    required this.phone,
    required this.lines,
    required this.fulfillment,
    this.tableNo = '',
    this.pickupTime = 'ASAP',
    this.street = '',
    this.barangay = '',
    this.city = '',
    this.province = '',
    this.deliveryNotes = '',
    required this.paymentMethod,
    this.paid = false,
    this.promoCode = '',
    required this.subtotal,
    this.discount = 0,
    this.rewardDiscount = 0,
    this.rewardPointsUsed = 0,
    this.serviceFee = 0,
    this.deliveryFee = 0,
    required this.total,
    this.prepMinutes = 0,
    this.status = OrderStatus.received,
    List<StatusEvent>? history,
    required this.createdAt,
    this.pointsAwarded = false,
    this.note = '',
  }) : history = history ?? [];

  int get itemCount => lines.fold(0, (a, l) => a + l.quantity);
  bool get isActive =>
      status != OrderStatus.completed && status != OrderStatus.cancelled;
  String get statusLabel => status.labelFor(fulfillment);

  /// The ordered steps shown in the customer's progress tracker.
  List<OrderStatus> get flow => fulfillment == Fulfillment.delivery
      ? const [
          OrderStatus.received,
          OrderStatus.confirmed,
          OrderStatus.preparing,
          OrderStatus.outForDelivery,
          OrderStatus.completed,
        ]
      : const [
          OrderStatus.received,
          OrderStatus.confirmed,
          OrderStatus.preparing,
          OrderStatus.ready,
          OrderStatus.completed,
        ];

  /// The next status staff can move this order to, or null when finished.
  OrderStatus? get nextStatus {
    if (!isActive) return null;
    final i = flow.indexOf(status);
    if (i < 0 || i >= flow.length - 1) return null;
    return flow[i + 1];
  }

  String get addressLine => [
    street,
    barangay,
    city,
    province,
  ].where((s) => s.trim().isNotEmpty).join(', ');

  Map<String, dynamic> toJson() => {
    'id': id,
    'orderNo': orderNo,
    'userId': userId,
    'customerName': customerName,
    'email': email,
    'phone': phone,
    'lines': lines.map((l) => l.toJson()).toList(),
    'fulfillment': fulfillment.name,
    'tableNo': tableNo,
    'pickupTime': pickupTime,
    'street': street,
    'barangay': barangay,
    'city': city,
    'province': province,
    'deliveryNotes': deliveryNotes,
    'paymentMethod': paymentMethod,
    'paid': paid,
    'promoCode': promoCode,
    'subtotal': subtotal,
    'discount': discount,
    'rewardDiscount': rewardDiscount,
    'rewardPointsUsed': rewardPointsUsed,
    'serviceFee': serviceFee,
    'deliveryFee': deliveryFee,
    'total': total,
    'prepMinutes': prepMinutes,
    'status': status.name,
    'history': history.map((h) => h.toJson()).toList(),
    'createdAt': createdAt.toIso8601String(),
    'pointsAwarded': pointsAwarded,
    'note': note,
  };

  factory CafeOrder.fromJson(Map<String, dynamic> j) => CafeOrder(
    id: j['id'] as String,
    orderNo: j['orderNo'] as String,
    userId: j['userId'] as String,
    customerName: j['customerName'] as String,
    email: j['email'] as String,
    phone: j['phone'] as String,
    lines: (j['lines'] as List)
        .map((e) => OrderLine.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList(),
    fulfillment: Fulfillment.values.byName(j['fulfillment'] as String),
    tableNo: j['tableNo'] as String,
    pickupTime: j['pickupTime'] as String,
    street: j['street'] as String,
    barangay: j['barangay'] as String,
    city: j['city'] as String,
    province: j['province'] as String,
    deliveryNotes: j['deliveryNotes'] as String,
    paymentMethod: j['paymentMethod'] as String,
    paid: j['paid'] as bool,
    promoCode: j['promoCode'] as String,
    subtotal: (j['subtotal'] as num).toDouble(),
    discount: (j['discount'] as num).toDouble(),
    rewardDiscount: (j['rewardDiscount'] as num).toDouble(),
    rewardPointsUsed: j['rewardPointsUsed'] as int,
    serviceFee: (j['serviceFee'] as num).toDouble(),
    deliveryFee: (j['deliveryFee'] as num).toDouble(),
    total: (j['total'] as num).toDouble(),
    prepMinutes: j['prepMinutes'] as int,
    status: OrderStatus.values.byName(j['status'] as String),
    history: (j['history'] as List)
        .map((e) => StatusEvent.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList(),
    createdAt: DateTime.parse(j['createdAt'] as String),
    pointsAwarded: j['pointsAwarded'] as bool,
    note: j['note'] as String,
  );
}

// ---------------------------------------------------------------------------
// People
// ---------------------------------------------------------------------------

class SavedAddress {
  String label;
  String street;
  String barangay;
  String city;
  String province;
  SavedAddress({
    required this.label,
    required this.street,
    required this.barangay,
    required this.city,
    required this.province,
  });

  String get line => [street, barangay, city, province]
      .where((s) => s.trim().isNotEmpty)
      .join(', ');

  Map<String, dynamic> toJson() => {
    'label': label,
    'street': street,
    'barangay': barangay,
    'city': city,
    'province': province,
  };
  factory SavedAddress.fromJson(Map<String, dynamic> j) => SavedAddress(
    label: j['label'] as String,
    street: j['street'] as String,
    barangay: j['barangay'] as String,
    city: j['city'] as String,
    province: j['province'] as String,
  );
}

class AppUser {
  String id;
  String name;
  String email;
  String phone;
  String password; // demo-only local storage, see README
  bool isAdmin;
  DateTime createdAt;
  List<String> favorites;
  List<SavedAddress> addresses;
  bool notifyOrders;
  bool notifyPromos;

  AppUser({
    required this.id,
    required this.name,
    required this.email,
    this.phone = '',
    required this.password,
    this.isAdmin = false,
    DateTime? createdAt,
    List<String>? favorites,
    List<SavedAddress>? addresses,
    this.notifyOrders = true,
    this.notifyPromos = true,
  }) : createdAt = createdAt ?? DateTime.now(),
       favorites = favorites ?? [],
       addresses = addresses ?? [];

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'phone': phone,
    'password': password,
    'isAdmin': isAdmin,
    'createdAt': createdAt.toIso8601String(),
    'favorites': favorites,
    'addresses': addresses.map((a) => a.toJson()).toList(),
    'notifyOrders': notifyOrders,
    'notifyPromos': notifyPromos,
  };
  factory AppUser.fromJson(Map<String, dynamic> j) => AppUser(
    id: j['id'] as String,
    name: j['name'] as String,
    email: j['email'] as String,
    phone: j['phone'] as String,
    password: j['password'] as String,
    isAdmin: j['isAdmin'] as bool,
    createdAt: DateTime.parse(j['createdAt'] as String),
    favorites: List<String>.from(j['favorites'] as List),
    addresses: (j['addresses'] as List)
        .map((e) => SavedAddress.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList(),
    notifyOrders: j['notifyOrders'] as bool,
    notifyPromos: j['notifyPromos'] as bool,
  );
}

// ---------------------------------------------------------------------------
// Promotions, announcements, reviews, loyalty, inventory, settings
// ---------------------------------------------------------------------------

class Promo {
  String id;
  String code;
  String title;
  bool percent; // true = percentage, false = fixed peso amount
  double value;
  double minPurchase;
  String scope; // 'all', 'mocha', 'matcha', 'dessert'
  DateTime? expiresAt;
  bool active;

  Promo({
    required this.id,
    required this.code,
    required this.title,
    required this.percent,
    required this.value,
    this.minPurchase = 0,
    this.scope = 'all',
    this.expiresAt,
    this.active = true,
  });

  bool get expired => expiresAt != null && DateTime.now().isAfter(expiresAt!);
  bool get usable => active && !expired;

  String get valueLabel => percent
      ? '${value.toStringAsFixed(value == value.roundToDouble() ? 0 : 1)}% off'
      : '${Brand.currency}${value.toStringAsFixed(value == value.roundToDouble() ? 0 : 2)} off';

  Map<String, dynamic> toJson() => {
    'id': id,
    'code': code,
    'title': title,
    'percent': percent,
    'value': value,
    'minPurchase': minPurchase,
    'scope': scope,
    'expiresAt': expiresAt?.toIso8601String(),
    'active': active,
  };
  factory Promo.fromJson(Map<String, dynamic> j) => Promo(
    id: j['id'] as String,
    code: j['code'] as String,
    title: j['title'] as String,
    percent: j['percent'] as bool,
    value: (j['value'] as num).toDouble(),
    minPurchase: (j['minPurchase'] as num).toDouble(),
    scope: j['scope'] as String,
    expiresAt: j['expiresAt'] == null
        ? null
        : DateTime.parse(j['expiresAt'] as String),
    active: j['active'] as bool,
  );
}

class Announcement {
  String id;
  String title;
  String body;
  bool active;
  DateTime createdAt;
  Announcement({
    required this.id,
    required this.title,
    required this.body,
    this.active = true,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'body': body,
    'active': active,
    'createdAt': createdAt.toIso8601String(),
  };
  factory Announcement.fromJson(Map<String, dynamic> j) => Announcement(
    id: j['id'] as String,
    title: j['title'] as String,
    body: j['body'] as String,
    active: j['active'] as bool,
    createdAt: DateTime.parse(j['createdAt'] as String),
  );
}

enum ReviewState { pending, approved, hidden }

class Review {
  String id;
  String orderId;
  String orderNo;
  String userId;
  String userName;
  int rating;
  String text;
  ReviewState state;
  DateTime createdAt;
  Review({
    required this.id,
    required this.orderId,
    required this.orderNo,
    required this.userId,
    required this.userName,
    required this.rating,
    required this.text,
    this.state = ReviewState.pending,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'orderId': orderId,
    'orderNo': orderNo,
    'userId': userId,
    'userName': userName,
    'rating': rating,
    'text': text,
    'state': state.name,
    'createdAt': createdAt.toIso8601String(),
  };
  factory Review.fromJson(Map<String, dynamic> j) => Review(
    id: j['id'] as String,
    orderId: j['orderId'] as String,
    orderNo: j['orderNo'] as String,
    userId: j['userId'] as String,
    userName: j['userName'] as String,
    rating: j['rating'] as int,
    text: j['text'] as String,
    state: ReviewState.values.byName(j['state'] as String),
    createdAt: DateTime.parse(j['createdAt'] as String),
  );
}

/// A reward customers can redeem at checkout for a peso discount.
class Reward {
  String id;
  String name;
  int pointsCost;
  double value;
  bool active;
  Reward({
    required this.id,
    required this.name,
    required this.pointsCost,
    required this.value,
    this.active = true,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'pointsCost': pointsCost,
    'value': value,
    'active': active,
  };
  factory Reward.fromJson(Map<String, dynamic> j) => Reward(
    id: j['id'] as String,
    name: j['name'] as String,
    pointsCost: j['pointsCost'] as int,
    value: (j['value'] as num).toDouble(),
    active: j['active'] as bool,
  );
}

class LoyaltyEntry {
  String id;
  String userId;
  int points; // positive = earned, negative = redeemed
  String reason;
  DateTime at;
  LoyaltyEntry({
    required this.id,
    required this.userId,
    required this.points,
    required this.reason,
    required this.at,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'points': points,
    'reason': reason,
    'at': at.toIso8601String(),
  };
  factory LoyaltyEntry.fromJson(Map<String, dynamic> j) => LoyaltyEntry(
    id: j['id'] as String,
    userId: j['userId'] as String,
    points: j['points'] as int,
    reason: j['reason'] as String,
    at: DateTime.parse(j['at'] as String),
  );
}

/// Ingredient / supply stock. Updated manually by the owner; nothing is
/// deducted automatically because there are no recipe definitions.
class StockItem {
  String id;
  String name;
  String unit;
  double quantity;
  double threshold;
  StockItem({
    required this.id,
    required this.name,
    required this.unit,
    required this.quantity,
    required this.threshold,
  });

  bool get low => quantity <= threshold;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'unit': unit,
    'quantity': quantity,
    'threshold': threshold,
  };
  factory StockItem.fromJson(Map<String, dynamic> j) => StockItem(
    id: j['id'] as String,
    name: j['name'] as String,
    unit: j['unit'] as String,
    quantity: (j['quantity'] as num).toDouble(),
    threshold: (j['threshold'] as num).toDouble(),
  );
}

class CafeSettings {
  String name;
  String tagline;
  String description;
  String phone;
  String email;
  String address;
  String instagram;
  String facebook;
  String currency;
  int openHour; // 24h clock
  int closeHour;
  bool acceptingOrders;
  bool dineInEnabled;
  bool tableService;
  bool pickupEnabled;
  bool deliveryEnabled;
  double deliveryFee;
  double serviceFeePercent; // applied to dine-in orders
  String cashInstructions;
  String gcashInstructions;
  String bankInstructions;
  bool cashEnabled;
  bool gcashEnabled;
  bool bankEnabled;
  int pesosPerPoint; // spend this much to earn 1 point
  int prepRegular; // minutes
  int prepCustomized;
  int prepSpecialty;
  int prepLargeOrder;
  int largeOrderQty;

  CafeSettings({
    this.name = Brand.name,
    this.tagline = Brand.tagline,
    this.description = Brand.description,
    this.phone = Brand.phone,
    this.email = Brand.email,
    this.address = Brand.address,
    this.instagram = Brand.instagram,
    this.facebook = Brand.facebook,
    this.currency = Brand.currency,
    this.openHour = 8,
    this.closeHour = 21,
    this.acceptingOrders = true,
    this.dineInEnabled = true,
    this.tableService = true,
    this.pickupEnabled = true,
    this.deliveryEnabled = true,
    this.deliveryFee = 49,
    this.serviceFeePercent = 0,
    this.cashInstructions = 'Pay at the counter when you pick up or are served.',
    this.gcashInstructions =
        'Send the total to GCash 0917 000 0000 (Mocha & Moss) and show the receipt to our staff. Sample details, replace them in Settings.',
    this.bankInstructions =
        'Transfer to Sample Bank, Account 0000-0000-00, Mocha & Moss. Keep your receipt. Sample details, replace them in Settings.',
    this.cashEnabled = true,
    this.gcashEnabled = true,
    this.bankEnabled = true,
    this.pesosPerPoint = 10,
    this.prepRegular = 5,
    this.prepCustomized = 8,
    this.prepSpecialty = 10,
    this.prepLargeOrder = 20,
    this.largeOrderQty = 5,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'tagline': tagline,
    'description': description,
    'phone': phone,
    'email': email,
    'address': address,
    'instagram': instagram,
    'facebook': facebook,
    'currency': currency,
    'openHour': openHour,
    'closeHour': closeHour,
    'acceptingOrders': acceptingOrders,
    'dineInEnabled': dineInEnabled,
    'tableService': tableService,
    'pickupEnabled': pickupEnabled,
    'deliveryEnabled': deliveryEnabled,
    'deliveryFee': deliveryFee,
    'serviceFeePercent': serviceFeePercent,
    'cashInstructions': cashInstructions,
    'gcashInstructions': gcashInstructions,
    'bankInstructions': bankInstructions,
    'cashEnabled': cashEnabled,
    'gcashEnabled': gcashEnabled,
    'bankEnabled': bankEnabled,
    'pesosPerPoint': pesosPerPoint,
    'prepRegular': prepRegular,
    'prepCustomized': prepCustomized,
    'prepSpecialty': prepSpecialty,
    'prepLargeOrder': prepLargeOrder,
    'largeOrderQty': largeOrderQty,
  };

  factory CafeSettings.fromJson(Map<String, dynamic> j) {
    final d = CafeSettings();
    return CafeSettings(
      name: j['name'] as String? ?? d.name,
      tagline: j['tagline'] as String? ?? d.tagline,
      description: j['description'] as String? ?? d.description,
      phone: j['phone'] as String? ?? d.phone,
      email: j['email'] as String? ?? d.email,
      address: j['address'] as String? ?? d.address,
      instagram: j['instagram'] as String? ?? d.instagram,
      facebook: j['facebook'] as String? ?? d.facebook,
      currency: j['currency'] as String? ?? d.currency,
      openHour: j['openHour'] as int? ?? d.openHour,
      closeHour: j['closeHour'] as int? ?? d.closeHour,
      acceptingOrders: j['acceptingOrders'] as bool? ?? d.acceptingOrders,
      dineInEnabled: j['dineInEnabled'] as bool? ?? d.dineInEnabled,
      tableService: j['tableService'] as bool? ?? d.tableService,
      pickupEnabled: j['pickupEnabled'] as bool? ?? d.pickupEnabled,
      deliveryEnabled: j['deliveryEnabled'] as bool? ?? d.deliveryEnabled,
      deliveryFee: (j['deliveryFee'] as num?)?.toDouble() ?? d.deliveryFee,
      serviceFeePercent:
          (j['serviceFeePercent'] as num?)?.toDouble() ?? d.serviceFeePercent,
      cashInstructions: j['cashInstructions'] as String? ?? d.cashInstructions,
      gcashInstructions:
          j['gcashInstructions'] as String? ?? d.gcashInstructions,
      bankInstructions: j['bankInstructions'] as String? ?? d.bankInstructions,
      cashEnabled: j['cashEnabled'] as bool? ?? d.cashEnabled,
      gcashEnabled: j['gcashEnabled'] as bool? ?? d.gcashEnabled,
      bankEnabled: j['bankEnabled'] as bool? ?? d.bankEnabled,
      pesosPerPoint: j['pesosPerPoint'] as int? ?? d.pesosPerPoint,
      prepRegular: j['prepRegular'] as int? ?? d.prepRegular,
      prepCustomized: j['prepCustomized'] as int? ?? d.prepCustomized,
      prepSpecialty: j['prepSpecialty'] as int? ?? d.prepSpecialty,
      prepLargeOrder: j['prepLargeOrder'] as int? ?? d.prepLargeOrder,
      largeOrderQty: j['largeOrderQty'] as int? ?? d.largeOrderQty,
    );
  }
}
