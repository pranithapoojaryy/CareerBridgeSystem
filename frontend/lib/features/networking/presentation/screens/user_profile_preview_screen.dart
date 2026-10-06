import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/utils/identity_helper.dart';
import '../../../../core/theme/app_theme.dart';
import 'chat_screen.dart';
import 'recruiter_profile_view.dart';

class UserProfilePreviewScreen extends StatefulWidget {
  final String userId;
  final String userName;
  final String? userAvatar;

  const UserProfilePreviewScreen({
    super.key,
    required this.userId,
    required this.userName,
    this.userAvatar,
  });

  @override
  State<UserProfilePreviewScreen> createState() =>
      _UserProfilePreviewScreenState();
}

class _UserProfilePreviewScreenState extends State<UserProfilePreviewScreen> {
  final _client = Supabase.instance.client;
  bool _isLoading = true;
  Map<String, dynamic>? _userProfile;
  List<Map<String, dynamic>> _userPosts = [];
  String _displayName = '';
  String? _displayAvatar;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    try {
      // Fetch user profile
      final profileData = await _client
          .from('profiles')
          .select('*, organizations(name, logo_url)')
          .eq('id', widget.userId)
          .single();

      // Check if recruiter role - redirect to recruiter profile view
      if (profileData['role'] == 'recruiter') {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => RecruiterProfileView(
                userId: widget.userId,
                userName: widget.userName,
                userAvatar: widget.userAvatar,
              ),
            ),
          );
        }
        return;
      }

      // Fetch user's recent posts
      final postsData = await _client
          .from('posts')
          .select('*')
          .eq('author_id', widget.userId)
          .order('created_at', ascending: false)
          .limit(5);

      if (mounted) {
        final identity = IdentityHelper.getOrganizationalIdentity(profileData);
        setState(() {
          _userProfile = profileData;
          _userPosts = List<Map<String, dynamic>>.from(postsData);
          _displayName = identity['display_name'] ?? widget.userName;
          _displayAvatar = identity['avatar_url'] ?? widget.userAvatar;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading profile: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          _displayName.isNotEmpty ? _displayName : widget.userName,
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  _buildProfileHeader(),
                  const SizedBox(height: 16),
                  _buildActionButtons(),
                  const SizedBox(height: 24),
                  _buildRecentPosts(),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileHeader() {
    final identity = IdentityHelper.getOrganizationalIdentity(_userProfile!);
    final role = identity['role_label'] ?? 'User';
    final college = _userProfile?['organizations']?['name'] ?? '';
    final String displayName = identity['display_name'] ?? widget.userName;
    final String? displayAvatar = identity['avatar_url'] ?? widget.userAvatar;
    final bio = _userProfile?['bio'] ?? '';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(color: Colors.white),
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundImage: displayAvatar != null
                ? NetworkImage(displayAvatar)
                : null,
            child: displayAvatar == null
                ? Text(
                    displayName.isNotEmpty ? displayName[0] : '?',
                    style: GoogleFonts.outfit(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
          const SizedBox(height: 16),
          Text(
            displayName,
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$role${college.isNotEmpty ? ' at $college' : ''}',
            style: GoogleFonts.outfit(fontSize: 14, color: Colors.grey[600]),
          ),
          if (bio.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              bio,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(fontSize: 14, color: Colors.grey[700]),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatScreen(
                      targetUserId: widget.userId,
                      targetUserName: _displayName,
                      targetUserAvatar: _displayAvatar,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.message_rounded),
              label: Text(
                'Message',
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentPosts() {
    if (_userPosts.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(Icons.post_add_outlined, size: 48, color: Colors.grey[300]),
            const SizedBox(height: 8),
            Text(
              'No posts yet',
              style: GoogleFonts.outfit(color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'Recent Posts',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 12),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          itemCount: _userPosts.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final post = _userPosts[index];
            return _buildPostCard(post);
          },
        ),
      ],
    );
  }

  Widget _buildPostCard(Map<String, dynamic> post) {
    final content = post['content'] ?? '';
    final imageUrl = post['image_url'];
    final createdAt = DateTime.parse(post['created_at']);
    final timeAgo = _getTimeAgo(createdAt);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            timeAgo,
            style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey[500]),
          ),
          const SizedBox(height: 8),
          Text(content, style: GoogleFonts.outfit(fontSize: 14)),
          if (imageUrl != null) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                imageUrl,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
