// ─── Blog / Post Models ───────────────────────────────────────────────────────

class BlogPagination {
  final List<BlogPost> posts;
  final int currentPage;
  final int lastPage;
  final int total;

  const BlogPagination({
    this.posts = const [],
    this.currentPage = 1,
    this.lastPage = 1,
    this.total = 0,
  });

  factory BlogPagination.fromJson(Map<String, dynamic> json) {
    return BlogPagination(
      posts: (json['posts'] as List<dynamic>? ?? []).map((p) => BlogPost.fromJson(p)).toList(),
      currentPage: json['current_page'] ?? 1,
      lastPage: json['last_page'] ?? 1,
      total: json['total'] ?? 0,
    );
  }
}


class BlogPost {
  final int id;
  final String title;
  final String slug;
  final String? excerpt;
  final String? category;
  final String? date;
  final String? image;

  const BlogPost({
    required this.id,
    required this.title,
    required this.slug,
    this.excerpt,
    this.category,
    this.date,
    this.image,
  });

  factory BlogPost.fromJson(Map<String, dynamic> json) {
    return BlogPost(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      slug: json['slug'] ?? '',
      excerpt: json['excerpt'],
      category: json['category'],
      date: json['date'],
      image: json['image'],
    );
  }

  String get imageUrl {
    if (image == null) return '';
    if (image!.startsWith('http')) return image!;
    return 'https://www.starjd.com$image';
  }
}

class BlogPostDetail extends BlogPost {
  final String? body;
  final String? author;
  final String? metaTitle;
  final String? metaDescription;
  final List<String> categoryTags;
  final int viewCount;
  final String? updatedAt;

  const BlogPostDetail({
    required super.id,
    required super.title,
    required super.slug,
    super.excerpt,
    super.category,
    super.date,
    super.image,
    this.body,
    this.author,
    this.metaTitle,
    this.metaDescription,
    this.categoryTags = const [],
    this.viewCount = 0,
    this.updatedAt,
  });

  factory BlogPostDetail.fromJson(Map<String, dynamic> json) {
    return BlogPostDetail(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      slug: json['slug'] ?? '',
      excerpt: json['excerpt'],
      category: json['category'],
      date: json['date'],
      image: json['image'],
      body: json['body'],
      author: json['author'],
      metaTitle: json['meta_title'],
      metaDescription: json['meta_description'],
      categoryTags: (json['category_tags'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      viewCount: json['view_count'] ?? 0,
      updatedAt: json['updated_at'],
    );
  }
}

class BlogCategory {
  final String label;
  final String slug;

  const BlogCategory({required this.label, required this.slug});

  factory BlogCategory.fromJson(Map<String, dynamic> json) {
    return BlogCategory(
      label: json['label'] ?? '',
      slug: json['slug'] ?? '',
    );
  }
}
