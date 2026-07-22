import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mycosmetics_client/mycosmetics_client.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/session_manager.dart';

part 'profile_repository.g.dart';

/// Thin wrapper around `client.profile` (see
/// mycosmetics_server/lib/src/endpoints/profile_endpoint.dart, which takes
/// an explicit `token` param rather than session-based `AuthGuard`, same
/// pattern already established by checkout_repository.dart) and
/// `client.wishlist` (already wired on PDP/Cart) for the Profile screens.
///
/// Avatar upload (`ProfileEndpoint.updateAvatarUrl`) is NOT wrapped here --
/// it expects a public URL from a separate Serverpod file/storage upload
/// step that no client-side flow wires up yet (no image-picker + storage
/// upload plumbing exists in this app). Edit Profile only offers full-name
/// editing for now.
class ProfileRepository {
  ProfileRepository(this._client, this._session);

  final Client _client;
  final SessionManager _session;

  Future<String> _requireToken() async {
    final token = await _session.get();
    if (token == null) throw Exception('Not signed in.');
    return token;
  }

  Future<AuthUser> getProfile() async {
    final token = await _requireToken();
    return _client.profile.getProfile(token: token);
  }

  Future<AuthUser> updateProfile({String? fullName}) async {
    final token = await _requireToken();
    return _client.profile.updateProfile(token: token, fullName: fullName);
  }

  Future<List<Address>> listAddresses() async {
    final token = await _requireToken();
    return _client.profile.listAddresses(token: token);
  }

  Future<Address> addAddress(Address address) async {
    final token = await _requireToken();
    return _client.profile.addAddress(token: token, address: address);
  }

  Future<Address> updateAddress(Address address) async {
    final token = await _requireToken();
    return _client.profile.updateAddress(token: token, address: address);
  }

  Future<void> deleteAddress(int addressId) async {
    final token = await _requireToken();
    await _client.profile.deleteAddress(token: token, addressId: addressId);
  }

  Future<List<WishlistItemDetail>> wishlist() => _client.wishlist.list();

  Future<void> removeFromWishlist(int wishlistItemId) => _client.wishlist.remove(wishlistItemId: wishlistItemId);
}

@riverpod
ProfileRepository profileRepository(Ref ref) =>
    ProfileRepository(ref.watch(apiClientProvider), ref.watch(sessionManagerProvider));
