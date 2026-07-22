import 'package:serverpod/serverpod.dart';
import 'package:mycosmetics_server/src/generated/protocol.dart' hide UserRepository, AddressRepository;
import 'package:mycosmetics_server/src/repositories/user_repository.dart';
import 'package:mycosmetics_server/src/repositories/address_repository.dart';

class ProfileException implements Exception {
  final String message;
  ProfileException(this.message);
  @override
  String toString() => message;
}

class ProfileService {
  final UserRepository _users = UserRepository();
  final AddressRepository _addresses = AddressRepository();

  // Same hash-free projection AuthService uses for AuthResult -- passwordHash
  // must never leave the service boundary. See auth_service.dart's
  // _toAuthUser and auth_dto.spy.yaml's comment on AuthUser.
  AuthUser _toAuthUser(User u) => AuthUser(
        id: u.id!,
        email: u.email,
        fullName: u.fullName,
        role: u.role,
        avatarUrl: u.avatarUrl,
      );

  Future<AuthUser> getProfile(Session session, int userId) async {
    final user = await _users.findById(session, userId);
    if (user == null) throw ProfileException('User not found.');
    return _toAuthUser(user);
  }

  Future<AuthUser> updateProfile(
    Session session, {
    required int userId,
    String? fullName,
  }) async {
    final user = await _users.findById(session, userId);
    if (user == null) throw ProfileException('User not found.');
    final updated = await _users.update(
      session,
      user.copyWith(
        fullName: fullName?.trim() ?? user.fullName,
        updatedAt: DateTime.now().toUtc(),
      ),
    );
    return _toAuthUser(updated);
  }

  Future<AuthUser> updateAvatarUrl(Session session, {required int userId, required String avatarUrl}) async {
    final user = await _users.findById(session, userId);
    if (user == null) throw ProfileException('User not found.');
    final updated = await _users.update(session, user.copyWith(avatarUrl: avatarUrl, updatedAt: DateTime.now().toUtc()));
    return _toAuthUser(updated);
  }

  Future<List<Address>> listAddresses(Session session, int userId) {
    return _addresses.listForUser(session, userId);
  }

  Future<Address> addAddress(Session session, Address address) async {
    if (address.isDefault) {
      await _addresses.clearDefaultForUser(session, address.userId);
    }
    final now = DateTime.now().toUtc();
    return _addresses.create(session, address.copyWith(createdAt: now, updatedAt: now));
  }

  Future<Address> updateAddress(Session session, {required int userId, required Address address}) async {
    final existing = await _addresses.findById(session, address.id!);
    if (existing == null || existing.userId != userId) {
      throw ProfileException('Address not found.');
    }
    if (address.isDefault && !existing.isDefault) {
      await _addresses.clearDefaultForUser(session, userId);
    }
    return _addresses.update(session, address.copyWith(userId: userId, updatedAt: DateTime.now().toUtc()));
  }

  Future<void> deleteAddress(Session session, {required int userId, required int addressId}) async {
    final existing = await _addresses.findById(session, addressId);
    if (existing == null || existing.userId != userId) {
      throw ProfileException('Address not found.');
    }
    await _addresses.delete(session, addressId);
  }
}
