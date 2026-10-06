import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart'; // Added for TapGestureRecognizer
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart'; // Added for url launching
import '../../../../features/networking/data/network_repository.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/full_screen_image_viewer.dart';
import 'create_post_dialog.dart';

class SocialFeedPanel extends ConsumerStatefulWidget {
  const SocialFeedPanel({super.key});

  @override
  ConsumerState<SocialFeedPanel> createState() => _SocialFeedPanelState();
}

class _SocialFeedPanelState extends ConsumerState<SocialFeedPanel> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;
  List<Map<String, dynamic>> _posts = [];
  Map<String, dynamic>? _currentUserProfile;
  final _networkRepository = NetworkRepository();
  final Map<String, String> _connectionStatuses = {};
  Set<String> _likedPostIds = {};

  @override
  void initState() {
    super.initState();
    _loadPosts();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      final response = await _supabase
          .from('profiles')
          .select('*')
          .eq('id', user.id)
          .maybeSingle();

      if (mounted && response != null) {
        setState(() {
          _currentUserProfile = response;
        });
      }
    } catch (e) {
      debugPrint('Error loading user profile: $e');
    }
  }

  Future<void> _loadPosts() async {
    try {
      final response = await _supabase
          .from('posts')
          .select(
            // Fetch both image columns for author, and organization logo
            '*, author:profiles(id, full_name, avatar_url, profile_image_url, profile_photo_url, role, organization_id, organization:organizations(name, logo_url))',
          )
          .order('created_at', ascending: false)
          .limit(20);

      final posts = List<Map<String, dynamic>>.from(response);

      // Fetch connection statuses for authors
      final uniqueAuthorIds = posts
          .map((p) => (p['author'] as Map?)?['id'] as String?)
          .where((id) => id != null && id != _supabase.auth.currentUser?.id)
          .toSet();

      for (final authorId in uniqueAuthorIds) {
        if (authorId != null) {
          _connectionStatuses[authorId] =
              await _networkRepository.getConnectionStatus(authorId) ?? '';
        }
      }

      // Fetch liked posts
      final user = _supabase.auth.currentUser;
      Set<String> likedIds = {};
      if (user != null) {
        final likedResponse = await _supabase
            .from('post_likes')
            .select('post_id')
            .eq('user_id', user.id);

        likedIds = (likedResponse as List)
            .map((e) => e['post_id'] as String)
            .toSet();
      }

      setState(() {
        _posts = posts;
        _likedPostIds = likedIds;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading posts: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleConnect(String targetUserId) async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) return;

      setState(() {
        _connectionStatuses[targetUserId] = 'pending';
      });

      await _networkRepository.sendConnectionRequest(targetUserId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Connection request sent!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _connectionStatuses.remove(targetUserId);
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _showCommentSheet(Map<String, dynamic> post) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CommentSheet(postId: post['id']),
    );
  }

  Future<void> _toggleLike(String postId, int index) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    final isLiked = _likedPostIds.contains(postId);
    final currentLikes = _posts[index]['likes_count'] as int;

    // Optimistic Update
    setState(() {
      if (isLiked) {
        _likedPostIds.remove(postId);
        _posts[index]['likes_count'] = currentLikes > 0 ? currentLikes - 1 : 0;
      } else {
        _likedPostIds.add(postId);
        _posts[index]['likes_count'] = currentLikes + 1;
      }
    });

    try {
      if (isLiked) {
        // Unlike
        await _supabase
            .from('post_likes')
            .delete()
            .eq('post_id', postId)
            .eq('user_id', user.id);
      } else {
        // Like
        await _supabase.from('post_likes').insert({
          'post_id': postId,
          'user_id': user.id,
        });
      }
    } catch (e) {
      // Revert on error
      setState(() {
        if (isLiked) {
          _likedPostIds.add(postId);
          _posts[index]['likes_count'] = currentLikes;
        } else {
          _likedPostIds.remove(postId);
          _posts[index]['likes_count'] = currentLikes;
        }
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error updating like: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    /* if (_posts.isEmpty) {
       // Removed early return to always show create post card
    } */

    return ListView(
      // Using standard list view but inside a container or column in parent
      // Parent will likely use expanded, so we actually want a Column to put in specific widgets
      // But 'ListView' inside column might error if not expanded.
      // The parent structure is 'Column' (sidebar layout).
      // We should return a Column of widgets or ListView.builder with specific physics?
      // Let's return a Column of cards.
      primary: false,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
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
                const SizedBox(height: 8),
                Text(
                  'Connect with others to see their updates here.',
                  style: GoogleFonts.outfit(color: Colors.grey[500]),
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

  void _openCreatePostDialog() async {
    final result = await showDialog(
      context: context,
      builder: (context) => const CreatePostDialog(),
    );

    if (result == true) {
      _loadPosts(); // Reload feed on success
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

  // ... (existing _loadPosts and other methods)

  // In _buildCreatePostCard:
  /* Wrapper function to help locate insertion point, logic below replaces entire _buildCreatePostCard */
  Widget _buildCreatePostCard() {
    // Logic matching Profile Screen: Prioritize profile_photo_url, then profile_image_url, then avatar_url
    final String? imageUrl = _currentUserProfile != null
        ? (_currentUserProfile!['profile_photo_url'] ??
              _currentUserProfile!['profile_image_url'] ??
              _currentUserProfile!['avatar_url'])
        : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            const Color(0xFFF3F0FF), // Subtle violet tint
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF6A11CB).withValues(alpha: 0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6A11CB).withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
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
                backgroundImage: imageUrl != null && imageUrl.isNotEmpty
                    ? NetworkImage(imageUrl)
                    : null,
                child: imageUrl == null || imageUrl.isEmpty
                    ? Icon(Icons.person_rounded, color: AppTheme.primaryColor)
                    : null,
              ),
              // Cleaned up syntax
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
                      color: Colors.white,
                      gradient: LinearGradient(
                        colors: [Colors.grey[50]!, Colors.grey[100]!],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(50),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Text(
                      'Start a post...',
                      style: GoogleFonts.outfit(
                        color: Colors.grey[500],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  onPressed: _openCreatePostDialog,
                  icon: const Icon(Icons.add, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 8),
          Wrap(
            alignment: WrapAlignment.spaceAround,
            runSpacing: 8,
            children: [
              _buildMediaButton(
                Icons.image_outlined,
                'Media',
                Colors.blue,
                onTap: _openCreatePostDialog,
              ),
              _buildMediaButton(
                Icons.calendar_today_outlined,
                'Event',
                Colors.orange,
              ),
              _buildMediaButton(
                Icons.article_outlined,
                'Article',
                Colors.purple,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMediaButton(
    IconData icon,
    String label,
    Color color, {
    VoidCallback? onTap,
  }) {
    return TextButton.icon(
      onPressed: onTap ?? () {},
      icon: Icon(icon, color: color, size: 20),
      label: Text(label, style: GoogleFonts.outfit(color: Colors.grey[600])),
    );
  }

  Widget _buildPostCard(Map<String, dynamic> post, int index) {
    final author = post['author'] ?? {};
    final String authorName = author['full_name'] ?? 'Unknown User';

    // Logic matching Profile Screen: Prioritize profile_photo_url, then profile_image_url, then avatar_url
    final String? authorImageUrl =
        author['profile_photo_url'] ??
        author['profile_image_url'] ??
        author['avatar_url'];

    final organization = author['organization'];
    final String orgName = organization?['name'] ?? '';
    final String? orgLogoUrl = organization?['logo_url'];
    final timeAgo = timeago.format(DateTime.parse(post['created_at']));
    final content = post['content'] ?? '';
    final likesCount = post['likes_count'] ?? 0;
    final commentsCount = post['comments_count'] ?? 0;
    final postId = post['id'];

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            Colors.white, // Keep mostly white for readability
            const Color(0xFFF0F4FF), // Very subtle blue tint at bottom right
          ],
          stops: const [0.0, 0.7, 1.0],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // 1. Avatar (Profile Photo) with Verification Badge
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor:
                          (author['role'] == 'admin' ||
                                      author['role'] == 'college_admin' ||
                                      author['role'] == 'recruiter'
                                  ? Colors.orange
                                  : AppTheme.primaryColor)
                              .withValues(alpha: 0.1),
                      backgroundImage:
                          (author['role'] == 'admin' ||
                                  author['role'] == 'college_admin' ||
                                  author['role'] == 'recruiter') &&
                              orgLogoUrl != null
                          ? NetworkImage(orgLogoUrl)
                          : (authorImageUrl != null && authorImageUrl.isNotEmpty
                                ? NetworkImage(authorImageUrl)
                                : null),
                      child:
                          ((author['role'] == 'admin' ||
                                      author['role'] == 'college_admin' ||
                                      author['role'] == 'recruiter') &&
                                  orgLogoUrl == null) ||
                              ((author['role'] != 'admin' &&
                                      author['role'] != 'college_admin' &&
                                      author['role'] != 'recruiter') &&
                                  (authorImageUrl == null ||
                                      authorImageUrl.isEmpty))
                          ? Icon(
                              (author['role'] == 'admin' ||
                                      author['role'] == 'college_admin' ||
                                      author['role'] == 'recruiter')
                                  ? Icons.business_rounded
                                  : Icons.person_rounded,
                              color:
                                  (author['role'] == 'admin' ||
                                      author['role'] == 'college_admin' ||
                                      author['role'] == 'recruiter')
                                  ? Colors.orange
                                  : AppTheme.primaryColor,
                            )
                          : null,
                    ),
                    // Show Verified Badge on Avatar if user has an organization (College Verified Student)
                    if (organization != null)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.verified_rounded,
                            color: Colors.green,
                            size: 14,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 12),

                // 2. Name & Meta
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              // Force Organization Name for Recruiter/Admin
                              ((author['role'] == 'admin' ||
                                          author['role'] == 'college_admin' ||
                                          author['role'] == 'recruiter') &&
                                      orgName.isNotEmpty)
                                  ? orgName
                                  : authorName,
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Colors.black87,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          // Admin/Recruiter Badge (Blue)
                          if (author['role'] == 'admin' ||
                              author['role'] == 'college_admin' ||
                              author['role'] == 'recruiter')
                            const Icon(
                              Icons.verified,
                              size: 14,
                              color: Colors.blue,
                            ),
                        ],
                      ),

                      // Subtitle Logic
                      if (author['role'] == 'admin' ||
                          author['role'] == 'college_admin')
                        Text(
                          'Official Update',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        )
                      else if (author['role'] == 'recruiter')
                        // Simplified subtitle since Title is now Company Name
                        Text(
                          'Recruiter',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        )
                      else
                        Row(
                          children: [
                            if (orgName.isNotEmpty) ...[
                              if (orgLogoUrl != null && orgLogoUrl.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(right: 4),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: Image.network(
                                      orgLogoUrl,
                                      width: 14,
                                      height: 14,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Icon(
                                        Icons.school,
                                        size: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ),
                                )
                              else
                                Padding(
                                  padding: const EdgeInsets.only(right: 4),
                                  child: Icon(
                                    Icons.school,
                                    size: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                            ],
                            Expanded(
                              child: Text(
                                orgName.isNotEmpty
                                    ? 'student at $orgName'
                                    : 'Student',
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                                overflow: TextOverflow.ellipsis,
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
                // Connect or Follow Button
                if (author['id'] != _supabase.auth.currentUser?.id) ...[
                  Builder(
                    builder: (context) {
                      final status = _connectionStatuses[author['id']];

                      if (status == 'accepted') {
                        return TextButton.icon(
                          onPressed: null,
                          icon: const Icon(
                            Icons.check,
                            size: 16,
                            color: Colors.green,
                          ),
                          label: Text(
                            'Connected',
                            style: GoogleFonts.outfit(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      } else if (status == 'pending') {
                        return TextButton.icon(
                          onPressed: null,
                          icon: const Icon(
                            Icons.access_time,
                            size: 16,
                            color: Colors.orange,
                          ),
                          label: Text(
                            'Pending',
                            style: GoogleFonts.outfit(
                              color: Colors.orange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      } else {
                        return TextButton(
                          onPressed: () => _handleConnect(author['id']),
                          child: Text(
                            '+ Connect',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ],
            ),
          ),

          const Divider(height: 1),

          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildRichText(content), // Helper for tags/mentions
                const SizedBox(height: 12),

                // Images
                if (post['image_urls'] != null &&
                    (post['image_urls'] as List).isNotEmpty)
                  _buildPostImages(post['image_urls'] as List),

                // Referenced Content (Certificate/Project)
                if (post['reference_type'] == 'certification' &&
                    post['reference_data'] != null)
                  _buildCertificateReference(post['reference_data']),

                if (post['reference_type'] == 'project' &&
                    post['reference_data'] != null)
                  _buildProjectReference(post['reference_data']),
              ],
            ),
          ),

          // Actions
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildActionButton(
                  icon: _likedPostIds.contains(postId)
                      ? Icons.thumb_up_rounded
                      : Icons.thumb_up_alt_outlined,
                  color: _likedPostIds.contains(postId)
                      ? Colors.blue
                      : Colors.grey[600]!,
                  label: likesCount > 0 ? '$likesCount Likes' : 'Like',
                  onTap: () => _toggleLike(postId, index),
                ),
                _buildActionButton(
                  icon: Icons.comment_outlined,
                  label: commentsCount > 0
                      ? '$commentsCount Comments'
                      : 'Comment',
                  onTap: () => _showCommentSheet(post),
                ),
                _buildActionButton(
                  icon: Icons.share_outlined,
                  label: 'Share',
                  onTap: () {
                    final content =
                        post['content'] ??
                        'Check out this post on CareerBridge!';
                    // Simple share for now
                    Share.share('$content\n\nSent via CareerBridge');
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRichText(String text) {
    if (text.isEmpty) return const SizedBox.shrink();

    final List<TextSpan> spans = [];
    final RegExp exp = RegExp(
      r"((https?:www\.)|(https?:\/\/)|(www\.))[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9]{1,6}(\/[-a-zA-Z0-9()@:%_\+.~#?&\/\/=]*)?",
    );

    text.splitMapJoin(
      exp,
      onMatch: (Match match) {
        final String url = match.group(0)!;
        spans.add(
          TextSpan(
            text: url,
            style: GoogleFonts.outfit(
              color: Colors.blue,
              decoration: TextDecoration.underline,
              fontWeight: FontWeight.w500,
            ),
            recognizer: TapGestureRecognizer()
              ..onTap = () async {
                final Uri uri = Uri.parse(
                  !url.startsWith('http') ? 'https://$url' : url,
                );
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
          ),
        );
        return '';
      },
      onNonMatch: (String nonMatch) {
        // Process hashtags/mentions in non-url text
        final words = nonMatch.split(' ');
        for (int i = 0; i < words.length; i++) {
          final word = words[i];
          final isLast = i == words.length - 1;
          final isTag = word.startsWith('#') || word.startsWith('@');

          spans.add(
            TextSpan(
              text: '$word${isLast ? '' : ' '}',
              style: isTag
                  ? const TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.w600,
                    )
                  : GoogleFonts.outfit(
                      color: Colors.black87,
                      height: 1.5,
                      fontSize: 14,
                    ),
            ),
          );
        }
        return '';
      },
    );

    return RichText(text: TextSpan(children: spans));
  }

  Widget _buildPostImages(List images) {
    if (images.isEmpty) return const SizedBox.shrink();

    // Convert to string list safely
    final List<String> imageUrls = images.map((e) => e.toString()).toList();
    final count = imageUrls.length;

    return Container(
      margin: const EdgeInsets.only(top: 12),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: AspectRatio(
        aspectRatio: count == 1
            ? 1.5
            : 1, // 1.5 for single (landscape), 1 for grid
        child: _buildGridForCount(count, imageUrls),
      ),
    );
  }

  Widget _buildGridForCount(int count, List<String> imageUrls) {
    if (count == 1) {
      return _buildSingleImage(imageUrls[0], 0, imageUrls);
    } else if (count == 2) {
      return Row(
        children: [
          Expanded(child: _buildSingleImage(imageUrls[0], 0, imageUrls)),
          const SizedBox(width: 2),
          Expanded(child: _buildSingleImage(imageUrls[1], 1, imageUrls)),
        ],
      );
    } else if (count == 3) {
      return Row(
        children: [
          Expanded(child: _buildSingleImage(imageUrls[0], 0, imageUrls)),
          const SizedBox(width: 2),
          Expanded(
            child: Column(
              children: [
                Expanded(child: _buildSingleImage(imageUrls[1], 1, imageUrls)),
                const SizedBox(height: 2),
                Expanded(child: _buildSingleImage(imageUrls[2], 2, imageUrls)),
              ],
            ),
          ),
        ],
      );
    } else {
      // 4 or more
      return Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(child: _buildSingleImage(imageUrls[0], 0, imageUrls)),
                const SizedBox(width: 2),
                Expanded(child: _buildSingleImage(imageUrls[1], 1, imageUrls)),
              ],
            ),
          ),
          const SizedBox(height: 2),
          Expanded(
            child: Row(
              children: [
                Expanded(child: _buildSingleImage(imageUrls[2], 2, imageUrls)),
                const SizedBox(width: 2),
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _buildSingleImage(imageUrls[3], 3, imageUrls),
                      if (count > 4)
                        Container(
                          color: Colors.black54,
                          alignment: Alignment.center,
                          child: Text(
                            '+${count - 4}',
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }
  }

  Widget _buildSingleImage(String url, int index, List<String> allUrls) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                FullScreenImageViewer(imageUrls: allUrls, initialIndex: index),
          ),
        );
      },
      child: Image.network(
        url,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            color: Colors.grey[100],
            alignment: Alignment.center,
            child: const Icon(Icons.image, color: Colors.grey),
          );
        },
        errorBuilder: (_, __, ___) => Container(
          color: Colors.grey[200],
          child: const Icon(Icons.broken_image, color: Colors.grey),
        ),
      ),
    );
  }

  Widget _buildCertificateReference(Map<String, dynamic> data) {
    final title = data['title'] ?? 'Certification';
    final subtitle = data['subtitle'] ?? 'Provider';
    final imageUrl = data['image_url'];
    final isVerified = data['verification_status'] == 'verified';

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey[50],
              image: imageUrl != null
                  ? DecorationImage(image: NetworkImage(imageUrl))
                  : null,
            ),
            child: imageUrl == null
                ? const Icon(Icons.workspace_premium, color: Colors.orange)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
          ),
          if (isVerified)
            const Icon(Icons.verified, color: Colors.blue, size: 20),
        ],
      ),
    );
  }

  Widget _buildProjectReference(Map<String, dynamic> data) {
    // Placeholder for future project reference implementation
    return const SizedBox.shrink();
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color color = Colors.grey,
  }) {
    return Expanded(
      // Ensure equal distribution
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 4,
            vertical: 8,
          ), // Reduced padding
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center, // Center content
            children: [
              Icon(icon, size: 18, color: color), // Slightly smaller icon
              const SizedBox(width: 6),
              Flexible(
                // Allow text to shrink/truncate
                child: Text(
                  label,
                  style: GoogleFonts.outfit(
                    fontSize: 12, // Slightly smaller font
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} // End of SocialFeedPanelState

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
