import 'package:serverpod/serverpod.dart';
import 'package:mycosmetics_server/src/generated/protocol.dart';
import 'package:mycosmetics_server/src/business/product_image_service.dart';
import 'package:mycosmetics_server/src/utils/auth_guard.dart';

class ProductImageEndpoint extends Endpoint {
  final ProductImageService _images = ProductImageService();

  Future<List<ProductImage>> listForProduct(Session session, {required int productId}) {
    return _images.listForProduct(session, productId);
  }

  /// Client uploads image bytes via Serverpod's file/storage API separately,
  /// then calls this with the resulting public URL to attach it to the product.
  Future<ProductImage> add(
    Session session, {
    required String token,
    required int productId,
    required String url,
    int? variantId,
    int sortOrder = 0,
  }) async {
    await AuthGuard.requireAdminOrStaff(session, token);
    return _images.add(session, productId: productId, url: url, variantId: variantId, sortOrder: sortOrder);
  }

  Future<void> delete(Session session, {required String token, required int id, required int productId}) async {
    await AuthGuard.requireAdminOrStaff(session, token);
    await _images.delete(session, id: id, productId: productId);
  }
}
