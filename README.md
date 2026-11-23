# MOCHA & MOSS

*Your Daily Comfort, Brewed Beautifully.*

A Flutter café ordering and management app for a specialty café built around
**mocha drinks**, with a smaller **matcha** collection, supporting café drinks
and desserts. It started as the Bloom & Brew login demo and keeps its dark
espresso / cream / gold / caramel look, its login and sign-up screens and its
light/dark theme toggle.

> **Demo mode.** The app has no server. Menu, accounts, orders, cart, loyalty
> points and settings are saved **on the device** (`shared_preferences`).
> Orders are **not** shared between phones. See "Going live" below.

## Features

**Customer**
- Splash, 3-slide onboarding (with Skip), login, sign-up, saved sessions
- Home storefront: hero, announcements, Signature Mocha, Matcha Corner, other
  drinks, best sellers, new arrivals, offers and bundles, personal recommendations
- Menu: 7 categories (Signature Mocha first), search (names, ingredients,
  categories), filters (hot/iced, price, bestsellers, new, available), 5 sort orders
- Drink page: size, hot/iced, sweetness, milk, espresso shots, toppings, matcha
  options (only where relevant), quantity, notes, live price, related drinks
- Cart (edit, merge, quantities), checkout (dine-in, pickup with time slots,
  delivery with address; cash, GCash, bank transfer), promo codes, loyalty
  rewards, order confirmation, live order tracker, history, reorder, cancel
  before confirmation, reviews
- Favorites, profile, saved addresses, notification settings, change password

**Café owner (admin)**
- Dashboard (sales today / 7 / 30 days, chart, best sellers, recent orders)
  calculated from saved orders. Only **completed** orders count as revenue.
- Order queue (New / Preparing / Ready / Done) with status actions
- Menu manager: add / edit / delete drinks, sizes and prices, hot/iced, labels,
  availability, stock, which options each drink offers
- Drink options: sweetness levels, milks, shots, toppings, matcha extras (prices, on/off)
- Inventory: product stock with low-stock alerts, manually edited ingredient stock
- Customers, reports (date filters, CSV export to clipboard), promotions,
  loyalty rules and rewards, announcements, review moderation, café settings

## Demo accounts

| Role | Email | Password |
|---|---|---|
| Customer | `demo@mochaandmoss.com` | `mocha123` |
| Admin | `admin@mochaandmoss.com` | `admin123` |

On the login screen, the **Customer demo** and **Admin demo** chips fill the
form for you. You can also sign up a new customer account. The first launch
creates two weeks of sample orders so the dashboard has real records to
calculate from. *Admin > More > Reset demo data* restores everything.

## Requirements

- Flutter SDK matching `pubspec.yaml` (Dart `>=3.12.2`), plus the Android SDK
- VS Code with the **Flutter** and **Dart** extensions
- Internet on first run (Google Fonts are fetched at runtime; the app falls back
  to system fonts offline)

## Run it in VS Code

1. Extract the ZIP and open the folder (**File > Open Folder**).
2. In the terminal: `flutter doctor`, then `flutter pub get`.
3. Start an Android emulator or plug in a phone, then press **F5** or run `flutter run`.
4. Quality checks: `flutter analyze` and `flutter test`.

`pubspec.lock` was written for the original project. `flutter pub get` will
update it for the newly added `shared_preferences` package.


## Customizing

- **Name, tagline, currency, contact:** edit `lib/config/brand.dart` (defaults),
  or change them live in *Admin > More > Settings*. Live edits are saved on the
  device and take precedence.
- **Colors:** `AppColors.dark` / `AppColors.light` in `lib/theme/app_theme.dart`.
- **Logo:** drawn in `lib/widgets/brand_logo.dart`. The launcher icon files are
  in `android/app/src/main/res/mipmap-*` and `web/icons`.
- **Add menu items / change prices:** *Admin > Menu > Add item* or tap an item.
  No code needed. Starting menu data lives in `lib/data/seed_data.dart` (it is
  only used on first run or after a reset).
- **Drink options (sizes, sweetness, milks, toppings, extra charges):** per item in
  the item editor, and globally in *Admin > Menu > Options*.
- **Payment instructions:** *Admin > More > Settings > Payments*. The sample
  GCash and bank details are placeholders: replace them.
- **Photos:** drinks without a photo show a built-in illustration. Put images in
  `assets/images/` and enter `assets/images/name.jpg` (or an `https://` URL) in
  the item editor. A broken image falls back to the illustration.
- **Loyalty:** earning rate and rewards in *Admin > More > Loyalty*. Points are
  only given for completed, **paid** orders.


    match /users/{uid} { allow read, write: if request.auth.uid == uid || isAdmin(); }
  }
}
```
