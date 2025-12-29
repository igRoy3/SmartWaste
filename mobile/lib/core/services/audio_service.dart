import 'dart:async';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';

class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  
  AudioService._internal();

  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();
  
  String? _recordingPath;
  bool _isRecording = false;
  StreamSubscription? _amplitudeSubscription;

  bool get isRecording => _isRecording;
  String? get lastRecordingPath => _recordingPath;

  // Amplitude stream for visualizations
  Stream<double>? _amplitudeStream;
  Stream<double>? get amplitudeStream => _amplitudeStream;

  Future<bool> requestPermission() async {
    return await _recorder.hasPermission();
  }

  Future<void> startRecording() async {
    if (_isRecording) return;

    final hasPermission = await requestPermission();
    if (!hasPermission) {
      throw Exception('Microphone permission not granted');
    }

    // Get temp directory for recording
    final directory = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    _recordingPath = '${directory.path}/recording_$timestamp.m4a';

    // Start recording
    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        sampleRate: 44100,
      ),
      path: _recordingPath!,
    );

    _isRecording = true;
    
    // Create amplitude stream for visualization
    _amplitudeStream = _recorder
        .onAmplitudeChanged(const Duration(milliseconds: 100))
        .map((amp) => (amp.current + 50) / 50); // Normalize to 0-1 range
  }

  Future<File?> stopRecording() async {
    if (!_isRecording) return null;

    await _recorder.stop();
    _isRecording = false;
    _amplitudeStream = null;

    if (_recordingPath != null) {
      return File(_recordingPath!);
    }
    return null;
  }

  Future<void> cancelRecording() async {
    if (!_isRecording) return;

    await _recorder.stop();
    _isRecording = false;
    _amplitudeStream = null;

    // Delete the recording file
    if (_recordingPath != null) {
      final file = File(_recordingPath!);
      if (await file.exists()) {
        await file.delete();
      }
    }
    _recordingPath = null;
  }

  Future<void> playRecording([String? path]) async {
    final filePath = path ?? _recordingPath;
    if (filePath == null) return;

    await _player.play(DeviceFileSource(filePath));
  }

  Future<void> stopPlayback() async {
    await _player.stop();
  }

  Future<void> pausePlayback() async {
    await _player.pause();
  }

  Future<void> resumePlayback() async {
    await _player.resume();
  }

  Stream<PlayerState> get playerStateStream => _player.onPlayerStateChanged;
  Stream<Duration> get positionStream => _player.onPositionChanged;
  Stream<Duration?> get durationStream => _player.onDurationChanged;

  void dispose() {
    _recorder.dispose();
    _player.dispose();
    _amplitudeSubscription?.cancel();
  }
}
