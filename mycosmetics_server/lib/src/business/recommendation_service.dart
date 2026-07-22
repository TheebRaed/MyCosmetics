import 'package:serverpod/serverpod.dart';
import 'package:mycosmetics_server/src/generated/protocol.dart'
    hide
        ProductRepository,
        ProductVariantRepository,
        CategoryRepository,
        ShadeRecommendationRepository,
        RecommendationHistoryRepository,
        RecommendationEventRepository,
        TryOnEventRepository;
import 'package:mycosmetics_server/src/repositories/shade_recommendation_repository.dart';
import 'package:mycosmetics_server/src/repositories/recommendation_history_repository.dart';
import 'package:mycosmetics_server/src/repositories/recommendation_event_repository.dart';
import 'package:mycosmetics_server/src/repositories/tryon_event_repository.dart';
import 'package:mycosmetics_server/src/repositories/product_repository.dart';
import 'package:mycosmetics_server/src/repositories/product_variant_repository.dart';
import 'package:mycosmetics_server/src/repositories/category_repository.dart';
import 'package:mycosmetics_server/src/business/skin_profile_service.dart';
import 'package:mycosmetics_server/src/utils/color_matcher.dart';

/// Rule-based shade recommendation engine. No ML model, no third-party
/// service -- every score component is computed from real rows already in
/// this database (catalog data + this user's / all users' recorded
/// events), or from a documented color-math heuristic. `engineVersion`
/// below should be bumped whenever the weights or scoring formulas change,
/// so RecommendationHistory rows stay attributable to a specific algorithm
/// version.
class RecommendationService {
  static const String engineVersion = 'rule-based-v1';

  /// Weighted-sum weights for the final 0-100 match score. Sum to 1.0.
  /// Skin tone gets the largest weight because color-distance is the most
  /// direct, least-noisy signal we have; undertone is a strong secondary
  /// signal; the remaining three (popularity / this user's own preference /
  /// this user's own try-on activity) are behavioral signals that matter
  /// less than the two color-derived signals but still meaningfully
  /// re-rank close calls.
  static const double _wSkinTone = 0.40;
  static const double _wUndertone = 0.25;
  static const double _wPopularity = 0.15;
  static const double _wUserPreference = 0.10;
  static const double _wTryOnActivity = 0.10;

  static const int _topN = 10;

  final ShadeRecommendationRepository _recs = ShadeRecommendationRepository();
  final RecommendationHistoryRepository _history = RecommendationHistoryRepository();
  final RecommendationEventRepository _events = RecommendationEventRepository();
  final TryOnEventRepository _tryOnEvents = TryOnEventRepository();
  final ProductRepository _products = ProductRepository();
  final ProductVariantRepository _variants = ProductVariantRepository();
  final CategoryRepository _categories = CategoryRepository();
  final SkinProfileService _profiles = SkinProfileService();

