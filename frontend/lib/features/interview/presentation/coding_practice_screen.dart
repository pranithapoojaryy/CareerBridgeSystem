import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../domain/interview_models.dart';
import 'interview_providers.dart';

class CodingPracticeScreen extends ConsumerStatefulWidget {
  final InterviewQuestion question;

  const CodingPracticeScreen({super.key, required this.question});

  @override
  ConsumerState<CodingPracticeScreen> createState() =>
      _CodingPracticeScreenState();
}

class _CodingPracticeScreenState extends ConsumerState<CodingPracticeScreen> {
  final TextEditingController _codeController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _submitCode() async {
    if (_codeController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please write some code first!')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // For coding, we don't have a video.
      // We are hacking the repo method or we should add a specific one.
      // Since repo.submitInterview expects video args, let's create a specialized
      // submitCodeAttempt in the repo or modify submitInterview to be more generic.
      // For speed, let's check repo implementation.
      // The current submitInterview requires videoPath.
      // Let's assume we update repo later or add a specific method.
      // I will add `submitCodingInterview` to repo next.

      await ref
          .read(interviewRepositoryProvider)
          .submitCodingInterview(
            questionId: widget.question.id,
            codeAnswer: _codeController.text,
            categoryName: "Technical", // Could fetch from question
          );

      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text("Submitted!"),
            content: const Text("Your code has been submitted for review."),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx); // Close dialog
                  Navigator.pop(ctx); // Close screen
                },
                child: const Text("OK"),
              ),
            ],
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
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Coding Round')),
      body: Column(
        children: [
          // Question Header
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.blue.shade50,
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Problem Statement",
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.question.questionText,
                  style: GoogleFonts.poppins(fontSize: 16),
                ),
              ],
            ),
          ),

          // Code Editor Area
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _codeController,
                maxLines: null,
                expands: true,
                style: GoogleFonts.firaCode(fontSize: 14),
                decoration: InputDecoration(
                  hintText: "// Write your solution here...",
                  border: const OutlineInputBorder(),
                  fillColor: Colors.grey.shade50,
                  filled: true,
                ),
              ),
            ),
          ),

          // Submit Button
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _submitCode,
                icon: const Icon(Icons.code),
                label: _isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Submit Solution"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
