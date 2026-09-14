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

## Address selection (locate me, saved addresses, or add one)

Picking a pickup/delivery address on the schedule screen
(`lib/screens/customer/address_selector.dart`) works like Talabat's address
step:

- **Use my current location** — a one-tap, one-off pickup point read from
  the device's real GPS (`lib/services/device_location_service.dart`, via
  the `geolocator` package — this is real, not simulated). Used for that
  order only; not saved to the address book.
- **Saved addresses** — the customer's address book
  (`Customer.addresses`), same as before.
- **Add a new address** — opens `lib/screens/customer/add_address_screen.dart`:
  drop a pin on a map (or use current location to set one), confirm a
  label/address/city, and it's saved to the address book for future orders.

The map itself (`lib/widgets/map_pin_picker.dart`) is a stylized,
tap-to-place placeholder over a small fixed demo area, **not real Google
Maps tiles** — that needs a Google Maps API key with billing enabled, which
this project doesn't have. It's built the same way as the live-tracking map
so a real `google_maps_flutter` integration can swap in later without
changing how callers use it (they just get a `GeoPoint` out either way).
Real device geolocation, though, needs no API key and works today.

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

**Sign-up collects, per role:**

- **Every role**: name, email (also used as the sign-in username), password,
  and phone number.
- **Customer**: a pickup address + city.
- **Laundry Partner**: an area/neighbourhood, plus two required document
  uploads — an owner **ID** and a **Commercial Registration**
  (`lib/widgets/document_picker_field.dart`).
- **Driver**: vehicle details, plus two required document uploads — a
  **Residential ID** and a **Driver's Licence**.

New partner/driver accounts start `VerificationStatus.pending` (shown on the
Admin → Users screen); the pre-seeded demo partners/drivers are already
`verified`. Document upload only remembers the picked file's *name* — see
the caveat on `DocumentPickerField` for what a real KYC/onboarding pipeline
needs to do instead (upload to secure storage, route to a human or
automated review that's what should flip the status to verified/rejected —
nothing in this demo does that yet).

**Forgot password** (`lib/screens/auth/forgot_password_screen.dart`, linked
from the sign-in screen): a two-step reset — confirm the account's email,
then set a new password. This demo has no email service, so it skips
straight from "email exists" to "set a new password" instead of requiring
a token from an emailed reset link first; see the warning on
`AppState.resetPassword` for why that shortcut is demo-only and must not
ship to production (as written, anyone who knows an email on the platform
could reset that account's password).

## Driver availability & slot capacity

Each driver sets a **weekly recurring schedule** — which of the six 9 AM-9 PM
windows (`kSlotWindows` in `lib/utils/scheduling.dart`) they work, per day
of the week — on the Driver app's **Schedule** tab
(`lib/screens/driver/driver_schedule_screen.dart`). Edits build up in a
local draft; nothing is saved until "Confirm and save schedule" is tapped
(`AppState.setDriverWeeklyAvailability`). This is what makes a pickup slot
"fully booked":

- `AppState.isSlotFullyBooked(slot)` — true once every driver rostered for
  that weekday/window already has an order booked into it. The customer's
  schedule screen (`lib/screens/customer/schedule_screen.dart`) disables
  such slots and labels them "Fully booked" instead of a pickable time
  (and flags a day as "(Full)" once every slot in it is).
- `AppState.driversAvailableForSlot(slot)` — the drivers a partner can
  actually offer for a pickup: rostered for that window, on shift
  (`Driver.isAvailable`), and not already covering a different active
  pickup in the same window. When this is empty, the partner's order
  screen (`lib/screens/partner/partner_order_detail_screen.dart`) shows
  "Fully booked" instead of an empty driver list.

New drivers (sign-up and the seeded demo accounts) default to being
rostered for every slot, every day — otherwise every booking would look
fully booked before anyone has ever visited the schedule screen.

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
  tasks, a live route-tracking view, one-tap milestone updates (picked up /
  out for delivery / delivered), and set a **weekly availability
  schedule** (9 AM - 9 PM, in the same six windows a customer books from) on
  the Schedule tab.
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

```bash
flutter pub get
flutter run                # picks a connected device/simulator, or:
flutter run -d chrome      # web
flutter build apk          # Android
flutter build ios          # iOS (needs a Mac + Xcode)
flutter build macos        # macOS (needs a Mac + Xcode)
flutter build windows      # Windows (needs Windows + Visual Studio)
flutter build linux        # Linux (needs libgtk-3-dev)
```

Run the smoke tests with:

```bash
flutter test
```

## Continuous Integration

Three GitHub Actions workflows run on every push/PR to `main`
(`.github/workflows/`):

- **`web-build.yml`** — analyze, test, `flutter build web --release`, then
  deploy to GitHub Pages on pushes to `main`:
  https://talalscorpions-dotcom.github.io/Laundry-/
- **`android-build.yml`** — analyze, test, then builds a release APK and App
  Bundle.
- **`ios-build.yml`** — analyze, test, then builds an unsigned iOS
  simulator app (no Apple Developer account needed for CI).

macOS/Windows/Linux desktop builds aren't wired into CI yet; run them
locally with the commands above.

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
