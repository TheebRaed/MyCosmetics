import 'package:serverpod/serverpod.dart';
import 'package:mycosmetics_server/src/generated/protocol.dart';
import 'package:mycosmetics_server/src/business/product_variant_service.dart';
import 'package:mycosmetics_server/src/utils/auth_guard.dart';

class ProductVariantEndpoint extends Endpoint {
  final ProductVariantService _variants = ProductVariantService();

  Future<List<ProductVariant>> listForProduct(Session session, {required int productId}) {
    return _variants.listForProduct(session, productId);
  }

  Future<ProductVariant> create(
    Session session, {
    required String token,
    required int productId,
    required String sku,
    required double price,
    String? shadeName,
    String? hexColor,
    String? size,
    int stockQty = 0,
  }) async {
    await AuthGuard.requireAdminOrStaff(session, token);
    return _variants.create(
      session,
      productId: productId,
      sku: sku,
      price: price,
      shadeName: shadeName,
      hexColor: hexColor,
      size: size,
      stockQty: stockQty,
    );
  }

  Future<ProductVariant> update(
    Session session, {
    required String token,
    required int id,
    double? price,
    int? stockQty,
    String? shadeName,
    String? hexColor,
    String? size,
    bool? isActive,
  }) async {
    await AuthGuard.requireAdminOrStaff(session, token);
    return _variants.update(
      session,
      id: id,
      price: price,
      stockQty: stockQty,
      shadeName: shadeName,
      hexColor: hexColor,
      size: size,
      isActive: isActive,
    );
  }

  Future<void> delete(Session session, {required String token, required int id}) async {
    await AuthGuard.requireAdminOrStaff(session, token);
    await _variants.delete(session, id);
  }
}
