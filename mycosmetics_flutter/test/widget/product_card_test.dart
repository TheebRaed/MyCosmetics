import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mycosmetics_client/mycosmetics_client.dart';
import 'package:mycosmetics_flutter/shared/widgets/product_card.dart';

// Widget tests for the shared ProductCard rail tile: discount badge
// presence/absence and correct price/name/brand rendering.

void main() {
  group('ProductCard', () {
    testWidgets('renders discount badge and correct percentage when product has a discount', (tester) async {
      final product = _product(name: 'Matte Lipstick', basePrice: 24.0, discountPercent: 20);
      await tester.pumpWidget(_wrap(ProductCard(product: product)));
      await tester.pump();

      expect(find.text('-20%'), findsOneWidget);
      expect(find.text('Matte Lipstick'), findsOneWidget);
      expect(find.text('GlowCo'), findsOneWidget);
      expect(find.text('\$24.00'), findsOneWidget);
    });

    testWidgets('renders normal price with no badge when product has no discount', (tester) async {
      final product = _product(name: 'Glow Serum', basePrice: 39.5, discountPercent: null);
      await tester.pumpWidget(_wrap(ProductCard(product: product)));
      await tester.pump();

      expect(find.textContaining('%'), findsNothing);
      expect(find.text('Glow Serum'), findsOneWidget);
      expect(find.text('\$39.50'), findsOneWidget);
    });

    testWidgets('renders no badge when discountPercent is zero', (tester) async {
      final product = _product(name: 'Cleanser', basePrice: 10.0, discountPercent: 0);
      await tester.pumpWidget(_wrap(ProductCard(product: product)));
      await tester.pump();

      expect(find.textContaining('%'), findsNothing);
    });

    testWidgets('shows rating when ratingCount > 0, hides it when zero', (tester) async {
      final withRating = _product(name: 'Rated Product', basePrice: 15.0, ratingCount: 3, ratingAvg: 4.5);
      await tester.pumpWidget(_wrap(ProductCard(product: withRating)));
      await tester.pump();
      expect(find.text('4.5'), findsOneWidget);

      final noRating = _product(name: 'Unrated Product', basePrice: 15.0);
      await tester.pumpWidget(_wrap(ProductCard(product: noRating)));
      await tester.pump();
      expect(find.text('0.0'), findsNothing);
    });

    testWidgets('tapping the card invokes onTap', (tester) async {
      var tapped = false;
      final product = _product(name: 'Tap Me', basePrice: 5.0);
      await tester.pumpWidget(_wrap(ProductCard(product: product, onTap: () => tapped = true)));
      await tester.pump();

      await tester.tap(find.text('Tap Me'));
      await tester.pump();
      expect(tapped, isTrue);
    });
  });
}

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

ProductDetail _product({
  required String name,
  required double basePrice,
  double? discountPercent,
  int ratingCount = 0,
  double ratingAvg = 0,
}) {
  final now = DateTime(2026, 1, 1);
  return ProductDetail(
    product: Product(
      id: 1,
      categoryId: 1,
      brandId: 1,
      name: name,
      slug: name.toLowerCase().replaceAll(' ', '-'),
      description: 'A great product',
      basePrice: basePrice,
      discountPercent: discountPercent,
      ratingCount: ratingCount,
      ratingAvg: ratingAvg,
      createdAt: now,
      updatedAt: now,
    ),
    variants: const [],
    images: const [],
    brandName: 'GlowCo',
    categoryName: 'Skincare',
  );
}
