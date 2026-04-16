// Lightweight plain-Dart models (no codegen) for Supabase rows.

enum BookingStatus {
  pending,
  confirmed,
  inProgress,
  completed,
  cancelled,
  refunded;

  static BookingStatus fromString(String? v) => switch (v) {
        'confirmed' => BookingStatus.confirmed,
        'in_progress' => BookingStatus.inProgress,
        'completed' => BookingStatus.completed,
        'cancelled' => BookingStatus.cancelled,
        'refunded' => BookingStatus.refunded,
        _ => BookingStatus.pending,
      };

  String get value => switch (this) {
        BookingStatus.confirmed => 'confirmed',
        BookingStatus.inProgress => 'in_progress',
        BookingStatus.completed => 'completed',
        BookingStatus.cancelled => 'cancelled',
        BookingStatus.refunded => 'refunded',
        _ => 'pending',
      };

  String get label => switch (this) {
        BookingStatus.pending => 'Pending',
        BookingStatus.confirmed => 'Confirmed',
        BookingStatus.inProgress => 'In Progress',
        BookingStatus.completed => 'Completed',
        BookingStatus.cancelled => 'Cancelled',
        BookingStatus.refunded => 'Refunded',
      };
}

class ServicePackage {
  final String id;
  final String slug;
  final String name;
  final String? description;
  final double basePrice;
  final String? planningDuration;
  final List<String> features;
  final String? imageUrl;

  const ServicePackage({
    required this.id,
    required this.slug,
    required this.name,
    required this.basePrice,
    this.description,
    this.planningDuration,
    this.features = const [],
    this.imageUrl,
  });

