// widgets/auth_state_handler.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../screens/login_screen.dart';
import '../screens/home_screen.dart';

class AuthStateHandler extends StatefulWidget {
  const AuthStateHandler({super.key});

  @override
  State<AuthStateHandler> createState() => _AuthStateHandlerState();
}

class _AuthStateHandlerState extends State<AuthStateHandler> {
  final _supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();

    // Listen to auth changes (login, logout, token refresh, etc.)
    _supabase.auth.onAuthStateChange.listen((data) {
      if (mounted) {
        setState(() {}); // Trigger rebuild when auth state changes
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = _supabase.auth.currentUser;

    // Smart routing based on auth state
    if (user != null) {
      return const HomeScreen();
    } else {
      return const LoginScreen();
    }
  }
}