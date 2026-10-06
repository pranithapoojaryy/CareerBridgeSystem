import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'mock_interview_providers.dart';
import '../../domain/mock_interview_models.dart';
import 'mock_submissions_screen.dart';
import 'create_mock_screen.dart';
import 'package:intl/intl.dart';

class ManageMocksScreen extends ConsumerStatefulWidget {
  const ManageMocksScreen({super.key});

  @override
  ConsumerState<ManageMocksScreen> createState() => _ManageMocksScreenState();
}

class _ManageMocksScreenState extends ConsumerState<ManageMocksScreen> {
  @override
  Widget build(BuildContext context) {
    final mocksAsync = ref.watch(mockDefinitionsProvider);

    return Stack(
      children: [
        mocksAsync.when(
          data: (mocks) {
            if (mocks.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.assignment_outlined,
                      size: 64,
                      color: Colors.grey.withValues(alpha: 0.2),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "No Mock Interviews Created",
                      style: GoogleFonts.outfit(color: Colors.grey),
                    ),
                  ],
                ),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(24),
              itemCount: mocks.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (ctx, index) {
                final mock = mocks[index];
                return _MockCard(mock: mock, ref: ref);
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, s) => Center(child: Text("Error: $e")),
        ),
        Positioned(
          bottom: 24,
          right: 24,
          child: FloatingActionButton.extended(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CreateMockScreen()),
              ).then((_) => ref.refresh(mockDefinitionsProvider));
            },
            label: Text(
              'Create Mock',
              style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
            ),
            icon: const Icon(Icons.add_rounded),
            backgroundColor: const Color(0xFF1A1F36),
            foregroundColor: Colors.white,
            elevation: 4,
          ),
        ),
      ],
    );
  }
}

class _MockCard extends StatelessWidget {
  final MockDefinition mock;
  final WidgetRef ref;

  const _MockCard({required this.mock, required this.ref});

  void _showSubmissionsModal(
    BuildContext context,
    WidgetRef ref,
    MockDefinition mock,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        height: MediaQuery.of(context).size.height * 0.95,
        decoration: const BoxDecoration(
          color: Color(0xFFF9FAFC),
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              decoration: const BoxDecoration(
                color: Color(0xFF1A1F36),
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mock Submissions',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFAFB5CF),
                          letterSpacing: 1.1,
                        ),
                      ),
                      Text(
                        mock.title,
                        style: GoogleFonts.outfit(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: MockSubmissionsScreen(
                mockId: mock.id,
                mockTitle: mock.title,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(20),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF0F2F5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.assignment_rounded, color: Color(0xFF5A6ACF)),
        ),
        title: Text(
          mock.title,
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: const Color(0xFF1A1F36),
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (mock.description != null)
              Text(
                mock.description!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.outfit(color: const Color(0xFF697386)),
              ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.timer_outlined,
                  size: 14,
                  color: Color(0xFF697386),
                ),
                const SizedBox(width: 4),
                Text(
                  "${mock.timeLimitMinutes} mins",
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: const Color(0xFF697386),
                  ),
                ),
                const SizedBox(width: 16),
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 14,
                  color: Color(0xFF697386),
                ),
                const SizedBox(width: 4),
                Text(
                  DateFormat('MMM d, yyyy').format(mock.createdAt.toLocal()),
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: const Color(0xFF697386),
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(
                Icons.visibility_outlined,
                color: Color(0xFF5A6ACF),
              ),
              tooltip: "View Submissions",
              onPressed: () => _showSubmissionsModal(context, ref, mock),
            ),
            IconButton(
              icon: const Icon(
                Icons.delete_outline_rounded,
                color: Color(0xFFF44336),
              ),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    title: Text(
                      "Delete Mock Interview?",
                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                    ),
                    content: Text(
                      "This action cannot be undone. All student submissions and analytics associated with this mock will be permanently removed.",
                      style: GoogleFonts.outfit(),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: Text(
                          "Cancel",
                          style: GoogleFonts.outfit(
                            color: const Color(0xFF697386),
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: Text(
                          "Delete",
                          style: GoogleFonts.outfit(
                            color: const Color(0xFFF44336),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  await ref.read(mockRepositoryProvider).deleteMock(mock.id);
                  ref.refresh(mockDefinitionsProvider);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