  Future<RecommendationResult> generate(
    Session session, {
    required int userId,
    String? categoryFilter,
  }) async {
    final profile = await _profiles.requireCompleteProfile(session, userId);
    final userHex = profile.skinToneHex!;
    final userUndertone = profile.undertone!;

    int? categoryId;
    if (categoryFilter != null && categoryFilter.trim().isNotEmpty) {
      final category = await _categories.findByNameCI(session, categoryFilter);
      if (category == null) {
        throw BeautyTechException('Unknown category filter: "$categoryFilter".');
      }
      categoryId = category.id;
    }

    // Candidate pool: active products (optionally scoped to one category),
    // then their active variants that actually have a hexColor to match
    // against. pageSize is generous (500) since this is a rule-based scan,
    // not a paginated listing -- fine for this catalog's scale.
    final products = await _products.list(
      session,
      ProductFilter(categoryId: categoryId),
      sortBy: ProductSortBy.newest,
      page: 0,
      pageSize: 500,
    );

    final categoryNameCache = <int, String>{};
    final candidates = <_Candidate>[];
    for (final product in products) {
      final categoryName = categoryNameCache[product.categoryId] ??=
          (await _categories.findById(session, product.categoryId))?.name ?? 'Uncategorized';
      final variants = await _variants.listForProduct(session, product.id!, activeOnly: true);
      for (final variant in variants) {
        if (variant.hexColor == null) continue;
        candidates.add(_Candidate(product: product, variant: variant, categoryName: categoryName));
      }
    }

    if (candidates.isEmpty) {
      throw BeautyTechException('No matching products with shade colors are available right now.');
    }

    final variantIds = candidates.map((c) => c.variant.id!).toSet();

    // Popularity: addedToCart/purchased events (all users) + try-on events
    // (all users) per variant, normalized against the max in this pool.
    final popularityRecs = await _recs.listByVariantIds(session, variantIds);
    final recIdToVariantId = {for (final r in popularityRecs) r.id!: r.productVariantId};
    final popularityEvents = await _events.listForRecommendations(
      session,
      recIdToVariantId.keys.toSet(),
      types: {RecommendationEventType.addedToCart, RecommendationEventType.purchased},
    );
    final allTryOns = await _tryOnEvents.listForVariants(session, variantIds);
    final rawPopularity = <int, int>{};
    for (final e in popularityEvents) {
      final variantId = recIdToVariantId[e.recommendationId];
      if (variantId != null) rawPopularity[variantId] = (rawPopularity[variantId] ?? 0) + 1;
    }
    for (final e in allTryOns) {
      rawPopularity[e.productVariantId] = (rawPopularity[e.productVariantId] ?? 0) + 1;
    }
    final maxPopularity = rawPopularity.values.isEmpty ? 0 : rawPopularity.values.reduce((a, b) => a > b ? a : b);

    // This user's own try-on activity per variant, normalized against this
    // user's own max in the pool.
    final userTryOns = await _tryOnEvents.listForUserAndVariants(session, userId, variantIds);
    final rawUserTryOn = <int, int>{};
    for (final e in userTryOns) {
      rawUserTryOn[e.productVariantId] = (rawUserTryOn[e.productVariantId] ?? 0) + 1;
    }
    final maxUserTryOn = rawUserTryOn.values.isEmpty ? 0 : rawUserTryOn.values.reduce((a, b) => a > b ? a : b);

    // This user's own preference history, scoped per category present in
    // the candidate pool: net of (addedToCart + purchased) minus dismissed,
    // mapped onto 0.0-1.0 with 0.5 as the neutral "no history" baseline.
    final categoryNames = candidates.map((c) => c.categoryName).toSet();
    final userPreferenceByCategory = <String, double>{};
    for (final categoryName in categoryNames) {
      final categoryRecs = await _recs.listByCategory(session, categoryName);
      final categoryRecIds = categoryRecs.map((r) => r.id!).toSet();
      final userEvents = await _events.listForUserAndRecommendations(session, userId, categoryRecIds);
      if (userEvents.isEmpty) {
        userPreferenceByCategory[categoryName] = 0.5;
        continue;
      }
      var positive = 0;
      var negative = 0;
      for (final e in userEvents) {
        if (e.eventType == RecommendationEventType.addedToCart || e.eventType == RecommendationEventType.purchased) {
          positive++;
        } else if (e.eventType == RecommendationEventType.dismissed) {
          negative++;
        }
      }
      final net = positive - negative;
      // Squash net score into 0..1 around a 0.5 midpoint; every net point
      // shifts the score by 0.1, capped at the edges.
      userPreferenceByCategory[categoryName] = (0.5 + net * 0.1).clamp(0.0, 1.0);
    }

    // Score every candidate.
    final scored = <_ScoredCandidate>[];
    for (final c in candidates) {
      final scoreSkinTone = ColorMatcher.similarity(userHex, c.variant.hexColor!);
      final scoreUndertone = _undertoneScore(userUndertone, c.variant.hexColor!);
      final scorePopularity = maxPopularity == 0 ? 0.0 : (rawPopularity[c.variant.id!] ?? 0) / maxPopularity;
      final scoreUserPreference = userPreferenceByCategory[c.categoryName] ?? 0.5;
      final scoreTryOnActivity = maxUserTryOn == 0 ? 0.0 : (rawUserTryOn[c.variant.id!] ?? 0) / maxUserTryOn;

      final weighted = _wSkinTone * scoreSkinTone +
          _wUndertone * scoreUndertone +
          _wPopularity * scorePopularity +
          _wUserPreference * scoreUserPreference +
          _wTryOnActivity * scoreTryOnActivity;
      final finalScore = (weighted * 100).round().clamp(0, 100);

      scored.add(_ScoredCandidate(
        candidate: c,
        scoreSkinTone: scoreSkinTone,
        scoreUndertone: scoreUndertone,
        scorePopularity: scorePopularity,
        scoreUserPreference: scoreUserPreference,
        scoreTryOnActivity: scoreTryOnActivity,
        finalScore: finalScore,
      ));
    }

    scored.sort((a, b) => b.finalScore.compareTo(a.finalScore));
    final top = scored.take(_topN).toList();

    final now = DateTime.now().toUtc();
    final historyRow = await _history.insert(
      session,
      RecommendationHistory(
        userId: userId,
        skinProfileId: profile.id!,
        engineVersion: engineVersion,
        totalGenerated: top.length,
        categoryFilter: categoryFilter,
        triggeredBy: 'user',
        createdAt: now,
      ),
    );

    final details = <ShadeRecommendationDetail>[];
    for (final s in top) {
      final rec = await _recs.insert(
        session,
        ShadeRecommendation(
          userId: userId,
          skinProfileId: profile.id!,
          productVariantId: s.candidate.variant.id!,
          historyId: historyRow.id,
          category: s.candidate.categoryName,
          confidenceScore: s.finalScore / 100.0,
          reason: _buildReason(s),
          scoreSkinTone: s.scoreSkinTone,
          scoreUndertone: s.scoreUndertone,
          scorePopularity: s.scorePopularity,
          scoreUserPreference: s.scoreUserPreference,
          scoreTryOnActivity: s.scoreTryOnActivity,
          createdAt: now,
        ),
      );
      details.add(ShadeRecommendationDetail(
        recommendation: rec,
        variantName: s.candidate.variant.shadeName,
        productName: s.candidate.product.name,
        hexColor: s.candidate.variant.hexColor,
        imageUrl: null,
        scoreBreakdown: ScoreBreakdown(
          skinTone: s.scoreSkinTone,
          undertone: s.scoreUndertone,
          popularity: s.scorePopularity,
          userPreference: s.scoreUserPreference,
          tryOnActivity: s.scoreTryOnActivity,
          finalScore: s.finalScore,
        ),
      ));
    }

    return RecommendationResult(
      skinProfile: profile,
      recommendations: details,
      historyId: historyRow.id!,
    );
  }

