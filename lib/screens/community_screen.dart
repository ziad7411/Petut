import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import '../models/Post.dart';
import '../utils/avatar_helper.dart';
import 'create_post_screen.dart';
import 'post_details_screen.dart';
import 'edit_post_screen.dart';
import 'profile_view_screen.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  String _selectedTopic = 'All';
  String _sortBy = 'latest';
  String _timeFilter = 'all';
  final List<String> _topics = ['All', 'Adoption', 'Breeding', 'Others'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Community', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value.startsWith('sort_')) {
                setState(() => _sortBy = value.replaceFirst('sort_', ''));
              } else {
                setState(() => _timeFilter = value);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'sort_latest', child: Text('الأحدث')),
              const PopupMenuItem(value: 'sort_oldest', child: Text('الأقدم')),
              const PopupMenuDivider(),
              const PopupMenuItem(value: 'all', child: Text('الكل')),
              const PopupMenuItem(value: '24h', child: Text('آخر 24 ساعة')),
              const PopupMenuItem(value: '7d', child: Text('آخر أسبوع')),
              const PopupMenuItem(value: '30d', child: Text('آخر 30 يوم')),
            ],
            child: Icon(Icons.filter_list, color: theme.colorScheme.primary),
          ),
        ],
      ),
      body: Column(
        children: [
          // Topic Filter
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _topics.length,
              itemBuilder: (context, index) {
                final topic = _topics[index];
                final isSelected = _selectedTopic == topic;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(topic),
                    selected: isSelected,
                    onSelected: (_) => setState(() => _selectedTopic = topic),
                    selectedColor: theme.colorScheme.primary,
                    backgroundColor: theme.colorScheme.surface,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : theme.textTheme.bodyLarge?.color,
                    ),
                  ),
                );
              },
            ),
          ),
          // Posts List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _getPostsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No posts yet. Be the first to share!'));
                }

                return FutureBuilder<List<Post>>(
                  future: _loadPostsWithUserData(snapshot.data!.docs),
                  builder: (context, postsSnapshot) {
                    if (postsSnapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!postsSnapshot.hasData) {
                      return const Center(child: Text('Error loading posts'));
                    }
                    
                    final posts = _filterAndSortPosts(postsSnapshot.data!);
                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: posts.length,
                      itemBuilder: (context, index) => _buildPostCard(posts[index], theme),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CreatePostScreen()),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }

  Stream<QuerySnapshot> _getPostsStream() {
    Query query = FirebaseFirestore.instance.collection('posts');
    
    if (_selectedTopic != 'All') {
      query = query.where('topic', isEqualTo: _selectedTopic);
    }
    
    return query.orderBy('timestamp', descending: true).snapshots();
  }

  List<Post> _filterAndSortPosts(List<Post> posts) {
    final now = DateTime.now();
    List<Post> filteredPosts = posts;

    // Apply time filter
    switch (_timeFilter) {
      case '24h':
        filteredPosts = posts.where((post) => 
          now.difference(post.timestamp).inHours <= 24).toList();
        break;
      case '7d':
        filteredPosts = posts.where((post) => 
          now.difference(post.timestamp).inDays <= 7).toList();
        break;
      case '30d':
        filteredPosts = posts.where((post) => 
          now.difference(post.timestamp).inDays <= 30).toList();
        break;
      case 'all':
      default:
        filteredPosts = posts;
        break;
    }

    // Apply sorting
    if (_sortBy == 'latest') {
      filteredPosts.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    } else if (_sortBy == 'oldest') {
      filteredPosts.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    }

    return filteredPosts;
  }

  Future<List<Post>> _loadPostsWithUserData(List<DocumentSnapshot> docs) async {
    List<Post> posts = [];
    
    for (var doc in docs) {
      final post = Post.fromFirestore(doc);
      
      try {
        // Get fresh user data every time
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(post.userId).get();
        if (userDoc.exists) {
          final userData = userDoc.data()!;
          post.authorName = userData['fullName'] ?? 'Unknown User';
          post.authorImage = userData['profileImage'];
        } else {
          post.authorName = 'Unknown User';
          post.authorImage = null;
        }
      } catch (e) {
        post.authorName = 'Unknown User';
        post.authorImage = null;
      }
      
      // Get comments count
      try {
        final commentsSnapshot = await FirebaseFirestore.instance
            .collection('posts')
            .doc(post.id)
            .collection('comments')
            .get();
        post.commentsCount = commentsSnapshot.docs.length;
      } catch (e) {
        post.commentsCount = 0;
      }
      
      posts.add(post);
    }
    
    return posts;
  }

  Widget _buildPostCard(Post post, ThemeData theme) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => PostDetailsScreen(post: post)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Author Info
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProfileViewScreen(
                          userId: post.userId,
                          userName: post.authorName ?? 'Unknown User',
                          userImage: post.authorImage,
                        ),
                      ),
                    ),
                    child: _buildUserAvatar(post.authorImage, post.authorName, 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(post.authorName ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text(
                          _formatTime(post.timestamp),
                          style: TextStyle(color: theme.hintColor, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getTopicColor(post.topic),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          post.topic,
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                      if (FirebaseAuth.instance.currentUser?.uid == post.userId) ...[
                        const SizedBox(width: 8),
                        PopupMenuButton(
                          icon: const Icon(Icons.more_vert, size: 16),
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit, size: 16),
                                  SizedBox(width: 8),
                                  Text('Edit'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete, color: Colors.red, size: 16),
                                  SizedBox(width: 8),
                                  Text('Delete', style: TextStyle(color: Colors.red)),
                                ],
                              ),
                            ),
                          ],
                          onSelected: (value) {
                            if (value == 'delete') _deletePost(post.id);
                            if (value == 'edit') _editPost(post);
                          },
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Content
              Text(post.content),
              if (post.imageUrl != null) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.memory(
                    base64Decode(post.imageUrl!),
                    width: double.infinity,
                    height: 200,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 200,
                        color: Colors.grey[300],
                        child: const Icon(Icons.broken_image, size: 50),
                      );
                    },
                  ),
                ),
              ],
              const SizedBox(height: 12),
              // Actions
              Row(
                children: [
                  Icon(Icons.comment, size: 16, color: theme.hintColor),
                  const SizedBox(width: 4),
                  Text('${post.commentsCount} comments', style: TextStyle(color: theme.hintColor)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getTopicColor(String topic) {
    switch (topic) {
      case 'Adoption': return Colors.green;
      case 'Breeding': return Colors.pink;
      default: return Colors.blue;
    }
  }

  Future<void> _deletePost(String postId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Post'),
        content: const Text('Are you sure you want to delete this post?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance.collection('posts').doc(postId).delete();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post deleted successfully')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _editPost(Post post) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditPostScreen(post: post),
      ),
    );
  }

  Widget _buildUserAvatar(String? imageData, String? userName, double radius) {
    if (imageData != null && imageData.isNotEmpty) {
      // Check if it's fluttermoji avatar
      if (imageData == 'fluttermoji_avatar') {
        return AvatarHelper.buildAvatar(imageData, size: radius * 2);
      }
      // Check if it's base64 image
      try {
        final imageBytes = base64Decode(imageData);
        return CircleAvatar(
          radius: radius,
          backgroundImage: MemoryImage(imageBytes),
        );
      } catch (e) {
        // Fallback to text avatar
        return _buildTextAvatar(userName ?? 'U', radius);
      }
    }
    // Default text avatar
    return _buildTextAvatar(userName ?? 'U', radius);
  }

  Widget _buildTextAvatar(String userName, double radius) {
    final initials = userName.isNotEmpty 
        ? userName.trim().split(' ').map((name) => name.isNotEmpty ? name[0].toUpperCase() : '').take(2).join()
        : 'U';
    
    return CircleAvatar(
      radius: radius,
      backgroundColor: Theme.of(context).colorScheme.primary,
      child: Text(
        initials,
        style: TextStyle(
          color: Colors.white,
          fontSize: radius * 0.8,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 0) return '${difference.inDays}d ago';
    if (difference.inHours > 0) return '${difference.inHours}h ago';
    if (difference.inMinutes > 0) return '${difference.inMinutes}m ago';
    return 'Just now';
  }
}