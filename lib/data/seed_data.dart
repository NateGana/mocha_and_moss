import 'dart:math';

import '../models/models.dart';
import 'pricing.dart';

// These sample drinks, accounts and orders are used when the app runs in demo
// mode. Everything here can be edited from the admin screens afterwards.

const _milkIds = [
  'milk_whole',
  'milk_fresh',
  'milk_oat',
  'milk_almond',
  'milk_soy',
];
const _shotIds = ['shot_regular', 'shot_extra', 'shot_double'];
const _toppingIds = [
  'top_whip',
  'top_choc_drizzle',
  'top_mocha_drizzle',
  'top_chips',
  'top_cocoa',
  'top_vanilla',
];
const _matchaIntensityIds = ['mat_light', 'mat_regular', 'mat_strong'];
const _matchaExtraIds = ['mat_strawberry', 'mat_cream'];

List<AddOn> seedAddOns() => [
  AddOn(id: 'milk_whole', group: AddOnGroups.milk, name: 'Whole Milk'),
  AddOn(id: 'milk_fresh', group: AddOnGroups.milk, name: 'Fresh Milk'),
  AddOn(id: 'milk_oat', group: AddOnGroups.milk, name: 'Oat Milk', price: 20),
  AddOn(
    id: 'milk_almond',
    group: AddOnGroups.milk,
    name: 'Almond Milk',
    price: 25,
  ),
  AddOn(id: 'milk_soy', group: AddOnGroups.milk, name: 'Soy Milk', price: 20),
  AddOn(id: 'shot_regular', group: AddOnGroups.shot, name: 'Regular Espresso'),
  AddOn(
    id: 'shot_extra',
    group: AddOnGroups.shot,
    name: 'Extra Shot',
    price: 30,
  ),
  AddOn(
    id: 'shot_double',
    group: AddOnGroups.shot,
    name: 'Double Shot',
    price: 50,
  ),
  AddOn(
    id: 'top_whip',
    group: AddOnGroups.topping,
    name: 'Whipped Cream',
    price: 20,
  ),
  AddOn(
    id: 'top_choc_drizzle',
    group: AddOnGroups.topping,
    name: 'Chocolate Drizzle',
    price: 15,
  ),
  AddOn(
    id: 'top_mocha_drizzle',
    group: AddOnGroups.topping,
    name: 'Mocha Drizzle',
    price: 15,
  ),
  AddOn(
    id: 'top_chips',
    group: AddOnGroups.topping,
    name: 'Chocolate Chips',
    price: 20,
  ),
  AddOn(
    id: 'top_cocoa',
    group: AddOnGroups.topping,
    name: 'Cocoa Powder',
    price: 10,
  ),
  AddOn(
    id: 'top_vanilla',
    group: AddOnGroups.topping,
    name: 'Vanilla Cream',
    price: 20,
  ),
  AddOn(id: 'mat_light', group: AddOnGroups.matchaIntensity, name: 'Light'),
  AddOn(id: 'mat_regular', group: AddOnGroups.matchaIntensity, name: 'Regular'),
  AddOn(
    id: 'mat_strong',
    group: AddOnGroups.matchaIntensity,
    name: 'Strong',
    price: 25,
  ),
  AddOn(
    id: 'mat_strawberry',
    group: AddOnGroups.matchaExtra,
    name: 'Strawberry Flavor',
    price: 25,
  ),
  AddOn(
    id: 'mat_cream',
    group: AddOnGroups.matchaExtra,
    name: 'Cream Topping',
    price: 20,
  ),
];

List<SizeOption> _drinkSizes() => [
  SizeOption('Small', 0),
  SizeOption('Medium', 20),
  SizeOption('Large', 40),
];

