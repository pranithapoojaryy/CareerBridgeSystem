import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import 'student_mock_providers.dart';
import '../../domain/mock_interview_models.dart';
import 'active_mock_session_screen.dart';
import '../../../../core/theme/app_theme.dart';
import 'package:flutter_animate/flutter_animate.dart';

class StudentMocksScreen extends ConsumerStatefulWidget {
  const StudentMocksScreen({super.key});

  @override
  ConsumerState<StudentMocksScreen> createState() => _StudentMocksScreenState();
}

class _StudentMocksScreenState extends ConsumerState<StudentMocksScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Mock Interviews',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            color: AppTheme.textColor,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppTheme.textColor,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.grey[600],
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(25),
                gradient: LinearGradient(
                  colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
                ),
              ),
              tabs: [
                Tab(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      "Available",
                      style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                Tab(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      "History",
                      style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [_AvailableMocksList(), _MockHistoryList()],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}

class _AvailableMocksList extends ConsumerWidget {
  const _AvailableMocksList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mocksAsync = ref.watch(availableMocksProvider);
    final historyAsync = ref.watch(studentMockAttemptsProvider);

    return mocksAsync.when(
      data: (mocks) {
        if (mocks.isEmpty) {
          return Center(
            child: Text(
              "No mock interviews available yet.",
              style: GoogleFonts.poppins(color: Colors.grey),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: mocks.length,
          itemBuilder: (context, index) {
            final mock = mocks[index];
            final size = MediaQuery.of(context).size;
            final isSmallScreen = size.width < 600;

            bool hasAttempted = false;
            if (historyAsync.hasValue) {
              hasAttempted = historyAsync.value!.any(
                (a) => a.mockId == mock.id,
              );
            }

            final colors = [
              [const Color(0xFF8B5CF6), const Color(0xFF6D28D9)],
              [AppTheme.primaryColor, AppTheme.secondaryColor],
              [const Color(0xFFF97316), const Color(0xFFD97706)],
              [const Color(0xFF10B981), const Color(0xFF059669)],
            ];
            final gradient = colors[index % colors.length];

            return Container(
                  margin: EdgeInsets.only(bottom: isSmallScreen ? 16 : 24),
                  decoration: AppTheme.clayDecoration,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      decoration: const BoxDecoration(color: Colors.white),
                      child: Padding(
                        padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(
                                    isSmallScreen ? 10 : 12,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(colors: gradient),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.video_camera_front,
                                    color: Colors.white,
                                    size: isSmallScreen ? 24 : 28,
                                  ),
                                ),
                                SizedBox(width: isSmallScreen ? 12 : 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        mock.title,
                                        style: GoogleFonts.outfit(
                                          fontSize: isSmallScreen ? 16 : 18,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.textColor,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        mock.description ?? 'No description',
                                        style: GoogleFonts.outfit(
                                          fontSize: isSmallScreen ? 13 : 14,
                                          color: Colors.grey[600],
                                          height: 1.4,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: isSmallScreen ? 12 : 16),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: gradient[0].withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: gradient[0].withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.timer_outlined,
                                        size: 16,
                                        color: gradient[0],
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${mock.timeLimitMinutes} mins',
                                        style: GoogleFonts.outfit(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: gradient[0],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (hasAttempted) ...[
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.check_circle,
                                          size: 16,
                                          color: Colors.blue.shade700,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Attempted',
                                          style: GoogleFonts.outfit(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.blue.shade700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            SizedBox(height: isSmallScreen ? 12 : 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: hasAttempted
                                    ? null
                                    : () => _startMock(context, ref, mock),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: gradient[0],
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(
                                    vertical: isSmallScreen ? 12 : 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                ),
                                child: Text(
                                  hasAttempted
                                      ? 'Already Attempted'
                                      : 'Start Mock',
                                  style: GoogleFonts.outfit(
                                    fontSize: isSmallScreen ? 14 : 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                )
                .animate()
                .fadeIn(duration: 400.ms, delay: (index * 100).ms)
                .slideY(begin: 0.2, end: 0, curve: Curves.easeOutCubic);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text("Error: $e")),
    );
  }

  Future<void> _startMock(
    BuildContext context,
    WidgetRef ref,
    MockDefinition mock,
  ) async {
    final attemptId = const Uuid().v4();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ActiveMockSessionScreen(attemptId: attemptId, mockId: mock.id),
      ),
    );
  }
}

class _MockHistoryList extends ConsumerWidget {
  const _MockHistoryList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(studentMockAttemptsProvider);

    return historyAsync.when(
      data: (attempts) {
        if (attempts.isEmpty) {
          return const Center(child: Text("No history yet."));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: attempts.length,
          itemBuilder: (context, index) {
            final attempt = attempts[index];
            return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: AppTheme.clayDecoration,
                  child: ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.history_rounded,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    title: Text(
                      attempt.mockTitle ?? 'Mock Interview',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textColor,
                      ),
                    ),
                    subtitle: Text(
                      'Score: ${attempt.totalScore ?? "Pending"}',
                      style: GoogleFonts.outfit(color: Colors.grey[600]),
                    ),
                    trailing: Text(
                      attempt.submittedAt != null
                          ? '${attempt.submittedAt!.day}/${attempt.submittedAt!.month}'
                          : '',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[500],
                      ),
                    ),
                  ),
                )
                .animate()
                .fadeIn(duration: 400.ms, delay: (index * 100).ms)
                .slideX(begin: -0.2, end: 0);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text("Error: $e")),
    );
  }
}
