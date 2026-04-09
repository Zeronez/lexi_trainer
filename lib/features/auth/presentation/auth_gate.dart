import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lexi_trainer/features/auth/presentation/auth_screen.dart';
import 'package:lexi_trainer/features/home/presentation/home_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({
    super.key,
    this.initialSession,
    this.authStateChanges,
    this.authenticatedChild,
    this.unauthenticatedChild,
  });

  final Session? initialSession;
  final Stream<AuthState>? authStateChanges;
  final Widget? authenticatedChild;
  final Widget? unauthenticatedChild;

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late final StreamSubscription<AuthState> _authSubscription;
  Session? _session;

  @override
  void initState() {
    super.initState();

    final auth = (widget.initialSession == null || widget.authStateChanges == null)
        ? Supabase.instance.client.auth
        : null;
    _session = widget.initialSession ?? auth?.currentSession;
    final authStateStream = widget.authStateChanges ?? auth!.onAuthStateChange;
    _authSubscription = authStateStream.listen((state) {
      if (!mounted) {
        return;
      }

      setState(() => _session = state.session);
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
    return widget.authenticatedChild ?? const HomeScreen();
  }
}
