import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../../../core/theme/app_theme.dart';

class FeedPreviewWidget extends StatefulWidget {
  final VoidCallback onViewAll;
  final Map<String, dynamic>? orgData; // Added to support identity fallback

  const FeedPreviewWidget({super.key, required this.onViewAll, this.orgData});

  @override
  State<FeedPreviewWidget> createState() => _FeedPreviewWidgetState();
}

class _FeedPreviewWidgetState extends State<FeedPreviewWidget> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _latestPosts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPreviewPosts();
  }

  Future<void> _loadPreviewPosts() async {
    try {
      final response = await _supabase
          .from('posts')
          .select(
            '*, author:profiles(id, full_name, avatar_url, profile_image_url, profile_photo_url, role, organization_id, organization:organizations(name, logo_url))',
          )
          .order('created_at', ascending: false)
          .limit(
            5,
          ); // Increased limit as we might show more in horizontal scroll

      if (mounted) {
        setState(() {
          _latestPosts = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            AppTheme.primaryColor.withValues(alpha: 0.02), // Very subtle tint
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.feed_rounded,
                          color: Colors.blue,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Text(
                          'Campus Feed',
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: widget.onViewAll,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'View All',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(24.0),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_latestPosts.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Center(
                child: Text(
                  'No updates yet',
                  style: GoogleFonts.outfit(color: Colors.grey),
                ),
              ),
            )
          else
            SizedBox(
              height: 240, // Increased height for image (was 160)
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                scrollDirection: Axis.horizontal,
                itemCount: _latestPosts.length,
                separatorBuilder: (context, index) => const SizedBox(width: 16),
                itemBuilder: (context, index) {
                  final post = _latestPosts[index];
                  return _buildPostTile(post);
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPostTile(Map<String, dynamic> post) {
    final author = post['author'] ?? {};
    final String currentUserId = _supabase.auth.currentUser?.id ?? '';
    final bool isMyPost = author['id'] == currentUserId;

    // Logic from CollegeFeedScreen:
    final bool isOfficialPost =
        author['role'] == 'admin' ||
        author['role'] == 'college_admin' ||
        author['role'] == 'recruiter';

    final organization = author['organization'];
    String orgName = organization?['name'] ?? '';
    String? orgLogoUrl = organization?['logo_url'];

    // Fallback to passed orgData if it's my post
    if (isMyPost && widget.orgData != null) {
      if (orgName.isEmpty) orgName = widget.orgData!['name'] ?? '';
      if (orgLogoUrl == null) orgLogoUrl = widget.orgData!['logo_url'];
    }

    final String displayName = (isOfficialPost && orgName.isNotEmpty)
        ? orgName
        : (author['full_name'] ?? 'Unknown User');

    final String? displayImage = (isOfficialPost && orgLogoUrl != null)
        ? orgLogoUrl
        : (author['profile_photo_url'] ??
              author['profile_image_url'] ??
              author['avatar_url']);

    final List images = post['image_urls'] as List? ?? [];
    final bool hasImage = images.isNotEmpty;

    return Container(
      width: 280, // Fixed width for each tile
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: InkWell(
        onTap: widget.onViewAll,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Header
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundImage: displayImage != null
                        ? NetworkImage(displayImage)
                        : null,
                    backgroundColor: Colors.white,
                    child: displayImage == null
                        ? Icon(
                            isOfficialPost ? Icons.business : Icons.person,
                            size: 14,
                            color: isOfficialPost
                                ? Colors.orange
                                : Colors.grey[400],
                          )
                        : null,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          timeago.format(
                            DateTime.parse(post['created_at']),
                            locale: 'en_short',
                          ),
                          style: GoogleFonts.outfit(
                            color: Colors.grey[500],
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 2. Image (if present)
            if (hasImage)
              Container(
                height: 110,
                width: double.infinity,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: NetworkImage(images.first.toString()),
                    fit: BoxFit.cover,
                  ),
                ),
              ),

            // 3. Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                child: Text(
                  post['content'] ?? '',
                  maxLines: hasImage ? 2 : 5,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    color: Colors.grey[800],
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
