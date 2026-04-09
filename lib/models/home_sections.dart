// ─── Sections / Home Data Models ─────────────────────────────────────────────

class HomeCategory {
  final String name;
  final String countDisplay;
  final String image;

  const HomeCategory({
    required this.name,
    required this.countDisplay,
    required this.image,
  });

  factory HomeCategory.fromJson(Map<String, dynamic> json) {
    return HomeCategory(
      name: json['name'] ?? '',
      countDisplay: json['count']?.toString() ?? '0',
      image: json['image'] ?? '',
    );
  }
}

class HomeTestimonial {
  final String quote;
  final String name;
  final String? role;
  final String avatar;

  const HomeTestimonial({
    required this.quote,
    required this.name,
    this.role,
    required this.avatar,
  });

  factory HomeTestimonial.fromJson(Map<String, dynamic> json) {
    return HomeTestimonial(
      quote: json['quote'] ?? '',
      name: json['name'] ?? '',
      role: json['role'],
      avatar: json['avatar'] ?? '',
    );
  }
}

class HomeFaq {
  final String question;
  final String answer;

  const HomeFaq({required this.question, required this.answer});

  factory HomeFaq.fromJson(Map<String, dynamic> json) {
    return HomeFaq(
      question: json['question'] ?? '',
      answer: json['answer'] ?? '',
    );
  }
}

class HomeStep {
  final String title;
  final String desc;

  const HomeStep({required this.title, required this.desc});

  factory HomeStep.fromJson(Map<String, dynamic> json) {
    return HomeStep(
      title: json['title'] ?? '',
      desc: json['desc'] ?? '',
    );
  }
}

class Partner {
  final int id;
  final String name;
  final String? logoUrl;
  final String? link;

  const Partner({
    required this.id,
    required this.name,
    this.logoUrl,
    this.link,
  });

  factory Partner.fromJson(Map<String, dynamic> json) {
    return Partner(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      logoUrl: json['logo_url'],
      link: json['link'],
    );
  }
}

class HomeBanner {
  final int id;
  final String? title;
  final String? link;
  final String image;

  const HomeBanner({
    required this.id,
    this.title,
    this.link,
    required this.image,
  });

  factory HomeBanner.fromJson(Map<String, dynamic> json) {
    return HomeBanner(
      id: json['id'] ?? 0,
      title: json['title'],
      link: json['link'],
      image: json['image'] ?? '',
    );
  }
}

class HomeSections {
  final List<HomeCategory> categories;
  final List<HomeTestimonial> testimonials;
  final List<HomeFaq> faqs;
  final List<HomeStep> steps;
  final List<Partner> partners;
  final List<HomeBanner> banners;
  final Map<String, dynamic> hero;

  const HomeSections({
    this.categories = const [],
    this.testimonials = const [],
    this.faqs = const [],
    this.steps = const [],
    this.partners = const [],
    this.banners = const [],
    this.hero = const {},
  });

  factory HomeSections.fromJson(Map<String, dynamic> json) {
    return HomeSections(
      categories: (json['categories'] as List<dynamic>? ?? [])
          .map((c) => HomeCategory.fromJson(c))
          .toList(),
      testimonials: (json['testimonials'] as List<dynamic>? ?? [])
          .map((t) => HomeTestimonial.fromJson(t))
          .toList(),
      faqs: (json['faqs'] as List<dynamic>? ?? [])
          .map((f) => HomeFaq.fromJson(f))
          .toList(),
      steps: (json['steps'] as List<dynamic>? ?? [])
          .map((s) => HomeStep.fromJson(s))
          .toList(),
      partners: (json['partners'] as List<dynamic>? ?? [])
          .map((p) => Partner.fromJson(p))
          .toList(),
      banners: (json['banners'] as List<dynamic>? ?? [])
          .map((b) => HomeBanner.fromJson(b))
          .toList(),
      hero: json['hero'] is Map ? Map<String, dynamic>.from(json['hero']) : {},
    );
  }
}
