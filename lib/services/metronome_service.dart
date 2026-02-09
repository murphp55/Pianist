import 'dart:async';

import 'package:just_audio/just_audio.dart';

import 'app_logger.dart';

class MetronomeService {
  final AudioPlayer _player = AudioPlayer();
  Timer? _timer;
  bool _isRunning = false;
  int _currentBeat = 0;

  // Stream for visual indicator synchronization
  final StreamController<int> _beatController =
      StreamController<int>.broadcast();
  Stream<int> get beatStream => _beatController.stream;

  Future<void> initialize() async {
    try {
      // Load click sound from assets
      await _player.setAsset('assets/sounds/metronome_click.mp3');
      await _player.setVolume(0.7);
      AppLogger.info('Metronome initialized successfully');
    } catch (e, stack) {
      AppLogger.error('Failed to initialize metronome', e, stack);
      // Continue without audio - visual indicator will still work
    }
  }

  Future<void> start(int bpm) async {
    if (_isRunning) return;
    _isRunning = true;
    _currentBeat = 0;

    final intervalMs = (60000 / bpm).round();
    AppLogger.debug('Starting metronome at $bpm BPM (${intervalMs}ms interval)');

    // Play first beat immediately
    _playClick();
    _beatController.add(_currentBeat);

    _timer = Timer.periodic(Duration(milliseconds: intervalMs), (_) {
      _currentBeat = (_currentBeat + 1) % 4; // 4/4 time
      _beatController.add(_currentBeat);
      _playClick();
    });
  }

  Future<void> _playClick() async {
    try {
      await _player.seek(Duration.zero);
      await _player.play();
    } catch (e) {
      // Ignore audio playback errors - visual will still work
      AppLogger.warning('Metronome audio playback failed: $e');
    }
  }

  void stop() {
    if (!_isRunning) return;
    _timer?.cancel();
    _timer = null;
    _isRunning = false;
    _currentBeat = 0;
    AppLogger.debug('Metronome stopped');
  }

  void dispose() {
    stop();
    _player.dispose();
    _beatController.close();
  }
}
