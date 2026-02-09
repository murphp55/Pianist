import 'dart:async';

import 'package:flutter/services.dart';

import 'app_logger.dart';
import 'practice_evaluator.dart';

class MidiDevice {
  const MidiDevice({required this.id, required this.name});

  final String id;
  final String name;
}

abstract class MidiService {
  Stream<NoteOnEvent> get noteStream;

  Future<List<MidiDevice>> listDevices();

  Future<bool> connect(String deviceId);

  Future<void> disconnect();

  void simulateNote(int midiNote);
}

class PlatformMidiService implements MidiService {
  static const MethodChannel _methodChannel = MethodChannel('pianist/midi');
  static const EventChannel _eventChannel = EventChannel('pianist/midi_events');

  final StreamController<NoteOnEvent> _controller =
      StreamController<NoteOnEvent>.broadcast();
  StreamSubscription<dynamic>? _noteSubscription;
  bool _isListening = false;

  @override
  Stream<NoteOnEvent> get noteStream => _controller.stream;

  @override
  Future<List<MidiDevice>> listDevices() async {
    try {
      final result = await _methodChannel.invokeMethod<List<dynamic>>('list');
      if (result == null) {
        AppLogger.warning('MIDI list returned null');
        return [];
      }
      final devices = result
          .map((entry) => entry as Map<dynamic, dynamic>)
          .map((entry) => MidiDevice(
                id: entry['id']?.toString() ?? '',
                name: entry['name']?.toString() ?? 'Unknown',
              ))
          .where((device) => device.id.isNotEmpty)
          .toList();
      AppLogger.info('Found ${devices.length} MIDI devices');
      return devices;
    } on MissingPluginException {
      AppLogger.warning('MIDI plugin not available, using mock devices');
      return [];
    } on PlatformException catch (e, stack) {
      AppLogger.error('Platform error listing MIDI devices', e, stack);
      return [];
    } catch (e, stack) {
      AppLogger.error('Unexpected error listing MIDI devices', e, stack);
      return [];
    }
  }

  @override
  Future<bool> connect(String deviceId) async {
    try {
      AppLogger.info('Attempting to connect to MIDI device: $deviceId');
      final result =
          await _methodChannel.invokeMethod<bool>('connect', deviceId);
      if (result == true) {
        _ensureListening();
        AppLogger.info('Successfully connected to MIDI device');
      } else {
        AppLogger.warning('MIDI connection returned false');
      }
      return result ?? false;
    } on MissingPluginException {
      AppLogger.warning('MIDI plugin not available');
      return false;
    } on PlatformException catch (e, stack) {
      AppLogger.error('Platform error connecting to MIDI device', e, stack);
      return false;
    } catch (e, stack) {
      AppLogger.error('Unexpected error connecting to MIDI device', e, stack);
      return false;
    }
  }

  @override
  Future<void> disconnect() async {
    try {
      await _methodChannel.invokeMethod<void>('disconnect');
    } on MissingPluginException {
      // ignore
    }
  }

  @override
  void simulateNote(int midiNote) {
    // No-op for platform implementation.
  }

  void _handleEvent(dynamic event) {
    if (event is Map) {
      final midiNote = event['midiNote'] as int?;
      final velocity = event['velocity'] as int? ?? 0;
      if (midiNote != null) {
        _controller.add(NoteOnEvent(
          midiNote: midiNote,
          velocity: velocity,
          timestamp: DateTime.now(),
        ));
      }
    }
  }

  void dispose() {
    _noteSubscription?.cancel();
    _controller.close();
  }

  void _ensureListening() {
    if (_isListening) return;
    _isListening = true;
    try {
      _noteSubscription = _eventChannel
          .receiveBroadcastStream()
          .listen(_handleEvent, onError: (error) {
        AppLogger.error('MIDI event stream error', error);
      });
    } on MissingPluginException {
      AppLogger.warning('MIDI event channel not available');
      _isListening = false;
    } catch (e, stack) {
      AppLogger.error('Failed to start listening to MIDI events', e, stack);
      _isListening = false;
    }
  }
}

class MockMidiService implements MidiService {
  final StreamController<NoteOnEvent> _controller =
      StreamController<NoteOnEvent>.broadcast();

  @override
  Stream<NoteOnEvent> get noteStream => _controller.stream;

  @override
  Future<List<MidiDevice>> listDevices() async {
    return const [
      MidiDevice(id: 'mock-1', name: 'Mock MIDI Keyboard'),
      MidiDevice(id: 'mock-2', name: 'Bluetooth Piano (Mock)'),
    ];
  }

  @override
  Future<bool> connect(String deviceId) async => true;

  @override
  Future<void> disconnect() async {}

  @override
  void simulateNote(int midiNote) {
    _controller.add(NoteOnEvent(
      midiNote: midiNote,
      velocity: 96,
      timestamp: DateTime.now(),
    ));
  }

  void dispose() {
    _controller.close();
  }
}

class MidiServiceFactory {
  MidiServiceFactory() : _platform = PlatformMidiService();

  final PlatformMidiService _platform;
  MidiService? _fallback;

  MidiService get service => _fallback ?? _platform;

  Future<List<MidiDevice>> listDevices() async {
    final devices = await _platform.listDevices();
    if (devices.isNotEmpty) return devices;
    _fallback ??= MockMidiService();
    return _fallback!.listDevices();
  }

  Future<bool> connect(String deviceId) async {
    final success = await _platform.connect(deviceId);
    if (success) return true;
    _fallback ??= MockMidiService();
    return _fallback!.connect(deviceId);
  }

  Future<void> disconnect() async {
    await _platform.disconnect();
    await _fallback?.disconnect();
  }

  void dispose() {
    _platform.dispose();
    if (_fallback is MockMidiService) {
      (_fallback as MockMidiService).dispose();
    }
  }
}
