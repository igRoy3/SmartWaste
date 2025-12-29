import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:audioplayers/audioplayers.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/services/audio_service.dart';
import '../widgets/recording_button.dart';
import '../widgets/waveform_visualizer.dart';
import '../widgets/feedback_card.dart';

class PracticeScreen extends StatefulWidget {
  const PracticeScreen({super.key});

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen> {
  PracticeState _state = PracticeState.idle;
  int _recordingSeconds = 0;
  Timer? _timer;
  final AudioService _audioService = AudioService();
  File? _recordedFile;
  bool _isPlaying = false;

  // Mock feedback data (will be replaced with API response later)
  final _feedback = PracticeFeedback(
    transcription:
        "Hello, my name is John and I would like to order a coffee please.",
    correctedText:
        "Hello, my name is John, and I would like to order a coffee, please.",
    score: 85,
    feedback:
        "Great job! Your pronunciation is clear and natural. Just remember to add commas for better pacing.",
    pronunciationTips: [
      "The 'th' sound in 'the' could be slightly more emphasized",
      "Good stress on 'coffee' - keep it up!",
    ],
    grammarNotes: [
      "Add a comma before 'and' when joining independent clauses",
      "Add a comma before 'please' for politeness emphasis",
    ],
  );

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final hasPermission = await _audioService.requestPermission();
    if (!hasPermission && mounted) {
      _showErrorSnackBar(
        'Microphone permission is required for speech practice',
      );
    }
  }

  void _startRecording() async {
    try {
      await _audioService.startRecording();

      setState(() {
        _state = PracticeState.recording;
        _recordingSeconds = 0;
      });

      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          _recordingSeconds++;
        });

