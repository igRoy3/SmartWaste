import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/app_colors.dart';

class RecordingButton extends StatelessWidget {
  final bool isRecording;
  final VoidCallback onTap;

  const RecordingButton({
    super.key,
    required this.isRecording,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer ring animation
          if (isRecording)
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.accent.withOpacity(0.3),
                  width: 3,
                ),
              ),
            )
                .animate(onPlay: (controller) => controller.repeat())
                .scale(
                  begin: const Offset(1, 1),
                  end: const Offset(1.3, 1.3),
                  duration: 1000.ms,
                )
                .fadeOut(begin: 0.5, duration: 1000.ms),
          
          // Second ring
          if (isRecording)
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.accent.withOpacity(0.3),
                  width: 3,
                ),
              ),
            )
                .animate(onPlay: (controller) => controller.repeat())
                .scale(
                  begin: const Offset(1, 1),
                  end: const Offset(1.5, 1.5),
                  delay: 500.ms,
                  duration: 1000.ms,
                )
                .fadeOut(begin: 0.5, delay: 500.ms, duration: 1000.ms),
          
          // Main button
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: isRecording ? 100 : 88,
            height: isRecording ? 100 : 88,
            decoration: BoxDecoration(
              gradient: isRecording
                  ? AppColors.warmGradient
                  : AppColors.primaryGradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: (isRecording ? AppColors.accent : AppColors.primary)
                      .withOpacity(0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(
              isRecording ? Icons.stop_rounded : Icons.mic_rounded,
              color: Colors.white,
              size: isRecording ? 44 : 40,
            ),
          ),
        ],
      ),
    );
  }
}
