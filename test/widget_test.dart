import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:finals_itp107/data/app_store.dart';
import 'package:finals_itp107/data/report_service.dart';
import 'package:finals_itp107/main.dart';
import 'package:finals_itp107/models/models.dart';
import 'package:finals_itp107/theme/app_theme.dart';

CheckoutRequest _pickup({String payment = PaymentMethods.cash, String promo = ''}) =>
    CheckoutRequest(
      name: 'Alex Rivera',
      email: 'demo@mochaandmoss.com',
      phone: '09171234567',
      fulfillment: Fulfillment.pickup,
      paymentMethod: payment,
      promoCode: promo,
    );

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AppFonts.offline = true;
    await store.init();
    await store.resetDemoData();
    store.onboardingSeen = true;
    expect(store.login('demo@mochaandmoss.com', 'mocha123'), isNull);
    store.clearCart();
  });

  group('pricing', () {
    test('size, milk, shot and topping prices add up', () {
      final p = store.productById('p01')!;
      final sel = store.defaultItemFor(p)
        ..size = 'Medium'
        ..optionIds = ['milk_oat', 'shot_double', 'top_whip'];
      // 145 base + 20 medium + 20 oat + 50 double shot + 20 whipped cream
      expect(store.unitPriceOf(sel), 255);
    });

    test('matcha drinks do not offer mocha-only options', () {
      final p = store.productById('p11')!;
      expect(p.optionIds.contains('shot_double'), isFalse);
      expect(p.optionIds.contains('top_chips'), isFalse);
      expect(p.optionIds.contains('mat_strong'), isTrue);
    });

    test('identical drinks merge in the cart', () {
      final p = store.productById('p01')!;
      store.addToCart(store.defaultItemFor(p));
      store.addToCart(store.defaultItemFor(p));
      expect(store.cart.length, 1);
      expect(store.cartCount, 2);
    });
  });

  group('orders', () {
    test('placing an order saves it, clears the cart and blocks a duplicate', () {
      store.addToCart(store.defaultItemFor(store.productById('p01')!)..quantity = 2);
      final order = store.placeOrder(_pickup());
      expect(order.total, 290);
      expect(order.orderNo.startsWith('MM-'), isTrue);
      expect(order.status, OrderStatus.received);
      expect(order.paid, isFalse); // the app never marks payment as received
      expect(store.cart, isEmpty);
      expect(store.orderById(order.id), isNotNull);
      expect(() => store.placeOrder(_pickup()), throwsA(isA<OrderException>()));
    });

    test('delivery needs an address', () {
      store.addToCart(store.defaultItemFor(store.productById('p01')!));
      final request = _pickup()..fulfillment = Fulfillment.delivery;
      expect(() => store.placeOrder(request), throwsA(isA<OrderException>()));
    });

    test('completed cash order is paid and earns points; cancelled does not count', () {
      final before = store.pointsFor('u_demo');
      store.addToCart(store.defaultItemFor(store.productById('p01')!)..quantity = 2);
      final done = store.placeOrder(_pickup());
      for (final s in [
        OrderStatus.confirmed,
        OrderStatus.preparing,
        OrderStatus.ready,
        OrderStatus.completed,
      ]) {
        store.setOrderStatus(done.id, s);
      }
      expect(done.paid, isTrue);
      expect(store.pointsFor('u_demo') - before, 29); // 290 / 10

      store.addToCart(store.defaultItemFor(store.productById('p02')!));
      final cancelled = store.placeOrder(_pickup());
      store.setOrderStatus(cancelled.id, OrderStatus.cancelled);
      final report = SalesReport.build(store.orders, DateTime(2000), DateTime.now());
      expect(report.completed.any((o) => o.id == cancelled.id), isFalse);
      expect(report.completed.any((o) => o.id == done.id), isTrue);
    });

    test('online payments must be marked received before completing', () {
      store.addToCart(store.defaultItemFor(store.productById('p01')!));
      final o = store.placeOrder(_pickup(payment: PaymentMethods.gcash));
      store.setOrderStatus(o.id, OrderStatus.confirmed);
      store.setOrderStatus(o.id, OrderStatus.preparing);
      store.setOrderStatus(o.id, OrderStatus.ready);
      expect(() => store.setOrderStatus(o.id, OrderStatus.completed), throwsA(isA<OrderException>()));
      store.markPaid(o.id, true);
      store.setOrderStatus(o.id, OrderStatus.completed);
      expect(o.status, OrderStatus.completed);
    });

    test('tracked stock is reduced and restored on cancel', () {
      final brownie = store.productById('p21')!;
      final start = brownie.stock!;
      store.addToCart(store.defaultItemFor(brownie)..quantity = 3);
      final o = store.placeOrder(_pickup());
      expect(brownie.stock, start - 3);
      store.setOrderStatus(o.id, OrderStatus.cancelled);
      expect(brownie.stock, start);
    });

    test('promo code discounts only matching items and respects the minimum', () {
      store.addToCart(store.defaultItemFor(store.productById('p01')!)..quantity = 2);
      final q = store.quote(fulfillment: Fulfillment.pickup, promoCode: 'MOCHA20');
      expect(q.discount, 20);
      expect(q.total, 270);
      store.clearCart();
      store.addToCart(store.defaultItemFor(store.productById('p15')!));
      final none = store.quote(promoCode: 'MOCHA20');
      expect(none.promoMessage, isNotNull);
    });
  });

  group('persistence', () {
    test('a fresh store reads back saved orders and menu edits', () async {
      store.addToCart(store.defaultItemFor(store.productById('p01')!));
      final o = store.placeOrder(_pickup());
      final edited = store.productById('p03')!..basePrice = 170;
      store.saveProduct(edited);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      final fresh = AppStore();
      await fresh.init();
      expect(fresh.orderById(o.id), isNotNull);
      expect(fresh.productById('p03')!.basePrice, 170);
      expect(fresh.isLoggedIn, isTrue);
    });
  });

  group('app', () {
    testWidgets('splash leads to login, customer can sign in and see the storefront', (tester) async {
      // A small phone, to catch overflow problems.
      tester.view.physicalSize = const Size(360 * 2, 640 * 2);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);
      store.logout();

      await tester.pumpWidget(const MochaAndMossApp());
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
      expect(find.text('Ready for your next mocha?'), findsOneWidget);

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'demo@mochaandmoss.com');
      await tester.enterText(fields.at(1), 'mocha123');
      await tester.tap(find.text('Log in'));
      await tester.pumpAndSettle();

      expect(find.text('MOCHA MOMENTS.'), findsOneWidget);
      expect(find.text('Signature Mocha'), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('wrong password shows an error', (tester) async {
      store.logout();
      await tester.pumpWidget(const MochaAndMossApp());
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'demo@mochaandmoss.com');
      await tester.enterText(fields.at(1), 'wrong-password');
      await tester.tap(find.text('Log in'));
      await tester.pumpAndSettle();
      expect(find.text('Incorrect password.'), findsOneWidget);
    });
  });
}
