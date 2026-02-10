import '../models/fingered_note.dart';
import '../models/key_signature.dart';
import '../models/practice_plan.dart';
import '../models/practice_task.dart';

class PlanFactory {
  static PracticePlan buildDailyPlan({KeySignature key = KeySignature.cMajor}) {
    final keyName = key.name;
    const repeatCount = 5;
    final rightHandRoot = key.tonicMidi;
    final leftHandRoot = key.tonicMidi - 12; // One octave lower
    final keySlug = keyName.toLowerCase().replaceAll(' ', '-');

    // Get scale notes and fingerings from the key signature
    final scaleNotesRH = key.getMidiNotes();
    final scaleFingeringRH = key.rightHandFingering;
    final scaleNotesLH = key.getMidiNotes().map((n) => n - 12).toList();
    final scaleFingeringLH = key.leftHandFingering;

    // Get arpeggio notes and fingerings
    final arpeggioNotesRH = key.getArpeggioMidiNotes();
    final arpeggioFingeringRH = key.getArpeggioRightHandFingering();
    final arpeggioNotesLH = key.getArpeggioMidiNotes().map((n) => n - 12).toList();
    final arpeggioFingeringLH = key.getArpeggioLeftHandFingering();

    final inversionStepsRight = _triadInversionsTwoOctaves();
    final inversionStepsLeft = _triadInversionsTwoOctaves();

    return PracticePlan(sections: [
      PracticeSection(title: 'Scales', tasks: [
        _buildTaskWithFingering(
          id: 'scale-rh-$keySlug',
          title: '$keyName Scale (Right Hand, 2 Octaves)',
          description:
              'Right hand only, ascending 2 octaves. Repeat $repeatCount times.',
          notes: scaleNotesRH,
          fingering: scaleFingeringRH,
          repeatCount: repeatCount,
          tempoBpm: 88,
        ),
        _buildTaskWithFingering(
          id: 'scale-lh-$keySlug',
          title: '$keyName Scale (Left Hand, 2 Octaves)',
          description:
              'Left hand only, ascending 2 octaves. Repeat $repeatCount times.',
          notes: scaleNotesLH,
          fingering: scaleFingeringLH,
          repeatCount: repeatCount,
          tempoBpm: 84,
        ),
        _buildTaskWithFingering(
          id: 'scale-ht-$keySlug',
          title: '$keyName Scale (Hands Together, 2 Octaves)',
          description:
              'Hands together, ascending 2 octaves. Repeat $repeatCount times.',
          notes: scaleNotesRH,
          fingering: scaleFingeringRH,
          repeatCount: repeatCount,
          tempoBpm: 80,
        ),
      ]),
      PracticeSection(title: 'Arpeggios', tasks: [
        _buildTaskWithFingering(
          id: 'arpeggio-rh-$keySlug',
          title: '$keyName Arpeggio (Right Hand, 2 Octaves)',
          description:
              'Right hand only, ascending 2 octaves. Repeat $repeatCount times.',
          notes: arpeggioNotesRH,
          fingering: arpeggioFingeringRH,
          repeatCount: repeatCount,
          tempoBpm: 80,
        ),
        _buildTaskWithFingering(
          id: 'arpeggio-lh-$keySlug',
          title: '$keyName Arpeggio (Left Hand, 2 Octaves)',
          description:
              'Left hand only, ascending 2 octaves. Repeat $repeatCount times.',
          notes: arpeggioNotesLH,
          fingering: arpeggioFingeringLH,
          repeatCount: repeatCount,
          tempoBpm: 76,
        ),
        _buildTaskWithFingering(
          id: 'arpeggio-ht-$keySlug',
          title: '$keyName Arpeggio (Hands Together, 2 Octaves)',
          description:
              'Hands together, ascending 2 octaves. Repeat $repeatCount times.',
          notes: arpeggioNotesRH,
          fingering: arpeggioFingeringRH,
          repeatCount: repeatCount,
          tempoBpm: 72,
        ),
      ]),
      PracticeSection(title: 'I Chord Inversions', tasks: [
        _buildTask(
          id: 'inversions-rh-$keySlug',
          title: '$keyName I Chord Inversions (Right Hand)',
          description:
              'Root, 1st, 2nd inversion sequentially up the keyboard. Repeat $repeatCount times.',
          rootMidi: rightHandRoot,
          steps: inversionStepsRight,
          repeatCount: repeatCount,
          tempoBpm: 72,
        ),
        _buildTask(
          id: 'inversions-lh-$keySlug',
          title: '$keyName I Chord Inversions (Left Hand)',
          description:
              'Root, 1st, 2nd inversion sequentially up the keyboard. Repeat $repeatCount times.',
          rootMidi: leftHandRoot,
          steps: inversionStepsLeft,
          repeatCount: repeatCount,
          tempoBpm: 68,
        ),
        _buildTask(
          id: 'inversions-ht-$keySlug',
          title: '$keyName I Chord Inversions (Hands Together)',
          description:
              'Root, 1st, 2nd inversion sequentially up the keyboard. Repeat $repeatCount times.',
          rootMidi: rightHandRoot,
          steps: inversionStepsRight,
          repeatCount: repeatCount,
          tempoBpm: 64,
        ),
      ]),
    ]);
  }

