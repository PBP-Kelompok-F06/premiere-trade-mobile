class BestElevenClub {
  final int id;
  final String name;

  BestElevenClub({required this.id, required this.name});

  factory BestElevenClub.fromJson(Map<String, dynamic> json) {
    return BestElevenClub(
      id: json['id'],
      name: json['name'],
    );
  }
}

class BestElevenPlayer {
  final String id; // UUID
  final String name;
  final String clubName;
  final String position;
  final String nationality;
  final int marketValue;
  final String profileImageUrl;
  String? slotId; // Helper for frontend to track which slot this player occupies

  BestElevenPlayer({
    required this.id,
    required this.name,
    required this.clubName,
    required this.position,
    required this.nationality,
    required this.marketValue,
    required this.profileImageUrl,
    this.slotId,
  });

  factory BestElevenPlayer.fromJson(Map<String, dynamic> json) {
    return BestElevenPlayer(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unknown',
      clubName: json['club_name']?.toString() ?? 'N/A',
      position: json['position']?.toString() ?? '-',
      nationality: json['nationality']?.toString() ?? '-',
      marketValue: (json['market_value'] is int) 
          ? json['market_value'] as int 
          : (json['market_value'] is num) 
              ? (json['market_value'] as num).toInt() 
              : 0,
      profileImageUrl: json['profile_image_url']?.toString() ?? '',
      slotId: json['slotId']?.toString(),
    );
  }
}

class BestElevenFormation {
  final int id;
  final String name;
  final String layout;
  final List<BestElevenPlayer>? players; // Populated for detail view

  BestElevenFormation({
    required this.id,
    required this.name,
    required this.layout,
    this.players,
  });

  factory BestElevenFormation.fromJson(Map<String, dynamic> json) {
    var playersList = <BestElevenPlayer>[];
    if (json['players'] != null) {
      playersList = (json['players'] as List)
          .map((p) => BestElevenPlayer.fromJson(p))
          .toList();
    }
    
    return BestElevenFormation(
      id: json['id'],
      name: json['name'],
      layout: json['layout'],
      players: playersList,
    );
  }
}
