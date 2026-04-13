import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../auth/auth_controller.dart';
import '../models/models.dart';

// ========== SERVICES ==========
class ServiceRepository {
  ServiceRepository(this._client);
  final SupabaseClient _client;

  Future<List<ServicePackage>> listActive() async {
    final rows = await _client
        .from('services')
        .select()
        .eq('is_active', true)
        .order('base_price');
    return (rows as List).map((e) => ServicePackage.fromRow(e)).toList();
  }

  Future<ServicePackage?> getBySlug(String slug) async {
    final row = await _client.from('services').select().eq('slug', slug).maybeSingle();
    return row == null ? null : ServicePackage.fromRow(row);
  }
}

final serviceRepoProvider =
    Provider((ref) => ServiceRepository(ref.watch(supabaseClientProvider)));

final servicesProvider = FutureProvider<List<ServicePackage>>(
    (ref) => ref.watch(serviceRepoProvider).listActive());

// ========== VENDORS ==========
class VendorRepository {
  VendorRepository(this._client);
  final SupabaseClient _client;

  Future<List<Vendor>> list({String? category, String? city, String? query}) async {
    var q = _client.from('vendors').select('*, users(name, avatar_url)');
    if (category != null) q = q.eq('category', category);
    if (city != null) q = q.eq('city', city);
    if (query != null && query.isNotEmpty) q = q.ilike('bio', '%$query%');
    final rows = await q.order('rating_avg', ascending: false).limit(50);
    return (rows as List).map((e) => Vendor.fromRow(e)).toList();
  }

  Future<Vendor?> getById(String id) async {
    final row = await _client
        .from('vendors')
        .select('*, users(name, avatar_url)')
        .eq('id', id)
        .maybeSingle();
    return row == null ? null : Vendor.fromRow(row);
  }

  Future<void> upsertMyVendor({
    required String category,
    required String bio,
    required String city,
    required double basePrice,
    required List<String> portfolioUrls,
  }) async {
    final uid = _client.auth.currentUser!.id;
    await _client.from('vendors').upsert({
      'user_id': uid,
      'category': category,
      'bio': bio,
      'city': city,
      'base_price': basePrice,
      'portfolio_urls': portfolioUrls,
    });
  }

  Future<List<Vendor>> listPendingVerification() async {
    final rows = await _client
        .from('vendors')
        .select('*, users(name, avatar_url)')
        .eq('is_verified', false)
        .order('created_at', ascending: false);
    return (rows as List).map((e) => Vendor.fromRow(e)).toList();
  }

  Future<void> verify(String id, bool verified) =>
      _client.from('vendors').update({'is_verified': verified}).eq('id', id);
}

final vendorRepoProvider =
    Provider((ref) => VendorRepository(ref.watch(supabaseClientProvider)));

final vendorListProvider = FutureProvider.family<List<Vendor>, String?>(
  (ref, category) => ref.watch(vendorRepoProvider).list(category: category),
);

// ========== BOOKINGS ==========
class BookingRepository {
  BookingRepository(this._client);
  final SupabaseClient _client;

  Future<Booking> create({
    required String serviceId,
    String? vendorId,
    required DateTime eventDate,
    required int guestCount,
    required String venue,
    String? notes,
    required double totalAmount,
  }) async {
    final uid = _client.auth.currentUser!.id;
    final row = await _client
        .from('bookings')
        .insert({
          'client_id': uid,
          'service_id': serviceId,
          'vendor_id': vendorId,
          'event_date': eventDate.toIso8601String().substring(0, 10),
          'guest_count': guestCount,
          'venue': venue,
          'notes': notes,
          'total_amount': totalAmount,
          'status': 'pending',
        })
        .select()
        .single();
    return Booking.fromRow(row);
  }

  Future<List<Booking>> listMine() async {
    final uid = _client.auth.currentUser!.id;
    final rows = await _client
        .from('bookings')
        .select()
        .eq('client_id', uid)
        .order('event_date', ascending: false);
    return (rows as List).map((e) => Booking.fromRow(e)).toList();
  }

  Future<List<Booking>> listForVendor() async {
    final uid = _client.auth.currentUser!.id;
    final rows = await _client
        .from('bookings')
        .select('*, vendors!inner(user_id)')
        .eq('vendors.user_id', uid)
        .order('event_date', ascending: false);
    return (rows as List).map((e) => Booking.fromRow(e)).toList();
  }

  Future<List<Booking>> listAll() async {
    final rows =
        await _client.from('bookings').select().order('created_at', ascending: false);
    return (rows as List).map((e) => Booking.fromRow(e)).toList();
  }

  Future<void> updateStatus(String id, BookingStatus status) =>
      _client.from('bookings').update({'status': status.value}).eq('id', id);
}

final bookingRepoProvider =
    Provider((ref) => BookingRepository(ref.watch(supabaseClientProvider)));

final myBookingsProvider = FutureProvider<List<Booking>>(
    (ref) => ref.watch(bookingRepoProvider).listMine());
final vendorBookingsProvider = FutureProvider<List<Booking>>(
    (ref) => ref.watch(bookingRepoProvider).listForVendor());

// ========== MESSAGES ==========
class MessageRepository {
  MessageRepository(this._client);
  final SupabaseClient _client;

  Stream<List<Message>> stream(String bookingId) => _client
      .from('messages')
      .stream(primaryKey: ['id'])
      .eq('booking_id', bookingId)
      .order('created_at')
      .map((rows) => rows.map(Message.fromRow).toList());

  Future<void> send(String bookingId, String receiverId, String content) async {
    final uid = _client.auth.currentUser!.id;
    await _client.from('messages').insert({
      'booking_id': bookingId,
      'sender_id': uid,
      'receiver_id': receiverId,
      'content': content,
    });
  }
}

final messageRepoProvider =
    Provider((ref) => MessageRepository(ref.watch(supabaseClientProvider)));

// ========== NOTIFICATIONS ==========
class NotificationRepository {
  NotificationRepository(this._client);
  final SupabaseClient _client;

  Future<List<AppNotification>> listMine() async {
    final uid = _client.auth.currentUser!.id;
    final rows = await _client
        .from('notifications')
        .select()
        .eq('user_id', uid)
        .order('created_at', ascending: false)
        .limit(50);
    return (rows as List).map((e) => AppNotification.fromRow(e)).toList();
  }

  Future<void> markRead(String id) =>
      _client.from('notifications').update({'is_read': true}).eq('id', id);
}

final notificationRepoProvider =
    Provider((ref) => NotificationRepository(ref.watch(supabaseClientProvider)));

final notificationsProvider = FutureProvider<List<AppNotification>>(
    (ref) => ref.watch(notificationRepoProvider).listMine());
