import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mycosmetics_client/mycosmetics_client.dart';
import 'package:mycosmetics_flutter/features/home/presentation/widgets/category_chips.dart';
import 'package:mycosmetics_flutter/features/home/presentation/widgets/home_section.dart';

// Widget tests for the Home tab sections (HomeProductSection, CategoryChips).
//
// Both widgets take their data as a plain `AsyncValue` constructor parameter
// rather than watching a provider internally, so these tests exercise the
// loading/empty/error/data states directly -- no ProviderScope overrides or
// generated-client mocking needed (matching this repo's lightweight
// widget-test style established in auth_screens_test.dart).

void main() {
  group('HomeProductSection', () {
    testWidgets('loading state shows skeleton placeholders, not data or error UI', (tester) async {
      await tester.pumpWidget(_wrap(
        HomeProductSection(
          title: 'New Arrivals',
          asyncProducts: const AsyncValue.loading(),
          onRetry: () {},
          emptyMessage: 'No new arrivals yet -- check back soon.',
        ),
      ));
      await tester.pump();

      expect(find.text('New Arrivals'), findsOneWidget);
      expect(find.text('No new arrivals yet -- check back soon.'), findsNothing);
      expect(find.text("Couldn't load this section"), findsNothing);
    });

    testWidgets('empty state shows the empty message', (tester) async {
      await tester.pumpWidget(_wrap(
        HomeProductSection(
          title: 'Best Sellers',
          asyncProducts: const AsyncValue.data(<ProductDetail>[]),
          onRetry: () {},
          emptyMessage: 'No best sellers yet.',
        ),
      ));
      await tester.pump();

      expect(find.text('No best sellers yet.'), findsOneWidget);
    });

    testWidgets('error state shows retry affordance and invokes onRetry when tapped', (tester) async {
      var retried = false;
      await tester.pumpWidget(_wrap(
        HomeProductSection(
          title: 'Featured',
          asyncProducts: AsyncValue<List<ProductDetail>>.error(Exception('boom'), StackTrace.empty),
          onRetry: () => retried = true,
          emptyMessage: 'No featured products yet.',
        ),
      ));
      await tester.pump();

      expect(find.text("Couldn't load this section"), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);

      await tester.tap(find.text('Retry'));
      await tester.pump();
      expect(retried, isTrue);
    });

    testWidgets('data state renders one product tile per item', (tester) async {
      final items = [_product(id: 1, name: 'Matte Lipstick'), _product(id: 2, name: 'Glow Serum')];
      await tester.pumpWidget(_wrap(
        HomeProductSection(
          title: 'Recently Viewed',
          asyncProducts: AsyncValue.data(items),
          onRetry: () {},
          emptyMessage: 'Products you view will show up here.',
        ),
      ));
      await tester.pump();

      expect(find.text('Matte Lipstick'), findsOneWidget);
      expect(find.text('Glow Serum'), findsOneWidget);
      expect(find.text('Products you view will show up here.'), findsNothing);
    });

    testWidgets('tapping a product tile invokes onProductTap with that product', (tester) async {
      ProductDetail? tapped;
      final item = _product(id: 42, name: 'Vitamin C Serum');
      await tester.pumpWidget(_wrap(
        HomeProductSection(
          title: 'Featured',
          asyncProducts: AsyncValue.data([item]),
          onRetry: () {},
          emptyMessage: 'No featured products yet.',
          onProductTap: (p) => tapped = p,
        ),
      ));
      await tester.pump();

      await tester.tap(find.text('Vitamin C Serum'));
      await tester.pump();

      expect(tapped?.product.id, 42);
    });
  });

  group('CategoryChips', () {
    testWidgets('loading state shows a progress indicator', (tester) async {
      await tester.pumpWidget(_wrap(
        CategoryChips(asyncCategories: const AsyncValue.loading(), onRetry: () {}),
      ));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('empty state shows "No categories yet"', (tester) async {
      await tester.pumpWidget(_wrap(
        CategoryChips(asyncCategories: const AsyncValue.data(<Category>[]), onRetry: () {}),
      ));
      await tester.pump();

      expect(find.text('No categories yet'), findsOneWidget);
    });

    testWidgets('error state shows retry text and invokes onRetry when tapped', (tester) async {
      var retried = false;
      await tester.pumpWidget(_wrap(
        CategoryChips(
          asyncCategories: AsyncValue<List<Category>>.error(Exception('boom'), StackTrace.empty),
          onRetry: () => retried = true,
        ),
      ));
      await tester.pump();

      expect(find.textContaining("Couldn't load categories"), findsOneWidget);
      await tester.tap(find.textContaining("Couldn't load categories"));
      await tester.pump();
      expect(retried, isTrue);
    });

    testWidgets('data state renders a chip per category', (tester) async {
      final categories = [_category(id: 1, name: 'Skincare'), _category(id: 2, name: 'Makeup')];
      await tester.pumpWidget(_wrap(
        CategoryChips(asyncCategories: AsyncValue.data(categories), onRetry: () {}),
      ));
      await tester.pump();

      expect(find.text('Skincare'), findsOneWidget);
      expect(find.text('Makeup'), findsOneWidget);
    });
  });
}

Widget _wrap(Widget child) {
  return ProviderScope(
    child: MaterialApp(home: Scaffold(body: child)),
  );
}

ProductDetail _product({required int id, required String name, double? discountPercent}) {
  final now = DateTime(2026, 1, 1);
  return ProductDetail(
    product: Product(
      id: id,
      categoryId: 1,
      brandId: 1,
      name: name,
      slug: name.toLowerCase().replaceAll(' ', '-'),
      description: 'A great product',
      basePrice: 19.99,
      discountPercent: discountPercent,
      createdAt: now,
      updatedAt: now,
    ),
    variants: const [],
    images: const [],
    brandName: 'GlowCo',
    categoryName: 'Skincare',
  );
}

Category _category({required int id, required String name}) {
  final now = DateTime(2026, 1, 1);
  return Category(
    id: id,
    name: name,
    slug: name.toLowerCase(),
    createdAt: now,
    updatedAt: now,
  );
}
