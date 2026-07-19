import 'package:serverpod/serverpod.dart';
import 'package:mycosmetics_server/src/generated/protocol.dart';
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

  Future<User> getProfile(Session session, int userId) async {
    final user = await _users.findById(session, userId);
    if (user == null) throw ProfileException('User not found.');
    return user;
  }

  Future<User> updateProfile(
    Session session, {
    required int userId,
    String? fullName,
    String? phone,
  }) async {
    final user = await _users.findById(session, userId);
    if (user == null) throw ProfileException('User not found.');
    return _users.update(
      session,
      user.copyWith(
        fullName: fullName?.trim() ?? user.fullName,
        phone: phone ?? user.phone,
        updatedAt: DateTime.now().toUtc(),
      ),
    );
  }

  Future<User> updateAvatarUrl(Session session, {required int userId, required String avatarUrl}) async {
    final user = await _users.findById(session, userId);
    if (user == null) throw ProfileException('User not found.');
    return _users.update(session, user.copyWith(avatarUrl: avatarUrl, updatedAt: DateTime.now().toUtc()));
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
