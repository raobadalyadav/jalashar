import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../auth/auth_controller.dart';
import '../models/models.dart';

// ========== WISHLIST ==========
class WishlistRepository {
  WishlistRepository(this._client);
  final SupabaseClient _client;

  Future<List<Vendor>> listMine() async {
    final uid = _client.auth.currentUser!.id;
    final rows = await _client
        .from('wishlist')
        .select('vendors(*, users(name, avatar_url))')
        .eq('user_id', uid);
    return (rows as List)
        .map((e) => Vendor.fromRow(e['vendors'] as Map<String, dynamic>))
        .toList();
  }

  Future<bool> isSaved(String vendorId) async {
    final uid = _client.auth.currentUser!.id;
    final row = await _client
        .from('wishlist')
        .select('vendor_id')
        .eq('user_id', uid)
        .eq('vendor_id', vendorId)
        .maybeSingle();
    return row != null;
  }

  Future<void> toggle(String vendorId) async {
    final uid = _client.auth.currentUser!.id;
    final saved = await isSaved(vendorId);
    if (saved) {
      await _client
          .from('wishlist')
          .delete()
          .eq('user_id', uid)
          .eq('vendor_id', vendorId);
    } else {
      await _client.from('wishlist').insert({
        'user_id': uid,
        'vendor_id': vendorId,
      });
    }
  }
}

final wishlistRepoProvider =
    Provider((ref) => WishlistRepository(ref.watch(supabaseClientProvider)));
final wishlistProvider = FutureProvider<List<Vendor>>(
    (ref) => ref.watch(wishlistRepoProvider).listMine());

// ========== REVIEWS ==========
class Review {
  final String id;
  final String bookingId;
  final String clientId;
  final String vendorId;
  final int stars;
  final String? comment;
  final DateTime createdAt;
  final String? clientName;

  const Review({
    required this.id,
    required this.bookingId,
    required this.clientId,
    required this.vendorId,
    required this.stars,
    required this.createdAt,
    this.comment,
    this.clientName,
  });

  factory Review.fromRow(Map<String, dynamic> r) => Review(
        id: r['id'] as String,
        bookingId: r['booking_id'] as String,
        clientId: r['client_id'] as String,
        vendorId: r['vendor_id'] as String,
        stars: r['stars'] as int,
        comment: r['comment'] as String?,
        createdAt: DateTime.parse(r['created_at'] as String),
        clientName: (r['users'] as Map?)?['name'] as String?,
      );
}

class ReviewRepository {
  ReviewRepository(this._client);
  final SupabaseClient _client;

  Future<List<Review>> forVendor(String vendorId) async {
    final rows = await _client
        .from('reviews')
        .select('*, users(name)')
        .eq('vendor_id', vendorId)
        .order('created_at', ascending: false);
    return (rows as List).map((e) => Review.fromRow(e)).toList();
  }

  Future<void> submit({
    required String bookingId,
    required String vendorId,
    required int stars,
    String? comment,
  }) async {
    final uid = _client.auth.currentUser!.id;
    await _client.from('reviews').insert({
      'booking_id': bookingId,
      'client_id': uid,
      'vendor_id': vendorId,
      'stars': stars,
      'comment': comment,
    });
  }
}

final reviewRepoProvider =
    Provider((ref) => ReviewRepository(ref.watch(supabaseClientProvider)));

final vendorReviewsProvider = FutureProvider.family<List<Review>, String>(
    (ref, vendorId) => ref.watch(reviewRepoProvider).forVendor(vendorId));

final myVendorReviewsProvider = FutureProvider<List<Review>>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final uid = client.auth.currentUser?.id;
  if (uid == null) return [];
  final vendorRow = await client
      .from('vendors')
      .select('id')
      .eq('user_id', uid)
      .maybeSingle();
  if (vendorRow == null) return [];
  return ref.watch(reviewRepoProvider).forVendor(vendorRow['id'] as String);
});

// ========== STORAGE / UPLOADS ==========
class StorageRepository {
  StorageRepository(this._client);
  final SupabaseClient _client;

  Future<String> uploadAvatar(File file) async {
    final uid = _client.auth.currentUser!.id;
    final path = '$uid/${DateTime.now().millisecondsSinceEpoch}.jpg';
    await _client.storage.from('avatars').upload(path, file);
    return _client.storage.from('avatars').getPublicUrl(path);
  }

  Future<String> uploadPortfolio(File file) async {
    final uid = _client.auth.currentUser!.id;
    final path = '$uid/${DateTime.now().millisecondsSinceEpoch}.jpg';
    await _client.storage.from('portfolios').upload(path, file);
    return _client.storage.from('portfolios').getPublicUrl(path);
  }
}

final storageRepoProvider =
    Provider((ref) => StorageRepository(ref.watch(supabaseClientProvider)));

// ========== USER PROFILE ==========
class UserRepository {
  UserRepository(this._client);
  final SupabaseClient _client;

  Future<void> updateProfile({
    String? name,
    String? phone,
    String? avatarUrl,
    String? locale,
  }) async {
    final uid = _client.auth.currentUser!.id;
    await _client.from('users').update({
      if (name != null) 'name': name,
      if (phone != null) 'phone': phone,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
      if (locale != null) 'locale': locale,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', uid);
  }
}

final userRepoProvider =
    Provider((ref) => UserRepository(ref.watch(supabaseClientProvider)));
