import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mycosmetics_client/mycosmetics_client.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/beautytech_repository.dart';

part 'beautytech_providers.g.dart';

/// The user's skin profile (null if never scanned). Drives the "set up vs
/// not" status on the Beauty tab home.
@riverpod
class SkinProfileController extends _$SkinProfileController {
  @override
  Future<SkinProfile?> build() => ref.watch(beautyTechRepositoryProvider).getProfile();

  /// Runs the "skin tone scan" -- submits the picked swatch + undertone for
  /// scoring, then refreshes the profile (submit() upserts it server-side).
  Future<String?> submitScan({
    required String skinToneHex,
    required String undertone,
    String? concerns,
  }) async {
    try {
      final repo = ref.read(beautyTechRepositoryProvider);
      await repo.submitScan(skinToneHex: skinToneHex, undertone: undertone);
      // `submit()` doesn't accept `concerns` -- persist it via `save()` if
      // supplied (see beautytech_repository.dart doc comment).
      if (concerns != null && concerns.trim().isNotEmpty) {
        await repo.saveProfile(concerns: concerns.trim());
      }
      final profile = await repo.getProfile();
      state = AsyncData(profile);
      return null;
    } catch (e) {
      return friendlyBeautyTechErrorMessage(e);
    }
  }

  Future<String?> reset() async {
    try {
      await ref.read(beautyTechRepositoryProvider).resetProfile();
      state = const AsyncData(null);
      return null;
    } catch (e) {
      return friendlyBeautyTechErrorMessage(e);
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = AsyncData(await ref.read(beautyTechRepositoryProvider).getProfile());
  }
}

@riverpod
Future<SkinAnalysisResult?> latestScan(Ref ref) => ref.watch(beautyTechRepositoryProvider).latestScan();

@riverpod
Future<List<SkinAnalysisResult>> scanHistory(Ref ref, {int limit = 20}) =>
    ref.watch(beautyTechRepositoryProvider).scanHistory(limit: limit);

@riverpod
class RecommendationController extends _$RecommendationController {
  @override
  Future<RecommendationResult?> build() async => null;

  Future<String?> generate({String? categoryFilter}) async {
    state = const AsyncLoading();
    try {
      final result = await ref.read(beautyTechRepositoryProvider).generateRecommendations(categoryFilter: categoryFilter);
      state = AsyncData(result);
      return null;
    } catch (e) {
      state = const AsyncData(null);
      return friendlyBeautyTechErrorMessage(e);
    }
  }

  Future<void> recordViewed(int recommendationId) async {
    try {
      await ref.read(beautyTechRepositoryProvider).recordEvent(
            recommendationId: recommendationId,
            eventType: RecommendationEventType.viewed,
          );
    } catch (_) {
      // Best-effort telemetry -- a failed "viewed" event shouldn't block the
      // user from seeing/using the recommendation.
    }
  }
}

@riverpod
Future<List<RecommendationHistory>> recommendationHistory(Ref ref, {int limit = 20}) =>
    ref.watch(beautyTechRepositoryProvider).recommendationHistory(limit: limit);

@riverpod
class SavedLooksController extends _$SavedLooksController {
  @override
  Future<List<SavedLook>> build() => ref.watch(beautyTechRepositoryProvider).listSavedLooks();

  Future<String?> create({required String name, required String imageUrl, required List<int> appliedVariantIds}) async {
    try {
      await ref.read(beautyTechRepositoryProvider).createSavedLook(
            name: name,
            imageUrl: imageUrl,
            appliedVariantIds: appliedVariantIds,
          );
      state = AsyncData(await ref.read(beautyTechRepositoryProvider).listSavedLooks());
      return null;
    } catch (e) {
      return friendlyBeautyTechErrorMessage(e);
    }
  }

  Future<String?> toggleFavorite(SavedLook look) async {
    try {
      await ref.read(beautyTechRepositoryProvider).updateSavedLook(id: look.id!, isFavorite: !look.isFavorite);
      state = AsyncData(await ref.read(beautyTechRepositoryProvider).listSavedLooks());
      return null;
    } catch (e) {
      return friendlyBeautyTechErrorMessage(e);
    }
  }

  Future<String?> rename(SavedLook look, String newName) async {
    try {
      await ref.read(beautyTechRepositoryProvider).updateSavedLook(id: look.id!, name: newName);
      state = AsyncData(await ref.read(beautyTechRepositoryProvider).listSavedLooks());
      return null;
    } catch (e) {
      return friendlyBeautyTechErrorMessage(e);
    }
  }

  Future<String?> delete(int id) async {
    try {
      await ref.read(beautyTechRepositoryProvider).deleteSavedLook(id);
      state = AsyncData(await ref.read(beautyTechRepositoryProvider).listSavedLooks());
      return null;
    } catch (e) {
      return friendlyBeautyTechErrorMessage(e);
    }
  }
}

/// Same approach as `friendlyCartErrorMessage`/`friendlyAuthErrorMessage --
/// strips Serverpod's exception-class prefix so validation messages (e.g.
/// invalid hex/undertone from `InputValidator`) read cleanly.
String friendlyBeautyTechErrorMessage(Object e) {
  final raw = e.toString();
  if (raw.contains('Internal server error')) {
    return 'Something went wrong. Please try again.';
  }
  final match = RegExp(r'^ServerpodClientException:\s*(.*?),\s*statusCode').firstMatch(raw);
  return match?.group(1) ?? 'Something went wrong. Please try again.';
}
