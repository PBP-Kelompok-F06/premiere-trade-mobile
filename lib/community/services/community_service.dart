import 'dart:convert';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import '../models/community_models.dart';

class CommunityService {
  final CookieRequest request;
  // URL BACKEND: Gunakan URL dari main.dart / constants
  // URL BACKEND: Ganti ke URL deploy
  final String baseUrl = "https://walyulahdi-maulana-premieretrade.pbp.cs.ui.ac.id/community"; 

  CommunityService(this.request);

  Future<List<Post>> fetchPosts() async {
    final response = await request.get('$baseUrl/json-flutter/'); 

    if (response == null) {
      return [];
    }
    
    List<Post> listPost = [];
    for (var d in response) {
      if (d != null) {
        listPost.add(Post.fromJson(d));
      }
    }
    return listPost;
  }

  Future<Map<String, dynamic>> createPost(String title, String description, String imageUrl) async {
    final response = await request.postJson(
      '$baseUrl/add-flutter/', 
      jsonEncode({
        'title': title,
        'description': description,
        'image_url': imageUrl,
      }),
    );
    return response;
  }

  Future<List<Reply>> fetchReplies(int postId) async {
    final response = await request.get('$baseUrl/json-flutter/$postId/replies/');

    if (response == null) {
      return [];
    }

    List<Reply> listReply = [];
    for (var d in response) {
      if (d != null) {
        listReply.add(Reply.fromJson(d));
      }
    }
    return listReply;
  }

  Future<Map<String, dynamic>> addReply(int postId, String content) async {
    final response = await request.postJson(
      '$baseUrl/reply-flutter/$postId/',
      jsonEncode({'content': content}),
    );
    // print("ADD REPLY RESPONSE: $response"); 
    return response;
  }

  Future<Map<String, dynamic>> editPost(int postId, String title, String description, String imageUrl) async {
    final response = await request.postJson(
      '$baseUrl/edit-flutter/$postId/',
      jsonEncode({
        'title': title,
        'description': description,
        'image_url': imageUrl,
      }),
    );
    return response;
  }

  Future<Map<String, dynamic>> deletePost(int postId) async {
    final response = await request.postJson(
      '$baseUrl/delete-flutter/$postId/',
      jsonEncode({}), // Empty JSON body just to satisfy postJson if needed, or standard post
    );
    return response;
  }

  Future<Map<String, dynamic>> addNestedReply(int replyId, String content) async {
    final response = await request.postJson(
      '$baseUrl/nested-reply-flutter/$replyId/',
      jsonEncode({'content': content}),
    );
    return response;
  }
}
