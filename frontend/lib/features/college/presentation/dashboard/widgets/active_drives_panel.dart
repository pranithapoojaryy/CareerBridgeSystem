import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../data/college_providers.dart';

class ActiveDrivesPanel extends ConsumerStatefulWidget {
  const ActiveDrivesPanel({super.key});

  @override
  ConsumerState<ActiveDrivesPanel> createState() => _ActiveDrivesPanelState();
}

class _ActiveDrivesPanelState extends ConsumerState<ActiveDrivesPanel> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _drives = [];

  @override
  void initState() {
    super.initState();
    _fetchDrives();
  }

  Future<void> _fetchDrives() async {
    try {
      final response = await Supabase.instance.client
          .from('jobs')
          .select('''
            *,
            organization:organizations(name, logo_url)
          ''')
          .eq('status', 'open')
          .order('created_at', ascending: false)
          .limit(4);

      if (mounted) {
        setState(() {
          _drives = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            AppTheme.primaryColor.withValues(alpha: 0.02), // Very subtle tint
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.06),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Active & Upcoming Drives',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              TextButton(
                onPressed: () {
                  ref.read(collegeDashboardIndexProvider.notifier).setIndex(3);
                },
                child: Text(
                  'View All',
                  style: GoogleFonts.outfit(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Table / List Header
          Row(
            children: [
              Expanded(flex: 3, child: _headerText('Company')),
              Expanded(flex: 2, child: _headerText('Role')),
              Expanded(flex: 2, child: _headerText('Date')),
              Expanded(flex: 2, child: _headerText('Status')),
            ],
          ),
          const Divider(height: 24),

          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_drives.isEmpty)
            _buildEmptyState()
          else
            ..._drives.map((drive) => _buildDriveRow(drive)),
        ],
      ),
    );
  }

  Widget _buildDriveRow(Map<String, dynamic> drive) {
    final companyName = drive['organization']?['name'] ?? 'Unknown';
    final role = drive['title'] ?? 'N/A';
    final createdAt =
        DateTime.tryParse(drive['created_at'] ?? '') ?? DateTime.now();
    final dateStr = DateFormat('MMM dd, yyyy').format(createdAt);
    final status = drive['status'] ?? 'open';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                  backgroundImage: drive['organization']?['logo_url'] != null
                      ? NetworkImage(drive['organization']?['logo_url'])
                      : null,
                  child: drive['organization']?['logo_url'] == null
                      ? Text(
                          companyName[0].toUpperCase(),
                          style: GoogleFonts.outfit(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    companyName,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              role,
              style: GoogleFonts.outfit(fontSize: 13, color: Colors.grey[700]),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              dateStr,
              style: GoogleFonts.outfit(fontSize: 13, color: Colors.grey[600]),
            ),
          ),
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                status.toUpperCase(),
                style: GoogleFonts.outfit(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[700],
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(Icons.work_off_outlined, size: 48, color: Colors.grey[300]),
          const SizedBox(height: 12),
          Text(
            'No Active Drives',
            style: GoogleFonts.outfit(color: Colors.grey[500], fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _headerText(String text) {
    return Text(
      text.toUpperCase(),
      style: GoogleFonts.outfit(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: Colors.grey[400],
        letterSpacing: 1,
      ),
    );
  }
}
