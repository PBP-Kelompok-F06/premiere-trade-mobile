import 'dart:convert';

List<Club> clubFromJson(String str) => List<Club>.from(json.decode(str).map((x) => Club.fromJson(x)));

class Club {
    int pk;
    String name;
    String country;
    String? logoUrl;

    Club({
        required this.pk,
        required this.name,
        required this.country,
        this.logoUrl,
    });

    factory Club.fromJson(Map<String, dynamic> json) => Club(
        pk: json["pk"],
        name: json["fields"]["name"],
        country: json["fields"]["country"],
        logoUrl: json["fields"]["logo_url"],
    );
}