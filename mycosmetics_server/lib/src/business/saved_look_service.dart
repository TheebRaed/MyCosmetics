import 'package:serverpod/serverpod.dart';
import 'package:mycosmetics_server/src/generated/protocol.dart' hide SavedLookRepository;
import 'package:mycosmetics_server/src/repositories/saved_look_repository.dart';
import 'package:mycosmetics_server/src/business/skin_profile_service.dart';
import 'package:mycosmetics_server/src/utils/input_validator.dart';

/// `SavedLook.appliedVariantIds` is a plain `String` column (see
/// saved_look.spy.yaml). Encoding chosen here: comma-joined variant ids,
/// e.g. "12,45,7", with no spaces. `SavedLookService` is the single place
/// that encodes/decodes it -- callers on the Dart side (this service, and
/// any future service) should go through [encodeVariantIds] /
/// [decodeVariantIds] rather than hand-rolling the format. Flutter clients
/// consuming the generated `SavedLook.appliedVariantIds` field directly
/// should split on ',' and parse ints themselves.
class SavedLookService {
  final SavedLookRepository _looks = SavedLookRepository();

  static String encodeVariantIds(List<int> ids) => ids.join(',');

  static List<int> decodeVariantIds(String encoded) {
    if (encoded.trim().isEmpty) return [];
    return encoded.split(',').map(int.parse).toList();
  }

  Future<List<SavedLook>> list(Session session, int userId) {
    return _looks.listForUser(session, userId);
  }

  Future<SavedLook> create(
    Session session, {
    required int userId,
    required String name,
    required String imageUrl,
    required List<int> appliedVariantIds,
  }) async {
    final trimmedName = InputValidator.sanitizeText(name, maxLength: 100);
    if (trimmedName.isEmpty) throw BeautyTechException('Look name is required.');

    final now = DateTime.now().toUtc();
    return _looks.create(
      session,
      SavedLook(
        userId: userId,
        name: trimmedName,
        imageUrl: imageUrl,
        appliedVariantIds: encodeVariantIds(appliedVariantIds),
        isFavorite: false,
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  Future<SavedLook> update(
    Session session, {
    required int userId,
    required int id,
    String? name,
    bool? isFavorite,
  }) async {
    final existing = await _looks.findById(session, id);
    if (existing == null || existing.userId != userId) {
      throw BeautyTechException('Saved look not found.');
    }

    final updatedName = name != null ? InputValidator.sanitizeText(name, maxLength: 100) : existing.name;
    if (updatedName.isEmpty) throw BeautyTechException('Look name is required.');

    return _looks.update(
      session,
      existing.copyWith(
        name: updatedName,
        isFavorite: isFavorite ?? existing.isFavorite,
        updatedAt: DateTime.now().toUtc(),
      ),
    );
  }

  Future<void> delete(Session session, {required int userId, required int id}) async {
    final existing = await _looks.findById(session, id);
    if (existing == null || existing.userId != userId) {
      throw BeautyTechException('Saved look not found.');
    }
    await _looks.delete(session, id: id, userId: userId);
  }
}
