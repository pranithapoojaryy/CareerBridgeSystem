import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/utils/identity_helper.dart';
import 'org_identity_tile.dart';
import '../../../networking/data/network_repository.dart';
import '../../../networking/presentation/screens/network_screen.dart';
import '../../../networking/presentation/screens/chat_screen.dart';

class MessagingPreviewWidget extends ConsumerStatefulWidget {
  const MessagingPreviewWidget({super.key});

  @override
  ConsumerState<MessagingPreviewWidget> createState() =>
      _MessagingPreviewWidgetState();
}

class _MessagingPreviewWidgetState
    extends ConsumerState<MessagingPreviewWidget> {
  final _repository = NetworkRepository();
  bool _isLoading = true;
  List<Map<String, dynamic>> _conversations = [];

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    try {
      final data = await _repository.getMyConversations();

      // Simplify logic using IdentityHelper
      final enhancedData = await IdentityHelper.enhanceUserList(data);

      if (mounted) {
        setState(() {
          // Take only top 3 for preview
          _conversations = enhancedData.take(3).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading conversations: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6A11CB).withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            const Color(0xFFF3F0FF), // Light Violet tint
          ],
        ),
        border: Border.all(
          color: const Color(0xFF6A11CB).withValues(alpha: 0.1),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Messages',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2D3748),
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const NetworkScreen(), // Opens Network Tab 0 (Messages)
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6A11CB).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_forward_rounded,
                    size: 16,
                    color: Color(0xFF6A11CB),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_conversations.isEmpty)
            _buildEmptyState()
          else
            ..._conversations.map((c) => _buildConversationItem(c)),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          children: [
            Icon(
              Icons.chat_bubble_outline_rounded,
              size: 32,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 8),
            Text(
              'No new messages',
              style: GoogleFonts.outfit(color: Colors.grey[500], fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConversationItem(Map<String, dynamic> conversation) {
    final bool isUnread = (conversation['unread_count'] ?? 0) > 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: OrgIdentityTile(
        userData: conversation,
        isCondensed: true,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatScreen(
                targetUserId: conversation['user_id'],
                targetUserName:
                    conversation['display_name'] ?? conversation['full_name'],
                targetUserAvatar: conversation['avatar_url'],
              ),
            ),
          );
        },
        trailing: isUnread
            ? Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: Color(0xFFFF416C),
                  shape: BoxShape.circle,
                ),
              )
            : null,
      ),
    );
  }
}
