import 'package:flutter_test/flutter_test.dart';
import 'package:premiere_trade/community/models/community_models.dart';

void main() {
  group('Community Models Test', () {
    test('Post.fromJson parses correctly', () {
      final json = {
        "id": 1,
        "author_username": "messi",
        "title": "GOAT discussion",
        "description": "Who is the GOAT?",
        "image_url": "http://example.com/messi.jpg",
        "created_at": "2023-10-10T10:00:00Z"
      };

      final post = Post.fromJson(json);

      expect(post.id, 1);
      expect(post.author, "messi");
      expect(post.title, "GOAT discussion");
      expect(post.description, "Who is the GOAT?");
      expect(post.imageUrl, "http://example.com/messi.jpg");
      expect(post.createdAt, isNotNull);
    });

    test('Reply.fromJson parses simple reply correctly', () {
      final json = {
        "id": 101,
        "author_username": "ronaldo",
        "content": "Siuuu",
        "created_at": "2023-10-10T10:05:00Z",
        "parent_id": null,
        "post_id": 1
      };

      final reply = Reply.fromJson(json);

      expect(reply.id, 101);
      expect(reply.author, "ronaldo");
      expect(reply.content, "Siuuu");
      expect(reply.childReplies, isEmpty);
    });

    test('Reply.fromJson parses NESTED replies recursively', () {
      final json = {
        "id": 100,
        "author_username": "parent",
        "content": "I am parent",
        "post_id": 1,
        "replies": [
          {
            "id": 200,
            "author_username": "child1",
            "content": "I am child 1",
            "post_id": 1,
            "replies": []
          },
          {
            "id": 201,
            "author_username": "child2",
            "content": "I am child 2",
            "post_id": 1,
            "replies": [
               {
                "id": 300,
                "author_username": "grandchild",
                "content": "I am grandchild",
                "post_id": 1,
                "replies": []
              }
            ]
          }
        ]
      };

      final reply = Reply.fromJson(json);

      expect(reply.id, 100);
      expect(reply.childReplies.length, 2);
      
      // Check First Child
      expect(reply.childReplies[0].author, "child1");
      expect(reply.childReplies[0].childReplies, isEmpty);

      // Check Second Child (Recursive)
      expect(reply.childReplies[1].author, "child2");
      expect(reply.childReplies[1].childReplies.length, 1);
      
      // Check Grandchild
      expect(reply.childReplies[1].childReplies[0].author, "grandchild");
      expect(reply.childReplies[1].childReplies[0].content, "I am grandchild");
    });
  });
}
