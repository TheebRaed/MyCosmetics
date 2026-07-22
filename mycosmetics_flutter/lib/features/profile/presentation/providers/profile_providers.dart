import 'package:mycosmetics_client/mycosmetics_client.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/profile_repository.dart';

part 'profile_providers.g.dart';

@riverpod
class ProfileController extends _$ProfileController {
  @override
  Future<AuthUser> build() => ref.watch(profileRepositoryProvider).getProfile();

  Future<String?> updateFullName(String fullName) async {
    try {
      final updated = await ref.read(profileRepositoryProvider).updateProfile(fullName: fullName);
      state = AsyncData(updated);
      return null;
    } catch (e) {
      return friendlyProfileErrorMessage(e);
    }
  }
}

@riverpod
class ProfileAddressList extends _$ProfileAddressList {
  @override
  Future<List<Address>> build() => ref.watch(profileRepositoryProvider).listAddresses();

  Future<String?> add(Address address) async {
    try {
      await ref.read(profileRepositoryProvider).addAddress(address);
      ref.invalidateSelf();
      await future;
      return null;
    } catch (e) {
      return friendlyProfileErrorMessage(e);
    }
  }

  Future<String?> updateAddress(Address address) async {
    try {
      await ref.read(profileRepositoryProvider).updateAddress(address);
      ref.invalidateSelf();
      await future;
      return null;
    } catch (e) {
      return friendlyProfileErrorMessage(e);
    }
  }

  Future<String?> delete(int addressId) async {
    try {
      await ref.read(profileRepositoryProvider).deleteAddress(addressId);
      ref.invalidateSelf();
      await future;
      return null;
    } catch (e) {
      return friendlyProfileErrorMessage(e);
    }
  }
}

@riverpod
class WishlistController extends _$WishlistController {
  @override
  Future<List<WishlistItemDetail>> build() => ref.watch(profileRepositoryProvider).wishlist();

  Future<String?> remove(int wishlistItemId) async {
    try {
      await ref.read(profileRepositoryProvider).removeFromWishlist(wishlistItemId);
      ref.invalidateSelf();
      await future;
      return null;
    } catch (e) {
      return friendlyProfileErrorMessage(e);
    }
  }
}

/// Strips Serverpod's exception-class prefix, same pattern as
/// cart_providers.dart's `friendlyCartErrorMessage`.
String friendlyProfileErrorMessage(Object e) {
  final raw = e.toString();
  if (raw.contains('Internal server error')) {
    return 'Something went wrong. Please try again.';
  }
  final match = RegExp(r'^ServerpodClientException:\s*(.*?),\s*statusCode').firstMatch(raw);
  return match?.group(1) ?? 'Something went wrong. Please try again.';
}
