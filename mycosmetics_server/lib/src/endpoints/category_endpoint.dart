import 'package:serverpod/serverpod.dart';
import 'package:mycosmetics_server/src/generated/protocol.dart';
import 'package:mycosmetics_server/src/business/category_service.dart';
import 'package:mycosmetics_server/src/utils/auth_guard.dart';

class CategoryEndpoint extends Endpoint {
  final CategoryService _categories = CategoryService();

  Future<List<Category>> listTopLevel(Session session) {
    return _categories.listTopLevel(session);
  }

  Future<List<Category>> listSubCategories(Session session, {required int parentId}) {
    return _categories.listSubCategories(session, parentId);
  }

  Future<Category> create(
    Session session, {
    required String name,
    required String slug,
    int? parentId,
    String? imageUrl,
    int sortOrder = 0,
  }) async {
    await AuthGuard.requireAdminOrStaff(session);
    return _categories.create(
      session,
      name: name,
      slug: slug,
      parentId: parentId,
      imageUrl: imageUrl,
      sortOrder: sortOrder,
    );
  }

  Future<Category> update(
    Session session, {
    required int id,
    String? name,
    String? imageUrl,
    int? sortOrder,
    bool? isActive,
  }) async {
    await AuthGuard.requireAdminOrStaff(session);
    return _categories.update(
      session,
      id: id,
      name: name,
      imageUrl: imageUrl,
      sortOrder: sortOrder,
      isActive: isActive,
    );
  }

  Future<void> delete(Session session, {required int id}) async {
    await AuthGuard.requireAdminOrStaff(session);
    await _categories.delete(session, id);
  }
}
