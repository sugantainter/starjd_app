class AppVideo {
  final int id;
  final String videoId;
  final String title;
  final String? desc;
  final String embedUrl;
  final String watchUrl;

  const AppVideo({
    required this.id,
    required this.videoId,
    required this.title,
    this.desc,
    required this.embedUrl,
    required this.watchUrl,
  });

  factory AppVideo.fromJson(Map<String, dynamic> json) {
    return AppVideo(
      id: json['id'] ?? 0,
      videoId: json['videoId'] ?? '',
      title: json['title'] ?? '',
      desc: json['desc'],
      embedUrl: json['embedUrl'] ?? '',
      watchUrl: json['watchUrl'] ?? '',
    );
  }

  String get thumbnailUrl => 'https://img.youtube.com/vi/$videoId/hqdefault.jpg';
}
