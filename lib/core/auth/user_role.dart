enum UserRole {
  admin('admin'),
  teacher('teacher'),
  student('student'),
  unknown('unknown');

  const UserRole(this.value);

  final String value;

  static UserRole fromValue(String? value) {
    switch (value) {
      case 'admin':
        return UserRole.admin;
      case 'teacher':
        return UserRole.teacher;
      case 'student':
        return UserRole.student;
      default:
        return UserRole.unknown;
    }
  }
}

extension UserRoleAccess on UserRole {
  bool get canOpenAdminSection =>
      this == UserRole.admin || this == UserRole.teacher;
}
