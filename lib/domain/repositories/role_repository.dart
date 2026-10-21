import '../entities/role.dart';

abstract class RoleRepository {
  Future<List<Role>> getAllRoles();
  Future<Role?> getRoleByKey(String key);
  Future<Role?> getRoleById(int id);
}
