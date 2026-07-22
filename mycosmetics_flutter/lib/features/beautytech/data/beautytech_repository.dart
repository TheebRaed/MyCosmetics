import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mycosmetics_client/mycosmetics_client.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/network/api_client.dart';

part 'beautytech_repository.g.dart';

/// Thin wrapper around `client.skinProfile`/`client.skinAnalysis`/
/// `client.savedLook`/`client.recommendation` -- see
/// mycosmetics_server/lib/src/endpoints/{skin_profile,skin_analysis,
/// saved_look,recommendation}_endpoint.dart.
///
/// Naming note (honesty framing, see CLAUDE.md task brief): there is no
/// ML/vision pipeline behind "skin analysis" -- it's the user picking a
/// skin-tone swatch + undertone, submitted for scoring. Copy in the UI
/// layer calls this a "skin tone scan", never "AI analysis". The
/// recommendation match score IS a real rule-based calculation (color
/// distance + real usage signals), so `ScoreBreakdown.finalScore` is shown
/// verbatim as a genuine match percentage.
///
/// `skinAnalysis.submit()` already upserts the user's `SkinProfile` server
/// side (see skin_analysis_service.dart -- it calls the same repository
/// `SkinProfileRepository.upsert` under the hood), so a separate
/// `skinProfile.save()` call is only needed to persist `concerns` text,
/// which `submit()` does not accept.
class BeautyTechRepository {
  BeautyTechRepository(this._client);

  final Client _client;

  Future<SkinProfile?> getProfile() => _client.skinProfile.get();

  Future<SkinProfile> saveProfile({String? skinToneHex, String? undertone, String? concerns}) =>
      _client.skinProfile.save(skinToneHex: skinToneHex, undertone: undertone, concerns: concerns);

  Future<void> resetProfile() => _client.skinProfile.reset();

  Future<SkinAnalysisResult> submitScan({
    required String skinToneHex,
    required String undertone,
    double? brightness,
    double? uniformityScore,
    String? deviceModel,
  }) =>
      _client.skinAnalysis.submit(
        skinToneHex: skinToneHex,
        undertone: undertone,
        brightness: brightness,
        uniformityScore: uniformityScore,
        deviceModel: deviceModel,
      );

  Future<SkinAnalysisResult?> latestScan() => _client.skinAnalysis.latest();

  Future<List<SkinAnalysisResult>> scanHistory({int limit = 20}) => _client.skinAnalysis.history(limit: limit);

  Future<List<SavedLook>> listSavedLooks() => _client.savedLook.list();

  Future<SavedLook> createSavedLook({
    required String name,
    required String imageUrl,
    required List<int> appliedVariantIds,
  }) =>
      _client.savedLook.create(name: name, imageUrl: imageUrl, appliedVariantIds: appliedVariantIds);

  Future<SavedLook> updateSavedLook({required int id, String? name, bool? isFavorite}) =>
      _client.savedLook.update(id: id, name: name, isFavorite: isFavorite);

  Future<void> deleteSavedLook(int id) => _client.savedLook.delete(id: id);

  Future<RecommendationResult> generateRecommendations({String? categoryFilter}) =>
      _client.recommendation.generate(categoryFilter: categoryFilter);

  Future<List<RecommendationHistory>> recommendationHistory({int limit = 20}) =>
      _client.recommendation.history(limit: limit);

  Future<RecommendationEvent> recordEvent({required int recommendationId, required RecommendationEventType eventType}) =>
      _client.recommendation.recordEvent(recommendationId: recommendationId, eventType: eventType);
}

@riverpod
BeautyTechRepository beautyTechRepository(Ref ref) => BeautyTechRepository(ref.watch(apiClientProvider));

/// Splits `SavedLook.appliedVariantIds` (a comma-joined string of ints,
/// e.g. "12,45,7" -- see CLAUDE.md task brief) into a `List<int>`.
List<int> parseAppliedVariantIds(String csv) {
  if (csv.trim().isEmpty) return const [];
  return csv.split(',').map((s) => int.tryParse(s.trim())).whereType<int>().toList();
}
