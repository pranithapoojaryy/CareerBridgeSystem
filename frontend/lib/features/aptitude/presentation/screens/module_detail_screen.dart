import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/aptitude_module.dart';
import '../controllers/aptitude_controller.dart';
import '../../domain/test_attempt.dart';
import 'test_taking_screen.dart';

class ModuleDetailScreen extends ConsumerStatefulWidget {
  final AptitudeModule module;

  const ModuleDetailScreen({super.key, required this.module});

  @override
  ConsumerState<ModuleDetailScreen> createState() => _ModuleDetailScreenState();
}

class _ModuleDetailScreenState extends ConsumerState<ModuleDetailScreen> {
  String _selectedDifficulty = 'medium';
  bool _isStarting = false;

  @override
  Widget build(BuildContext context) {
    Color moduleColor;
    try {
      moduleColor = widget.module.colorCode != null
          ? Color(int.parse(widget.module.colorCode!.replaceAll('#', '0xFF')))
          : Colors.blueAccent;
    } catch (_) {
      moduleColor = Colors.blueAccent;
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.grey[50]!,
              moduleColor.withValues(alpha: 0.05),
              Colors.purple.withValues(alpha: 0.05),
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 100, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header section
              Center(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: moduleColor.withValues(alpha: 0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Text(
                        widget.module.icon,
                        style: const TextStyle(fontSize: 64),
                      ),
                    ).animate().scale(
                      curve: Curves.easeOutBack,
                      duration: 600.ms,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      widget.module.name,
                      style: GoogleFonts.outfit(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textColor,
                      ),
                    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        widget.module.description,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          color: Colors.grey[600],
                          height: 1.4,
                        ),
                      ),
                    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1),
                  ],
                ),
              ),

              const SizedBox(height: 48),

              // Start Practice Card
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: moduleColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.bolt_rounded,
                                color: moduleColor,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Text(
                              'Practice Configuration',
                              style: GoogleFonts.outfit(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        Text(
                          'SELECT DIFFICULTY',
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[500],
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: widget.module.difficultyLevels.map((
                            difficulty,
                          ) {
                            final isSelected =
                                _selectedDifficulty == difficulty;
                            return InkWell(
                              onTap: () => setState(
                                () => _selectedDifficulty = difficulty,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              child: AnimatedContainer(
                                duration: 200.ms,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 16,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? moduleColor
                                      : Colors.grey[50],
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isSelected
                                        ? moduleColor
                                        : Colors.grey[200]!,
                                    width: 2,
                                  ),
                                ),
                                child: Text(
                                  difficulty.toUpperCase(),
                                  style: GoogleFonts.outfit(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.grey[600],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 40),
                        SizedBox(
                          width: double.infinity,
                          height: 60,
                          child: ElevatedButton(
                            onPressed: _isStarting ? null : _startTest,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: moduleColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                              elevation: 0,
                            ),
                            child: _isStarting
                                ? const CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Text(
                                        'Start Arena Battle',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      const Icon(Icons.arrow_forward_rounded),
                                    ],
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _startTest() async {
    setState(() => _isStarting = true);
    try {
      final practiceTests = await ref
          .read(aptitudeRepositoryProvider)
          .getPracticeTests(widget.module.id);

      if (practiceTests.isEmpty) {
        throw Exception(
          'No practice test configuration found for this module.',
        );
      }

      final testToStart = practiceTests.first;

      final result = await ref
          .read(aptitudeRepositoryProvider)
          .startTest(testId: testToStart.id, testType: 'practice');

      if (mounted) {
        final attempt = result['attempt'] as TestAttempt;
        final settings = result['settings'] as Map<String, dynamic>;

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                TestTakingScreen(attempt: attempt, settings: settings),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isStarting = false);
      }
    }
  }
}
