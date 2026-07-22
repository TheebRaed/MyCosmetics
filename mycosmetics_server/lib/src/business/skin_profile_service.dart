import 'package:serverpod/serverpod.dart';
import 'package:mycosmetics_server/src/generated/protocol.dart' hide SkinProfileRepository;
import 'package:mycosmetics_server/src/repositories/skin_profile_repository.dart';
import 'package:mycosmetics_server/src/utils/input_validator.dart';

/// Shared exception type for the BeautyTech domain (skin profile, skin
/// analysis, recommendations, saved looks). Mirrors the per-domain
/// exception pattern used elsewhere (ProfileException, OrderException) --
/// kept here since SkinProfileService is the foundational service other
/// BeautyTech services build on.
class BeautyTechException implements Exception {
  final String message;
  BeautyTechException(this.message);
  @override
  String toString() => message;
}

class SkinProfileService {
  final SkinProfileRepository _profiles = SkinProfileRepository();

  Future<SkinProfile?> get(Session session, int userId) {
    return _profiles.findByUserId(session, userId);
  }

  /// Upserts the caller's skin profile. `scannedAt` is (re)stamped only
  /// when `skinToneHex` changes -- that's the moment a real "analysis"
  /// (swatch pick / selfie extraction) happened, as opposed to e.g. just
  /// editing `concerns` text.
  Future<SkinProfile> save(
    Session session, {
    required int userId,
    String? skinToneHex,
    String? undertone,
    String? concerns,
  }) async {
    if (skinToneHex != null) InputValidator.validateHexColor(skinToneHex);
    if (undertone != null) InputValidator.validateUndertone(undertone);

    final existing = await _profiles.findByUserId(session, userId);
    final now = DateTime.now().toUtc();
    final toneChanged = skinToneHex != null && skinToneHex != existing?.skinToneHex;

    final profile = (existing ?? SkinProfile(userId: userId, createdAt: now, updatedAt: now)).copyWith(
      skinToneHex: skinToneHex ?? existing?.skinToneHex,
      undertone: undertone ?? existing?.undertone,
      concerns: concerns ?? existing?.concerns,
      scannedAt: toneChanged ? now : existing?.scannedAt,
      updatedAt: now,
    );

    return _profiles.upsert(session, profile);
  }

  /// Requires a complete profile (skinToneHex + undertone both set) --
  /// used by RecommendationService before generating recommendations.
  Future<SkinProfile> requireCompleteProfile(Session session, int userId) async {
    final profile = await _profiles.findByUserId(session, userId);
    if (profile == null || profile.skinToneHex == null || profile.undertone == null) {
      throw BeautyTechException(
        'A skin profile with a skin tone and undertone is required before generating recommendations. '
        'Submit a skin analysis or save a profile first.',
      );
    }
    return profile;
  }

  Future<void> reset(Session session, int userId) {
    return _profiles.delete(session, userId);
  }
}
