import 'dart:convert';
import '../env/env.dart';

class ProfessionalGig {
  final int id;
  final String title;
  final String slug;
  final String description;
  final String thumbnail;
  final String sellerName;
  final String sellerImage;
  final String sellerRating;
  final String price;
  final String category;

  ProfessionalGig({
    required this.id,
    required this.title,
    required this.slug,
    required this.description,
    required this.thumbnail,
    required this.sellerName,
    required this.sellerImage,
    required this.sellerRating,
    required this.price,
    required this.category,
  });

  factory ProfessionalGig.fromJson(Map<String, dynamic> json) {
    // Pricing tiers is cast to array in Laravel model
    final List<dynamic> tiers = json['pricing_tiers'] ?? [];
    final String priceVal = tiers.isNotEmpty ? (tiers[0]['price']?.toString() ?? '0') : '0';
    
    // Gallery parsing
    String thumb = '';
    if (json['gallery'] != null) {
      if (json['gallery'] is List && (json['gallery'] as List).isNotEmpty) {
        thumb = json['gallery'][0].toString();
      } else if (json['gallery'] is String) {
        String gStr = json['gallery'].toString().trim();
        if (gStr.startsWith('[')) {
          try {
            List<dynamic> parsed = jsonDecode(gStr);
            if (parsed.isNotEmpty) thumb = parsed[0].toString();
          } catch (_) {}
        } else if (gStr.isNotEmpty) {
          thumb = gStr;
        }
      }
    }
    if (thumb.isNotEmpty && !thumb.startsWith('http')) {
      final String baseUrl = Env.apiUrl.endsWith('/') ? Env.apiUrl.substring(0, Env.apiUrl.length - 1) : Env.apiUrl;
      final String path = thumb.startsWith('/') ? thumb : '/$thumb';
      thumb = '$baseUrl$path';
    }

    String avatar = json['user']?['avatar_url'] ?? '';
    if (avatar.isNotEmpty && !avatar.startsWith('http')) {
      final String baseUrl = Env.apiUrl.endsWith('/') ? Env.apiUrl.substring(0, Env.apiUrl.length - 1) : Env.apiUrl;
      final String path = avatar.startsWith('/') ? avatar : '/$avatar';
      avatar = '$baseUrl$path';
    }

    return ProfessionalGig(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      slug: json['slug'] ?? '',
      description: json['description'] ?? '',
      thumbnail: thumb,
      sellerName: json['user']?['name'] ?? 'Professional',
      sellerImage: avatar,
      sellerRating: '5.0', // Placeholder as rating is not directly on ServiceListing model in PHP snippet
      price: priceVal,
      category: json['service_category']?['name'] ?? '',
    );
  }
}

class ProfessionalGigPagination {
  final List<ProfessionalGig> gigs;
  final int currentPage;
  final int lastPage;
  final int total;

  ProfessionalGigPagination({
    required this.gigs,
    required this.currentPage,
    required this.lastPage,
    required this.total,
  });
}
