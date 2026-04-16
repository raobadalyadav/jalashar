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
    Map<String, dynamic> meta = const {},
  }) async {
    final uid = _client.auth.currentUser!.id;
    await _client.from('vendors').upsert({
      'user_id': uid,
      'category': category,
      'bio': bio,
      'city': city,
      'base_price': basePrice,
      'portfolio_urls': portfolioUrls,
      'meta': meta,
    });
  }

  Future<Vendor?> myVendor() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return null;
    final row = await _client
        .from('vendors')
        .select('*, users(name, avatar_url)')
        .eq('user_id', uid)
        .maybeSingle();
    return row == null ? null : Vendor.fromRow(row);
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
    String? serviceId,
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
          if (serviceId != null && serviceId.isNotEmpty) 'service_id': serviceId,
          'vendor_id': vendorId,
          'event_date': eventDate.toIso8601String().substring(0, 10),
          'guest_count': guestCount,
          'venue': venue,
          if (notes != null && notes.isNotEmpty) 'notes': notes,
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

  Future<void> cancel(String id) =>
      _client.from('bookings').update({'status': 'cancelled'}).eq('id', id);

  Future<void> reschedule(String id, DateTime newDate) =>
      _client.from('bookings').update({
        'event_date': newDate.toIso8601String().substring(0, 10),
      }).eq('id', id);

  Future<Booking> getById(String id) async {
    final row = await _client.from('bookings').select().eq('id', id).single();
    return Booking.fromRow(row);
  }
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

  Future<void> markAllRead(String bookingId, String myId) =>
      _client
          .from('messages')
          .update({'is_read': true})
          .eq('booking_id', bookingId)
          .eq('receiver_id', myId);

  Future<int> unreadForBooking(String bookingId, String myId) async {
    final rows = await _client
        .from('messages')
        .select()
        .eq('booking_id', bookingId)
        .eq('receiver_id', myId)
        .eq('is_read', false);
    return (rows as List).length;
  }

  Future<Message?> lastMessage(String bookingId) async {
    final rows = await _client
        .from('messages')
        .select()
        .eq('booking_id', bookingId)
        .order('created_at', ascending: false)
        .limit(1);
    final list = rows as List;
    return list.isEmpty ? null : Message.fromRow(list.first);
  }
}

final messageRepoProvider =
    Provider((ref) => MessageRepository(ref.watch(supabaseClientProvider)));

// ========== CONVERSATION INBOX ==========
class ConversationSummary {
  final Booking booking;
  final Message? lastMsg;
  final int unread;
  const ConversationSummary({
    required this.booking,
    this.lastMsg,
    this.unread = 0,
  });
}

final myConversationsProvider =
    FutureProvider<List<ConversationSummary>>((ref) async {
  final bookings = await ref.watch(bookingRepoProvider).listMine();
  final repo = ref.watch(messageRepoProvider);
  final uid = ref.watch(supabaseClientProvider).auth.currentUser?.id ?? '';
  final convos = <ConversationSummary>[];
  for (final b in bookings) {
    if (b.vendorId == null) continue;
    final last = await repo.lastMessage(b.id);
    final unread = last != null ? await repo.unreadForBooking(b.id, uid) : 0;
    convos.add(ConversationSummary(booking: b, lastMsg: last, unread: unread));
  }
  convos.sort((a, b) {
    final aTime = a.lastMsg?.createdAt ?? a.booking.createdAt;
    final bTime = b.lastMsg?.createdAt ?? b.booking.createdAt;
    return bTime.compareTo(aTime);
  });
  return convos;
});

final vendorConversationsProvider =
    FutureProvider<List<ConversationSummary>>((ref) async {
  final bookings = await ref.watch(bookingRepoProvider).listForVendor();
  final repo = ref.watch(messageRepoProvider);
  final uid = ref.watch(supabaseClientProvider).auth.currentUser?.id ?? '';
  final convos = <ConversationSummary>[];
  for (final b in bookings) {
    final last = await repo.lastMessage(b.id);
    final unread = last != null ? await repo.unreadForBooking(b.id, uid) : 0;
    convos.add(ConversationSummary(booking: b, lastMsg: last, unread: unread));
  }
  convos.sort((a, b) {
    final aTime = a.lastMsg?.createdAt ?? a.booking.createdAt;
    final bTime = b.lastMsg?.createdAt ?? b.booking.createdAt;
    return bTime.compareTo(aTime);
  });
  return convos;
});

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

  Future<int> unreadCount() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return 0;
    final rows = await _client
        .from('notifications')
        .select()
        .eq('user_id', uid)
        .eq('is_read', false);
    return (rows as List).length;
  }
}

final notificationRepoProvider =
    Provider((ref) => NotificationRepository(ref.watch(supabaseClientProvider)));

final notificationsProvider = FutureProvider<List<AppNotification>>(
    (ref) => ref.watch(notificationRepoProvider).listMine());

final notificationUnreadCountProvider = FutureProvider<int>(
    (ref) => ref.watch(notificationRepoProvider).unreadCount());

// ========== VENDOR PACKAGES ==========
class VendorPackageRepository {
  VendorPackageRepository(this._client);
  final SupabaseClient _client;

  Future<String?> myVendorId() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return null;
    final row = await _client
        .from('vendors')
        .select('id')
        .eq('user_id', uid)
        .maybeSingle();
    return row?['id'] as String?;
  }

  Future<List<VendorPackage>> listForVendor(String vendorId) async {
    final rows = await _client
        .from('vendor_packages')
        .select()
        .eq('vendor_id', vendorId)
        .order('price');
    return (rows as List).map((e) => VendorPackage.fromRow(e)).toList();
  }

  Future<List<VendorPackage>> listMine() async {
    final uid = _client.auth.currentUser!.id;
    final vendorRow = await _client
        .from('vendors')
        .select('id')
        .eq('user_id', uid)
        .maybeSingle();
    if (vendorRow == null) return [];
    return listForVendor(vendorRow['id'] as String);
  }

  Future<void> upsert({
    String? id,
    required String vendorId,
    required String name,
    required double price,
    int? durationHours,
    List<String> features = const [],
    String? eventType,
  }) async {
    final data = {
      'vendor_id': vendorId,
      'name': name,
      'price': price,
      'duration_hours': durationHours,
      'features': features,
      if (eventType != null && eventType.isNotEmpty) 'event_type': eventType,
    };
    if (id != null) {
      await _client.from('vendor_packages').update(data).eq('id', id);
    } else {
      await _client.from('vendor_packages').insert(data);
    }
  }

  Future<void> delete(String id) =>
      _client.from('vendor_packages').delete().eq('id', id);
}

final vendorPackageRepoProvider =
    Provider((ref) => VendorPackageRepository(ref.watch(supabaseClientProvider)));

final vendorPackagesProvider =
    FutureProvider.family<List<VendorPackage>, String>(
  (ref, vendorId) =>
      ref.watch(vendorPackageRepoProvider).listForVendor(vendorId),
);

final myVendorPackagesProvider = FutureProvider<List<VendorPackage>>(
    (ref) => ref.watch(vendorPackageRepoProvider).listMine());
