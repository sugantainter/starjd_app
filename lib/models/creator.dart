// ─── Creator Models ───────────────────────────────────────────────────────────

class SocialAccount {
  final String platform;
  final String? username;
  final String? profileUrl;
  final int? followersCount;
  final bool isConnected;
  final Map<String, dynamic>? analyticsData;

  const SocialAccount({
    required this.platform,
    this.username,
    this.profileUrl,
    this.followersCount,
    this.isConnected = false,
    this.analyticsData,
  });

  factory SocialAccount.fromJson(Map<String, dynamic> json) {
    return SocialAccount(
      platform: json['platform'] ?? '',
      username: json['username'],
      profileUrl: json['profile_url'],
      followersCount: _toInt(json['followers_count'], nullable: true),
      isConnected: json['is_connected'] ?? false,
      analyticsData: json['analytics_data'],
    );
  }

  String get platformIcon {
    switch (platform.toLowerCase()) {
      case 'instagram':
        return 'IG';
      case 'youtube':
        return 'YT';
      case 'tiktok':
        return 'TK';
      case 'twitter':
      case 'x':
        return 'X';
      case 'facebook':
        return 'FB';
      case 'linkedin':
        return 'LI';
      default:
        return platform.substring(0, 2).toUpperCase();
    }
  }

  String get formattedFollowers {
    if (followersCount == null) return '';
    final n = followersCount!;
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }
}

class CreatorPackage {
  final int id;
  final String name;
  final double price;
  final String? description;
  final String? category;

  const CreatorPackage({
    required this.id,
    required this.name,
    required this.price,
    this.description,
    this.category,
  });

  factory CreatorPackage.fromJson(Map<String, dynamic> json) {
    return CreatorPackage(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      price: _toDouble(json['price']) ?? 0.0,
      description: json['description'],
      category: json['category'],
    );
  }
}

class CreatorPortfolioItem {
  final int id;
  final String? image;
  final String? caption;

  const CreatorPortfolioItem({
    required this.id,
    this.image,
    this.caption,
  });

  factory CreatorPortfolioItem.fromJson(Map<String, dynamic> json) {
    return CreatorPortfolioItem(
      id: json['id'] ?? 0,
      image: json['image'],
      caption: json['caption'],
    );
  }
}

class Creator {
  final int id;
  final int? userId;
  final String slug;
  final String? name;
  final String? bio;
  final String? avatar;
  final String? avatarUrl;
  final String? location;
  final String? tagline;
  final String? category;
  final String? gender;
  final String? language;
  final double? minRate;
  final double? engagementRate;
  final String? verificationStatus;
  final bool isFeatured;
  final int totalFollowers;
  final double? averageRating;
  final double? minPrice;
  final int packagesCount;
  // Detail-only
  final List<SocialAccount> socialAccounts;
  final List<CreatorPackage> packages;
  final List<CreatorPortfolioItem> portfolio;
  final int reviewsCount;

  const Creator({
    required this.id,
    this.userId,
    required this.slug,
    this.name,
    this.bio,
    this.avatar,
    this.avatarUrl,
    this.location,
    this.tagline,
    this.category,
    this.gender,
    this.language,
    this.minRate,
    this.engagementRate,
    this.verificationStatus,
    this.isFeatured = false,
    this.totalFollowers = 0,
    this.averageRating,
    this.minPrice,
    this.packagesCount = 0,
    this.socialAccounts = const [],
    this.packages = const [],
    this.portfolio = const [],
    this.reviewsCount = 0,
  });

  factory Creator.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>?;
    return Creator(
      id: json['id'] ?? 0,
      userId: user?['id'] ?? json['user_id'],
      slug: json['slug'] ?? '',
      name: user?['name'] ?? json['name'],
      bio: json['bio'],
      avatar: json['avatar'],
      avatarUrl: json['avatar_url'],
      location: json['location'],
      tagline: json['tagline'],
      category: json['category'],
      gender: json['gender'],
      language: json['language'],
      minRate: _toDouble(json['min_rate']),
      engagementRate: _toDouble(json['engagement_rate']),
      verificationStatus: json['verification_status'],
      isFeatured: json['is_featured'] ?? false,
      totalFollowers: _toInt(json['total_followers']) ?? 0,
      averageRating: _toDouble(json['average_rating']),
      minPrice: _toDouble(json['min_price']),
      packagesCount: _toInt(json['packages_count']) ?? 0,
      reviewsCount: _toInt(json['reviews_count']) ?? 0,
      socialAccounts: (json['user']?['social_accounts'] as List<dynamic>? ?? [])
          .map((s) => SocialAccount.fromJson(s))
          .where((s) => s.isConnected)
          .toList(),
      packages: (json['packages'] as List<dynamic>? ?? [])
          .map((p) => CreatorPackage.fromJson(p))
          .toList(),
      portfolio: (json['portfolio'] as List<dynamic>? ?? [])
          .map((p) => CreatorPortfolioItem.fromJson(p))
          .toList(),
    );
  }

  String get displayName => name ?? 'Creator';

  String get displayPrice {
    final rate = minPrice ?? minRate;
    if (rate != null) return '₹${rate.toInt()}';
    return 'Contact';
  }

  String get formattedFollowers {
    if (totalFollowers == 0) return '';
    if (totalFollowers >= 1000000) {
      return '${(totalFollowers / 1000000).toStringAsFixed(1)}M';
    }
    if (totalFollowers >= 1000) {
      return '${(totalFollowers / 1000).toStringAsFixed(1)}K';
    }
    return '$totalFollowers';
  }

  bool get isVerified => verificationStatus == 'verified';

  String get imageUrl {
    final url = avatarUrl ?? avatar;
    if (url == null) return '';
    if (url.startsWith('http')) return url;
    return 'https://www.starjd.com$url';
  }

  String get initials {
    final n = displayName.trim().split(' ');
    if (n.length >= 2) return '${n[0][0]}${n[1][0]}'.toUpperCase();
    return displayName.substring(0, displayName.length >= 2 ? 2 : 1).toUpperCase();
  }
}

class CreatorPagination {
  final List<Creator> creators;
  final int currentPage;
  final int lastPage;
  final int total;

  const CreatorPagination({
    required this.creators,
    required this.currentPage,
    required this.lastPage,
    required this.total,
  });
}

class CreatorFilters {
  final List<String> categories;
  final List<String> genders;
  final List<String> languages;
  final List<String> platforms;

  const CreatorFilters({
    this.categories = const [],
    this.genders = const [],
    this.languages = const [],
    this.platforms = const [],
  });

  factory CreatorFilters.fromJson(Map<String, dynamic> json) {
    List<String> list(String key) {
      final val = json[key];
      if (val is List) return val.map((e) => e.toString()).toList();
      if (val is Map) return val.values.map((e) => e.toString()).toList();
      return [];
    }
    return CreatorFilters(
      categories: list('categories'),
      genders: list('genders'),
      languages: list('languages'),
      platforms: list('platforms'),
    );
  }
}

double? _toDouble(dynamic val) {
  if (val == null) return null;
  if (val is double) return val;
  if (val is int) return val.toDouble();
  if (val is String) return double.tryParse(val);
  return null;
}

int? _toInt(dynamic val, {bool nullable = false}) {
  if (val == null) return nullable ? null : 0;
  if (val is int) return val;
  if (val is double) return val.toInt();
  if (val is String) return int.tryParse(val) ?? (nullable ? null : 0);
  return nullable ? null : 0;
}
