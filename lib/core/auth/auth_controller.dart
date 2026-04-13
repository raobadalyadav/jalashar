import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'user_role.dart';

final supabaseClientProvider = Provider<SupabaseClient>(
  (_) => Supabase.instance.client,
);

final authStateProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(supabaseClientProvider).auth.onAuthStateChange;
});

class AppUser {
  final String id;
  final String? email;
  final String? phone;
  final String? name;
  final String? avatarUrl;
  final UserRole role;
  final String locale;

  const AppUser({
    required this.id,
    required this.role,
    required this.locale,
    this.email,
    this.phone,
    this.name,
    this.avatarUrl,
  });

  factory AppUser.fromRow(Map<String, dynamic> row) => AppUser(
        id: row['id'] as String,
        email: row['email'] as String?,
        phone: row['phone'] as String?,
        name: row['name'] as String?,
        avatarUrl: row['avatar_url'] as String?,
        role: UserRole.fromString(row['role'] as String?),
        locale: (row['locale'] as String?) ?? 'en',
      );
}

final currentUserProvider = FutureProvider<AppUser?>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final authUser = client.auth.currentUser;
  if (authUser == null) return null;
  ref.watch(authStateProvider);
  final row = await client
      .from('users')
      .select('id,email,phone,name,avatar_url,role,locale')
      .eq('id', authUser.id)
      .maybeSingle();
  if (row == null) return null;
  return AppUser.fromRow(row);
});

class AuthController {
  AuthController(this._client);
  final SupabaseClient _client;

  // ===== Email OTP (passwordless, 6-digit code) =====
  Future<void> sendEmailOtp(String email) =>
      _client.auth.signInWithOtp(email: email, shouldCreateUser: true);

  Future<AuthResponse> verifyEmailOtp(String email, String token) =>
      _client.auth.verifyOTP(email: email, token: token, type: OtpType.email);

  // ===== Google =====
  Future<AuthResponse> signInWithGoogle() async {
    final google = GoogleSignIn(scopes: ['email', 'profile']);
    final acct = await google.signIn();
    if (acct == null) throw Exception('Google sign-in cancelled');
    final auth = await acct.authentication;
    final idToken = auth.idToken;
    final accessToken = auth.accessToken;
    if (idToken == null) throw Exception('No ID token from Google');
    return _client.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: accessToken,
    );
  }

  // ===== Facebook =====
  Future<AuthResponse> signInWithFacebook() async {
    final result = await FacebookAuth.instance.login(
      permissions: const ['email', 'public_profile'],
    );
    if (result.status != LoginStatus.success || result.accessToken == null) {
      throw Exception('Facebook sign-in cancelled');
    }
    return _client.auth.signInWithIdToken(
      provider: OAuthProvider.facebook,
      idToken: result.accessToken!.tokenString,
    );
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
    try {
      await GoogleSignIn().signOut();
    } catch (_) {}
    try {
      await FacebookAuth.instance.logOut();
    } catch (_) {}
  }

  Future<void> completeProfile({
    required String name,
    required UserRole role,
    String? phone,
  }) async {
    final uid = _client.auth.currentUser!.id;
    await _client.from('users').upsert({
      'id': uid,
      'name': name,
      'role': role.value,
      if (phone != null) 'phone': phone,
    });
  }
}

final authControllerProvider = Provider<AuthController>(
  (ref) => AuthController(ref.watch(supabaseClientProvider)),
);
