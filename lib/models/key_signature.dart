/// Represents a musical key signature
class KeySignature {
  const KeySignature({
    required this.name,
    required this.tonicMidi,
    required this.scalePattern,
    required this.rightHandFingering,
    required this.leftHandFingering,
  });

  final String name;
  final int tonicMidi; // MIDI note number of the tonic (C4 = 60)
  final List<int> scalePattern; // Semitone intervals from tonic
  final List<int> rightHandFingering; // Fingering for 2 octaves ascending
  final List<int> leftHandFingering; // Fingering for 2 octaves descending

  /// All available major key signatures
  static const List<KeySignature> allMajorKeys = [
    cMajor,
    gMajor,
    dMajor,
    aMajor,
    eMajor,
    bMajor,
    fSharpMajor,
    dFlatMajor,
    aFlatMajor,
    eFlatMajor,
    bFlatMajor,
    fMajor,
  ];

  // Major scale pattern (whole-whole-half-whole-whole-whole-half)
  static const List<int> majorScalePattern = [0, 2, 4, 5, 7, 9, 11, 12];

  // C Major
  static const cMajor = KeySignature(
    name: 'C Major',
    tonicMidi: 60, // C4
    scalePattern: majorScalePattern,
    rightHandFingering: [1, 2, 3, 1, 2, 3, 4, 5, 1, 2, 3, 1, 2, 3, 4, 5],
    leftHandFingering: [5, 4, 3, 2, 1, 3, 2, 1, 5, 4, 3, 2, 1, 3, 2, 1],
  );

  // G Major
  static const gMajor = KeySignature(
    name: 'G Major',
    tonicMidi: 67, // G4
    scalePattern: majorScalePattern,
    rightHandFingering: [1, 2, 3, 1, 2, 3, 4, 5, 1, 2, 3, 1, 2, 3, 4, 5],
    leftHandFingering: [5, 4, 3, 2, 1, 3, 2, 1, 5, 4, 3, 2, 1, 3, 2, 1],
  );

  // D Major
  static const dMajor = KeySignature(
    name: 'D Major',
    tonicMidi: 62, // D4
    scalePattern: majorScalePattern,
    rightHandFingering: [1, 2, 3, 1, 2, 3, 4, 5, 1, 2, 3, 1, 2, 3, 4, 5],
    leftHandFingering: [5, 4, 3, 2, 1, 3, 2, 1, 5, 4, 3, 2, 1, 3, 2, 1],
  );

  // A Major
  static const aMajor = KeySignature(
    name: 'A Major',
    tonicMidi: 69, // A4
    scalePattern: majorScalePattern,
    rightHandFingering: [1, 2, 3, 1, 2, 3, 4, 5, 1, 2, 3, 1, 2, 3, 4, 5],
    leftHandFingering: [5, 4, 3, 2, 1, 3, 2, 1, 5, 4, 3, 2, 1, 3, 2, 1],
  );

  // E Major
  static const eMajor = KeySignature(
    name: 'E Major',
    tonicMidi: 64, // E4
    scalePattern: majorScalePattern,
    rightHandFingering: [1, 2, 3, 1, 2, 3, 4, 5, 1, 2, 3, 1, 2, 3, 4, 5],
    leftHandFingering: [5, 4, 3, 2, 1, 3, 2, 1, 5, 4, 3, 2, 1, 3, 2, 1],
  );

  // B Major
  static const bMajor = KeySignature(
    name: 'B Major',
    tonicMidi: 71, // B4
    scalePattern: majorScalePattern,
    rightHandFingering: [1, 2, 3, 1, 2, 3, 4, 5, 1, 2, 3, 1, 2, 3, 4, 5],
    leftHandFingering: [4, 3, 2, 1, 4, 3, 2, 1, 4, 3, 2, 1, 3, 2, 1, 2],
  );

