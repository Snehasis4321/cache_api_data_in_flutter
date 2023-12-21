class HackerNews {
  final String author;
  final String title;
  final String url;
  final int id;
  final String updatedAt;

  HackerNews({
    required this.id,
    required this.author,
    required this.title,
    required this.url,
    required this.updatedAt,
  });

  factory HackerNews.fromJson(Map<String, dynamic> json) => HackerNews(
      id: json["story_id"] ?? 0,
      author: json["author"] ?? "",
      title: json["title"] ?? "",
      url: json["url"] ?? "",
      updatedAt: json["updated_at"] ?? "");
}
