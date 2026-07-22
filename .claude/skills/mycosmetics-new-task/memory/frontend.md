---
name: frontend
description: Customer app (mycosmetics_flutter) screens/widgets built so far and the conventions they established.
metadata:
  type: project
---

## Cart + Checkout (2026-07-22)

Built `lib/features/cart/` (repo + `CartController` riverpod notifier + `CartScreen`, wired to the real Cart tab) and `lib/features/checkout/` (`CheckoutRepository`/providers/`CheckoutScreen`/`OrderConfirmationScreen`), reached via new routes `AppRoutes.checkout` (`/checkout`) and `AppRoutes.orderConfirmation` (`/order-confirmation`, `OrderDetail` passed via go_router `extra`).

Key backend facts discovered (still true as of this writing, re-verify before relying on them long-term):
- `ProfileEndpoint` (list/add/update/delete Addresses) already existed -- no new `AddressEndpoint` was needed for checkout. Unlike most endpoints it takes an explicit `token` param instead of session-based `AuthGuard`; client code fetches the token via `SessionManager.get()` (see `checkout_repository.dart`).
- `OrderEndpoint.checkout(addressId)` does NOT accept a shipping-method param and `Order.total` never includes a shipping fee -- shipping fee from `PaymentEndpoint.getShippingMethods` is estimate-only in the UI, called out with a caption rather than silently added.
- `PaymentEndpoint.initiatePayment` with `provider: 'cod'` is a real, fully server-side-implemented path (no external SDK). `provider: 'stripe'` is a server-side mock/TODO (`_initiateStripe` in `payment_service.dart`) -- do not surface it as a selectable payment method client-side until real Stripe client SDK wiring lands, or it fakes a successful payment.
- "Save for later" has no distinct backend concept -- implemented as move-to-wishlist-and-remove-from-cart, reusing `WishlistEndpoint` (already wired on PDP).

Widget/provider conventions reinforced by this build (match [[widget-conventions]] if that memory exists, else these are the reference points):
- Riverpod notifier pattern: `@riverpod class XController extends _$XController { Future<AsyncValue<T>> build() ...; Future<String?> action() { try {...; return null;} catch(e) {return friendlyXErrorMessage(e);} } }` -- same shape as `auth_controller.dart`'s `friendlyAuthErrorMessage`, duplicated per-feature (`friendlyCartErrorMessage`) rather than shared, matching existing precedent.
- Cross-feature provider reads are fine (checkout imports `cartControllerProvider` from the cart feature) -- same precedent as PDP importing `recentlyViewedStoreProvider` from home.
- `AppCard`, `PillButton`, `AppColors*`/`AppSpacing`/`AppRadius`/`AppShadows`/`AppGradients` tokens are the load-bearing shared UI vocabulary; every screen built so far (Home, PDP, Cart, Checkout) uses them instead of raw `Container`/`ElevatedButton`.
