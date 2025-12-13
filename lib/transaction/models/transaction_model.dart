class Transaction {
  final String id;
  final String playerId;
  final String playerName;
  final String? sellerId;
  final String? sellerName;
  final String? buyerId;
  final String? buyerName;
  final double price;
  final String timestamp;

  Transaction({
    required this.id,
    required this.playerId,
    required this.playerName,
    this.sellerId,
    this.sellerName,
    this.buyerId,
    this.buyerName,
    required this.price,
    required this.timestamp,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'].toString(),
      playerId: json['player_id'].toString(),
      playerName: json['player_name'] ?? '',
      sellerId: json['seller_id']?.toString(),
      sellerName: json['seller_name'],
      buyerId: json['buyer_id']?.toString(),
      buyerName: json['buyer_name'],
      price: (json['price'] ?? 0).toDouble(),
      timestamp: json['timestamp'] ?? '',
    );
  }
}

class Negotiation {
  final int id;
  final String fromClub;
  final String toClub;
  final String player;
  final String playerId;
  final double offeredPrice;
  final String status;
  final String createdAt;

  Negotiation({
    required this.id,
    required this.fromClub,
    required this.toClub,
    required this.player,
    required this.playerId,
    required this.offeredPrice,
    required this.status,
    required this.createdAt,
  });

  factory Negotiation.fromJson(Map<String, dynamic> json) {
    // Handle different types for offered_price (int, double, or String)
    double price = 0;
    if (json['offered_price'] != null) {
      if (json['offered_price'] is int) {
        price = (json['offered_price'] as int).toDouble();
      } else if (json['offered_price'] is double) {
        price = json['offered_price'] as double;
      } else if (json['offered_price'] is String) {
        price = double.tryParse(json['offered_price']) ?? 0;
      }
    }
    
    return Negotiation(
      id: json['id'] is int ? json['id'] as int : (json['id'] is String ? int.tryParse(json['id']) ?? 0 : 0),
      fromClub: json['from_club']?.toString() ?? '',
      toClub: json['to_club']?.toString() ?? '',
      player: json['player']?.toString() ?? '',
      playerId: json['player_id']?.toString() ?? '',
      offeredPrice: price,
      status: json['status']?.toString() ?? 'pending',
      createdAt: json['created_at']?.toString() ?? '',
    );
  }
}

class PlayerForSale {
  final String id;
  final String namaPemain;
  final String posisi;
  final int umur;
  final String negara;
  final int match;
  final int goal;
  final int assist;
  final double marketValue;
  final String thumbnail;
  final String namaKlub;
  final bool isMyClub;

  PlayerForSale({
    required this.id,
    required this.namaPemain,
    required this.posisi,
    required this.umur,
    required this.negara,
    required this.match,
    required this.goal,
    required this.assist,
    required this.marketValue,
    required this.thumbnail,
    required this.namaKlub,
    required this.isMyClub,
  });

  factory PlayerForSale.fromJson(Map<String, dynamic> json) {
    return PlayerForSale(
      id: json['id'].toString(),
      namaPemain: json['nama_pemain'] ?? '',
      posisi: json['posisi'] ?? '',
      umur: json['umur'] ?? 0,
      negara: json['negara'] ?? '',
      match: json['match'] ?? 0,
      goal: json['goal'] ?? 0,
      assist: json['assist'] ?? 0,
      marketValue: (json['market_value'] ?? 0).toDouble(),
      thumbnail: json['thumbnail'] ?? '',
      namaKlub: json['nama_klub'] ?? '',
      isMyClub: json['is_my_club'] ?? false,
    );
  }
}

class MyPlayer {
  final String id;
  final String namaPemain;
  final String posisi;
  final int umur;
  final String negara;
  final int match;
  final int goal;
  final int assist;
  final double marketValue;
  final bool sedangDijual;
  final String thumbnail;

  MyPlayer({
    required this.id,
    required this.namaPemain,
    required this.posisi,
    required this.umur,
    required this.negara,
    required this.match,
    required this.goal,
    required this.assist,
    required this.marketValue,
    required this.sedangDijual,
    required this.thumbnail,
  });

  factory MyPlayer.fromJson(Map<String, dynamic> json) {
    return MyPlayer(
      id: json['id'].toString(),
      namaPemain: json['nama_pemain'] ?? '',
      posisi: json['posisi'] ?? '',
      umur: json['umur'] ?? 0,
      negara: json['negara'] ?? '',
      match: json['match'] ?? 0,
      goal: json['goal'] ?? 0,
      assist: json['assist'] ?? 0,
      marketValue: (json['market_value'] ?? 0).toDouble(),
      sedangDijual: json['sedang_dijual'] ?? false,
      thumbnail: json['thumbnail'] ?? '',
    );
  }
}