List<Product> seedProducts() {
  final now = DateTime.now();
  final old = now.subtract(const Duration(days: 90));

  Product mocha(
    String id,
    String name,
    double price,
    String desc,
    List<String> ingredients, {
    String category = 'signature',
    bool hot = true,
    bool iced = true,
    String art = 'mocha_hot',
    bool best = false,
    bool isNew = false,
    bool withShots = true,
  }) => Product(
    id: id,
    name: name,
    description: desc,
    category: category,
    kind: Kinds.mocha,
    basePrice: price,
    sizes: _drinkSizes(),
    hot: hot,
    iced: iced,
    ingredients: ingredients,
    optionIds: [..._milkIds, if (withShots) ..._shotIds, ..._toppingIds],
    bestSeller: best,
    isNew: isNew,
    signature: true,
    artKey: art,
    createdAt: isNew ? now.subtract(const Duration(days: 6)) : old,
  );

  Product matcha(
    String id,
    String name,
    double price,
    String desc,
    List<String> ingredients, {
    bool hot = true,
    String art = 'matcha',
    bool isNew = false,
    bool strawberry = true,
  }) => Product(
    id: id,
    name: name,
    description: desc,
    category: 'matcha',
    kind: Kinds.matcha,
    basePrice: price,
    sizes: _drinkSizes(),
    hot: hot,
    iced: true,
    ingredients: ingredients,
    optionIds: [
      ..._milkIds,
      ..._matchaIntensityIds,
      if (strawberry) _matchaExtraIds.first,
      _matchaExtraIds.last,
    ],
    isNew: isNew,
    artKey: art,
    createdAt: isNew ? now.subtract(const Duration(days: 9)) : old,
  );

  Product coffee(
    String id,
    String name,
    double price,
    String desc,
    List<String> ingredients, {
    bool milk = true,
    String art = 'coffee',
  }) => Product(
    id: id,
    name: name,
    description: desc,
    category: 'hot_coffee',
    kind: Kinds.coffee,
    basePrice: price,
    sizes: _drinkSizes(),
    ingredients: ingredients,
    optionIds: [
      if (milk) ..._milkIds,
      ..._shotIds,
      if (milk) ...['top_whip', 'top_choc_drizzle', 'top_cocoa'],
    ],
    artKey: art,
    createdAt: old,
  );

  Product treat(
    String id,
    String name,
    double price,
    String desc,
    List<String> ingredients,
    String art,
    int stock, {
    bool best = false,
  }) => Product(
    id: id,
    name: name,
    description: desc,
    category: 'desserts',
    kind: Kinds.dessert,
    basePrice: price,
    sizes: [SizeOption('Regular', 0)],
    hot: false,
    iced: false,
    ingredients: ingredients,
    stock: stock,
    lowStock: 4,
    bestSeller: best,
    artKey: art,
    createdAt: old,
  );

  Product bundle(
    String id,
    String name,
    double price,
    String desc,
    List<String> items,
  ) => Product(
    id: id,
    name: name,
    description: desc,
    category: 'bundles',
    kind: Kinds.bundle,
    basePrice: price,
    sizes: [SizeOption('Regular', 0)],
    hot: false,
    iced: false,
    bundleItems: items,
    artKey: 'bundle',
    createdAt: old,
  );

  return [
    mocha(
      'p01',
      'Classic Signature Mocha',
      145,
      'Our house mocha: double-pulled espresso, dark chocolate sauce and steamed milk, finished with a light cocoa dusting.',
      ['Espresso', 'Chocolate sauce', 'Steamed milk', 'Cocoa powder'],
      best: true,
    ),
    mocha(
      'p02',
      'Iced Signature Mocha',
      155,
      'The classic mocha over ice. Cold, chocolatey and smooth, with a clean espresso finish.',
      ['Espresso', 'Chocolate sauce', 'Fresh milk', 'Ice'],
      category: 'iced',
      hot: false,
      art: 'mocha_iced',
      best: true,
    ),
    mocha(
      'p03',
      'Dark Chocolate Mocha',
      165,
      'Bittersweet dark chocolate melted into rich espresso for a deeper, less sweet mocha.',
      ['Espresso', 'Dark chocolate', 'Steamed milk'],
      art: 'mocha_dark',
    ),
    mocha(
      'p04',
      'White Chocolate Mocha',
      165,
      'Creamy white chocolate with smooth espresso. Sweet, velvety and mellow.',
      ['Espresso', 'White chocolate', 'Steamed milk'],
      art: 'mocha_white',
    ),
    mocha(
      'p05',
      'Spanish Mocha',
      155,
      'Espresso and chocolate sweetened with condensed milk for a silky, indulgent cup.',
      ['Espresso', 'Chocolate sauce', 'Condensed milk', 'Fresh milk'],
      art: 'mocha_spanish',
    ),
    mocha(
      'p06',
      'Salted Caramel Mocha',
      175,
      'Mocha swirled with house salted caramel and topped with a pinch of sea salt.',
      ['Espresso', 'Chocolate sauce', 'Salted caramel', 'Steamed milk'],
      art: 'mocha_caramel',
      isNew: true,
    ),
    mocha(
      'p07',
      'Hazelnut Mocha',
      175,
      'Toasty hazelnut syrup meets chocolate and espresso. Nutty, warm and balanced.',
      ['Espresso', 'Chocolate sauce', 'Hazelnut syrup', 'Steamed milk'],
      art: 'mocha_hazelnut',
    ),
    mocha(
      'p08',
      'Mocha Frappe',
      185,
      'Blended espresso and chocolate with ice, crowned with whipped cream and a chocolate drizzle.',
      ['Espresso', 'Chocolate sauce', 'Milk', 'Ice', 'Whipped cream'],
      category: 'iced',
      hot: false,
      art: 'frappe',
      best: true,
    ),
    mocha(
      'p09',
      'Double Shot Mocha',
      190,
      'Built on two shots of espresso for chocolate lovers who want a stronger coffee kick.',
      ['Double espresso', 'Chocolate sauce', 'Steamed milk'],
      art: 'mocha_dark',
      withShots: false,
    ),
    mocha(
      'p10',
      'Vanilla Cream Mocha',
      175,
      'Mocha topped with a cloud of vanilla cream. Dessert in a cup.',
      ['Espresso', 'Chocolate sauce', 'Vanilla cream', 'Steamed milk'],
      art: 'mocha_vanilla',
      isNew: true,
    ),
    matcha(
      'p11',
      'Classic Matcha Latte',
      155,
      'Ceremonial-style matcha whisked smooth with steamed milk. Earthy and calm.',
      ['Matcha', 'Steamed milk'],
    ),
    matcha(
      'p12',
      'Iced Matcha Latte',
      165,
      'Cold, creamy and refreshing: matcha over ice and milk.',
      ['Matcha', 'Fresh milk', 'Ice'],
      hot: false,
      art: 'matcha_iced',
    ),
    matcha(
      'p13',
      'Strawberry Matcha Latte',
      185,
      'Sweet strawberry puree layered under milk and matcha.',
      ['Matcha', 'Strawberry puree', 'Fresh milk', 'Ice'],
      hot: false,
      art: 'matcha_strawberry',
      isNew: true,
      strawberry: false,
    ),
    matcha(
      'p14',
      'Matcha Frappe',
      185,
      'Blended matcha and milk with ice, topped with whipped cream.',
      ['Matcha', 'Milk', 'Ice', 'Whipped cream'],
      hot: false,
      art: 'matcha_frappe',
    ),
    coffee(
      'p15',
      'Americano',
      110,
      'Espresso lengthened with hot water. Clean, bold and simple.',
      ['Espresso', 'Water'],
      milk: false,
    ),
    coffee(
      'p16',
      'Café Latte',
      135,
      'Espresso with silky steamed milk and a thin layer of foam.',
      ['Espresso', 'Steamed milk'],
      art: 'latte',
    ),
    coffee(
      'p17',
      'Cappuccino',
      135,
      'Equal parts espresso, steamed milk and airy foam.',
      ['Espresso', 'Steamed milk', 'Milk foam'],
      art: 'latte',
    ),
    coffee(
      'p18',
      'Caramel Macchiato',
      155,
      'Vanilla milk marked with espresso and finished with caramel.',
      ['Espresso', 'Vanilla syrup', 'Steamed milk', 'Caramel'],
      art: 'mocha_caramel',
    ),
    Product(
      id: 'p19',
      name: 'Classic Hot Chocolate',
      description:
          'Rich cocoa and steamed milk, no coffee. Comforting and sweet.',
      category: 'non_coffee',
      kind: Kinds.other,
      basePrice: 135,
      sizes: _drinkSizes(),
      ingredients: ['Cocoa', 'Chocolate sauce', 'Steamed milk'],
      optionIds: [..._milkIds, ..._toppingIds],
      artKey: 'chocolate',
      createdAt: old,
    ),
    Product(
      id: 'p20',
      name: 'Chocolate Milk',
      description: 'Cold milk shaken with chocolate sauce over ice.',
      category: 'non_coffee',
      kind: Kinds.other,
      basePrice: 115,
      sizes: _drinkSizes(),
      hot: false,
      ingredients: ['Fresh milk', 'Chocolate sauce', 'Ice'],
      optionIds: [..._milkIds],
      artKey: 'chocolate',
      createdAt: old,
    ),
    treat(
      'p21',
      'Chocolate Brownie',
      75,
      'Fudgy, dense brownie with a crackly top.',
      ['Dark chocolate', 'Butter', 'Eggs', 'Flour'],
      'brownie',
      24,
      best: true,
    ),
    treat(
      'p22',
      'Chocolate Chip Cookie',
      65,
      'Chewy cookie with chocolate chips and a golden edge.',
      ['Butter', 'Chocolate chips', 'Brown sugar', 'Flour'],
      'cookie',
      30,
    ),
    treat(
      'p23',
      'Butter Croissant',
      95,
      'Flaky, buttery layers baked fresh each morning.',
      ['Butter', 'Flour', 'Yeast'],
      'croissant',
      16,
    ),
    treat(
      'p24',
      'Cinnamon Roll',
      110,
      'Soft roll swirled with cinnamon sugar and a light glaze.',
      ['Flour', 'Cinnamon', 'Brown sugar', 'Cream cheese glaze'],
      'roll',
      12,
    ),
    treat(
      'p25',
      'Mocha Cake Slice',
      145,
      'Moist chocolate sponge layered with mocha cream.',
      ['Chocolate sponge', 'Espresso', 'Cream'],
      'cake',
      10,
    ),
    treat(
      'p26',
      'Mini Cheesecake',
      120,
      'Creamy baked cheesecake on a buttery biscuit base.',
      ['Cream cheese', 'Biscuit crumb', 'Butter'],
      'cheesecake',
      12,
    ),
    bundle(
      'b01',
      'Signature Mocha + Brownie',
      205,
      'A small Classic Signature Mocha with a Chocolate Brownie.',
      ['Classic Signature Mocha (Small)', 'Chocolate Brownie'],
    ),
    bundle(
      'b02',
      'Iced Mocha + Chocolate Chip Cookie',
      205,
      'A small Iced Signature Mocha with a Chocolate Chip Cookie.',
      ['Iced Signature Mocha (Small)', 'Chocolate Chip Cookie'],
    ),
    bundle(
      'b03',
      'Mocha + Croissant',
      225,
      'A small Classic Signature Mocha with a Butter Croissant.',
      ['Classic Signature Mocha (Small)', 'Butter Croissant'],
    ),
    bundle(
      'b04',
      'Matcha Latte + Cheesecake',
      255,
      'A small Classic Matcha Latte with a Mini Cheesecake.',
      ['Classic Matcha Latte (Small)', 'Mini Cheesecake'],
    ),
  ];
}

