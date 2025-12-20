import 'dart:convert';

List<Rumor> rumorFromJson(String str) =>
    List<Rumor>.from(json.decode(str).map((x) => Rumor.fromJson(x)));

class Rumor {
  String id;
  String title;
  String content;
  String author;
  
  // Info Pemain
  String pemainNama;
  String pemainThumbnail;
  int pemainValue;
  int pemainUmur;
  String pemainPosisi;
  String pemainNegara;

  // Info Klub
  String clubAsalNama;
  String clubAsalLogo;
  String clubTujuanNama;
  String clubTujuanLogo;

  String status;
  String createdAt;
  int views;
  bool isAuthor;
  bool isAdmin;

  String pemainId;
  String clubAsalId;
  String clubTujuanId;

  Rumor({
    required this.id,
    required this.title,
    required this.content,
    required this.author,
    required this.pemainNama,
    required this.pemainThumbnail,
    required this.pemainValue,
    required this.pemainUmur,
    required this.pemainPosisi,
    required this.pemainNegara,
    required this.clubAsalNama,
    required this.clubAsalLogo,
    required this.clubTujuanNama,
    required this.clubTujuanLogo,
    required this.status,
    required this.createdAt,
    required this.views,
    required this.isAuthor,
    required this.isAdmin,
    required this.pemainId,
    required this.clubAsalId,
    required this.clubTujuanId,
  });

  factory Rumor.fromJson(Map<String, dynamic> json) => Rumor(
        id: json["id"],
        title: json["title"] ?? "Rumor Tanpa Judul",
        content: json["content"] ?? "",
        author: json["author"],
        
        pemainNama: json["pemain_nama"],
        pemainThumbnail: json["pemain_thumbnail"] ?? "",
        pemainValue: json["pemain_value"] ?? 0,
        pemainUmur: json["pemain_umur"] ?? 0,
        pemainPosisi: json["pemain_posisi"] ?? "-",
        pemainNegara: json["pemain_negara"] ?? "-",

        clubAsalNama: json["club_asal_nama"],
        clubAsalLogo: json["club_asal_logo"] ?? "",
        clubTujuanNama: json["club_tujuan_nama"],
        clubTujuanLogo: json["club_tujuan_logo"] ?? "",

        status: json["status"],
        createdAt: json["created_at"],
        views: json["views"],
        isAuthor: json["is_author"] ?? false,
        isAdmin: json["is_admin"] ?? false,

        pemainId: json["pemain_id"] ?? "",
        clubAsalId: json["club_asal_id"] ?? "",
        clubTujuanId: json["club_tujuan_id"] ?? "",
      );
}