import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../auth/auth_controller.dart';
import '../models/extra_models.dart';

// ========== CITIES + CATEGORIES + BANNERS + FAQ ==========
class ContentRepository {
  ContentRepository(this._client);
  final SupabaseClient _client;

  Future<List<City>> listCities() async {
    final rows = await _client
        .from('cities')
        .select()
        .eq('is_active', true)
        .order('name');
    return (rows as List).map((e) => City.fromRow(e)).toList();
  }

  Future<List<VendorCategory>> listCategories() async {
    final rows = await _client
        .from('vendor_categories')
        .select()
        .eq('is_active', true)
        .order('sort_order');
    return (rows as List).map((e) => VendorCategory.fromRow(e)).toList();
  }

  Future<List<Banner>> listBanners() async {
    final rows = await _client
        .from('banners')
        .select()
        .eq('is_active', true)
        .order('sort_order');
    return (rows as List).map((e) => Banner.fromRow(e)).toList();
  }

  Future<List<Faq>> listFaqs() async {
    final rows = await _client
        .from('faqs')
        .select()
        .eq('is_active', true)
        .order('sort_order');
    return (rows as List).map((e) => Faq.fromRow(e)).toList();
  }
}

final contentRepoProvider =
    Provider((ref) => ContentRepository(ref.watch(supabaseClientProvider)));

final citiesProvider =
    FutureProvider((ref) => ref.watch(contentRepoProvider).listCities());
final categoriesProvider =
    FutureProvider((ref) => ref.watch(contentRepoProvider).listCategories());
final bannersProvider =
    FutureProvider((ref) => ref.watch(contentRepoProvider).listBanners());
final faqsProvider =
    FutureProvider((ref) => ref.watch(contentRepoProvider).listFaqs());

// ========== COUPONS ==========
class CouponRepository {
  CouponRepository(this._client);
  final SupabaseClient _client;

  Future<Coupon?> byCode(String code) async {
    final row = await _client
        .from('coupons')
        .select()
        .eq('code', code.toUpperCase())
        .eq('is_active', true)
        .maybeSingle();
    return row == null ? null : Coupon.fromRow(row);
  }

  Future<void> applyToBooking(String bookingId, String couponId, double discount) =>
      _client.from('booking_coupons').insert({
        'booking_id': bookingId,
        'coupon_id': couponId,
        'discount_applied': discount,
      });
}

final couponRepoProvider =
    Provider((ref) => CouponRepository(ref.watch(supabaseClientProvider)));

// ========== CHECKLIST ==========
class ChecklistRepository {
  ChecklistRepository(this._client);
  final SupabaseClient _client;

  Future<List<ChecklistItem>> forBooking(String bookingId) async {
    final rows = await _client
        .from('booking_checklist')
        .select()
        .eq('booking_id', bookingId)
        .order('sort_order');
    return (rows as List).map((e) => ChecklistItem.fromRow(e)).toList();
  }

  Future<void> generateFromTemplate(String bookingId, String eventType) async {
    final tpl = await _client
        .from('checklist_templates')
        .select()
        .eq('event_type', eventType)
        .maybeSingle();
    if (tpl == null) return;
    final items = (tpl['items'] as List).cast<String>();
    final rows = items
        .asMap()
        .entries
        .map((e) => {
              'booking_id': bookingId,
              'title': e.value,
              'sort_order': e.key,
            })
        .toList();
    await _client.from('booking_checklist').insert(rows);
  }

  Future<void> toggle(String id, bool done) =>
      _client.from('booking_checklist').update({'is_done': done}).eq('id', id);

  Future<void> add(String bookingId, String title) =>
      _client.from('booking_checklist').insert({
        'booking_id': bookingId,
        'title': title,
      });

  Future<void> delete(String id) =>
      _client.from('booking_checklist').delete().eq('id', id);
}

final checklistRepoProvider =
    Provider((ref) => ChecklistRepository(ref.watch(supabaseClientProvider)));

final checklistProvider = FutureProvider.family<List<ChecklistItem>, String>(
    (ref, bookingId) => ref.watch(checklistRepoProvider).forBooking(bookingId));