List<StockItem> seedIngredients() => [
  StockItem(id: 'i01', name: 'Espresso Beans', unit: 'kg', quantity: 8, threshold: 2),
  StockItem(id: 'i02', name: 'Chocolate Sauce', unit: 'L', quantity: 6, threshold: 2),
  StockItem(id: 'i03', name: 'Cocoa Powder', unit: 'kg', quantity: 3, threshold: 1),
  StockItem(id: 'i04', name: 'Fresh Milk', unit: 'L', quantity: 20, threshold: 8),
  StockItem(id: 'i05', name: 'Oat Milk', unit: 'L', quantity: 6, threshold: 3),
  StockItem(id: 'i06', name: 'Matcha Powder', unit: 'kg', quantity: 0.4, threshold: 0.5),
  StockItem(id: 'i07', name: 'Sugar', unit: 'kg', quantity: 10, threshold: 3),
  StockItem(id: 'i08', name: 'Whipped Cream', unit: 'cans', quantity: 8, threshold: 3),
  StockItem(id: 'i09', name: 'Syrups', unit: 'bottles', quantity: 10, threshold: 3),
  StockItem(id: 'i10', name: 'Cups', unit: 'pcs', quantity: 400, threshold: 100),
  StockItem(id: 'i11', name: 'Lids', unit: 'pcs', quantity: 400, threshold: 100),
  StockItem(id: 'i12', name: 'Straws', unit: 'pcs', quantity: 300, threshold: 100),
  StockItem(id: 'i13', name: 'Packaging', unit: 'pcs', quantity: 150, threshold: 50),
];

