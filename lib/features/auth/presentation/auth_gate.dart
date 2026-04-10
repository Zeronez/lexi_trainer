import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lexi_trainer/features/auth/presentation/auth_screen.dart';
import 'package:lexi_trainer/core/auth/user_role.dart';
import 'package:lexi_trainer/features/admin/presentation/admin_dashboard_screen.dart';
import 'package:lexi_trainer/features/home/presentation/home_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({
    super.key,
    this.initialSession,
    this.authStateChanges,
    this.authenticatedChild,
    this.unauthenticatedChild,
    this.useSupabaseClient = true,
  });

  final Session? initialSession;
  final Stream<AuthState>? authStateChanges;
  final Widget? authenticatedChild;
  final Widget? unauthenticatedChild;
  final bool useSupabaseClient;

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late final StreamSubscription<AuthState> _authSubscription;
  Session? _session;
  Future<UserRole>? _roleFuture;

  void _setSession(Session? session) {
    _session = session;
    _roleFuture = session == null
        ? null
        : _resolveRole(session, allowNetworkLookup: widget.useSupabaseClient);
  }

  @override
  void initState() {
    super.initState();

    if (widget.useSupabaseClient) {
      final auth = Supabase.instance.client.auth;
      _setSession(widget.initialSession ?? auth.currentSession);
      final authStateStream = widget.authStateChanges ?? auth.onAuthStateChange;
      _authSubscription = authStateStream.listen((state) {
        if (!mounted) {
          return;
        }

        setState(() => _setSession(state.session));
      });
      return;
    }

    _setSession(widget.initialSession);
    final authStateStream =
        widget.authStateChanges ?? const Stream<AuthState>.empty();
    _authSubscription = authStateStream.listen((state) {
      if (!mounted) {
        return;
      }

      setState(() => _setSession(state.session));
    });
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_session == null) {
      return widget.unauthenticatedChild ?? const AuthScreen();
    }

    return FutureBuilder<UserRole>(
      future:
          _roleFuture ??
          _resolveRole(_session!, allowNetworkLookup: widget.useSupabaseClient),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final role = snapshot.data ?? UserRole.student;
        if (role.canOpenAdminSection) {
          return const AdminDashboardScreen();
        }

        return widget.authenticatedChild ?? const HomeScreen();
      },
    );
  }

  Future<UserRole> _resolveRole(
    Session session, {
    required bool allowNetworkLookup,
  }) async {
    final metadataRole = UserRole.fromValue(
      session.user.userMetadata?['role'] as String?,
    );
    if (metadataRole != UserRole.unknown) {
      return metadataRole;
    }

    if (!allowNetworkLookup) {
      return UserRole.student;
    }

    try {
      final profile = await Supabase.instance.client
          .from('users')
          .select('roles(name)')
          .eq('id', session.user.id)
          .maybeSingle();

      final rolesPayload = profile?['roles'];
      if (rolesPayload is Map<String, dynamic>) {
        return UserRole.fromValue(rolesPayload['name'] as String?);
      }
    } catch (_) {
      // Keep the gate non-blocking if the role lookup fails.
    }

    return UserRole.student;
  }
}