  static PracticePlan buildExtrasPlan({KeySignature key = KeySignature.cMajor}) {
    final keyName = key.name;
    final rightHandRoot = key.tonicMidi;
    final keySlug = keyName.toLowerCase().replaceAll(' ', '-');

    // Get scale notes and fingerings from the key signature
    final scaleNotesRH = key.getMidiNotes();
    final scaleFingeringRH = key.rightHandFingering;

    // Get arpeggio notes and fingerings
    final arpeggioNotesRH = key.getArpeggioMidiNotes();
    final arpeggioFingeringRH = key.getArpeggioRightHandFingering();

    final inversionSteps = _triadInversionsTwoOctaves();

    return PracticePlan(sections: [
      PracticeSection(title: 'Technique', tasks: [
        _buildTaskWithFingering(
          id: 'contrary-scale-$keySlug',
          title: '$keyName Scale (Contrary Motion, 2 Octaves)',
          description:
              'Start both thumbs on middle C. Move outward to two octaves, then return inward. Count in 4/4 at 72 BPM. Keep wrists level and match touch between hands.',
          notes: scaleNotesRH,
          fingering: scaleFingeringRH,
          repeatCount: 3,
          tempoBpm: 72,
        ),
        _buildTaskWithFingering(
          id: 'thirds-scale-$keySlug',
          title: '$keyName Scale in Thirds (Hands Together)',
          description:
              'Play parallel thirds up two octaves and back. Use legato and even voicing between upper and lower notes. Aim for 60 BPM, 1 note per beat.',
          notes: scaleNotesRH,
          fingering: scaleFingeringRH,
          repeatCount: 2,
          tempoBpm: 60,
        ),
        _buildTaskWithFingering(
          id: 'sixths-scale-$keySlug',
          title: '$keyName Scale in Sixths (Hands Together)',
          description:
              'Play parallel sixths up two octaves and back. Keep the top voice singing, bottom voice soft. Start at 52 BPM, then increase to 64 BPM.',
          notes: scaleNotesRH,
          fingering: scaleFingeringRH,
          repeatCount: 2,
          tempoBpm: 52,
        ),
        _buildTaskWithFingering(
          id: 'arpeggio-inversions-$keySlug',
          title: '$keyName Arpeggios (Root + Inversions)',
          description:
              'Play root position, 1st inversion, and 2nd inversion arpeggios. Two octaves each, hands separate. Pause 2 beats between inversion changes.',
          notes: arpeggioNotesRH,
          fingering: arpeggioFingeringRH,
          repeatCount: 3,
          tempoBpm: 72,
        ),
        _buildTaskWithFingering(
          id: 'broken-chords-$keySlug',
          title: '$keyName Broken Chords (I–IV–V–I)',
          description:
              'Play broken triads: I, IV, V, I. Pattern: 1-5-3-5. Two octaves, hands together. Start at 60 BPM and keep pedal clean.',
          notes: arpeggioNotesRH,
          fingering: arpeggioFingeringRH,
          repeatCount: 3,
          tempoBpm: 60,
        ),
      ]),
      PracticeSection(title: 'Harmony', tasks: [
        _buildTask(
          id: 'triads-root-$keySlug',
          title: '$keyName Primary Triads (Root Position)',
          description:
              'Play I, IV, V, I in root position. Hold each chord for 4 beats. Focus on clean chord changes and balanced voicing.',
          rootMidi: rightHandRoot,
          steps: inversionSteps,
          repeatCount: 2,
          tempoBpm: 56,
        ),
        _buildTask(
          id: 'triads-inversions-$keySlug',
          title: '$keyName Primary Triads (All Inversions)',
          description:
              'Play I, IV, V in root, 1st, and 2nd inversions. Move by closest inversion (least movement). Hold each for 3 beats.',
          rootMidi: rightHandRoot,
          steps: inversionSteps,
          repeatCount: 2,
          tempoBpm: 56,
        ),
        _buildTask(
          id: 'cadences-$keySlug',
          title: '$keyName Cadences',
          description:
              'Play authentic (V–I), plagal (IV–I), and half (I–V) cadences. Hold each chord 4 beats. Repeat the sequence 4 times.',
          rootMidi: rightHandRoot,
          steps: inversionSteps,
          repeatCount: 4,
          tempoBpm: 60,
        ),
        _buildTask(
          id: 'sevenths-$keySlug',
          title: '$keyName Seventh Chords (I7, IV7, V7)',
          description:
              'Play I7, IV7, V7 in root position, then 1st inversion. Hold each chord 3 beats. Keep the 7th resolved smoothly.',
          rootMidi: rightHandRoot,
          steps: inversionSteps,
          repeatCount: 2,
          tempoBpm: 58,
        ),
      ]),
      PracticeSection(title: 'Articulation & Dynamics', tasks: [
        _buildTaskWithFingering(
          id: 'staccato-legato-$keySlug',
          title: '$keyName Scale (Staccato Then Legato)',
          description:
              'One octave staccato up, one octave legato down. Repeat 5 times. Keep staccato light and legato connected.',
          notes: scaleNotesRH,
          fingering: scaleFingeringRH,
          repeatCount: 5,
          tempoBpm: 80,
        ),
        _buildTaskWithFingering(
          id: 'dynamics-$keySlug',
          title: '$keyName Scale (pp Up, ff Down)',
          description:
              'Two octaves up from pp to mf, then two octaves down from ff to p. Maintain even rhythm at 72 BPM.',
          notes: scaleNotesRH,
          fingering: scaleFingeringRH,
          repeatCount: 3,
          tempoBpm: 72,
        ),
      ]),
      PracticeSection(title: 'Rhythm', tasks: [
        _buildTaskWithFingering(
          id: 'rhythm-subdivisions-$keySlug',
          title: '$keyName Scale (8ths, Triplets, 16ths)',
          description:
              'Play two octaves: 8ths up, triplets down, 16ths up, 16ths down. Keep metronome at 60 BPM.',
          notes: scaleNotesRH,
          fingering: scaleFingeringRH,
          repeatCount: 2,
          tempoBpm: 60,
        ),
        _buildTask(
          id: 'syncopation-$keySlug',
          title: '$keyName Syncopation Drill',
          description:
              'Use a single chord tone. Play off-beat accents (on the "and" of each beat) for 2 minutes. Keep tempo at 72 BPM.',
          rootMidi: rightHandRoot,
          steps: const [0],
          repeatCount: 16,
          tempoBpm: 72,
        ),
      ]),
      PracticeSection(title: 'Musicality', tasks: [
        _buildTaskWithFingering(
          id: 'melodic-pattern-$keySlug',
          title: '$keyName 4-Bar Melodic Pattern',
          description:
              'Create a 4-bar melody using scale tones only. Repeat it 5 times with identical rhythm and phrasing.',
          notes: scaleNotesRH,
          fingering: scaleFingeringRH,
          repeatCount: 5,
          tempoBpm: 76,
        ),
        _buildTask(
          id: 'progression-pattern-$keySlug',
          title: '$keyName I–vi–IV–V Pattern',
          description:
              'Play block chords once, then broken chords (1-5-3-5). Repeat the full sequence 4 times. Keep tone warm and even.',
          rootMidi: rightHandRoot,
          steps: inversionSteps,
          repeatCount: 4,
          tempoBpm: 64,
        ),
      ]),
    ]);
  }

