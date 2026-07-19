import 'package:serverpod/serverpod.dart';
import 'package:mycosmetics_server/src/generated/protocol.dart';
import 'package:mycosmetics_server/src/business/brand_service.dart';
import 'package:mycosmetics_server/src/utils/auth_guard.dart';

class BrandEndpoint extends Endpoint {
  final BrandService _brands = BrandService();

  Future<List<Brand>> listAll(Session session) {
    return _brands.listAll(session);
  }

  Future<Brand> create(
    Session session, {
    required String token,
    required String name,
    required String slug,
    String? logoUrl,
    String? description,
  }) async {
    await AuthGuard.requireAdminOrStaff(session, token);
    return _brands.create(session, name: name, slug: slug, logoUrl: logoUrl, description: description);
  }

  Future<Brand> update(
    Session session, {
    required String token,
    required int id,
    String? name,
    String? logoUrl,
    String? description,
    bool? isActive,
  }) async {
    await AuthGuard.requireAdminOrStaff(session, token);
    return _brands.update(
      session,
      id: id,
      name: name,
      logoUrl: logoUrl,
      description: description,
      isActive: isActive,
    );
  }

  Future<void> delete(Session session, {required String token, required int id}) async {
    await AuthGuard.requireAdminOrStaff(session, token);
    await _brands.delete(session, id);
  }
}
