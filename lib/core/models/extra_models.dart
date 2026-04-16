class City {
  final String id;
  final String name;
  final String state;
  const City({required this.id, required this.name, required this.state});
  factory City.fromRow(Map<String, dynamic> r) => City(
        id: r['id'] as String,
        name: r['name'] as String,
        state: r['state'] as String,
      );
}

class VendorCategory {
  final String slug;
  final String name;
  final String? icon;
  const VendorCategory({required this.slug, required this.name, this.icon});
  factory VendorCategory.fromRow(Map<String, dynamic> r) => VendorCategory(
        slug: r['slug'] as String,
        name: r['name'] as String,
        icon: r['icon'] as String?,
      );
}

class Banner {
  final String id;
  final String title;
  final String? subtitle;
  final String? imageUrl;
  final String? actionUrl;
  const Banner({
    required this.id,
    required this.title,
    this.subtitle,
    this.imageUrl,
    this.actionUrl,
  });
  factory Banner.fromRow(Map<String, dynamic> r) => Banner(
        id: r['id'] as String,
        title: r['title'] as String,
        subtitle: r['subtitle'] as String?,
        imageUrl: r['image_url'] as String?,
        actionUrl: r['action_url'] as String?,
      );
}

class Faq {
  final String id;
  final String? category;
  final String question;
  final String answer;
  const Faq({required this.id, required this.question, required this.answer, this.category});
  factory Faq.fromRow(Map<String, dynamic> r) => Faq(
        id: r['id'] as String,
        category: r['category'] as String?,
        question: r['question'] as String,
        answer: r['answer'] as String,
      );
}

class Coupon {
  final String id;
  final String code;
  final String? description;
  final String discountType;
  final double discountValue;
  final double minOrder;
  final double? maxDiscount;
  const Coupon({
    required this.id,
    required this.code,
    required this.discountType,
    required this.discountValue,
    required this.minOrder,
    this.description,
    this.maxDiscount,
  });
  factory Coupon.fromRow(Map<String, dynamic> r) => Coupon(
        id: r['id'] as String,
        code: r['code'] as String,
        description: r['description'] as String?,
        discountType: r['discount_type'] as String,
        discountValue: (r['discount_value'] as num).toDouble(),
        minOrder: ((r['min_order'] as num?) ?? 0).toDouble(),
        maxDiscount: (r['max_discount'] as num?)?.toDouble(),
      );

  double applyTo(double amount) {
    if (amount < minOrder) return 0;
    double d = discountType == 'percent' ? amount * discountValue / 100 : discountValue;
    if (maxDiscount != null && d > maxDiscount!) d = maxDiscount!;
    return d;
  }
}

class ChecklistItem {
  final String id;
  final String bookingId;
  final String title;
  final bool isDone;
  final DateTime? dueDate;
  const ChecklistItem({
    required this.id,
    required this.bookingId,
    required this.title,
    required this.isDone,
    this.dueDate,
  });
  factory ChecklistItem.fromRow(Map<String, dynamic> r) => ChecklistItem(
        id: r['id'] as String,
        bookingId: r['booking_id'] as String,
        title: r['title'] as String,
        isDone: (r['is_done'] as bool?) ?? false,
        dueDate:
            r['due_date'] != null ? DateTime.parse(r['due_date'] as String) : null,
      );
}

class Payout {
  final String id;
  final double amount;
  final String status;
  final String? method;
  final DateTime createdAt;
  final DateTime? paidAt;
  const Payout({
    required this.id,
    required this.amount,
    required this.status,
    required this.createdAt,
    this.method,
    this.paidAt,
  });
  factory Payout.fromRow(Map<String, dynamic> r) => Payout(
        id: r['id'] as String,
        amount: (r['amount'] as num).toDouble(),
        status: r['status'] as String,
        method: r['method'] as String?,
        createdAt: DateTime.parse(r['created_at'] as String),
        paidAt:
            r['paid_at'] != null ? DateTime.parse(r['paid_at'] as String) : null,
      );
}

class SupportTicket {
  final String id;
  final String subject;
  final String message;
  final String status;
  final String priority;
  final DateTime createdAt;
  const SupportTicket({
    required this.id,
    required this.subject,
    required this.message,
    required this.status,
    required this.priority,
    required this.createdAt,
  });
  factory SupportTicket.fromRow(Map<String, dynamic> r) => SupportTicket(
        id: r['id'] as String,
        subject: r['subject'] as String,
        message: r['message'] as String,
        status: r['status'] as String,
        priority: r['priority'] as String,
        createdAt: DateTime.parse(r['created_at'] as String),
      );
}

class SupportMessage {
  final String id;
  final String ticketId;
  final String senderId;
  final String body;
  final bool isAdmin;
  final DateTime createdAt;
  const SupportMessage({
    required this.id,
    required this.ticketId,
    required this.senderId,
    required this.body,
    required this.isAdmin,
    required this.createdAt,
  });
  factory SupportMessage.fromRow(Map<String, dynamic> r) => SupportMessage(
        id: r['id'] as String,
        ticketId: r['ticket_id'] as String,
        senderId: r['sender_id'] as String,
        body: r['body'] as String,
        isAdmin: (r['is_admin'] as bool?) ?? false,
        createdAt: DateTime.parse(r['created_at'] as String),
      );
}

class Referral {
  final String id;
  final String code;
  final String status;
  final double rewardAmount;
  final DateTime createdAt;
  const Referral({
    required this.id,
    required this.code,
    required this.status,
    required this.rewardAmount,
    required this.createdAt,
  });
  factory Referral.fromRow(Map<String, dynamic> r) => Referral(
        id: r['id'] as String,
        code: r['code'] as String,
        status: r['status'] as String,
        rewardAmount: ((r['reward_amount'] as num?) ?? 0).toDouble(),
        createdAt: DateTime.parse(r['created_at'] as String),
      );
}
