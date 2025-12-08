import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import '../../core/constants/colors.dart';
import '../models/community_models.dart';
import '../services/community_service.dart';
import 'post_detail_page.dart'; // Nanti kita buat file ini

class CommunityPage extends StatefulWidget {
  const CommunityPage({super.key});

  @override
  State<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage> {
  Future<List<Post>>? _futurePosts;

  @override
  void initState() {
    super.initState();
    // Di initState belum ada context.read<CookieRequest> yang aman jika provider belum siap,
    // tapi biasanya oke di sini atau di didChangeDependencies.
    // Kita panggil di build atau method terpisah supaya aman.
  }

  Future<List<Post>> _refreshPosts(CookieRequest request) {
    final service = CommunityService(request);
    return service.fetchPosts();
  }

  void _showCreatePostDialog(BuildContext context, CookieRequest request) {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    final imageController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("New Discussion"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: "Title"),
                ),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(labelText: "Description"),
                  maxLines: 3,
                ),
                TextField(
                  controller: imageController,
                  decoration: const InputDecoration(labelText: "Image URL (Optional)"),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.isNotEmpty &&
                    descController.text.isNotEmpty) {
                  final service = CommunityService(request);
                  await service.createPost(
                    titleController.text,
                    descController.text,
                    imageController.text,
                  );
                  // Refresh
                  if (context.mounted) {
                    Navigator.pop(context);
                    setState(() {});
                  }
                }
              },
              child: const Text("Post"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final request = context.watch<CookieRequest>();

    return Scaffold(
      backgroundColor: AppColors.background, // Konsisten dengan Profile
      body: FutureBuilder<List<Post>>(
        future: _refreshPosts(request),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          // Handle Error atau Kosong
          if (snapshot.hasError) {
             // Jika error, mungkin karena endpoint belum ada / return HTML
             return Center(
               child: Column(
                 mainAxisAlignment: MainAxisAlignment.center,
                 children: [
                   const Icon(Icons.error_outline, size: 60, color: Colors.grey),
                   const SizedBox(height: 16),
                   Text("Gagal memuat diskusi: ${snapshot.error}", textAlign: TextAlign.center),
                   const SizedBox(height: 8),
                   const Text("Pastikan backend sudah menyediakan endpoint JSON.", style: TextStyle(color: Colors.grey)),
                 ],
               ),
             );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text("Belum ada diskusi. Jadilah yang pertama!"),
            );
          }

          final posts = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: InkWell(
                  onTap: () async {
                    // Navigasi ke Detail
                     final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PostDetailPage(post: post),
                        ),
                      );
                      
                      // Jika result true (berarti ada edit/delete), refresh halaman
                      if (result == true) {
                        setState(() {});
                      }
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header: Author & Time (Jika ada)
                        Row(
                          children: [
                            const Icon(Icons.account_circle, size: 24, color: AppColors.primary),
                            const SizedBox(width: 8),
                            Text(post.author, style: const TextStyle(fontWeight: FontWeight.bold)),
                            const Spacer(),
                            if (post.createdAt != null)
                              Text(
                                "${post.createdAt!.day}/${post.createdAt!.month}/${post.createdAt!.year}",
                                style: const TextStyle(color: Colors.grey, fontSize: 12),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Title
                        Text(
                          post.title,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        // Short Desc
                         Text(
                          post.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        // Image Preview (Optional)
                        if (post.imageUrl != null && post.imageUrl!.isNotEmpty)
                           Padding(
                             padding: const EdgeInsets.only(top: 12.0),
                             child: ClipRRect(
                               borderRadius: BorderRadius.circular(8),
                               child: Image.network(
                                 post.imageUrl!,
                                 width: double.infinity,
                                 height: 150,
                                 fit: BoxFit.cover,
                                 errorBuilder: (ctx, err, stack) => const SizedBox(),
                               ),
                             ),
                           ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreatePostDialog(context, request),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
