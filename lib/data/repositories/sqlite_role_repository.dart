import '../../domain/entities/role.dart';
import '../../domain/repositories/role_repository.dart';
import '../../domain/roles/role_registry.dart';
import '../database/database_service.dart';

class SqliteRoleRepository implements RoleRepository {
  @override
  Future<List<Role>> getAllRoles() async {
    final db = await DatabaseService.database;
    final maps = await db.query('roles', orderBy: 'night_order ASC, id ASC');

    return maps.map((m) {
      final key = m['key'] as String;
      final behavior = RoleRegistry.get(key);
      return Role.fromMap(m, customDescription: behavior?.description);
    }).toList();
  }

  @override
  Future<Role?> getRoleByKey(String key) async {
    final db = await DatabaseService.database;
    final maps = await db.query(
      'roles',
      where: 'key = ?',
      whereArgs: [key.toLowerCase()],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    final behavior = RoleRegistry.get(key);
    return Role.fromMap(maps.first, customDescription: behavior?.description);
  }

  @override
  Future<Role?> getRoleById(int id) async {
    final db = await DatabaseService.database;
    final maps = await db.query(
      'roles',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    final key = maps.first['key'] as String;
    final behavior = RoleRegistry.get(key);
    return Role.fromMap(maps.first, customDescription: behavior?.description);
  }
}
