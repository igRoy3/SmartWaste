import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class RecentSessionsList extends StatelessWidget {
  const RecentSessionsList({super.key});

  @override
  Widget build(BuildContext context) {
    final sessions = [
      _SessionData(
        title: 'Daily Conversation',
        date: 'Today, 2:30 PM',
        score: 85,
        duration: '5 min',
      ),
      _SessionData(
        title: 'Restaurant Dialogue',
        date: 'Yesterday, 4:15 PM',
        score: 92,
        duration: '8 min',
      ),
      _SessionData(
        title: 'Travel Phrases',
        date: '2 days ago',
        score: 78,
        duration: '6 min',
      ),
    ];

    return Column(
      children: sessions.map((session) => _SessionCard(data: session)).toList(),
    );
  }
}

class _SessionData {
  final String title;
  final String date;
  final int score;
  final String duration;

  _SessionData({
    required this.title,
    required this.date,
    required this.score,
    required this.duration,
  });
}

class _SessionCard extends StatelessWidget {
  final _SessionData data;

  const _SessionCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Score Circle
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.getScoreColor(data.score).withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${data.score}',
                style: TextStyle(
                  color: AppColors.getScoreColor(data.score),
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          
          // Session Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  data.date,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          
          // Duration
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              data.duration,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
