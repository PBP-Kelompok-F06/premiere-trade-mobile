// Model untuk Formasi Best Eleven
class BestElevenFormation {
  int id;
  String name;
  String layout; // e.g., "4-3-3", "4-4-2", etc.
  int userId;
  String? username;
  DateTime? createdAt;
  DateTime? updatedAt;
  List<BestElevenPlayerSlot> players; // 11 pemain dalam formasi

  BestElevenFormation({
    required this.id,
    required this.name,
    required this.layout,
    required this.userId,
    this.username,
    this.createdAt,
    this.updatedAt,
    this.players = const [],
  });

  factory BestElevenFormation.fromJson(Map<String, dynamic> json) {
    List<BestElevenPlayerSlot> playersList = [];
    if (json['players'] != null) {
      if (json['players'] is List) {
        playersList = (json['players'] as List)
            .map((p) => BestElevenPlayerSlot.fromJson(p))
            .toList();
      }
    }

    return BestElevenFormation(
      id: json["id"] ?? 0,
      name: json["name"] ?? "",
      layout: json["layout"] ?? json["formation"] ?? "4-3-3",
      userId: json["user_id"] ?? json["user"] ?? 0,
      username: json["username"] ?? json["user_username"],
      createdAt: json["created_at"] != null 
          ? DateTime.tryParse(json["created_at"]) 
          : null,
      updatedAt: json["updated_at"] != null 
          ? DateTime.tryParse(json["updated_at"]) 
          : null,
      players: playersList,
    );
  }

  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
    "layout": layout,
    "user_id": userId,
    "username": username,
    "created_at": createdAt?.toIso8601String(),
    "updated_at": updatedAt?.toIso8601String(),
    "players": players.map((p) => p.toJson()).toList(),
  };
}

// Model untuk Slot Pemain dalam Formasi
class BestElevenPlayerSlot {
  String position; // e.g., "GK", "CB", "CM", "ST", etc. (juga bisa sebagai slotId)
  String? playerId; // UUID string dari Django
  BestElevenPlayer? player;
  String? slotId; // Slot ID dari Django (e.g., "GK", "LB", etc.)

  BestElevenPlayerSlot({
    required this.position,
    this.playerId,
    this.player,
    this.slotId,
  });

  factory BestElevenPlayerSlot.fromJson(Map<String, dynamic> json) {
    // Handle berbagai format dari Django
    // Format 1: {position: "GK", player: {...}}
    // Format 2: {slotId: "GK", player: {...}} (dari template HTML)
    // Format 3: {slotId: "GK", id: "...", name: "...", ...} (dari get_formation_details_api)
    String slotPosition = json["slotId"] ?? json["slot_id"] ?? json["position"] ?? "";
    
    // Jika player data langsung di json (bukan nested dalam "player")
    BestElevenPlayer? playerData;
    if (json["player"] != null) {
      playerData = BestElevenPlayer.fromJson(json["player"]);
    } else if (json["id"] != null || json["name"] != null) {
      // Player data langsung di root object
      playerData = BestElevenPlayer.fromJson(json);
    }
    
    return BestElevenPlayerSlot(
      position: slotPosition,
      slotId: json["slotId"] ?? json["slot_id"] ?? slotPosition,
      playerId: json["player_id"]?.toString() ?? json["playerId"]?.toString() ?? playerData?.id.toString(),
      player: playerData,
    );
  }

  Map<String, dynamic> toJson() => {
    "position": position,
    "slotId": slotId ?? position,
    "player_id": playerId,
    "player": player?.toJson(),
  };
}

// Model untuk Pemain
class BestElevenPlayer {
  String id; // UUID string dari Django
  String name;
  String position;
  String? clubName;
  int? clubId;
  String? nationality;
  int? age;
  String? photoUrl;
  String? profileImageUrl;
  double? marketValue;
  String? slotId; // Untuk formasi yang sudah dibuat

  BestElevenPlayer({
    required this.id,
    required this.name,
    required this.position,
    this.clubName,
    this.clubId,
    this.nationality,
    this.age,
    this.photoUrl,
    this.profileImageUrl,
    this.marketValue,
    this.slotId,
  });

  factory BestElevenPlayer.fromJson(Map<String, dynamic> json) {
    // Handle market_value dengan berbagai format
    double? marketValue;
    if (json["market_value"] != null) {
      if (json["market_value"] is num) {
        marketValue = json["market_value"].toDouble();
      } else if (json["market_value"] is String) {
        marketValue = double.tryParse(json["market_value"]);
      }
    }

    // Handle berbagai format response dari Django
    // Django mengembalikan UUID sebagai string
    String playerId = json["id"]?.toString() ?? json["pk"]?.toString() ?? json["player_id"]?.toString() ?? "";
    String playerName = json["name"] ?? json["player_name"] ?? json["nama_pemain"] ?? json["nama"] ?? "";
    String playerPosition = json["position"] ?? json["posisi"] ?? json["pos"] ?? "";
    
    // Handle club data - bisa berupa object atau ID
    String? clubName;
    int? clubId;
    if (json["club"] != null) {
      if (json["club"] is Map) {
        clubName = json["club"]["name"] ?? json["club"]["club_name"];
        clubId = json["club"]["id"] ?? json["club"]["pk"];
      } else if (json["club"] is String) {
        clubName = json["club"];
      }
    }
    clubName ??= json["club_name"] ?? json["club_nama"];
    if (json["club_id"] != null) {
      clubId = json["club_id"] is int ? json["club_id"] : int.tryParse(json["club_id"].toString());
    }

    return BestElevenPlayer(
      id: playerId,
      name: playerName,
      position: playerPosition,
      clubName: clubName,
      clubId: clubId,
      nationality: json["nationality"] ?? json["nationality_name"] ?? json["kebangsaan"] ?? json["negara"],
      age: json["age"] ?? json["umur"],
      photoUrl: json["photo_url"] ?? json["photo"] ?? json["image_url"] ?? json["thumbnail"],
      profileImageUrl: json["profile_image_url"] ?? json["photo_url"] ?? json["photo"] ?? json["image_url"] ?? json["thumbnail"],
      marketValue: marketValue,
      slotId: json["slotId"] ?? json["slot_id"],
    );
  }

  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
    "position": position,
    "club_name": clubName,
    "club_id": clubId,
    "nationality": nationality,
    "age": age,
    "photo_url": photoUrl,
    "profile_image_url": profileImageUrl,
    "market_value": marketValue,
    "slotId": slotId,
  };
}

// Model untuk Club
class BestElevenClub {
  int id;
  String name;

  BestElevenClub({
    required this.id,
    required this.name,
  });

  factory BestElevenClub.fromJson(Map<String, dynamic> json) {
    // Handle berbagai format response dari Django
    int clubId = json["id"] ?? json["pk"] ?? json["club_id"] ?? 0;
    String clubName = json["name"] ?? json["club_name"] ?? json["nama"] ?? "";
    
    return BestElevenClub(
      id: clubId,
      name: clubName,
    );
  }

  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
  };
}

