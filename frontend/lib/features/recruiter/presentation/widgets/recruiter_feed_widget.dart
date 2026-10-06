import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:share_plus/share_plus.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../student/presentation/widgets/create_post_dialog.dart';

class RecruiterFeedWidget extends ConsumerStatefulWidget {
  const RecruiterFeedWidget({super.key});

  @override
  ConsumerState<RecruiterFeedWidget> createState() =>
      _RecruiterFeedWidgetState();
}

class _RecruiterFeedWidgetState extends ConsumerState<RecruiterFeedWidget> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;
  List<Map<String, dynamic>> _posts = [];
  Map<String, dynamic>? _currentOrgData;

  @override
  void initState() {
    super.initState();
    _loadOrgData();
    _loadPosts();
  }

  Future<void> _loadOrgData() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      // Fetch organization from profile directly for recruiter
      final profile = await _supabase
          .from('profiles')
          .select('organization_id, organization:organizations(*)')
          .eq('id', user.id)
          .single();

      if (mounted && profile['organization'] != null) {
        setState(() {
          _currentOrgData = profile['organization'];
        });
      }
    } catch (e) {
      debugPrint('Error loading org data: $e');
    }
  }

  Future<void> _loadPosts() async {
    try {
      final response = await _supabase
          .from('posts')
          .select(
            '*, author:profiles(id, full_name, avatar_url, profile_image_url, profile_photo_url, role, organization_id, organization:organizations(name, logo_url))',
          )
          .order('created_at', ascending: false)
          .limit(20);

      if (mounted) {
        setState(() {
          _posts = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading posts: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleLike(String postId, int index) async {
    final currentLikes = _posts[index]['likes_count'] as int;

    // Optimistic update
    setState(() {
      _posts[index]['likes_count'] = currentLikes + 1;
    });

    try {
      final user = _supabase.auth.currentUser;
      if (user != null) {
        await _supabase.from('post_likes').insert({
          'post_id': postId,
          'user_id': user.id,
        });
      }
    } catch (e) {
      // Revert if duplicate or error
      if (mounted) {
        setState(() {
          _posts[index]['likes_count'] = currentLikes;
        });
      }
    }
  }

  void _openCreatePostDialog() async {
    final result = await showDialog(
      context: context,
      builder: (context) => const CreatePostDialog(),
    );

    if (result == true) {
      _loadPosts();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Post published successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCreatePostCard(),
        if (_posts.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Icon(Icons.feed_outlined, size: 48, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No posts yet',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ..._posts.asMap().entries.map((entry) {
          return _buildPostCard(entry.value, entry.key);
        }),
      ],
    );
  }

  void _showCommentSheet(Map<String, dynamic> post) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CommentSheet(postId: post['id']),
    );
  }

  Widget _buildCreatePostCard() {
    final String? orgLogoUrl = _currentOrgData?['logo_url'];
    final String orgName = _currentOrgData?['name'] ?? 'My Company';

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                backgroundImage: orgLogoUrl != null
                    ? NetworkImage(orgLogoUrl)
                    : null,
                child: orgLogoUrl == null
                    ? Text(
                        orgName.isNotEmpty ? orgName[0].toUpperCase() : 'C',
                        style: GoogleFonts.outfit(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: _openCreatePostDialog,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Text(
                      'Post an update, job opening, or news...',
                      style: GoogleFonts.outfit(
                        color: Colors.grey[500],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              TextButton.icon(
                onPressed: _openCreatePostDialog,
                icon: const Icon(
                  Icons.image_outlined,
                  color: Colors.blue,
                  size: 20,
                ),
                label: Text(
                  'Photo',
                  style: GoogleFonts.outfit(color: Colors.grey[600]),
                ),
              ),
              TextButton.icon(
                onPressed: _openCreatePostDialog,
                icon: const Icon(
                  Icons.calendar_today_outlined,
                  color: Colors.orange,
                  size: 20,
                ),
                label: Text(
                  'Event',
                  style: GoogleFonts.outfit(color: Colors.grey[600]),
                ),
              ),
              TextButton.icon(
                onPressed: _openCreatePostDialog,
                icon: const Icon(
                  Icons.article_outlined,
                  color: Colors.purple,
                  size: 20,
                ),
                label: Text(
                  'Article',
                  style: GoogleFonts.outfit(color: Colors.grey[600]),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPostCard(Map<String, dynamic> post, int index) {
    final author = post['author'] ?? {};
    final String currentUserId = _supabase.auth.currentUser?.id ?? '';
    final bool isMyPost = author['id'] == currentUserId;

    // Check if author is college admin or recruiter
    final bool isOfficialPost =
        author['role'] == 'admin' ||
        author['role'] == 'college_admin' ||
        author['role'] == 'recruiter';

    final organization = author['organization'];
    String orgName = organization?['name'] ?? '';
    String? orgLogoUrl = organization?['logo_url'];

    // Resolve Org Name/Logo: Prefer joined data, fallback to current session data if it's my post
    if (isMyPost && _currentOrgData != null) {
      if (orgName.isEmpty) orgName = _currentOrgData!['name'] ?? '';
      if (orgLogoUrl == null) orgLogoUrl = _currentOrgData!['logo_url'];
    }

    // Logic: If official post, try to use Org Name/Logo. Else use User Name/Pic.
    final String displayName = (isOfficialPost && orgName.isNotEmpty)
        ? orgName
        : (author['full_name'] ?? 'Unknown User');

    // For subtitle: if we used org name as title, show "Recruiter" or nothing as subtitle?
    // User requested: "USER HEARTWARE -- COMPANY NAME THROUGHTOUT"
    // So if Title is "Heartware", subtitle can be Empty or "Recruiter" or "Official Update"

    // final String? displayImage = (isOfficialPost && orgLogoUrl != null)
    //     ? orgLogoUrl
    //     : (author['profile_photo_url'] ??
    //           author['profile_image_url'] ??
    //           author['avatar_url']);

    // Actually, let's stick to the previous logic but ensure it's doing what we want.
    // If isOfficialPost is true, we want to force Org Name.

    final String? displayImage = (isOfficialPost && orgLogoUrl != null)
        ? orgLogoUrl
        : (author['profile_photo_url'] ??
              author['profile_image_url'] ??
              author['avatar_url']);

    // final String authorRole = author['role'] ?? 'User';

    final timeAgo = timeago.format(DateTime.parse(post['created_at']));
    final content = post['content'] ?? '';
    final likesCount = post['likes_count'] ?? 0;
    // NOTE: comments_count might fail if not in view, defaulting to handle null
    final commentsCount = post['comments_count'] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                  backgroundImage: displayImage != null
                      ? NetworkImage(displayImage)
                      : null,
                  child: displayImage == null
                      ? Icon(
                          isOfficialPost
                              ? Icons.business
                              : Icons.person_rounded,
                          color: AppTheme.primaryColor,
                          size: 16,
                        )
                      : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              displayName,
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: Colors.black87,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isOfficialPost)
                            const Padding(
                              padding: EdgeInsets.only(left: 4),
                              child: Icon(
                                Icons.verified,
                                size: 12,
                                color: Colors.blue,
                              ),
                            ),
                        ],
                      ),
                      Text(
                        timeAgo,
                        style: GoogleFonts.outfit(
                          fontSize: 10,
                          color: Colors.grey[400],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Content
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  content,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    color: Colors.black87,
                    height: 1.4,
                  ),
                ),
                if (post['image_urls'] != null &&
                    (post['image_urls'] as List).isNotEmpty)
                  _buildPostImages(post['image_urls'] as List),
              ],
            ),
          ),

          const Divider(height: 1),

          // Actions
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildActionButton(
                  icon: Icons.thumb_up_alt_outlined,
                  label: likesCount > 0 ? '$likesCount' : 'Like',
                  onTap: () => _toggleLike(post['id'], index),
                ),
                _buildActionButton(
                  icon: Icons.comment_outlined,
                  label: commentsCount > 0 ? '$commentsCount' : 'Comment',
                  onTap: () => _showCommentSheet(post),
                ),
                _buildActionButton(
                  icon: Icons.share_outlined,
                  label: 'Share',
                  onTap: () {
                    Share.share('${post['content']}\n\nSent via CareerBridge');
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostImages(List images) {
    if (images.isEmpty) return const SizedBox.shrink();
    final List<String> imageUrls = images.map((e) => e.toString()).toList();

    return Container(
      margin: const EdgeInsets.only(top: 12),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Image.network(
          imageUrls.first,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(color: Colors.grey[100]);
          },
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Icon(icon, size: 20, color: Colors.grey[600]),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CommentSheet extends ConsumerStatefulWidget {
  final String postId;

  const _CommentSheet({required this.postId});

  @override
  ConsumerState<_CommentSheet> createState() => _CommentSheetState();
}

class _CommentSheetState extends ConsumerState<_CommentSheet> {
  final _commentController = TextEditingController();
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;
  List<Map<String, dynamic>> _comments = [];

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadComments() async {
    try {
      final response = await _supabase
          .from('post_comments')
          .select(
            '*, user:profiles(full_name, avatar_url, role, organization:organizations(name, logo_url))',
          )
          .eq('post_id', widget.postId)
          .order('created_at', ascending: true);

      if (mounted) {
        setState(() {
          _comments = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading comments: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _addComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      final newComment = await _supabase
          .from('post_comments')
          .insert({
            'post_id': widget.postId,
            'user_id': user.id,
            'content': content,
          })
          .select(
            '*, user:profiles(full_name, avatar_url, role, organization:organizations(name, logo_url))',
          )
          .single();

      if (mounted) {
        setState(() {
          _comments.add(newComment);
          _commentController.clear();
        });
      }
    } catch (e) {
      debugPrint('Error adding comment: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error adding comment: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: Text(
                'Comments',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          const Divider(height: 1),

          // List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _comments.isEmpty
                ? Center(
                    child: Text(
                      'No comments yet. Be the first!',
                      style: GoogleFonts.outfit(color: Colors.grey[500]),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _comments.length,
                    itemBuilder: (context, index) {
                      final comment = _comments[index];
                      final user = comment['user'] ?? {};
                      final role = user['role'];
                      final organization = user['organization'];
                      final orgName = organization?['name'] ?? '';
                      final orgLogoUrl = organization?['logo_url'];

                      final isOfficial =
                          role == 'recruiter' ||
                          role == 'admin' ||
                          role == 'college_admin';

                      final name = (isOfficial && orgName.isNotEmpty)
                          ? orgName
                          : (user['full_name'] ?? 'User');

                      final avatarUrl = (isOfficial && orgLogoUrl != null)
                          ? orgLogoUrl
                          : user['avatar_url'];

                      final time = timeago.format(
                        DateTime.parse(comment['created_at']),
                      );

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: isOfficial
                                  ? AppTheme.primaryColor.withValues(alpha: 0.1)
                                  : null,
                              backgroundImage: avatarUrl != null
                                  ? NetworkImage(avatarUrl)
                                  : null,
                              child: avatarUrl == null
                                  ? (isOfficial
                                        ? Icon(
                                            Icons.business,
                                            size: 16,
                                            color: AppTheme.primaryColor,
                                          )
                                        : Text(
                                            name.isNotEmpty ? name[0] : '?',
                                            style: const TextStyle(
                                              fontSize: 12,
                                            ),
                                          ))
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              name,
                                              style: GoogleFonts.outfit(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                              ),
                                            ),
                                            if (isOfficial)
                                              const Padding(
                                                padding: EdgeInsets.only(
                                                  left: 4,
                                                ),
                                                child: Icon(
                                                  Icons.verified,
                                                  size: 12,
                                                  color: Colors.blue,
                                                ),
                                              ),
                                          ],
                                        ),
                                        Text(
                                          time,
                                          style: GoogleFonts.outfit(
                                            fontSize: 11,
                                            color: Colors.grey[500],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      comment['content'],
                                      style: GoogleFonts.outfit(
                                        color: Colors.black87,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),

          // Input
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: InputDecoration(
                      hintText: 'Add a comment...',
                      hintStyle: GoogleFonts.outfit(color: Colors.grey[400]),
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                    ),
                    textCapitalization: TextCapitalization.sentences,
                    onSubmitted: (_) => _addComment(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _addComment,
                  icon: const Icon(Icons.send_rounded),
                  color: AppTheme.primaryColor,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
