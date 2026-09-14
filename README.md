# LaundryGo

An on-demand laundry pickup & delivery marketplace — the "Talabat for
laundry" aggregator model: local laundromats (**partners**) list an itemized
menu, **customers** book a pickup window, **drivers** ferry items back and
forth, and the platform takes a commission on every order. This is a
**frontend MVP scaffold**: one Flutter codebase with a real, navigable app
for all four sides of the marketplace, backed by an in-memory data layer so
it runs standalone with no backend required.

This started life as a module inside the `Aqary-` real-estate repo and now
lives here as its own independent Flutter project/repo.

## Auth & Role-Based Access Control (RBAC)

The app opens on a **Sign in** screen (`lib/screens/auth/sign_in_screen.dart`);
new users **Sign up** as a Customer, Laundry Partner, or Driver
(`sign_up_screen.dart`) — Admin accounts aren't self-service, they're
provisioned directly (see the seeded `admin@laundrygo.com` account in
`lib/data/mock_data.dart`). Try it with the demo accounts printed on the
sign-in screen (`aisha@example.com` / `sparkle@example.com` /
`ali@example.com`, password `password123`; admin password `admin123`), or
create a new account.

Every account has exactly one `role` (`lib/models/enums.dart`'s
`UserRole`), and **routing middleware** — not each screen individually — is
what enforces it:

- `lib/routing/app_routes.dart` — the named top-level destinations
  (`/sign-in`, `/sign-up`, `/customer`, `/partner`, `/driver`, `/admin`).
- `lib/routing/auth_middleware.dart` — `AuthMiddleware.resolve()`, wired in
  as `MaterialApp.onGenerateRoute` in `lib/main.dart`. Every top-level
  navigation passes through it before a screen is shown: signed-out visitors
  asking for a role's shell are redirected to sign-in; a signed-in user
  asking for the *wrong* role's shell (a driver deep-linking to `/admin`,
  say) is redirected to their **own** shell instead of an access-denied
  page. It's the same idea a real backend expresses server-side — API
  middleware checking a JWT's role claim before handling a request — just
  enforced client-side over the in-memory session in `AppState.currentAccount`.

Screens pushed *within* an already-approved shell (catalog, cart, order
detail, ...) still use plain unnamed `Navigator.push`, since they're already
behind a route the middleware approved — the middleware only needs to guard
the handful of top-level entry points.

Passwords are hashed (not stored/compared as plaintext) even in this
in-memory demo — see the big warning comment in
`lib/utils/password_hash.dart` about what a real backend must do instead
(hash server-side with bcrypt/argon2/scrypt; never trust a client-side
check like this one in production).

## The four panels

All four are role-based flows inside **one app**, reached by signing in or
signing up as that role (see above):

- **Customer app** (`lib/screens/customer/`) — browse partners, pick items
  from an itemized catalog (wash & fold / dry clean / ironing, priced per
  item), schedule a locked pickup window, choose a payment method, then
  track the order (with a live-tracking map) through to delivery.
- **Laundry Partner panel** (`lib/screens/partner/`) — see incoming orders,
  accept them, move items through washing → ironing → ready, assign drivers
  for pickup/delivery, and edit per-item pricing.
- **Driver/Rider app** (`lib/screens/driver/`) — see assigned pickup/delivery
  tasks, a live route-tracking view, and one-tap milestone updates (picked
  up / out for delivery / delivered).
- **Admin panel** (`lib/screens/admin/`) — GMV and commission-revenue KPIs,
  a directory of every partner/driver, every order in the system, and a
  dispute queue with a resolve flow.

## Architecture

- `lib/models/` — plain Dart domain types (`LaundryOrder`, `CatalogItem`,
  `LaundryPartner`, `Driver`, `Dispute`, ...). No framework dependencies.
- `lib/data/app_state.dart` — a single `ChangeNotifier` acting as the
  in-memory "backend": every screen reads and mutates orders through it.
  Swap this for real API-backed repositories (one per bounded context —
  orders, catalog, users) behind the same method signatures when connecting
  a backend; the UI layer doesn't need to change.
- `lib/services/` — the integration points that are stubbed for the demo but
  designed to be swapped for real providers without touching UI code:
  - `payment_service.dart` — `PaymentGateway` interface; `MockPaymentGateway`
    simulates a charge. Plug in a real gateway (Stripe, PayTabs, Apple/Google
    Pay, a local bank or wallet aggregator) by implementing the same
    interface and passing it into `AppState(paymentGateway: ...)`.
  - `location_service.dart` — `LocationTracker` interface; the
    `SimulatedLocationTracker` animates a driver moving in a straight line.
    Replace with a real GPS/maps SDK (Google Maps + a fused location
    provider, Mapbox, a driver app's live location beacon) the same way.
  - `notification_service.dart` — `NotificationService` interface behind an
    in-memory feed; swap for FCM/SNS/Twilio.
- `lib/widgets/live_tracking_map.dart` — the "live GPS tracking" UI. It
  already consumes a `Stream<GeoPoint>` from `LocationTracker`, so wiring in
  a real map only means swapping the `CustomPaint` route drawing for an
  actual map widget — the streaming/progress plumbing stays.
- Commission math lives on `LaundryOrder` (`lib/models/order.dart`): each
  order snapshots the partner's commission rate at order time, so a later
  rate change never rewrites a past order's economics.

## Running it

This scaffold ships `lib/`, `pubspec.yaml`, and a `web/` folder, but not the
native `android/`/`ios/`/`macos/`/`windows`/`linux` runner projects (they're
generated, not hand-written). To run it:

```bash
flutter create . --platforms=android,ios,web   # generates the missing runner projects
flutter pub get
flutter run                                     # or: flutter run -d chrome
```

Run the smoke tests with:

```bash
flutter test
```

## Known simplifications (by design, for an MVP)

- **Auth is in-memory, client-side, and unpersisted** — real sessions
  (tokens, refresh, "remember me") and password hashing must move to a real
  backend; see `lib/utils/password_hash.dart`. Sign-up also doesn't verify
  email ownership.
- **Seed accounts + whatever you sign up** — `lib/data/mock_data.dart` seeds
  one customer, two partners, two drivers, and one admin, each with a login;
  new sign-ups add more customers/partners/drivers at runtime, but nothing
  persists across a restart.
- **Delivery fee** is a flat constant (`kDeliveryFee` in
  `lib/utils/formatters.dart`) rather than a distance/demand-priced quote.
- **Driver earnings** use a flat per-leg fee rather than a real payout
  engine.
- **The live map** is a stylized straight-line animation, not a routed map —
  see `lib/widgets/live_tracking_map.dart` for the swap point.
