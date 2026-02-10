import 'package:flutter/material.dart';

import '../helpers/note_name_helper.dart';
import '../models/key_signature.dart';
import '../models/fingered_note.dart';

class FingeringDiagram extends StatelessWidget {
  const FingeringDiagram({
    super.key,
    required this.notes,
    required this.highlightIndex,
    required this.keySignature,
  });

  final List<FingeredNote> notes;
  final int highlightIndex;
  final KeySignature keySignature;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _FingeringPainter(
        notes: notes,
        highlightIndex: highlightIndex,
        keySignature: keySignature,
        textStyle: Theme.of(context).textTheme.labelMedium ?? const TextStyle(),
      ),
      size: const Size(double.infinity, 280), // Increased from 180
    );
  }
}

class _FingeringPainter extends CustomPainter {
  _FingeringPainter({
    required this.notes,
    required this.highlightIndex,
    required this.keySignature,
    required this.textStyle,
  });

  final List<FingeredNote> notes;
  final int highlightIndex;
  final KeySignature keySignature;
  final TextStyle textStyle;

  @override
  void paint(Canvas canvas, Size size) {
    // Only display first octave (8 notes) for cleaner diagram.
    // If possible, keep the highlighted note visible.
    const maxDisplayNotes = 8;
    List<FingeredNote> displayNotes;
    int localHighlightIndex = -1;
    if (notes.isNotEmpty && notes.length > maxDisplayNotes) {
      var start = 0;
      if (highlightIndex >= 0 && highlightIndex < notes.length) {
        start = highlightIndex - (maxDisplayNotes ~/ 2);
        if (start < 0) start = 0;
        if (start > notes.length - maxDisplayNotes) {
          start = notes.length - maxDisplayNotes;
        }
        localHighlightIndex = highlightIndex - start;
      }
      displayNotes = notes.sublist(start, start + maxDisplayNotes);
    } else {
      displayNotes = notes;
      if (highlightIndex >= 0 && highlightIndex < displayNotes.length) {
        localHighlightIndex = highlightIndex;
      }
    }

    const int whiteKeyCount = 14; // Keep consistent key count across images
    int baseMidi = 55; // Default: G3 (C4 - 5 semitones)

    if (displayNotes.isNotEmpty) {
      final minMidi = displayNotes
          .map((n) => n.midiNote)
          .reduce((a, b) => a < b ? a : b);
      final maxMidi = displayNotes
          .map((n) => n.midiNote)
          .reduce((a, b) => a > b ? a : b);
      final centerMidi = ((minMidi + maxMidi) / 2).round();
      final targetWhiteMidi = _previousWhiteKeyMidi(centerMidi);

      // Center the scale within the fixed key count.
      final centerIndex = whiteKeyCount ~/ 2;
      baseMidi = _shiftByWhiteKeys(targetWhiteMidi, -centerIndex);
    }

    final keyWidth = size.width / whiteKeyCount;
    final keyHeight = size.height * 0.85;
    final blackKeyHeight = keyHeight * 0.65;

    final whitePaint = Paint()..color = const Color(0xFFF6F1E8);
    final borderPaint = Paint()
      ..color = const Color(0xFFB2A89A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final blackPaint = Paint()..color = const Color(0xFF2B2A2A);

    // Draw white keys
    for (int i = 0; i < whiteKeyCount; i++) {
      final rect = Rect.fromLTWH(i * keyWidth, size.height - keyHeight,
          keyWidth, keyHeight);
      canvas.drawRect(rect, whitePaint);
      canvas.drawRect(rect, borderPaint);
    }

    // Draw black keys - check each white key's note to determine if it has a black key after it
    for (int i = 0; i < whiteKeyCount; i++) {
      final whiteKeyMidi = _whiteKeyMidiFromIndex(baseMidi, i);
      final noteInOctave = whiteKeyMidi % 12;

      // Check if this white key has a black key after it
      // C(0), D(2), F(5), G(7), A(9) have sharps; E(4), B(11) don't
      final hasBlackKey = [0, 2, 5, 7, 9].contains(noteInOctave);

      if (hasBlackKey) {
        final rect = Rect.fromLTWH(
          (i + 0.7) * keyWidth,
          size.height - keyHeight,
          keyWidth * 0.6,
          blackKeyHeight,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(3)),
          blackPaint,
        );
      }
    }

    final notePaint = Paint()..color = const Color(0xFFDE6B35);
    final activePaint = Paint()..color = const Color(0xFF1F6E54);

    for (int i = 0; i < displayNotes.length; i++) {
      final note = displayNotes[i];
      final cx = _noteCenterX(
        note.midiNote,
        keyWidth,
        baseMidi,
        whiteKeyCount,
      );
      final isBlackKey = _isBlackKey(note.midiNote);

      // Place numbers ON the keys: lower for white keys, higher for black keys
      final cy = isBlackKey
          ? size.height - keyHeight + (blackKeyHeight * 0.5)
          : size.height - keyHeight * 0.25;

      canvas.drawCircle(
        Offset(cx, cy),
        16, // Slightly larger circles
        i == localHighlightIndex ? activePaint : notePaint,
      );

      // Show finger number and note name
      final label =
          '${note.finger}\n${NoteNameHelper.toName(note.midiNote, keySignature: keySignature)}';
      final tp = TextPainter(
        text: TextSpan(
          text: label,
          style: textStyle.copyWith(
            color: Colors.white,
            height: 1.1,
            fontWeight: FontWeight.bold,
          ),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: 50);
      tp.paint(canvas, Offset(cx - tp.width / 2, cy - tp.height / 2));
    }
  }

  bool _isBlackKey(int midiNote) {
    final semitone = midiNote % 12;
    return [1, 3, 6, 8, 10].contains(semitone);
  }

  int _nextWhiteKeyMidi(int midiNote) {
    int currentMidi = midiNote;
    while (_isBlackKey(currentMidi)) {
      currentMidi++;
    }
    return currentMidi;
  }

  int _previousWhiteKeyMidi(int midiNote) {
    int currentMidi = midiNote;
    while (_isBlackKey(currentMidi)) {
      currentMidi--;
    }
    return currentMidi;
  }

  int _shiftByWhiteKeys(int midiNote, int whiteSteps) {
    int currentMidi = midiNote;
    int remaining = whiteSteps;
    final direction = whiteSteps >= 0 ? 1 : -1;

    while (remaining != 0) {
      currentMidi += direction;
      if (!_isBlackKey(currentMidi)) {
        remaining -= direction;
      }
    }
    return currentMidi;
  }

  // Helper to calculate which MIDI note corresponds to a white key index
  int _whiteKeyMidiFromIndex(int baseMidi, int index) {
    // Start from baseMidi and count white keys
    int currentMidi = baseMidi;
    int whiteKeysFound = 0;

    while (whiteKeysFound < index) {
      currentMidi++;
      if (!_isBlackKey(currentMidi)) {
        whiteKeysFound++;
      }
    }
    return currentMidi;
  }

  @override
  bool shouldRepaint(covariant _FingeringPainter oldDelegate) {
    return oldDelegate.notes != notes ||
        oldDelegate.highlightIndex != highlightIndex;
  }

  double _noteCenterX(
    int midiNote,
    double keyWidth,
    int baseMidi,
    int whiteKeyCount,
  ) {
    final whiteKeyIndex =
        _whiteKeyIndexAtOrBefore(baseMidi, midiNote, whiteKeyCount);

    if (_isBlackKey(midiNote)) {
      // Black key: centered between its surrounding white keys.
      final index = (whiteKeyIndex + 1.0).clamp(0.0, whiteKeyCount - 1.0);
      return index * keyWidth;
    }

    // White key: centered within its key.
    final index = (whiteKeyIndex + 0.5).clamp(0.0, whiteKeyCount - 1.0);
    return index * keyWidth;
  }

  int _whiteKeyIndexAtOrBefore(
    int baseMidi,
    int midiNote,
    int whiteKeyCount,
  ) {
    int whiteIndex = 0;
    for (int midi = baseMidi; midi <= midiNote; midi++) {
      if (!_isBlackKey(midi)) {
        whiteIndex++;
      }
    }
    // Convert count to zero-based index.
    whiteIndex -= 1;
    if (whiteIndex < 0) whiteIndex = 0;
    if (whiteIndex > whiteKeyCount - 1) {
      whiteIndex = whiteKeyCount - 1;
    }
    return whiteIndex;
  }
}
