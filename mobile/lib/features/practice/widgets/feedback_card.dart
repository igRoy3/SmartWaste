import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../screens/practice_screen.dart';

class FeedbackCard extends StatelessWidget {
  final PracticeFeedback feedback;

  const FeedbackCard({super.key, required this.feedback});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Score Card
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.stars_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Great Job!',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${feedback.score}',
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                feedback.feedback,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white.withOpacity(0.9),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 20),
        
        // Transcription Card
        _FeedbackSection(
          icon: Icons.mic_rounded,
          title: 'What you said',
          color: AppColors.secondary,
          child: Text(
            feedback.transcription,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Corrected Text Card
        _FeedbackSection(
          icon: Icons.auto_fix_high_rounded,
          title: 'Improved version',
          color: AppColors.accentGreen,
          child: Text(
            feedback.correctedText,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppColors.accentGreen,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Pronunciation Tips
        if (feedback.pronunciationTips.isNotEmpty)
          _FeedbackSection(
            icon: Icons.record_voice_over_rounded,
            title: 'Pronunciation Tips',
            color: AppColors.primary,
            child: Column(
              children: feedback.pronunciationTips
                  .map((tip) => _TipItem(text: tip))
                  .toList(),
            ),
          ),
        
        const SizedBox(height: 16),
        
        // Grammar Notes
        if (feedback.grammarNotes.isNotEmpty)
          _FeedbackSection(
            icon: Icons.spellcheck_rounded,
            title: 'Grammar Notes',
            color: AppColors.accent,
            child: Column(
              children: feedback.grammarNotes
                  .map((note) => _TipItem(text: note))
                  .toList(),
            ),
          ),
      ],
    );
  }
}

class _FeedbackSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final Widget child;

  const _FeedbackSection({
    required this.icon,
    required this.title,
    required this.color,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _TipItem extends StatelessWidget {
  final String text;

  const _TipItem({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6),
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
