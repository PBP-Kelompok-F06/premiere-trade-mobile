import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import '../../core/constants/colors.dart';
import '../models/community_models.dart';
import '../services/community_service.dart';
import '../../core/providers/user_provider.dart';

class PostDetailPage extends StatefulWidget {
  final Post post;

  const PostDetailPage({super.key, required this.post});

  @override
  State<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<PostDetailPage> {
  late Future<List<Reply>> _futureReplies;

  @override
  void initState() {
    super.initState();
    // Panggil fetch pertama kali saat inisialisasi
    // Kita butuh context.read, tapi di initState agak riskan jika Provider belum mount.
    // Tapi biasanya pbp_django_auth aman. Atau kita taruh di didChangeDependencies.
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final request = context.watch<CookieRequest>();
    _futureReplies = CommunityService(request).fetchReplies(widget.post.id);
  }

  void _refreshReplies() {
    final request = context.read<CookieRequest>();
    setState(() {
      _futureReplies = CommunityService(request).fetchReplies(widget.post.id);
    });
  }

  void _showReplyDialog(BuildContext context, CookieRequest request) {
    final contentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Reply to Post"),
          content: TextField(
            controller: contentController,
            decoration: const InputDecoration(labelText: "Your Reply"),
            maxLines: 3,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                if (contentController.text.isNotEmpty) {
                  final service = CommunityService(request);
                  try {
                    final response = await service.addReply(widget.post.id, contentController.text);
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Reply sent!")),
                      );
                      // REFRESH SETELAH SUKSES
                      _refreshReplies();
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Error: $e")),
                      );
                    }
                  }
                }
              },
              child: const Text("Send"),
            ),
          ],
        );
      },
    );
  }

  void _showEditDialog(BuildContext context, CookieRequest request) {
    final titleController = TextEditingController(text: widget.post.title);
    final descController = TextEditingController(text: widget.post.description);
    // Assuming image URL is editable or just keep existing
    final imageController = TextEditingController(text: widget.post.imageUrl ?? "");

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Edit Post"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
               TextField(controller: titleController, decoration: const InputDecoration(labelText: "Title")),
               TextField(controller: descController, decoration: const InputDecoration(labelText: "Description"), maxLines: 3),
               TextField(controller: imageController, decoration: const InputDecoration(labelText: "Image URL (Optional)")),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () async {
                final service = CommunityService(request);
                try {
                   final response = await service.editPost(
                     widget.post.id, 
                     titleController.text, 
                     descController.text,
                     imageController.text
                   );
                   if (context.mounted) {
                     Navigator.pop(context);
                     if (response['status'] == 'success') {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Post updated!")));
                        Navigator.pop(context, true); // Return to list to refresh there or use naming route
                     } else {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed: ${response['message']}")));
                     }
                   }
                } catch (e) {
                   if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
                }
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, CookieRequest request) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Post"),
        content: const Text("Are you sure you want to delete this post?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(
            onPressed: () async {
              final service = CommunityService(request);
              try {
                final response = await service.deletePost(widget.post.id);
                if (context.mounted) {
                  Navigator.pop(context); // Close dialog
                  if (response['status'] == 'success') {
                     ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Post deleted!")));
                     Navigator.pop(context, true); // Return to list
                  } else {
                     ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed: ${response['message']}")));
                  }
                }
              } catch (e) {
                 if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
              }
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final request = context.watch<CookieRequest>();
    final currentUser = context.watch<UserProvider>().username;
    final isAuthor = widget.post.author == currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Discussion", style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (isAuthor) 
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'edit') {
                 _showEditDialog(context, request);
              } else if (value == 'delete') {
                 _confirmDelete(context, request);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(children: [Icon(Icons.edit, color: Colors.blue), SizedBox(width: 8), Text("Edit")]),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(children: [Icon(Icons.delete, color: Colors.red), SizedBox(width: 8), Text("Delete")]),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Author Info
             Row(
                children: [
                  const Icon(Icons.account_circle, size: 40, color: AppColors.primary),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.post.author, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      if (widget.post.createdAt != null)
                      Text(
                        "${widget.post.createdAt!.day}/${widget.post.createdAt!.month}/${widget.post.createdAt!.year}",
                         style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
            
            // Post Content
            Text(
              widget.post.title,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              widget.post.description,
              style: const TextStyle(fontSize: 16, height: 1.5),
            ),
            
            if (widget.post.imageUrl != null && widget.post.imageUrl!.isNotEmpty)
             Padding(
               padding: const EdgeInsets.only(top: 16.0),
               child: ClipRRect(
                 borderRadius: BorderRadius.circular(12),
                 child: Image.network(widget.post.imageUrl!),
               ),
             ),
             
             const Divider(height: 40, thickness: 1),
             
             // Section Reply
             const Text("Replies", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
             const SizedBox(height: 16),
             
             FutureBuilder<List<Reply>>(
                future: _futureReplies, 
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Text("Error: ${snapshot.error}");
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Text("No replies yet. Be the first!");
                  }
                  return ListView.builder(
                    shrinkWrap: true, 
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) {
                      return _buildReplyItem(snapshot.data![index]); // Recursion entry point
                    },
                  );
                },
             ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showReplyDialog(context, request),
        label: const Text("Reply", style: TextStyle(color: Colors.white)),
        icon: const Icon(Icons.reply, color: Colors.white),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  // Recursive Widget Builder
  Widget _buildReplyItem(Reply reply) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(reply.author, style: const TextStyle(fontWeight: FontWeight.bold)),
                    const Spacer(),
                    if (reply.createdAt != null)
                      Text(
                        "${reply.createdAt!.day}/${reply.createdAt!.month}/${reply.createdAt!.year}",
                         style: const TextStyle(color: Colors.grey, fontSize: 10),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(reply.content),
                const SizedBox(height: 8),
                // Tombol Reply Kecil (untuk nested)
                InkWell(
                  onTap: () => _showNestedReplyDialog(context, context.read<CookieRequest>(), reply.id),
                  child: const Text("Reply", style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
        // Render Child Replies (Recursive)
        if (reply.childReplies.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(left: 16.0), 
            decoration: const BoxDecoration(
              border: Border(left: BorderSide(color: Colors.grey, width: 2.0)),
            ),
            padding: const EdgeInsets.only(left: 12.0),
            child: Column(
              children: reply.childReplies.map((child) => _buildReplyItem(child)).toList(),
            ),
          ),
      ],
    );
  }
  
  void _showNestedReplyDialog(BuildContext context, CookieRequest request, int parentId) {
     // Logic similar to _showReplyDialog but calling addNestedReply
     final contentController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Reply to comment"),
          content: TextField(controller: contentController, decoration: const InputDecoration(labelText: "Your Reply")),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () async {
                 if (contentController.text.isNotEmpty) {
                    final service = CommunityService(request);
                    try {
                       await service.addNestedReply(parentId, contentController.text);
                       if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Reply sent!")));
                          _refreshReplies();
                       }
                    } catch (e) {
                       if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
                    }
                 }
              },
              child: const Text("Send"),
            )
          ],
        );
      }
    );
  }
}
