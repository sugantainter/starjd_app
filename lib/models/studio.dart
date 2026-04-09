// Models for Studio data

class StudioCategory {
  final int id;
  final String name;
  final String slug;

  const StudioCategory({
    required this.id,
    required this.name,
    required this.slug,
  });

  factory StudioCategory.fromJson(Map<String, dynamic> json) {
    return StudioCategory(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
    );
  }
}

class StudioAmenity {
  final int id;
  final String name;
  final String? slug;
  final String? icon;

  const StudioAmenity({
    required this.id,
    required this.name,
    this.slug,
    this.icon,
  });

  factory StudioAmenity.fromJson(Map<String, dynamic> json) {
    return StudioAmenity(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      slug: json['slug'],
      icon: json['icon'],
    );
  }
}

class StudioReview {
  final int id;
  final double rating;
  final String? comment;
  final String? userName;
  final String createdAt;

  const StudioReview({
    required this.id,
    required this.rating,
    this.comment,
    this.userName,
    required this.createdAt,
  });

  factory StudioReview.fromJson(Map<String, dynamic> json) {
    return StudioReview(
      id: json['id'] ?? 0,
      rating: (json['rating'] ?? 0).toDouble(),
      comment: json['comment'],
      userName: json['user_name'],
      createdAt: json['created_at'] ?? '',
    );
  }

  String get timeAgo {
    try {
      final dt = DateTime.parse(createdAt);
      final diff = DateTime.now().difference(dt);
      if (diff.inDays > 30) return '${(diff.inDays / 30).floor()}mo ago';
      if (diff.inDays > 0) return '${diff.inDays}d ago';
      if (diff.inHours > 0) return '${diff.inHours}h ago';
      return 'Just now';
    } catch (_) {
      return '';
    }
  }
}

class Studio {
  final int id;
  final String slug;
  final String name;
  final String? description;
  final String? mainImage;
  final double? pricePerHour;
  final double? pricePerDay;
  final double? ratingAvg;
  final int reviewsCount;
  final StudioCategory? category;
  final String? city;
  final String? state;
  final String? address;
  final String? pincode;
  final bool featured;
  // Detail-only fields
  final List<StudioAmenity> amenities;
  final List<StudioReview> reviews;
  final List<Map<String, dynamic>> gallery;

  const Studio({
    required this.id,
    required this.slug,
    required this.name,
    this.description,
    this.mainImage,
    this.pricePerHour,
    this.pricePerDay,
    this.ratingAvg,
    this.reviewsCount = 0,
    this.category,
    this.city,
    this.state,
    this.address,
    this.pincode,
    this.featured = false,
    this.amenities = const [],
    this.reviews = const [],
    this.gallery = const [],
  });

  factory Studio.fromJson(Map<String, dynamic> json) {
    return Studio(
      id: json['id'] ?? 0,
      slug: json['slug'] ?? '',
      name: json['name'] ?? 'Unknown Studio',
      description: json['description'],
      mainImage: json['main_image'],
      pricePerHour: _toDouble(json['price_per_hour']),
      pricePerDay: _toDouble(json['price_per_day']),
      ratingAvg: _toDouble(json['rating_avg']),
      reviewsCount: (json['reviews_count'] ?? 0) is int ? (json['reviews_count'] ?? 0) : int.tryParse(json['reviews_count']?.toString() ?? '') ?? 0,
      category: json['category'] != null
          ? StudioCategory.fromJson(json['category'])
          : null,
      city: json['city'],
      state: json['state'],
      address: json['address'],
      pincode: json['pincode'],
      featured: json['featured'] ?? false,
      amenities: (json['amenities'] as List<dynamic>? ?? [])
          .map((a) => StudioAmenity.fromJson(a))
          .toList(),
      reviews: (json['reviews'] as List<dynamic>? ?? [])
          .map((r) => StudioReview.fromJson(r))
          .toList(),
      gallery: (json['gallery'] as List<dynamic>? ?? [])
          .map((g) => Map<String, dynamic>.from(g))
          .toList(),
    );
  }

  String get locationDisplay {
    if (city != null && state != null) return '$city, $state';
    if (city != null) return city!;
    if (state != null) return state!;
    return 'Location not specified';
  }

  String get displayPrice {
    if (pricePerHour != null) return '₹${pricePerHour!.toInt()}/hr';
    if (pricePerDay != null) return '₹${pricePerDay!.toInt()}/day';
    return 'Contact for price';
  }

  int get pricePerHourInt => pricePerHour?.toInt() ?? 0;

  static double? _toDouble(dynamic val) {
    if (val == null) return null;
    if (val is double) return val;
    if (val is int) return val.toDouble();
    if (val is String) return double.tryParse(val);
    return null;
  }
}

class StudioPagination {
  final List<Studio> studios;
  final int currentPage;
  final int lastPage;
  final int total;
  final int perPage;

  const StudioPagination({
    required this.studios,
    required this.currentPage,
    required this.lastPage,
    required this.total,
    required this.perPage,
  });
}