  static List<int> _triadInversionsTwoOctaves() {
    final steps = <int>[];
    for (var octave = 0; octave < 2; octave++) {
      final base = 12 * octave;
      steps.addAll([base + 0, base + 4, base + 7]);
      steps.addAll([base + 4, base + 7, base + 12]);
      steps.addAll([base + 7, base + 12, base + 16]);
    }
    return steps;
  }

  // New method that accepts notes with fingerings
  static PracticeTask _buildTaskWithFingering({
    required String id,
    required String title,
    required String description,
    required List<int> notes,
    required List<int> fingering,
    required int repeatCount,
    required int tempoBpm,
  }) {
    final sequence = <FingeredNote>[];
    for (int i = 0; i < notes.length; i++) {
      sequence.add(FingeredNote(
        midiNote: notes[i],
        finger: fingering[i],
      ));
    }
    final expectedNotes = <FingeredNote>[];
    for (var i = 0; i < repeatCount; i++) {
      expectedNotes.addAll(sequence);
    }
    return PracticeTask(
      id: id,
      title: title,
      description: description,
      expectedNotes: expectedNotes,
      metronomeRequired: true,
      tempoBpm: tempoBpm,
    );
  }

  // Legacy method for chord inversions (still uses steps from root)
  static PracticeTask _buildTask({
    required String id,
    required String title,
    required String description,
    required int rootMidi,
    required List<int> steps,
    required int repeatCount,
    required int tempoBpm,
  }) {
    final sequence = steps
        .map((step) => FingeredNote(midiNote: rootMidi + step, finger: 1))
        .toList();
    final expectedNotes = <FingeredNote>[];
    for (var i = 0; i < repeatCount; i++) {
      expectedNotes.addAll(sequence);
    }
    return PracticeTask(
      id: id,
      title: title,
      description: description,
      expectedNotes: expectedNotes,
      metronomeRequired: true,
      tempoBpm: tempoBpm,
    );
  }
}
