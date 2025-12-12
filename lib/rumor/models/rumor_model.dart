import 'dart:convert';

List<Rumor> rumorFromJson(String str) =>
    List<Rumor>.from(json.decode(str).map((x) => Rumor.fromJson(x)));

class Rumor {
  String id;
  String title;
  String content;
  String author;
  String pemain;
  String clubAsal;
  String clubTujuan;
  String status;
  String createdAt;
  int views;
  bool isAuthor;
  bool isAdmin;

  Rumor({
    required this.id,
    required this.title,
    required this.content,
    required this.author,
    required this.pemain,
    required this.clubAsal,
    required this.clubTujuan,
    required this.status,
    required this.createdAt,
    required this.views,
    required this.isAuthor,
    required this.isAdmin,
  });

  factory Rumor.fromJson(Map<String, dynamic> json) => Rumor(
        id: json["id"],
        title: json["title"] ?? "Rumor Tanpa Judul",
        content: json["content"] ?? "",
        author: json["author"],
        pemain: json["pemain"],
        clubAsal: json["club_asal"],
        clubTujuan: json["club_tujuan"],
        status: json["status"],
        createdAt: json["created_at"],
        views: json["views"],
        isAuthor: json["is_author"] ?? false,
        isAdmin: json["is_admin"] ?? false,
      );
}