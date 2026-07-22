---
name: backend-beautytech
description: BeautyTech backend vertical (skin profile, skin analysis, saved looks, shade recommendations) -- endpoint signatures, scoring algorithm, and repository patterns
metadata:
  type: project
---

Built the full BeautyTech backend vertical (2026-07-22): SkinProfile, SkinAnalysis, SavedLook, and Recommendation
endpoints/services/repositories, on top of protocol models that already existed and were not touched.

**Why:** BeautyTech had zero endpoint/service code -- only `SkinProfileRepository.findByUserId`/`upsert` existed.
The Flutter agent needs exact signatures next to wire the customer app.

**How to apply:** When extending BeautyTech later (e.g. adding a new score factor, a new saved-look field), reuse
these exact files/signatures rather than re-deriving them -- verify they still exist first per the memory-freshness
rule.

## Files added
- `lib/src/utils/color_matcher.dart` -- pure RGB-space color math, no DB/session dependency.
- `lib/src/business/skin_profile_service.dart` -- defines shared `BeautyTechException` used by all BeautyTech services.
- `lib/src/business/skin_analysis_service.dart`, `lib/src/business/saved_look_service.dart`, `lib/src/business/recommendation_service.dart`
- `lib/src/repositories/skin_analysis_repository.dart`, `saved_look_repository.dart`, `shade_recommendation_repository.dart`, `recommendation_history_repository.dart`, `recommendation_event_repository.dart`, `tryon_event_repository.dart`
- `lib/src/endpoints/skin_profile_endpoint.dart`, `skin_analysis_endpoint.dart`, `saved_look_endpoint.dart`, `recommendation_endpoint.dart`
- Extended `skin_profile_repository.dart` (added `findById`, `delete`) and `category_repository.dart` (added `findByNameCI`, case-insensitive name lookup for `categoryFilter` resolution).

## Endpoint signatures (verbatim, for Flutter wiring)

SkinProfileEndpoint:
- `Future<SkinProfile?> get(Session session)`
- `Future<SkinProfile> save(Session session, {String? skinToneHex, String? undertone, String? concerns})`
- `Future<void> reset(Session session)`

SkinAnalysisEndpoint:
- `Future<SkinAnalysisResult> submit(Session session, {required String skinToneHex, required String undertone, double? brightness, double? uniformityScore, String? deviceModel})`
- `Future<SkinAnalysisResult?> latest(Session session)`
- `Future<List<SkinAnalysisResult>> history(Session session, {int limit = 20})`

SavedLookEndpoint:
- `Future<List<SavedLook>> list(Session session)`
- `Future<SavedLook> create(Session session, {required String name, required String imageUrl, required List<int> appliedVariantIds})`
- `Future<SavedLook> update(Session session, {required int id, String? name, bool? isFavorite})`
- `Future<void> delete(Session session, {required int id})`
- `SavedLook.appliedVariantIds` is comma-joined ints (e.g. `"12,45,7"`) -- `SavedLookService.encodeVariantIds`/`decodeVariantIds` are the canonical (de)serializers; Flutter can also just split on `,` and parse ints itself.

RecommendationEndpoint:
- `Future<RecommendationResult> generate(Session session, {String? categoryFilter})` -- throws `BeautyTechException` if the user's SkinProfile lacks `skinToneHex`/`undertone`, or if `categoryFilter` doesn't match any `Category.name` (case-insensitive).
- `Future<List<RecommendationHistory>> history(Session session, {int limit = 20})`
- `Future<RecommendationEvent> recordEvent(Session session, {required int recommendationId, required RecommendationEventType eventType})`
- `Future<TryOnEvent> recordTryOn(Session session, {required int productVariantId, required String productCategory, required String sessionId})` -- minimal swatch-preview logging, NOT real AR try-on.

## Recommendation engine (rule-based, `engineVersion = 'rule-based-v1'`)

Candidate pool = active `ProductVariant`s with non-null `hexColor`, from active `Product`s (optionally filtered to
one `Category` resolved by case-insensitive name match). Weights (sum to 1.0, named constants in
`recommendation_service.dart`): skinTone 0.40, undertone 0.25, popularity 0.15, userPreference 0.10, tryOnActivity 0.10.
`finalScore = round(weightedSum * 100)`, top 10 persisted as `ShadeRecommendation` rows + one `RecommendationHistory`
row per run.

- `scoreSkinTone`: `ColorMatcher.similarity` -- inverse-normalized Euclidean RGB distance (honest RGB space, not
  perceptual color science -- documented in the file).
- `scoreUndertone`: `ColorMatcher.classifyUndertone(hex)` (warm/cool/neutral from `red - blue` sign, threshold 15)
  compared to the user's stored undertone string: 1.0 exact match, 0.5 if either side is neutral, 0.0 otherwise.
  There is no undertone field on Product/ProductVariant in the schema -- this derivation is necessary, not optional.
- `scorePopularity`: count of `addedToCart`/`purchased` `RecommendationEvent`s (joined via `ShadeRecommendation.productVariantId`,
  all users) + all-user `TryOnEvent` count for that variant, normalized against the pool max.
- `scoreUserPreference`: this user's own net (`addedToCart`+`purchased` minus `dismissed`) `RecommendationEvent`
  history *scoped to the candidate's category name*, squashed onto 0..1 around a 0.5 neutral midpoint (each net
  point shifts by 0.1). 0.5 if the user has no history in that category.
- `scoreTryOnActivity`: this user's own `TryOnEvent` count for that specific variant, normalized against this
  user's own max in the pool.

`reason` string is built from whichever score components are >= 0.5 for that candidate, sorted descending, top 2 --
no generic filler text.

## Data model gotchas discovered
- `Product` has no `category` string field -- only `categoryId` -> `Category.name`. `ShadeRecommendation.category`
  is populated with the resolved `Category.name`, not a raw filter string.
- Neither `Product` nor `ProductVariant` has any undertone-like field -- must derive from `hexColor`.
- `serverpod generate` (run via `dart pub global run serverpod_cli generate` since no `serverpod` binary is on PATH,
  only `serverpod_cli` as a pub global package) only writes under `lib/src/generated/` -- confirmed it did NOT
  create a new migration, since `shade_recommendations`/`saved_looks`/`tryon_events`/`skin_analysis_results`/
  `recommendation_history`/`recommendation_events` tables already existed in migrations
  `00000000000003-beautytech` and `00000000000004-ai-intelligence`.
- Generated `protocol.dart` re-exports a `{ModelName}Repository` class for every table (Serverpod's own generated
  repository, unused in this codebase's convention). Any custom repository file with the same class name needs a
  `hide` clause on the `protocol.dart` import in every file that imports both, or you get `ambiguous_import`
  errors. Pattern already established in `wishlist_service.dart`; had to add `hide` clauses for
  `SkinProfileRepository`, `SkinAnalysisResultRepository`, `SavedLookRepository`, `ShadeRecommendationRepository`,
  `RecommendationHistoryRepository`, `RecommendationEventRepository`, `TryOnEventRepository`, `ProductRepository`,
  `ProductVariantRepository`, `CategoryRepository` as needed.
