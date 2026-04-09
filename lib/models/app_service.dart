// ─── Service Models ───────────────────────────────────────────────────────────

class AppService {
  final int id;
  final String name;
  final String slug;
  final String? shortDescription;
  final String? image;
  final String? imageFit;

  const AppService({
    required this.id,
    required this.name,
    required this.slug,
    this.shortDescription,
    this.image,
    this.imageFit,
  });

  factory AppService.fromJson(Map<String, dynamic> json) {
    return AppService(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      shortDescription: json['short_description'],
      image: json['image'],
      imageFit: json['image_fit'],
    );
  }

  String get imageUrl {
    if (image == null) return '';
    if (image!.startsWith('http')) return image!;
    return 'https://www.starjd.com/storage/$image';
  }
}

class AppServiceDetail extends AppService {
  final String? body;
  final String? bannerImage;
  final String? bannerPosition;
  final String? metaTitle;
  final String? metaDescription;

  const AppServiceDetail({
    required super.id,
    required super.name,
    required super.slug,
    super.shortDescription,
    super.image,
    super.imageFit,
    this.body,
    this.bannerImage,
    this.bannerPosition,
    this.metaTitle,
    this.metaDescription,
  });

  factory AppServiceDetail.fromJson(Map<String, dynamic> json) {
    return AppServiceDetail(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      shortDescription: json['short_description'],
      image: json['image'],
      imageFit: json['image_fit'],
      body: json['body'],
      bannerImage: json['banner_image'],
      bannerPosition: json['banner_position'],
      metaTitle: json['meta_title'],
      metaDescription: json['meta_description'],
    );
  }

  String get bannerImageUrl {
    final b = bannerImage ?? image;
    if (b == null) return '';
    if (b.startsWith('http')) return b;
    return 'https://www.starjd.com/storage/$b';
  }
}
