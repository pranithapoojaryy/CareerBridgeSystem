import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/identity_helper.dart';

class OrgIdentityTile extends StatelessWidget {
  final Map<String, dynamic> userData;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool isCondensed;

  const OrgIdentityTile({
    super.key,
    required this.userData,
    this.onTap,
    this.trailing,
    this.isCondensed = false,
  });

  @override
  Widget build(BuildContext context) {
    final identity = IdentityHelper.getOrganizationalIdentity(userData);
    final String name = identity['display_name'] ?? 'Unknown Member';
    final String? avatarUrl = identity['avatar_url'];
    final String roleLabel = identity['role_label'] ?? 'Member';
    final bool isOrgIdentity =
        userData['organization'] != null || userData['organizations'] != null;

    return ListTile(
      onTap: onTap,
      contentPadding: isCondensed
          ? EdgeInsets.zero
          : const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: isOrgIdentity
              ? Border.all(
                  color: AppTheme.primaryColor.withValues(alpha: 0.2),
                  width: 1.5,
                )
              : null,
        ),
        child: CircleAvatar(
          radius: isCondensed ? 18 : 24,
          backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
          backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
          child: avatarUrl == null
              ? Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                )
              : null,
        ),
      ),
      title: Text(
        name,
        style: GoogleFonts.outfit(
          fontWeight: FontWeight.bold,
          fontSize: isCondensed ? 14 : 16,
          color: Colors.black87,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        roleLabel,
        style: GoogleFonts.outfit(
          fontSize: isCondensed ? 11 : 12,
          color: Colors.grey[600],
        ),
      ),
      trailing: trailing,
    );
  }
}
