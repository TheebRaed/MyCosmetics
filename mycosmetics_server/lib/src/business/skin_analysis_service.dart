import 'package:serverpod/serverpod.dart';
import 'package:mycosmetics_server/src/generated/protocol.dart' hide SkinAnalysisResultRepository, SkinProfileRepository;
import 'package:mycosmetics_server/src/repositories/skin_analysis_repository.dart';
import 'package:mycosmetics_server/src/repositories/skin_profile_repository.dart';
import 'package:mycosmetics_server/src/utils/input_validator.dart';

class SkinAnalysisService {
  final SkinAnalysisRepository _analysis = SkinAnalysisRepository();
  final SkinProfileRepository _profiles = SkinProfileRepository();

  /// Server-side "skin analysis". There is no ML/vision pipeline in this
  /// stack -- the client submits a `skinToneHex` it already picked/derived
  /// (a swatch picker, or on-device extraction from a selfie). All this
  /// does is validate, derive an honest confidence score, persist the
  /// result, and keep the user's SkinProfile in sync.
  ///
  /// confidenceScore formula (0.0 - 1.0), based purely on completeness of
  /// what the client actually supplied -- NOT a fabricated ML confidence:
  ///   - base 0.6 for a valid skinToneHex + undertone (the two required
  ///     fields)
  ///   - +0.15 if brightness was supplied (helps disambiguate similar hues)
  ///   - +0.15 if uniformityScore was supplied (signals a controlled,
  ///     even-lighting capture rather than a guess)
  ///   - +0.10 if deviceModel was supplied (traceability -- lets us later
  ///     correlate low-quality captures with specific hardware)
  /// Capped at 1.0 (base + all three bonuses sums to exactly 1.0).
  static const double _baseConfidence = 0.6;
  static const double _brightnessBonus = 0.15;
  static const double _uniformityBonus = 0.15;
  static const double _deviceBonus = 0.10;

  double _computeConfidence({double? brightness, double? uniformityScore, String? deviceModel}) {
    var score = _baseConfidence;
    if (brightness != null) score += _brightnessBonus;
    if (uniformityScore != null) score += _uniformityBonus;
    if (deviceModel != null && deviceModel.trim().isNotEmpty) score += _deviceBonus;
    return score.clamp(0.0, 1.0);
  }

  Future<SkinAnalysisResult> submit(
    Session session, {
    required int userId,
    required String skinToneHex,
    required String undertone,
    double? brightness,
    double? uniformityScore,
    String? deviceModel,
  }) async {
    InputValidator.validateHexColor(skinToneHex);
    InputValidator.validateUndertone(undertone);
    if (brightness != null) InputValidator.validateFraction(brightness, 'brightness');
    if (uniformityScore != null) InputValidator.validateFraction(uniformityScore, 'uniformityScore');

    final now = DateTime.now().toUtc();
    final confidence = _computeConfidence(
      brightness: brightness,
      uniformityScore: uniformityScore,
      deviceModel: deviceModel,
    );

    // Upsert the profile first so the analysis row can link skinProfileId.
    final existingProfile = await _profiles.findByUserId(session, userId);
    final profile = await _profiles.upsert(
      session,
      (existingProfile ?? SkinProfile(userId: userId, createdAt: now, updatedAt: now)).copyWith(
        skinToneHex: skinToneHex,
        undertone: undertone,
        scannedAt: now,
        updatedAt: now,
      ),
    );

    final result = SkinAnalysisResult(
      userId: userId,
      skinProfileId: profile.id,
      skinToneHex: skinToneHex,
      brightness: brightness ?? 0.0,
      undertone: undertone,
      uniformityScore: uniformityScore ?? 0.0,
      confidenceScore: confidence,
      analyzedAt: now,
      deviceModel: deviceModel,
      createdAt: now,
    );

    return _analysis.insert(session, result);
  }

  Future<SkinAnalysisResult?> latest(Session session, int userId) {
    return _analysis.findLatestByUserId(session, userId);
  }

  Future<List<SkinAnalysisResult>> history(Session session, int userId, {int limit = 20}) {
    return _analysis.findHistoryByUserId(session, userId, limit: limit);
  }
}
