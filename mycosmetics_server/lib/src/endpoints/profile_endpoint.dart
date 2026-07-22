import 'package:serverpod/serverpod.dart';
import 'package:mycosmetics_server/src/generated/protocol.dart';
import 'package:mycosmetics_server/src/business/profile_service.dart';
import 'package:mycosmetics_server/src/endpoints/auth_endpoint.dart';

class ProfileEndpoint extends Endpoint {
  final ProfileService _profile = ProfileService();

  Future<int> _requireUserId(Session session, String token) async {
    final userId = await AuthEndpoint().resolveSession(session, token: token);
    if (userId == null) {
      throw Exception('Unauthorized: invalid or expired session.');
    }
    return userId;
  }

  // Returns AuthUser (hash-free), never the raw User model -- passwordHash
  // must never reach the client. Mirrors AuthEndpoint's login/register.
  Future<AuthUser> getProfile(Session session, {required String token}) async {
    final userId = await _requireUserId(session, token);
    return _profile.getProfile(session, userId);
  }

  Future<AuthUser> updateProfile(
    Session session, {
    required String token,
    String? fullName,
  }) async {
    final userId = await _requireUserId(session, token);
    return _profile.updateProfile(session, userId: userId, fullName: fullName);
  }

  /// Client uploads avatar bytes via Serverpod's file/storage API separately,
  /// then calls this with the resulting public URL to persist the reference.
  Future<AuthUser> updateAvatarUrl(Session session, {required String token, required String avatarUrl}) async {
    final userId = await _requireUserId(session, token);
    return _profile.updateAvatarUrl(session, userId: userId, avatarUrl: avatarUrl);
  }

  Future<List<Address>> listAddresses(Session session, {required String token}) async {
    final userId = await _requireUserId(session, token);
    return _profile.listAddresses(session, userId);
  }

  Future<Address> addAddress(Session session, {required String token, required Address address}) async {
    final userId = await _requireUserId(session, token);
    return _profile.addAddress(session, address.copyWith(userId: userId));
  }

  Future<Address> updateAddress(Session session, {required String token, required Address address}) async {
    final userId = await _requireUserId(session, token);
    return _profile.updateAddress(session, userId: userId, address: address);
  }

  Future<void> deleteAddress(Session session, {required String token, required int addressId}) async {
    final userId = await _requireUserId(session, token);
    await _profile.deleteAddress(session, userId: userId, addressId: addressId);
  }
}
