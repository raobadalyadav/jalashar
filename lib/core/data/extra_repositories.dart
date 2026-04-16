import 'dart:io';
import 'dart:math';

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
        .select('vendors!inner(*, users!vendors_user_id_fkey(name, avatar_url))')
        .eq('user_id', uid);
    return (rows as List)
        .where((e) => e['vendors'] != null)
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
  final List<String> photos;
  final int helpfulCount;
  final int unhelpfulCount;
  final bool isVerifiedBooking;

  const Review({
    required this.id,
    required this.bookingId,
    required this.clientId,
    required this.vendorId,
    required this.stars,
    required this.createdAt,
    this.comment,
    this.clientName,
    this.photos = const [],
    this.helpfulCount = 0,
    this.unhelpfulCount = 0,
    this.isVerifiedBooking = false,
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
        photos: (r['photos'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        helpfulCount: (r['helpful_count'] as int?) ?? 0,
        unhelpfulCount: (r['unhelpful_count'] as int?) ?? 0,
        isVerifiedBooking: (r['is_verified_booking'] as bool?) ?? false,
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
    List<String> photos = const [],
  }) async {
    final uid = _client.auth.currentUser!.id;
    await _client.from('reviews').insert({
      'booking_id': bookingId,
      'client_id': uid,
      'vendor_id': vendorId,
      'stars': stars,
      'comment': comment,
      'photos': photos,
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

  Future<String> uploadChatImage(File file) async {
    final uid = _client.auth.currentUser!.id;
    final path = '$uid/${DateTime.now().millisecondsSinceEpoch}.jpg';
    await _client.storage.from('chat-images').upload(path, file);
    return _client.storage.from('chat-images').getPublicUrl(path);
  }

  Future<String> uploadReviewPhoto(File file) async {
    final uid = _client.auth.currentUser!.id;
    final path = '$uid/${DateTime.now().millisecondsSinceEpoch}.jpg';
    await _client.storage.from('review-photos').upload(path, file);
    return _client.storage.from('review-photos').getPublicUrl(path);
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
      'name': name,
      'phone': phone,
      'avatar_url': avatarUrl,
      'locale': locale,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', uid);
  }
}

final userRepoProvider =
    Provider((ref) => UserRepository(ref.watch(supabaseClientProvider)));

// ========== REPORTS ==========
class ReportRepository {
  ReportRepository(this._client);
  final SupabaseClient _client;

  Future<void> submit({
    required String vendorId,
    required String reason,
    String? description,
  }) async {
    final uid = _client.auth.currentUser!.id;
    await _client.from('reports').insert({
      'reporter_id': uid,
      'reported_vendor_id': vendorId,
      'reason': reason,
      'description': description?.isNotEmpty == true ? description : null,
    });
  }
}

final reportRepoProvider =
    Provider((ref) => ReportRepository(ref.watch(supabaseClientProvider)));

// ========== ADMIN ==========
class AdminRepository {
  AdminRepository(this._client);
  final SupabaseClient _client;

  Future<List<PlatformUser>> listAllUsers() async {
    final rows = await _client
        .from('users')
        .select()
        .order('created_at', ascending: false);
    return (rows as List).map((e) => PlatformUser.fromRow(e)).toList();
  }

  Future<void> suspendUser(String userId, bool suspended) =>
      _client.from('users').update({
        'is_suspended': suspended,
        'suspended_at': suspended ? DateTime.now().toIso8601String() : null,
      }).eq('id', userId);

  Future<void> banUser(String userId, String reason) =>
      _client.from('users').update({
        'is_banned': true,
        'ban_reason': reason,
      }).eq('id', userId);

  Future<void> unbanUser(String userId) =>
      _client.from('users').update({
        'is_banned': false,
        'ban_reason': null,
      }).eq('id', userId);

  Future<void> setFeatured(String vendorId, bool featured) =>
      _client.from('vendors').update({'is_featured': featured}).eq('id', vendorId);

  Future<List<Map<String, dynamic>>> listReports() async {
    final rows = await _client
        .from('reports')
        .select()
        .order('created_at', ascending: false);
    return (rows as List).cast<Map<String, dynamic>>();
  }

  Future<void> resolveReport(String reportId) =>
      _client.from('reports').update({'status': 'resolved'}).eq('id', reportId);

  Future<void> broadcastNotification({
    required String title,
    required String body,
    String? targetRole,
  }) async {
    final users = await (targetRole != null
        ? _client.from('users').select('id').eq('role', targetRole)
        : _client.from('users').select('id')) as List;

    final notifications = users
        .map((u) => {
              'user_id': u['id'],
              'title': title,
              'body': body,
              'type': 'broadcast',
              'is_read': false,
            })
        .toList();
    if (notifications.isNotEmpty) {
      await _client.from('notifications').insert(notifications);
    }
  }

  Future<Map<String, dynamic>> getStats() async {
    final users = await _client.from('users').select('role');
    final vendors = await _client.from('vendors').select('category, city, is_verified');
    final bookings = await _client.from('bookings').select('status, created_at');

    final userCount = (users as List).length;
    final clientCount = users.where((u) => u['role'] == 'client').length;
    final vendorCount = users.where((u) => u['role'] == 'vendor').length;
    final verifiedVendors = (vendors as List).where((v) => v['is_verified'] == true).length;

    final categoryMap = <String, int>{};
    for (final v in vendors) {
      final cat = v['category'] as String? ?? 'Other';
      categoryMap[cat] = (categoryMap[cat] ?? 0) + 1;
    }

    final cityMap = <String, int>{};
    for (final v in vendors) {
      final city = v['city'] as String? ?? 'Unknown';
      cityMap[city] = (cityMap[city] ?? 0) + 1;
    }

    final bookingList = bookings as List;
    final now = DateTime.now();
    final last7Days = bookingList.where((b) {
      final created = DateTime.tryParse(b['created_at'] as String? ?? '');
      return created != null && now.difference(created).inDays <= 7;
    }).length;

    return {
      'userCount': userCount,
      'clientCount': clientCount,
      'vendorCount': vendorCount,
      'verifiedVendors': verifiedVendors,
      'totalBookings': bookingList.length,
      'last7DaysBookings': last7Days,
      'topCategories': categoryMap,
      'topCities': cityMap,
    };
  }
}

final adminRepoProvider =
    Provider((ref) => AdminRepository(ref.watch(supabaseClientProvider)));

final adminStatsProvider = FutureProvider<Map<String, dynamic>>(
    (ref) => ref.watch(adminRepoProvider).getStats());

final allUsersProvider = FutureProvider<List<PlatformUser>>(
    (ref) => ref.watch(adminRepoProvider).listAllUsers());

final adminReportsProvider = FutureProvider<List<Map<String, dynamic>>>(
    (ref) => ref.watch(adminRepoProvider).listReports());

// ========== GUEST INVITES ==========
class GuestInvite {
  final String id;
  final String bookingId;
  final String hostId;
  final String? eventName;
  final DateTime? eventDate;
  final String? venue;
  final String? message;
  final String code;
  final DateTime createdAt;

  const GuestInvite({
    required this.id,
    required this.bookingId,
    required this.hostId,
    required this.code,
    required this.createdAt,
    this.eventName,
    this.eventDate,
    this.venue,
    this.message,
  });

  factory GuestInvite.fromRow(Map<String, dynamic> r) => GuestInvite(
        id: r['id'] as String,
        bookingId: r['booking_id'] as String,
        hostId: r['host_id'] as String,
        code: r['code'] as String,
        createdAt: DateTime.parse(r['created_at'] as String),
        eventName: r['event_name'] as String?,
        eventDate: r['event_date'] != null
            ? DateTime.tryParse(r['event_date'] as String)
            : null,
        venue: r['venue'] as String?,
        message: r['message'] as String?,
      );
}

String _randomCode() {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  final rng = Random.secure();
  return List.generate(8, (_) => chars[rng.nextInt(chars.length)]).join();
}

class GuestInviteRepository {
  GuestInviteRepository(this._client);
  final SupabaseClient _client;

  Future<GuestInvite?> getForBooking(String bookingId) async {
    final row = await _client
        .from('guest_invites')
        .select()
        .eq('booking_id', bookingId)
        .maybeSingle();
    return row != null ? GuestInvite.fromRow(row) : null;
  }

  Future<GuestInvite> create({
    required String bookingId,
    required String eventName,
    required DateTime eventDate,
    required String venue,
    String? message,
  }) async {
    final uid = _client.auth.currentUser!.id;
    final row = await _client.from('guest_invites').insert({
      'booking_id': bookingId,
      'host_id': uid,
      'event_name': eventName,
      'event_date': eventDate.toIso8601String().split('T').first,
      'venue': venue,
      'message': message,
      'code': _randomCode(),
    }).select().single();
    return GuestInvite.fromRow(row);
  }
}

final guestInviteRepoProvider =
    Provider((ref) => GuestInviteRepository(ref.watch(supabaseClientProvider)));

// ========== VENDOR VIEW STATS ==========
class VendorViewStats {
  final int views7d;
  final int views30d;
  const VendorViewStats({required this.views7d, required this.views30d});
}

final myVendorViewStatsProvider = FutureProvider<VendorViewStats?>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final uid = client.auth.currentUser?.id;
  if (uid == null) return null;
  final vendorRow = await client
      .from('vendors')
      .select('id')
      .eq('user_id', uid)
      .maybeSingle();
  if (vendorRow == null) return null;
  final result = await client.rpc(
    'get_vendor_view_stats',
    params: {'vendor_uuid': vendorRow['id'] as String},
  );
  if (result == null) return const VendorViewStats(views7d: 0, views30d: 0);
  final row = result is List ? result.first : result;
  return VendorViewStats(
    views7d: (row['views_7d'] as num?)?.toInt() ?? 0,
    views30d: (row['views_30d'] as num?)?.toInt() ?? 0,
  );
});

// ========== REVIEW VOTES ==========
class ReviewVoteRepository {
  ReviewVoteRepository(this._client);
  final SupabaseClient _client;

  Future<Map<String, int>> votesForVendor(String vendorId) async {
    final rows = await _client
        .from('reviews')
        .select('id, review_votes(is_helpful)')
        .eq('vendor_id', vendorId);
    final Map<String, int> helpful = {};
    for (final r in rows as List) {
      final votes = (r['review_votes'] as List?) ?? [];
      helpful[r['id'] as String] =
          votes.where((v) => v['is_helpful'] == true).length;
    }
    return helpful;
  }

  Future<void> vote(String reviewId, bool isHelpful) async {
    final uid = _client.auth.currentUser!.id;
    await _client.from('review_votes').upsert({
      'review_id': reviewId,
      'user_id': uid,
      'is_helpful': isHelpful,
    }, onConflict: 'review_id,user_id');
  }

  Future<void> removeVote(String reviewId) async {
    final uid = _client.auth.currentUser!.id;
    await _client
        .from('review_votes')
        .delete()
        .eq('review_id', reviewId)
        .eq('user_id', uid);
  }
}

final reviewVoteRepoProvider =
    Provider((ref) => ReviewVoteRepository(ref.watch(supabaseClientProvider)));

// ========== BLOCKED VENDORS ==========
class BlockedVendorRepository {
  BlockedVendorRepository(this._client);
  final SupabaseClient _client;

  Future<bool> isBlocked(String vendorId) async {
    final uid = _client.auth.currentUser!.id;
    final row = await _client
        .from('blocked_vendors')
        .select('vendor_id')
        .eq('user_id', uid)
        .eq('vendor_id', vendorId)
        .maybeSingle();
    return row != null;
  }

  Future<void> block(String vendorId) async {
    final uid = _client.auth.currentUser!.id;
    await _client
        .from('blocked_vendors')
        .insert({'user_id': uid, 'vendor_id': vendorId});
  }

  Future<void> unblock(String vendorId) async {
    final uid = _client.auth.currentUser!.id;
    await _client
        .from('blocked_vendors')
        .delete()
        .eq('user_id', uid)
        .eq('vendor_id', vendorId);
  }
}

final blockedVendorRepoProvider =
    Provider((ref) => BlockedVendorRepository(ref.watch(supabaseClientProvider)));

// ========== VENDOR BUSY TOGGLE ==========
class VendorStatusRepository {
  VendorStatusRepository(this._client);
  final SupabaseClient _client;

  Future<void> setAccepting(bool accepting) async {
    final uid = _client.auth.currentUser!.id;
    await _client
        .from('vendors')
        .update({'is_accepting_bookings': accepting})
        .eq('user_id', uid);
  }

  Future<bool?> getAccepting() async {
    final uid = _client.auth.currentUser!.id;
    final row = await _client
        .from('vendors')
        .select('is_accepting_bookings')
        .eq('user_id', uid)
        .maybeSingle();
    return row?['is_accepting_bookings'] as bool?;
  }
}

final vendorStatusRepoProvider =
    Provider((ref) => VendorStatusRepository(ref.watch(supabaseClientProvider)));