        // Auto-stop after 60 seconds
        if (_recordingSeconds >= 60) {
          _stopRecording();
        }
      });
    } catch (e) {
      _showErrorSnackBar('Failed to start recording: $e');
    }
  }

  void _stopRecording() async {
    _timer?.cancel();

    try {
      final file = await _audioService.stopRecording();
      _recordedFile = file;

      setState(() {
        _state = PracticeState.processing;
      });

      // TODO: Send to backend API for speech analysis
      // For now, simulate processing
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _state = PracticeState.feedback;
          });
        }
      });
    } catch (e) {
      _showErrorSnackBar('Failed to stop recording: $e');
      _reset();
    }
  }

  void _cancelRecording() async {
    _timer?.cancel();
    await _audioService.cancelRecording();
    _reset();
  }

  void _playRecording() async {
    if (_recordedFile == null) return;

    try {
      setState(() => _isPlaying = true);
      await _audioService.playRecording(_recordedFile!.path);

      // Listen for playback completion
      _audioService.playerStateStream.listen((state) {
        if (state == PlayerState.completed || state == PlayerState.stopped) {
          if (mounted) {
            setState(() => _isPlaying = false);
          }
        }
      });
    } catch (e) {
      setState(() => _isPlaying = false);
      _showErrorSnackBar('Failed to play recording: $e');
    }
  }

  void _stopPlayback() async {
    await _audioService.stopPlayback();
    setState(() => _isPlaying = false);
  }

  void _reset() {
    _timer?.cancel();
    setState(() {
      _state = PracticeState.idle;
      _recordingSeconds = 0;
      _recordedFile = null;
      _isPlaying = false;
    });
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade400,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  String _formatTime(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _timer?.cancel();
    _audioService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('Practice'),
        actions: [
          if (_state == PracticeState.feedback)
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: _reset,
            ),
        ],
      ),
      body: SafeArea(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    switch (_state) {
      case PracticeState.idle:
        return _buildIdleState();
      case PracticeState.recording:
        return _buildRecordingState();
      case PracticeState.processing:
        return _buildProcessingState();
      case PracticeState.feedback:
        return _buildFeedbackState();
    }
  }

  Widget _buildIdleState() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Spacer(),

          // Prompt Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Today\'s Prompt',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Icon(
                  Icons.restaurant_menu_rounded,
                  size: 48,
                  color: AppColors.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  'Order a coffee at a café',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Try saying: "Hello, I would like to order a large latte with oat milk, please."',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1),

          const Spacer(),

          // Instructions
          Text(
            'Tap the microphone to start',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
          ).animate().fadeIn(delay: 300.ms, duration: 500.ms),

          const SizedBox(height: 32),

          // Recording Button
          RecordingButton(isRecording: false, onTap: _startRecording)
              .animate()
              .fadeIn(delay: 500.ms, duration: 500.ms)
              .scale(begin: const Offset(0.8, 0.8)),

          const SizedBox(height: 48),
        ],
      ),
    );
  }

  Widget _buildRecordingState() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Spacer(),

          // Timer
          Text(
                _formatTime(_recordingSeconds),
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.accent,
                ),
              )
              .animate(onPlay: (controller) => controller.repeat())
              .fadeIn()
              .then()
              .shimmer(
                duration: 1500.ms,
                color: AppColors.accent.withOpacity(0.3),
              ),

          const SizedBox(height: 16),

          Text(
            'Recording...',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(color: AppColors.textSecondary),
          ),

          const SizedBox(height: 48),

          // Waveform
          const WaveformVisualizer(),

          const Spacer(),

          // Stop instruction
          Text(
            'Tap to stop recording',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
          ),

          const SizedBox(height: 32),

          // Recording Button
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Cancel Button
              IconButton(
                onPressed: _cancelRecording,
                icon: const Icon(Icons.close_rounded),
                iconSize: 32,
                style: IconButton.styleFrom(
                  backgroundColor: Colors.grey.shade200,
                  padding: const EdgeInsets.all(16),
                ),
              ),
              const SizedBox(width: 32),
              // Stop Recording Button
              RecordingButton(isRecording: true, onTap: _stopRecording),
              const SizedBox(width: 32),
              // Placeholder for symmetry
              const SizedBox(width: 64),
            ],
          ),

          const SizedBox(height: 48),
        ],
      ),
    );
  }

  Widget _buildProcessingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: AppColors.primary,
                  ),
                ),
              )
              .animate(onPlay: (controller) => controller.repeat())
              .scale(
                begin: const Offset(1, 1),
                end: const Offset(1.1, 1.1),
                duration: 800.ms,
              )
              .then()
              .scale(
                begin: const Offset(1.1, 1.1),
                end: const Offset(1, 1),
                duration: 800.ms,
              ),

          const SizedBox(height: 32),

          Text(
            'Analyzing your speech...',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(color: AppColors.textSecondary),
          ),

          const SizedBox(height: 8),

          Text(
            'This may take a moment',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textHint),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Playback Controls
          if (_recordedFile != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: _isPlaying ? _stopPlayback : _playRecording,
                    icon: Icon(
                      _isPlaying
                          ? Icons.stop_rounded
                          : Icons.play_arrow_rounded,
                      color: AppColors.primary,
                    ),
                    iconSize: 32,
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.primary.withOpacity(0.1),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your Recording',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          _isPlaying ? 'Playing...' : 'Tap to listen',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    _formatTime(_recordingSeconds),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 500.ms),

          const SizedBox(height: 16),

          FeedbackCard(
            feedback: _feedback,
          ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1),

          const SizedBox(height: 24),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _reset,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Try Again'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('Done'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ).animate().fadeIn(delay: 300.ms, duration: 500.ms),
        ],
      ),
    );
  }
}

enum PracticeState { idle, recording, processing, feedback }

class PracticeFeedback {
  final String transcription;
  final String correctedText;
  final int score;
  final String feedback;
  final List<String> pronunciationTips;
  final List<String> grammarNotes;

  PracticeFeedback({
    required this.transcription,
    required this.correctedText,
    required this.score,
    required this.feedback,
    required this.pronunciationTips,
    required this.grammarNotes,
  });
}