// ========== REFERRALS ==========
class ReferralRepository {
  ReferralRepository(this._client);
  final SupabaseClient _client;

  Future<List<Referral>> listMine() async {
    final uid = _client.auth.currentUser!.id;
    final rows = await _client
        .from('referrals')
        .select()
        .eq('referrer_id', uid)
        .order('created_at', ascending: false);
    return (rows as List).map((e) => Referral.fromRow(e)).toList();
  }

  Future<Referral> generateMyCode() async {
    final uid = _client.auth.currentUser!.id;
    final code = 'JAL${uid.substring(0, 6).toUpperCase()}';
    final row = await _client
        .from('referrals')
        .insert({'referrer_id': uid, 'code': code})
        .select()
        .single();
    return Referral.fromRow(row);
  }
}

final referralRepoProvider =
    Provider((ref) => ReferralRepository(ref.watch(supabaseClientProvider)));

final myReferralsProvider =
    FutureProvider((ref) => ref.watch(referralRepoProvider).listMine());

// ========== PAYOUTS ==========
class PayoutRepository {
  PayoutRepository(this._client);
  final SupabaseClient _client;

  Future<List<Payout>> listForVendor() async {
    final uid = _client.auth.currentUser!.id;
    final rows = await _client
        .from('payouts')
        .select('*, vendors!inner(user_id)')
        .eq('vendors.user_id', uid)
        .order('created_at', ascending: false);
    return (rows as List).map((e) => Payout.fromRow(e)).toList();
  }
}

final payoutRepoProvider =
    Provider((ref) => PayoutRepository(ref.watch(supabaseClientProvider)));

final myPayoutsProvider =
    FutureProvider((ref) => ref.watch(payoutRepoProvider).listForVendor());

// ========== SUPPORT TICKETS ==========
class SupportRepository {
  SupportRepository(this._client);
  final SupabaseClient _client;

  Future<List<SupportTicket>> listMine() async {
    final uid = _client.auth.currentUser!.id;
    final rows = await _client
        .from('support_tickets')
        .select()
        .eq('user_id', uid)
        .order('created_at', ascending: false);
    return (rows as List).map((e) => SupportTicket.fromRow(e)).toList();
  }

  Future<void> create({
    required String subject,
    required String message,
    String priority = 'normal',
    String? bookingId,
  }) async {
    final uid = _client.auth.currentUser!.id;
    await _client.from('support_tickets').insert({
      'user_id': uid,
      'subject': subject,
      'message': message,
      'priority': priority,
      if (bookingId != null) 'booking_id': bookingId,
    });
  }
}

final supportRepoProvider =
    Provider((ref) => SupportRepository(ref.watch(supabaseClientProvider)));

final myTicketsProvider =
    FutureProvider((ref) => ref.watch(supportRepoProvider).listMine());

// ========== VENDOR AVAILABILITY ==========
class AvailabilityRepository {
  AvailabilityRepository(this._client);
  final SupabaseClient _client;

  Future<Set<DateTime>> blockedDates(String vendorId) async {
    final rows = await _client
        .from('vendor_availability')
        .select('blocked_date')
        .eq('vendor_id', vendorId);
    return (rows as List)
        .map((e) => DateTime.parse(e['blocked_date'] as String))
        .toSet();
  }

  Future<void> toggleBlock(String vendorId, DateTime date) async {
    final d = date.toIso8601String().substring(0, 10);
    final existing = await _client
        .from('vendor_availability')
        .select('id')
        .eq('vendor_id', vendorId)
        .eq('blocked_date', d)
        .maybeSingle();
    if (existing != null) {
      await _client
          .from('vendor_availability')
          .delete()
          .eq('id', existing['id']);
    } else {
      await _client
          .from('vendor_availability')
          .insert({'vendor_id': vendorId, 'blocked_date': d});
    }
  }
}

final availabilityRepoProvider =
    Provider((ref) => AvailabilityRepository(ref.watch(supabaseClientProvider)));