List<Reward> seedRewards() => [
  Reward(id: 'r1', name: '₱20 off your order', pointsCost: 30, value: 20),
  Reward(id: 'r2', name: '₱50 off your order', pointsCost: 70, value: 50),
  Reward(id: 'r3', name: '₱100 off your order', pointsCost: 130, value: 100),
];

List<Promo> seedPromos() {
  final now = DateTime.now();
  return [
    Promo(
      id: 'pr1',
      code: 'WELCOME10',
      title: 'Welcome treat: 10% off your order',
      percent: true,
      value: 10,
      minPurchase: 200,
      expiresAt: now.add(const Duration(days: 90)),
    ),
    Promo(
      id: 'pr2',
      code: 'MOCHA20',
      title: '₱20 off mocha drinks',
      percent: false,
      value: 20,
      minPurchase: 150,
      scope: 'mocha',
      expiresAt: now.add(const Duration(days: 60)),
    ),
    Promo(
      id: 'pr3',
      code: 'MATCHA15',
      title: '15% off matcha drinks',
      percent: true,
      value: 15,
      minPurchase: 150,
      scope: 'matcha',
      expiresAt: now.add(const Duration(days: 30)),
    ),
  ];
}

List<Announcement> seedAnnouncements() => [
  Announcement(
    id: 'a1',
    title: 'New: Salted Caramel Mocha',
    body: 'Our newest mocha is here, swirled with house salted caramel. Try it hot or iced.',
  ),
];

