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
