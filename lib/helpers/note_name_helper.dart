class NoteNameHelper {
  static const _names = [
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

  static String toName(int midiNote) {
    final note = _names[midiNote % 12];
    final octave = (midiNote ~/ 12) - 1;
    return '$note$octave';
  }
}