List<AppUser> seedUsers() {
  final now = DateTime.now();
  return [
    AppUser(
      id: 'u_admin',
      name: 'Café Owner',
      email: 'admin@mochaandmoss.com',
      password: 'admin123',
      isAdmin: true,
      createdAt: now.subtract(const Duration(days: 120)),
    ),
    AppUser(
      id: 'u_demo',
      name: 'Alex Rivera',
      email: 'demo@mochaandmoss.com',
      phone: '09171234567',
      password: 'mocha123',
      createdAt: now.subtract(const Duration(days: 40)),
      favorites: ['p01', 'p06'],
    ),
    AppUser(
      id: 'u_maria',
      name: 'Maria Santos',
      email: 'maria@example.com',
      phone: '09181234567',
      password: 'demo1234',
      createdAt: now.subtract(const Duration(days: 25)),
    ),
    AppUser(
      id: 'u_jon',
      name: 'Jon Reyes',
      email: 'jon@example.com',
      phone: '09191234567',
      password: 'demo1234',
      createdAt: now.subtract(const Duration(days: 12)),
    ),
  ];
}

/// Result of generating demo history: orders plus the loyalty entries that
/// completed, paid orders would have earned.
class DemoHistory {
  final List<CafeOrder> orders;
  final List<LoyaltyEntry> loyalty;
  final int lastOrderNumber;
  DemoHistory(this.orders, this.loyalty, this.lastOrderNumber);
}

