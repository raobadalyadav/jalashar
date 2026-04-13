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
  // Re-fetch on auth changes
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

  Future<void> signInWithEmail(String email, String password) =>
      _client.auth.signInWithPassword(email: email, password: password);

  Future<void> signUpWithEmail(String email, String password) =>
      _client.auth.signUp(email: email, password: password);

  Future<void> sendPhoneOtp(String phone) =>
      _client.auth.signInWithOtp(phone: phone);

  Future<AuthResponse> verifyPhoneOtp(String phone, String token) =>
      _client.auth.verifyOTP(phone: phone, token: token, type: OtpType.sms);

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

  Future<bool> signInWithApple() =>
      _client.auth.signInWithOAuth(OAuthProvider.apple);

  Future<bool> signInWithFacebook() =>
      _client.auth.signInWithOAuth(OAuthProvider.facebook);

  Future<void> signOut() => _client.auth.signOut();

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
