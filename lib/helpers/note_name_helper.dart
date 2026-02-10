import '../models/key_signature.dart';

class NoteNameHelper {
  static const _sharpNames = [
    'C',
    'C#',
    'D',
    'D#',
    'E',
    'F',
    'F#',
    'G',
    'G#',
    'A',
    'A#',
    'B',
  ];
  static const _flatNames = [
    'C',
    'Db',
    'D',
    'Eb',
    'E',
    'F',
    'Gb',
    'G',
    'Ab',
    'A',
    'Bb',
    'B',
  ];

  static String toName(
    int midiNote, {
    bool preferFlats = false,
    KeySignature? keySignature,
  }) {
    if (keySignature != null) {
      final semitoneFromTonic =
          (midiNote - keySignature.tonicMidi) % 12;
      final normalized =
          semitoneFromTonic < 0 ? semitoneFromTonic + 12 : semitoneFromTonic;
      final degreeIndex = keySignature.scalePattern.indexOf(normalized);
      if (degreeIndex >= 0 && degreeIndex < keySignature.scaleNoteNames.length) {
        final note = keySignature.scaleNoteNames[degreeIndex];
        final octave = (midiNote ~/ 12) - 1;
        return '$note$octave';
      }
      preferFlats = keySignature.preferFlats;
    }

    final names = preferFlats ? _flatNames : _sharpNames;
    final note = names[midiNote % 12];
    final octave = (midiNote ~/ 12) - 1;
    return '$note$octave';
  }
}
