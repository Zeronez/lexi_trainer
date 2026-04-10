import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lexi_trainer/core/auth/user_role.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final currentUserRoleProvider = FutureProvider<UserRole>((ref) async {
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) {
    return UserRole.unknown;
  }

  try {
    final profile = await Supabase.instance.client
        .from('users')
        .select('roles(name)')
        .eq('id', user.id)
        .maybeSingle();

    final rolesPayload = profile?['roles'];
    if (rolesPayload is Map<String, dynamic>) {
      return UserRole.fromValue(rolesPayload['name'] as String?);
    }
  } catch (_) {
    // Keep non-blocking fallback for UI.
  }

  final metadataRole = UserRole.fromValue(
    user.userMetadata?['role'] as String?,
  );
  if (metadataRole != UserRole.unknown) {
    return metadataRole;
  }

  return UserRole.student;
});
