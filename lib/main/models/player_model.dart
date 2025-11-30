import 'dart:convert';

List<Player> playerFromJson(String str) => List<Player>.from(json.decode(str).map((x) => Player.fromJson(x)));

class Player {
    String id;
    String name;
    String position;
    int marketValue;
    String? thumbnail;

    Player({
        required this.id,
        required this.name,
        required this.position,
        required this.marketValue,
        this.thumbnail,
    });

    factory Player.fromJson(Map<String, dynamic> json) => Player(
        id: json["pk"],
        name: json["fields"]["nama_pemain"], // Sesuaikan dengan models.py
        position: json["fields"]["position"],
        marketValue: json["fields"]["market_value"],
        thumbnail: json["fields"]["thumbnail"],
    );
}