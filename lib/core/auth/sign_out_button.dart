import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SignOutButton extends StatefulWidget {
  const SignOutButton({super.key, this.showLabel = false});

  final bool showLabel;

  @override
  State<SignOutButton> createState() => _SignOutButtonState();
}

class _SignOutButtonState extends State<SignOutButton> {
  bool _isSigningOut = false;

  Future<void> _signOut() async {
    if (_isSigningOut) {
      return;
    }

    setState(() {
      _isSigningOut = true;
    });

    try {
      await Supabase.instance.client.auth.signOut();
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '\u041d\u0435 \u0443\u0434\u0430\u043b\u043e\u0441\u044c \u0432\u044b\u0439\u0442\u0438 \u0438\u0437 \u0430\u043a\u043a\u0430\u0443\u043d\u0442\u0430: $error',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSigningOut = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const tooltipMessage =
        '\u0412\u044b\u0439\u0442\u0438 \u0438\u0437 \u0430\u043a\u043a\u0430\u0443\u043d\u0442\u0430';
    final icon = _isSigningOut
        ? const SizedBox.square(
            dimension: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : const Icon(Icons.logout_rounded);

    if (widget.showLabel) {
      return Tooltip(
        message: tooltipMessage,
        child: TextButton.icon(
          onPressed: _isSigningOut ? null : _signOut,
          icon: icon,
          label: const Text('\u0412\u044b\u0439\u0442\u0438'),
        ),
      );
    }

    return Tooltip(
      message: tooltipMessage,
      child: IconButton(onPressed: _isSigningOut ? null : _signOut, icon: icon),
    );
  }
}
