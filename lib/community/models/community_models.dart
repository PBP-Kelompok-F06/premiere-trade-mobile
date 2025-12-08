import 'dart:convert';

List<Post> postFromJson(String str) => List<Post>.from(json.decode(str).map((x) => Post.fromJson(x)));

String postToJson(List<Post> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class Post {
    int id;
    String author;
    String title;
    String description;
    String? imageUrl;
    DateTime? createdAt;
    // Kita asumsikan endpoint list post mungkin belum return replies, 
    // tapi nanti detail endpoint mungkin return.
    // List<Reply>? replies; 

    Post({
        required this.id,
        required this.author,
        required this.title,
        required this.description,
        this.imageUrl,
        this.createdAt,
    });

    factory Post.fromJson(Map<String, dynamic> json) => Post(
        id: json["id"],
        author: json["author_username"] ?? "Anonymous", // Sesuaikan dengan serializer backend
        title: json["title"],
        description: json["description"],
        imageUrl: json["image_url"],
        createdAt: json["created_at"] != null ? DateTime.parse(json["created_at"]) : null,
    );

    Map<String, dynamic> toJson() => {
        "id": id,
        "author_username": author,
        "title": title,
        "description": description,
        "image_url": imageUrl,
        "created_at": createdAt?.toIso8601String(),
    };
}

class Reply {
    int id;
    String author;
    String content;
    DateTime? createdAt;
    int? parentId; // ID reply induk jika nested
    int postId;
    List<Reply> childReplies; // Untuk struktur hierarki di frontend

    Reply({
        required this.id,
        required this.author,
        required this.content,
        this.createdAt,
        this.parentId,
        required this.postId,
        this.childReplies = const [],
    });

    factory Reply.fromJson(Map<String, dynamic> json) {
      var list = json['replies'] as List?;
      List<Reply> children = list != null 
          ? list.map((i) => Reply.fromJson(i)).toList() 
          : [];

      return Reply(
        id: json["id"],
        author: json["author_username"] ?? json["author"] ?? "Anonymous",
        content: json["content"],
        createdAt: json["created_at"] != null ? DateTime.tryParse(json["created_at"] ?? "") : null,
        parentId: json["parent_id"],
        postId: json["post_id"] ?? 0, 
        childReplies: children,
      );
    }
     
    // Factory khusus jika backend kirim child replies recursive
    // factory Reply.fromRecursiveJson ...
}
