import 'package:lexi_trainer/core/auth/user_role.dart';

abstract class AuthRoleSource {
  Future<UserRole> currentRole();
}

class FakeAuthRoleSource implements AuthRoleSource {
  FakeAuthRoleSource([this._role = UserRole.student]);

  UserRole _role;

  @override
  Future<UserRole> currentRole() async => _role;

  void setRole(UserRole role) {
    _role = role;
  }
}
