import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  static const _emailConfirmationRedirectUrl =
      'https://fixmycityadmindashboard.vercel.app/email-confirmed';

  SupabaseClient get _db => Supabase.instance.client;

  User? get currentUser => _db.auth.currentUser;

  Future<AuthResponse> signUp(String email, String password) {
    return _db.auth.signUp(
      email: email,
      password: password,
      emailRedirectTo: _emailConfirmationRedirectUrl,
    );
  }

  Future<AuthResponse> signIn(String email, String password) {
    return _db.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signOut() => _db.auth.signOut();
}

final authService = AuthService();