  // F# Major
  static const fSharpMajor = KeySignature(
    name: 'F# Major',
    tonicMidi: 66, // F#4
    scalePattern: majorScalePattern,
    rightHandFingering: [2, 3, 4, 1, 2, 3, 1, 2, 3, 4, 1, 2, 3, 1, 2, 3],
    leftHandFingering: [4, 3, 2, 1, 3, 2, 1, 2, 3, 2, 1, 4, 3, 2, 1, 2],
  );

  // Db Major
  static const dFlatMajor = KeySignature(
    name: 'Db Major',
    tonicMidi: 61, // Db4
    scalePattern: majorScalePattern,
    rightHandFingering: [2, 3, 1, 2, 3, 4, 1, 2, 3, 1, 2, 3, 4, 1, 2, 3],
    leftHandFingering: [3, 2, 1, 4, 3, 2, 1, 2, 3, 2, 1, 4, 3, 2, 1, 2],
  );

  // Ab Major
  static const aFlatMajor = KeySignature(
    name: 'Ab Major',
    tonicMidi: 68, // Ab4
    scalePattern: majorScalePattern,
    rightHandFingering: [2, 3, 1, 2, 3, 4, 1, 2, 3, 1, 2, 3, 4, 1, 2, 3],
    leftHandFingering: [3, 2, 1, 4, 3, 2, 1, 2, 3, 2, 1, 4, 3, 2, 1, 2],
  );

  // Eb Major
  static const eFlatMajor = KeySignature(
    name: 'Eb Major',
    tonicMidi: 63, // Eb4
    scalePattern: majorScalePattern,
    rightHandFingering: [3, 1, 2, 3, 4, 1, 2, 3, 1, 2, 3, 4, 1, 2, 3, 4],
    leftHandFingering: [3, 2, 1, 4, 3, 2, 1, 2, 1, 4, 3, 2, 1, 3, 2, 1],
  );

  // Bb Major
  static const bFlatMajor = KeySignature(
    name: 'Bb Major',
    tonicMidi: 70, // Bb4
    scalePattern: majorScalePattern,
    rightHandFingering: [4, 1, 2, 3, 1, 2, 3, 4, 1, 2, 3, 1, 2, 3, 4, 5],
    leftHandFingering: [3, 2, 1, 4, 3, 2, 1, 2, 1, 3, 2, 1, 4, 3, 2, 1],
  );

  // F Major
  static const fMajor = KeySignature(
    name: 'F Major',
    tonicMidi: 65, // F4
    scalePattern: majorScalePattern,
    rightHandFingering: [1, 2, 3, 4, 1, 2, 3, 4, 1, 2, 3, 4, 1, 2, 3, 4],
    leftHandFingering: [5, 4, 3, 2, 1, 3, 2, 1, 5, 4, 3, 2, 1, 3, 2, 1],
  );

  /// Generate MIDI notes for the scale based on this key signature
  List<int> getMidiNotes() {
    final notes = <int>[];
    for (int octave = 0; octave < 2; octave++) {
      for (final interval in scalePattern) {
        notes.add(tonicMidi + (octave * 12) + interval);
      }
    }
    return notes;
  }

  /// Generate arpeggio pattern (1-3-5-8) for this key
  List<int> getArpeggioMidiNotes() {
    final notes = <int>[];
    const arpeggioPattern = [0, 4, 7, 12]; // Root, 3rd, 5th, octave
    for (int octave = 0; octave < 2; octave++) {
      for (final interval in arpeggioPattern) {
        notes.add(tonicMidi + (octave * 12) + interval);
      }
    }
    return notes;
  }

  /// Get arpeggio fingering (simplified - typically 1-2-3-5 pattern for most keys)
  List<int> getArpeggioRightHandFingering() {
    // Standard arpeggio fingering for right hand
    return [1, 2, 3, 5, 1, 2, 3, 5];
  }

  List<int> getArpeggioLeftHandFingering() {
    // Standard arpeggio fingering for left hand (descending)
    return [5, 3, 2, 1, 5, 3, 2, 1];
  }
}