/// Creates two weeks of believable orders so the dashboard and reports have
/// real records to calculate from. They are saved like any other order.
DemoHistory seedDemoHistory(
  List<Product> products,
  List<AddOn> addOns,
  List<AppUser> users,
  CafeSettings settings,
) {
  final rng = Random(7);
  final customers = users.where((u) => !u.isAdmin).toList();
  final orderables = products.where((p) => p.kind != Kinds.bundle).toList();
  final drinks = products.where((p) => p.isDrink).toList();
  final mochaDrinks = products.where((p) => p.isMocha).toList();
  final now = DateTime.now();
  final orders = <CafeOrder>[];
  final loyalty = <LoyaltyEntry>[];
  var counter = 0;

  CafeOrder build(DateTime when, AppUser user, OrderStatus status) {
    counter++;
    final lines = <OrderLine>[];
    final lineCount = 1 + rng.nextInt(3);
    for (var i = 0; i < lineCount; i++) {
      // Mocha is the specialty, so most demo orders include a mocha.
      final Product p = (i == 0 && rng.nextInt(10) < 7)
          ? mochaDrinks[rng.nextInt(mochaDrinks.length)]
          : (rng.nextBool()
                ? drinks[rng.nextInt(drinks.length)]
                : orderables[rng.nextInt(orderables.length)]);
      final sel = defaultSelection(p, addOns, [0, 25, 50, 75, 100], 'seed');
      lines.add(
        OrderLine(
          productId: p.id,
          name: p.name,
          kind: p.kind,
          category: p.category,
          size: sel.size,
          temp: sel.temp,
          sweetness: sel.sweetness,
          optionIds: sel.optionIds,
          note: '',
          summary: describeSelection(
            p,
            addOns,
            size: sel.size,
            temp: sel.temp,
            sweetness: sel.sweetness,
            optionIds: sel.optionIds,
          ),
          quantity: 1 + rng.nextInt(2),
          unitPrice: unitPrice(p, addOns, sel.size, sel.optionIds),
        ),
      );
    }
    final subtotal = lines.fold<double>(0, (a, l) => a + l.total);
    final fulfillment = Fulfillment.values[rng.nextInt(2)];
    final payment = PaymentMethods.all[rng.nextInt(3)];
    final done = status == OrderStatus.completed;
    final stamp =
        '${when.year % 100}${when.month.toString().padLeft(2, '0')}${when.day.toString().padLeft(2, '0')}';
    final order = CafeOrder(
      id: 'seed_$counter',
      orderNo: 'MM-$stamp-${counter.toString().padLeft(4, '0')}',
      userId: user.id,
      customerName: user.name,
      email: user.email,
      phone: user.phone,
      lines: lines,
      fulfillment: fulfillment,
      paymentMethod: payment,
      paid: done,
      subtotal: subtotal,
      total: subtotal,
      prepMinutes: settings.prepSpecialty,
      status: status,
      history: [StatusEvent(OrderStatus.received, when)],
      createdAt: when,
      pointsAwarded: done,
    );
    if (done) {
      order.history.add(
        StatusEvent(OrderStatus.completed, when.add(const Duration(minutes: 20))),
      );
      final pts = (subtotal / settings.pesosPerPoint).floor();
      if (pts > 0) {
        loyalty.add(
          LoyaltyEntry(
            id: 'l_seed_$counter',
            userId: user.id,
            points: pts,
            reason: 'Order ${order.orderNo}',
            at: when.add(const Duration(minutes: 20)),
          ),
        );
      }
    }
    return order;
  }

  // Completed orders over the last 14 days (the demo customer appears often
  // so their loyalty history is not empty).
  for (var day = 13; day >= 1; day--) {
    final perDay = 1 + rng.nextInt(3);
    for (var k = 0; k < perDay; k++) {
      final user = (k == 0 && day % 3 == 0)
          ? customers.firstWhere((u) => u.id == 'u_demo')
          : customers[rng.nextInt(customers.length)];
      final when = DateTime(now.year, now.month, now.day, 9 + rng.nextInt(10), rng.nextInt(60))
          .subtract(Duration(days: day));
      orders.add(build(when, user, OrderStatus.completed));
    }
  }

  // One cancelled order, to show it is excluded from revenue.
  orders.add(
    build(
      now.subtract(const Duration(days: 3, hours: 2)),
      customers[1],
      OrderStatus.cancelled,
    ),
  );

  // A couple of live orders for the queue, relative to "now".
  final live1 = build(
    now.subtract(const Duration(minutes: 12)),
    customers[1],
    OrderStatus.received,
  );
  live1.paid = false;
  orders.add(live1);
  final live2 = build(
    now.subtract(const Duration(minutes: 25)),
    customers[2],
    OrderStatus.preparing,
  );
  live2.history.addAll([
    StatusEvent(OrderStatus.confirmed, now.subtract(const Duration(minutes: 22))),
    StatusEvent(OrderStatus.preparing, now.subtract(const Duration(minutes: 18))),
  ]);
  orders.add(live2);

  return DemoHistory(orders, loyalty, counter);
}
