import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import '../models/Post.dart';
import '../utils/avatar_helper.dart';
import 'edit_post_screen.dart';
import 'profile_view_screen.dart';

class PostDetailsScreen extends StatefulWidget {
  final Post post;

  const PostDetailsScreen({super.key, required this.post});

  @override
  State<PostDetailsScreen> createState() => _PostDetailsScreenState();
}

class _PostDetailsScreenState extends State<PostDetailsScreen> {
  final _commentController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadPostAuthorData();
  }

  Future<void> _loadPostAuthorData() async {
    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(widget.post.userId).get();
      if (userDoc.exists && mounted) {
        final userData = userDoc.data()!;
        setState(() {
          widget.post.authorName = userData['fullName'] ?? 'Unknown User';
          widget.post.authorImage = userData['profileImage'];
        });
      }
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> _addComment() async {
    if (_commentController.text.trim().isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser!;
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final userData = userDoc.data()!;

      await FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.post.id)
          .collection('comments')
          .add({
        'userId': user.uid,
        'postId': widget.post.id,
        'postOwnerId': widget.post.userId,
        'comment': _commentController.text.trim(),
        'timestamp': FieldValue.serverTimestamp(),
      });

      _commentController.clear();
      
      // Force refresh
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Post'),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Post Content
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            child: Card(
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
                                userId: widget.post.userId,
                                userName: widget.post.authorName ?? 'Unknown User',
                                userImage: widget.post.authorImage,
                              ),
                            ),
                          ),
                          child: _buildUserAvatar(widget.post.authorImage, widget.post.authorName, 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(widget.post.authorName ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold)),
                              Text(
                                _formatTime(widget.post.timestamp),
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
                                color: _getTopicColor(widget.post.topic),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                widget.post.topic,
                                style: const TextStyle(color: Colors.white, fontSize: 12),
                              ),
                            ),
                            if (FirebaseAuth.instance.currentUser?.uid == widget.post.userId) ...[
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
                                        Text('Edit Post'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        Icon(Icons.delete, color: Colors.red, size: 16),
                                        SizedBox(width: 8),
                                        Text('Delete Post', style: TextStyle(color: Colors.red)),
                                      ],
                                    ),
                                  ),
                                ],
                                onSelected: (value) {
                                  if (value == 'delete') _deletePost();
                                  if (value == 'edit') _editPost();
                                },
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Content
                    Text(widget.post.content, style: const TextStyle(fontSize: 16)),
                    if (widget.post.imageUrl != null) ...[
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.memory(
                          base64Decode(widget.post.imageUrl!),
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          
          // Comments Section
          Expanded(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      const Text('Comments', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const Spacer(),
                      Text('${widget.post.commentsCount}', style: TextStyle(color: theme.hintColor)),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('posts')
                        .doc(widget.post.id)
                        .collection('comments')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                      
                      return FutureBuilder<List<Comment>>(
                        future: _loadCommentsWithUserData(snapshot.data!.docs),
                        builder: (context, commentsSnapshot) {
                          if (commentsSnapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          if (!commentsSnapshot.hasData) {
                            return const Center(child: Text('Error loading comments'));
                          }
                          
                          final comments = commentsSnapshot.data!;
                          comments.sort((a, b) => a.timestamp.compareTo(b.timestamp));
                      
                          if (comments.isEmpty) {
                            return const Center(child: Text('No comments yet. Be the first to comment!'));
                          }
                          
                          return ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: comments.length,
                            itemBuilder: (context, index) => _buildCommentCard(comments[index], theme),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          
          // Comment Input
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border(top: BorderSide(color: theme.dividerColor)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: InputDecoration(
                      hintText: 'Write a comment...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _isLoading ? null : _addComment,
                  icon: _isLoading 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentCard(Comment comment, ThemeData theme) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProfileViewScreen(
                    userId: comment.userId,
                    userName: comment.authorName ?? 'Unknown User',
                    userImage: comment.authorImage,
                  ),
                ),
              ),
              child: _buildUserAvatar(comment.authorImage, comment.authorName, 16),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(comment.authorName ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(width: 8),
                      Text(
                        _formatTime(comment.timestamp),
                        style: TextStyle(color: theme.hintColor, fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(comment.comment),
                ],
              ),
            ),
          ],
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

  Future<List<Comment>> _loadCommentsWithUserData(List<DocumentSnapshot> docs) async {
    List<Comment> comments = [];
    
    for (var doc in docs) {
      final comment = Comment.fromFirestore(doc);
      
      try {
        // Get fresh user data every time
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(comment.userId).get();
        if (userDoc.exists) {
          final userData = userDoc.data()!;
          comment.authorName = userData['fullName'] ?? 'Unknown User';
          comment.authorImage = userData['profileImage'];
        } else {
          comment.authorName = 'Unknown User';
          comment.authorImage = null;
        }
      } catch (e) {
        comment.authorName = 'Unknown User';
        comment.authorImage = null;
      }
      
      comments.add(comment);
    }
    
    return comments;
  }

  Future<void> _deletePost() async {
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
        await FirebaseFirestore.instance.collection('posts').doc(widget.post.id).delete();
        Navigator.pop(context);
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

  void _editPost() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditPostScreen(post: widget.post),
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

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }
}