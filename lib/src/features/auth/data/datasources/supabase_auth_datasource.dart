import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:aanda/src/features/auth/data/models/account_model.dart';
import 'package:aanda/src/features/auth/domain/entities/auth_credentials.dart';
import 'package:aanda/src/features/auth/domain/entities/auth_status.dart';

/// Supabase-backed authentication datasource.
///
/// Handles sign-up, sign-in, sign-out, and auth-state streaming.
/// All profile reads are done against the `profiles` table in Supabase.
class SupabaseAuthDatasource {
  SupabaseAuthDatasource({required SupabaseClient supabase})
    : _supabase = supabase;

  final SupabaseClient _supabase;

  // ── Auth stream ────────────────────────────────────────────────────────────

  /// Emits [AuthStatus] whenever the Supabase session changes.
  Stream<AuthStatus> get authStream {
    return _supabase.auth.onAuthStateChange.asyncMap(_mapEvent).distinct(
      (a, b) => switch ((a, b)) {
        (Authenticated prev, Authenticated curr) =>
          prev.account.id == curr.account.id,
        (UnAuthenticated(), UnAuthenticated()) => true,
        (LoadingAuthSignature(), LoadingAuthSignature()) => true,
        _ => false,
      },
    );
  }

  Future<AuthStatus> _mapEvent(AuthState event) async {
    final session = event.session;
    if (session == null) return UnAuthenticated();
    return _accountFromSession(session);
  }

  // ── Operations ─────────────────────────────────────────────────────────────

  /// Signs the user in with [params.email] and [params.password].
  Future<AccountModel> signInWithEmail(SignInParams params) async {
    final response = await _supabase.auth.signInWithPassword(
      email: params.email,
      password: params.password,
    );
    final session = response.session;
    final user = response.user;
    if (session == null || user == null) {
      throw Exception('Sign-in failed: no session returned.');
    }

    final profile = await _fetchProfile(user.id);
    return AccountModel.fromSupabase(
      profile: profile,
      email: user.email ?? params.email,
      token: session.accessToken,
    );
  }

  /// Registers a new user with email + password, then upserts a profile row.
  Future<AccountModel> signUpWithEmail(SignUpParams params) async {
    final response = await _supabase.auth.signUp(
      email: params.email,
      password: params.password,
    );

    final session = response.session;
    final user = response.user;
    if (user == null) {
      throw Exception('Sign-up failed: no user returned.');
    }

    // Upsert the profile row (trigger may not fire immediately on all plans).
    await _supabase.from('profiles').upsert({
      'id': user.id,
      'username': params.username,
      if (params.fullName != null) 'full_name': params.fullName,
    });

    final profile = await _fetchProfile(user.id);
    return AccountModel.fromSupabase(
      profile: profile,
      email: user.email ?? params.email,
      token: session?.accessToken,
    );
  }

  /// Signs the current user out.
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  /// Returns the currently authenticated [AccountModel] or null.
  Future<AccountModel?> getCurrentAccount() async {
    final session = _supabase.auth.currentSession;
    final user = _supabase.auth.currentUser;
    if (session == null || user == null) return null;
    final profile = await _fetchProfile(user.id);
    return AccountModel.fromSupabase(
      profile: profile,
      email: user.email ?? '',
      token: session.accessToken,
    );
  }

  /// Returns true if [username] is not yet taken in the profiles table.
  Future<bool> isUsernameAvailable(String username) async {
    final result = await _supabase
        .from('profiles')
        .select('id')
        .eq('username', username)
        .maybeSingle();
    return result == null;
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> _fetchProfile(String userId) async {
    final data = await _supabase
        .from('profiles')
        .select()
        .eq('id', userId)
        .single();
    return data;
  }

  Future<AuthStatus> _accountFromSession(Session session) async {
    try {
      final user = session.user;
      final profile = await _fetchProfile(user.id);
      final account = AccountModel.fromSupabase(
        profile: profile,
        email: user.email ?? '',
        token: session.accessToken,
      );
      return Authenticated(account);
    } catch (_) {
      return UnAuthenticated();
    }
  }
}
