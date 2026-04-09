import 'package:lexi_trainer/core/auth/user_role.dart';

class RoleFactory {
  const RoleFactory._();

  static UserRole admin() => UserRole.admin;

  static UserRole teacher() => UserRole.teacher;

  static UserRole student() => UserRole.student;

  static UserRole unknown() => UserRole.unknown;

  static UserRole fromValue(String? value) => UserRole.fromValue(value);
}
