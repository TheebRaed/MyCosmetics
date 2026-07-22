import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mycosmetics_client/mycosmetics_client.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/session_manager.dart';

part 'checkout_repository.g.dart';

/// Thin wrapper around `client.profile` (addresses), `client.payment`
/// (shipping methods + payment) and `client.order` (checkout) for the
/// Checkout screen.
///
/// Notes on what's real vs. deliberately narrowed (see task brief):
/// - Addresses: `ProfileEndpoint.listAddresses/addAddress` are real, backed
///   by `AddressRepository`/`Address` -- no new backend endpoint was needed.
///   Unlike most endpoints (session-based `AuthGuard`), `ProfileEndpoint`
///   takes an explicit `token` param -- fetched from [SessionManager] here,
///   matching the one existing call site (none yet; this is the first
///   client-side use of ProfileEndpoint's address methods).
/// - Shipping methods: `PaymentEndpoint.getShippingMethods` is real and fee
///   is computed server-side. NOTE: `OrderEndpoint.checkout` does not accept
///   a shipping-method param and `Order.total` never includes a shipping
///   fee (confirmed in order_service.dart) -- so the fee shown here is an
///   honest estimate, not (yet) added to what's actually charged.
/// - Payment: `PaymentEndpoint.initiatePayment` supports `cod` for real,
///   end-to-end, with no external SDK (see payment_service.dart's
///   `_initiateCod`). `stripe` is a server-side mock/TODO
///   (`_initiateStripe`) with no client-side Stripe SDK wired in this app
///   yet, so it is intentionally NOT offered as a selectable method here --
///   offering it would fake a "payment successful" state.
class CheckoutRepository {
  CheckoutRepository(this._client, this._session);

  final Client _client;
  final SessionManager _session;

  Future<String> _requireToken() async {
    final token = await _session.get();
    if (token == null) throw Exception('Not signed in.');
    return token;
  }

  Future<List<Address>> listAddresses() async {
    final token = await _requireToken();
    return _client.profile.listAddresses(token: token);
  }

  Future<Address> addAddress(Address address) async {
    final token = await _requireToken();
    return _client.profile.addAddress(token: token, address: address);
  }

  Future<List<Map<String, dynamic>>> getShippingMethods({required String country, required double orderTotal}) =>
      _client.payment.getShippingMethods(country: country, orderTotal: orderTotal);

  Future<OrderDetail> checkout({required int addressId}) => _client.order.checkout(addressId: addressId);

  /// Cash-on-delivery is the only real, end-to-end payment path today (see
  /// class doc). [orderId]'s amount is read server-side from the order
  /// record, not trusted from the client.
  Future<Map<String, dynamic>> payCashOnDelivery({required int orderId}) => _client.payment.initiatePayment(
        orderId: orderId,
        provider: 'cod',
        method: 'cash',
        idempotencyKey: _newIdempotencyKey(),
      );

  static final _random = Random.secure();

  /// Not a real UUID (no `uuid` package dependency pulled in for this),
  /// but unique and stable enough to satisfy `PaymentService`'s
  /// idempotency-key requirement for a single checkout attempt.
  String _newIdempotencyKey() {
    final bytes = List<int>.generate(16, (_) => _random.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }
}

@riverpod
CheckoutRepository checkoutRepository(Ref ref) =>
    CheckoutRepository(ref.watch(apiClientProvider), ref.watch(sessionManagerProvider));
