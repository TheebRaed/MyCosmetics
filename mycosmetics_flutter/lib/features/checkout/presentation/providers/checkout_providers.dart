import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mycosmetics_client/mycosmetics_client.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/checkout_repository.dart';

part 'checkout_providers.g.dart';

@riverpod
class AddressList extends _$AddressList {
  @override
  Future<List<Address>> build() => ref.watch(checkoutRepositoryProvider).listAddresses();

  Future<Address?> add(Address address) async {
    final created = await ref.read(checkoutRepositoryProvider).addAddress(address);
    ref.invalidateSelf();
    await future;
    return created;
  }
}

/// Shipping methods for a given country + order total -- both required by
/// `PaymentEndpoint.getShippingMethods` (fee depends on the order total for
/// free-shipping thresholds).
@riverpod
Future<List<Map<String, dynamic>>> shippingMethods(
  Ref ref, {
  required String country,
  required double orderTotal,
}) {
  return ref.watch(checkoutRepositoryProvider).getShippingMethods(country: country, orderTotal: orderTotal);
}
