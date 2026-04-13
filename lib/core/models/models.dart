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
  final String? city;
  final double? basePrice;
  final bool isVerified;
  final double ratingAvg;
  final List<String> portfolioUrls;
  final String? name;
  final String? avatarUrl;

  const Vendor({
    required this.id,
    required this.userId,
    required this.category,
    required this.isVerified,
    required this.ratingAvg,
    this.bio,
    this.city,
    this.basePrice,
    this.portfolioUrls = const [],
    this.name,
    this.avatarUrl,
  });

  factory Vendor.fromRow(Map<String, dynamic> r) {
    final user = r['users'] as Map<String, dynamic>?;
    return Vendor(
      id: r['id'] as String,
      userId: r['user_id'] as String,
      category: r['category'] as String,
      bio: r['bio'] as String?,
      city: r['city'] as String?,
      basePrice: (r['base_price'] as num?)?.toDouble(),
      isVerified: (r['is_verified'] as bool?) ?? false,
      ratingAvg: ((r['rating_avg'] as num?) ?? 0).toDouble(),
      portfolioUrls:
          (r['portfolio_urls'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      name: user?['name'] as String?,
      avatarUrl: user?['avatar_url'] as String?,
    );
  }
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
  });

  factory Message.fromRow(Map<String, dynamic> r) => Message(
        id: r['id'] as String,
        bookingId: r['booking_id'] as String,
        senderId: r['sender_id'] as String,
        receiverId: r['receiver_id'] as String,
        content: r['content'] as String,
        isRead: (r['is_read'] as bool?) ?? false,
        createdAt: DateTime.parse(r['created_at'] as String),
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
