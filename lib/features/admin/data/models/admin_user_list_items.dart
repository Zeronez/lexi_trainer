class AdminStudentListItem {
  const AdminStudentListItem({
    required this.id,
    required this.username,
    required this.email,
    required this.studyGroupId,
    required this.studyGroupName,
  });

  final String id;
  final String username;
  final String email;
  final int? studyGroupId;
  final String? studyGroupName;

  factory AdminStudentListItem.fromJson(Map<String, dynamic> json) {
    final studyGroup = json['study_groups'];
    final studyGroupJson = studyGroup is Map
        ? Map<String, dynamic>.from(studyGroup)
        : null;

    return AdminStudentListItem(
      id: json['id'] as String,
      username: json['username'] as String,
      email: json['email'] as String,
      studyGroupId: _readNullableInt(json['study_group_id']),
      studyGroupName: studyGroupJson?['name'] as String?,
    );
  }

  String get displayName => username.isNotEmpty ? username : email;

  String get subtitle {
    final parts = <String>[];
    if (email.isNotEmpty) {
      parts.add(email);
    }
    if (studyGroupName != null && studyGroupName!.isNotEmpty) {
      parts.add('Текущая группа: $studyGroupName');
    } else if (studyGroupId != null) {
      parts.add('Текущая группа: #$studyGroupId');
    }
    return parts.join(' · ');
  }
}

class AdminUserListItem {
  const AdminUserListItem({
    required this.id,
    required this.username,
    required this.email,
    required this.roleId,
    required this.roleName,
    required this.studyGroupId,
    required this.studyGroupName,
    required this.registeredAt,
  });

  final String id;
  final String username;
  final String email;
  final int roleId;
  final String roleName;
  final int? studyGroupId;
  final String? studyGroupName;
  final DateTime registeredAt;

  factory AdminUserListItem.fromJson(Map<String, dynamic> json) {
    final role = json['roles'];
    final roleJson = role is Map ? Map<String, dynamic>.from(role) : null;
    final studyGroup = json['study_groups'];
    final studyGroupJson = studyGroup is Map
        ? Map<String, dynamic>.from(studyGroup)
        : null;

    return AdminUserListItem(
      id: json['id'] as String,
      username: json['username'] as String,
      email: json['email'] as String,
      roleId: _readInt(json['role_id']),
      roleName: roleJson?['name'] as String? ?? 'unknown',
      studyGroupId: _readNullableInt(json['study_group_id']),
      studyGroupName: studyGroupJson?['name'] as String?,
      registeredAt: DateTime.parse(json['registered_at'] as String),
    );
  }

  String get displayName => username.isNotEmpty ? username : email;

  String get roleLabel => switch (roleName) {
    'admin' => 'Администратор',
    'teacher' => 'Преподаватель',
    'student' => 'Студент',
    _ => roleName,
  };

  String get subtitle {
    final parts = <String>[email, roleLabel];
    if (studyGroupName != null && studyGroupName!.isNotEmpty) {
      parts.add('Группа: $studyGroupName');
    } else if (studyGroupId != null) {
      parts.add('Группа: #$studyGroupId');
    }
    return parts.where((part) => part.trim().isNotEmpty).join(' · ');
  }
}

class AdminRoleListItem {
  const AdminRoleListItem({required this.id, required this.name});

  final int id;
  final String name;

  factory AdminRoleListItem.fromJson(Map<String, dynamic> json) {
    return AdminRoleListItem(
      id: _readInt(json['id']),
      name: json['name'] as String,
    );
  }

  String get label => switch (name) {
    'admin' => 'Администратор',
    'teacher' => 'Преподаватель',
    'student' => 'Студент',
    _ => name,
  };
}

int _readInt(Object? value) {
  if (value is int) {
    return value;
  }

  if (value is num) {
    return value.toInt();
  }

  if (value is String) {
    return int.parse(value);
  }

  throw FormatException('Не удалось прочитать числовое значение.');
}

int? _readNullableInt(Object? value) {
  if (value == null) {
    return null;
  }

  if (value is int) {
    return value;
  }

  if (value is num) {
    return value.toInt();
  }

  if (value is String) {
    return int.tryParse(value);
  }

  return null;
}