  factory ServicePackage.fromRow(Map<String, dynamic> r) => ServicePackage(
        id: r['id'] as String,
        slug: r['slug'] as String,
        name: r['name'] as String,
        description: r['description'] as String?,
        basePrice: (r['base_price'] as num).toDouble(),
        planningDuration: r['planning_duration'] as String?,
        features: (r['features'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        imageUrl: r['image_url'] as String?,
      );
}

class Vendor {
  final String id;
  final String userId;
  final String category;
  final String? bio;
  final String? tagline;
  final String? city;
  final String? address;
  final double? lat;
  final double? lng;
  final double? basePrice;
  final bool isVerified;
  final bool isFeatured;
  final bool fullyBooked;
  final double ratingAvg;
  final int eventsCount;
  final int yearsExperience;
  final int profileViews;
  final List<String> portfolioUrls;
  final List<String> serviceCities;
  final List<String> languages;
  final String? name;
  final String? avatarUrl;
  final String? phone;
  final String? whatsapp;
  final String? instagramUrl;
  final String? youtubeUrl;
  final String? facebookUrl;
  final Map<String, dynamic> meta;
  final bool isAcceptingBookings;
  final int responseRate;
  final bool badgeTop10;
  final int earlyBirdDiscount;
  final List<String> videoUrls;
  final DateTime? createdAt;
  final int? acceptanceHours;

  const Vendor({
    required this.id,
    required this.userId,
    required this.category,
    required this.isVerified,
    required this.ratingAvg,
    this.bio,
    this.tagline,
    this.city,
    this.address,
    this.lat,
    this.lng,
    this.basePrice,
    this.isFeatured = false,
    this.fullyBooked = false,
    this.isAcceptingBookings = true,
    this.responseRate = 100,
    this.badgeTop10 = false,
    this.earlyBirdDiscount = 0,
    this.eventsCount = 0,
    this.yearsExperience = 0,
    this.profileViews = 0,
    this.portfolioUrls = const [],
    this.videoUrls = const [],
    this.serviceCities = const [],
    this.languages = const [],
    this.name,
    this.avatarUrl,
    this.phone,
    this.whatsapp,
    this.instagramUrl,
    this.youtubeUrl,
    this.facebookUrl,
    this.meta = const {},
    this.createdAt,
    this.acceptanceHours,
  });

  factory Vendor.fromRow(Map<String, dynamic> r) {
    final user = r['users'] as Map<String, dynamic>?;
    return Vendor(
      id: r['id'] as String,
      userId: r['user_id'] as String,
      category: r['category'] as String,
      bio: r['bio'] as String?,
      tagline: r['tagline'] as String?,
      city: r['city'] as String?,
      address: r['address'] as String?,
      lat: (r['lat'] as num?)?.toDouble(),
      lng: (r['lng'] as num?)?.toDouble(),
      basePrice: (r['base_price'] as num?)?.toDouble(),
      isVerified: (r['is_verified'] as bool?) ?? false,
      isFeatured: (r['is_featured'] as bool?) ?? false,
      fullyBooked: (r['fully_booked'] as bool?) ?? false,
      ratingAvg: ((r['rating_avg'] as num?) ?? 0).toDouble(),
      eventsCount: (r['events_count'] as int?) ?? 0,
      yearsExperience: (r['years_experience'] as int?) ?? 0,
      profileViews: (r['profile_views'] as int?) ?? 0,
      portfolioUrls:
          (r['portfolio_urls'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      serviceCities:
          (r['service_cities'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      languages:
          (r['languages'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      name: user?['name'] as String?,
      avatarUrl: user?['avatar_url'] as String?,
      phone: r['phone'] as String?,
      whatsapp: r['whatsapp'] as String?,
      instagramUrl: r['instagram_url'] as String?,
      youtubeUrl: r['youtube_url'] as String?,
      facebookUrl: r['facebook_url'] as String?,
      meta: (r['meta'] as Map<String, dynamic>?) ?? const {},
      isAcceptingBookings: (r['is_accepting_bookings'] as bool?) ?? true,
      responseRate: (r['response_rate'] as int?) ?? 100,
      badgeTop10: (r['badge_top_10'] as bool?) ?? false,
      earlyBirdDiscount: (r['early_bird_discount'] as int?) ?? 0,
      videoUrls: (r['video_urls'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      createdAt: r['created_at'] != null ? DateTime.tryParse(r['created_at'].toString()) : null,
      acceptanceHours: r['acceptance_hours'] as int?,
    );
  }
}

class Report {
  final String id;
  final String reporterId;
  final String reportedVendorId;
  final String reason;
  final String? description;
  final String status;
  final DateTime createdAt;

  const Report({
    required this.id,
    required this.reporterId,
    required this.reportedVendorId,
    required this.reason,
    required this.status,
    required this.createdAt,
    this.description,
  });

  factory Report.fromRow(Map<String, dynamic> r) => Report(
        id: r['id'] as String,
        reporterId: r['reporter_id'] as String,
        reportedVendorId: r['reported_vendor_id'] as String,
        reason: r['reason'] as String,
        description: r['description'] as String?,
        status: (r['status'] as String?) ?? 'pending',
        createdAt: DateTime.parse(r['created_at'] as String),
      );
}

class VendorPackage {
  final String id;
  final String vendorId;
  final String name;
  final double price;
  final int? durationHours;
  final List<String> features;
  final String? eventType;

  const VendorPackage({
    required this.id,
    required this.vendorId,
    required this.name,
    required this.price,
    this.durationHours,
    this.features = const [],
    this.eventType,
  });

  factory VendorPackage.fromRow(Map<String, dynamic> r) => VendorPackage(
        id: r['id'] as String,
        vendorId: r['vendor_id'] as String,
        name: r['name'] as String,
        price: (r['price'] as num).toDouble(),
        durationHours: r['duration_hours'] as int?,
        features: (r['features'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        eventType: r['event_type'] as String?,
      );
}

class Booking {
  final String id;
  final String clientId;
  final String? vendorId;
  final String? serviceId;
  final DateTime eventDate;
  final BookingStatus status;
  final int? guestCount;
  final String? venue;
  final String? notes;
  final double totalAmount;
  final double advancePaid;
  final DateTime createdAt;

  const Booking({
    required this.id,
    required this.clientId,
    required this.eventDate,
    required this.status,
    required this.totalAmount,
    required this.advancePaid,
    required this.createdAt,
    this.vendorId,
    this.serviceId,
    this.guestCount,
    this.venue,
    this.notes,
  });

  factory Booking.fromRow(Map<String, dynamic> r) => Booking(
        id: r['id'] as String,
        clientId: r['client_id'] as String,
        vendorId: r['vendor_id'] as String?,
        serviceId: r['service_id'] as String?,
        eventDate: DateTime.parse(r['event_date'] as String),
        status: BookingStatus.fromString(r['status'] as String?),
        guestCount: r['guest_count'] as int?,
        venue: r['venue'] as String?,
        notes: r['notes'] as String?,
        totalAmount: (r['total_amount'] as num).toDouble(),
        advancePaid: ((r['advance_paid'] as num?) ?? 0).toDouble(),
        createdAt: DateTime.parse(r['created_at'] as String),
      );
}

class Message {
  final String id;
  final String bookingId;
  final String senderId;
  final String receiverId;
  final String content;
  final String? imageUrl;
  final bool isRead;
  final DateTime createdAt;

  const Message({
    required this.id,
    required this.bookingId,
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.isRead,
    required this.createdAt,
    this.imageUrl,
  });

  factory Message.fromRow(Map<String, dynamic> r) => Message(
        id: r['id'] as String,
        bookingId: r['booking_id'] as String,
        senderId: r['sender_id'] as String,
        receiverId: r['receiver_id'] as String,
        content: r['content'] as String,
        imageUrl: r['image_url'] as String?,
        isRead: (r['is_read'] as bool?) ?? false,
        createdAt: DateTime.parse(r['created_at'] as String),
      );
}

class PlatformUser {
  final String id;
  final String? name;
  final String? phone;
  final String? role;
  final String? city;
  final String? avatarUrl;
  final bool isSuspended;
  final bool isBanned;
  final String? banReason;

  const PlatformUser({
    required this.id,
    this.name,
    this.phone,
    this.role,
    this.city,
    this.avatarUrl,
    this.isSuspended = false,
    this.isBanned = false,
    this.banReason,
  });

  factory PlatformUser.fromRow(Map<String, dynamic> r) => PlatformUser(
        id: r['id'] as String,
        name: r['name'] as String?,
        phone: r['phone'] as String?,
        role: r['role'] as String?,
        city: r['city'] as String?,
        avatarUrl: r['avatar_url'] as String?,
        isSuspended: (r['is_suspended'] as bool?) ?? false,
        isBanned: (r['is_banned'] as bool?) ?? false,
        banReason: r['ban_reason'] as String?,
      );
}

class AppNotification {
  final String id;
  final String title;
  final String? body;
  final String? type;
  final bool isRead;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.title,
    required this.isRead,
    required this.createdAt,
    this.body,
    this.type,
  });

  factory AppNotification.fromRow(Map<String, dynamic> r) => AppNotification(
        id: r['id'] as String,
        title: r['title'] as String,
        body: r['body'] as String?,
        type: r['type'] as String?,
        isRead: (r['is_read'] as bool?) ?? false,
        createdAt: DateTime.parse(r['created_at'] as String),
      );
}