  /// 1.0 if the variant's color-derived undertone matches the user's
  /// stored undertone exactly, 0.5 partial credit if either side is
  /// 'neutral' (neutral pairs reasonably with anything), 0.0 otherwise
  /// (warm vs cool -- a real mismatch).
  double _undertoneScore(String userUndertone, String variantHex) {
    final variantUndertone = ColorMatcher.classifyUndertone(variantHex);
    if (variantUndertone == userUndertone) return 1.0;
    if (variantUndertone == 'neutral' || userUndertone == 'neutral') return 0.5;
    return 0.0;
  }

  /// Builds a short, honest, human-readable explanation from whichever
  /// score components actually scored highest for this candidate -- no
  /// generic filler text.
  String _buildReason(_ScoredCandidate s) {
    final parts = <MapEntry<String, double>>[
      MapEntry('a close match to your skin tone', s.scoreSkinTone),
      MapEntry('your ${s.candidate.categoryName.toLowerCase()} undertone preference', s.scoreUndertone),
      MapEntry('strong popularity among other shoppers', s.scorePopularity),
      MapEntry('shades you\'ve liked before', s.scoreUserPreference),
      MapEntry('shades you\'ve previewed before', s.scoreTryOnActivity),
    ]..sort((a, b) => b.value.compareTo(a.value));

    final top = parts.where((p) => p.value >= 0.5).take(2).map((p) => p.key).toList();
    if (top.isEmpty) return 'A reasonable option based on your profile.';
    return 'Recommended for ${top.join(' and ')}.';
  }

  Future<List<RecommendationHistory>> history(Session session, int userId, {int limit = 20}) {
    return _history.listForUser(session, userId, limit: limit);
  }

  Future<RecommendationEvent> recordEvent(
    Session session, {
    required int userId,
    required int recommendationId,
    required RecommendationEventType eventType,
  }) async {
    final rec = await _recs.findById(session, recommendationId);
    if (rec == null || rec.userId != userId) {
      throw BeautyTechException('Recommendation not found.');
    }
    return _events.insert(
      session,
      RecommendationEvent(
        userId: userId,
        recommendationId: recommendationId,
        eventType: eventType,
        createdAt: DateTime.now().toUtc(),
      ),
    );
  }

  /// Minimal "digital swatch preview" logging -- NOT real AR try-on, no
  /// image processing. Just records that the user previewed a variant, so
  /// scoreTryOnActivity has real data to work with.
  Future<TryOnEvent> recordTryOn(
    Session session, {
    required int userId,
    required int productVariantId,
    required String productCategory,
    required String sessionId,
  }) {
    return _tryOnEvents.insert(
      session,
      TryOnEvent(
        userId: userId,
        productVariantId: productVariantId,
        productCategory: productCategory,
        sessionId: sessionId,
        createdAt: DateTime.now().toUtc(),
      ),
    );
  }
}

class _Candidate {
  final Product product;
  final ProductVariant variant;
  final String categoryName;
  _Candidate({required this.product, required this.variant, required this.categoryName});
}

class _ScoredCandidate {
  final _Candidate candidate;
  final double scoreSkinTone;
  final double scoreUndertone;
  final double scorePopularity;
  final double scoreUserPreference;
  final double scoreTryOnActivity;
  final int finalScore;

  _ScoredCandidate({
    required this.candidate,
    required this.scoreSkinTone,
    required this.scoreUndertone,
    required this.scorePopularity,
    required this.scoreUserPreference,
    required this.scoreTryOnActivity,
    required this.finalScore,
  });
}
