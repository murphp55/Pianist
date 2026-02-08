import 'package:flutter/material.dart';

import '../helpers/note_name_helper.dart';
import '../models/fingered_note.dart';

class FingeringDiagram extends StatelessWidget {
  const FingeringDiagram({
    super.key,
    required this.notes,
    required this.highlightIndex,
  });

  final List<FingeredNote> notes;
  final int highlightIndex;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _FingeringPainter(
        notes: notes,
        highlightIndex: highlightIndex,
        textStyle: Theme.of(context).textTheme.labelSmall ?? const TextStyle(),
      ),
      size: const Size(double.infinity, 180),
    );
  }
}

class _FingeringPainter extends CustomPainter {
  _FingeringPainter({
    required this.notes,
    required this.highlightIndex,
    required this.textStyle,
  });

  final List<FingeredNote> notes;
  final int highlightIndex;
  final TextStyle textStyle;

  @override
  void paint(Canvas canvas, Size size) {
    const whiteKeyCount = 14;
    final keyWidth = size.width / whiteKeyCount;
    final keyHeight = size.height * 0.55;
    final blackKeyHeight = keyHeight * 0.65;

    final whitePaint = Paint()..color = const Color(0xFFF6F1E8);
    final borderPaint = Paint()
      ..color = const Color(0xFFB2A89A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final blackPaint = Paint()..color = const Color(0xFF2B2A2A);

    for (int i = 0; i < whiteKeyCount; i++) {
      final rect = Rect.fromLTWH(i * keyWidth, size.height - keyHeight,
          keyWidth, keyHeight);
      canvas.drawRect(rect, whitePaint);
      canvas.drawRect(rect, borderPaint);
    }

    const blackKeyPattern = [1, 1, 0, 1, 1, 1, 0];
    for (int i = 0; i < whiteKeyCount; i++) {
      final patternIndex = i % 7;
      if (blackKeyPattern[patternIndex] == 1) {
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

    if (notes.isEmpty) return;

    final notePaint = Paint()..color = const Color(0xFFDE6B35);
    final activePaint = Paint()..color = const Color(0xFF1F6E54);

    for (int i = 0; i < notes.length; i++) {
      final note = notes[i];
      final cx = _noteCenterX(note.midiNote, keyWidth);
      final cy = size.height - keyHeight - 12;
      canvas.drawCircle(
        Offset(cx, cy),
        14,
        i == highlightIndex ? activePaint : notePaint,
      );

      final label = '${note.finger}\n${NoteNameHelper.toName(note.midiNote)}';
      final tp = TextPainter(
        text: TextSpan(
          text: label,
          style: textStyle.copyWith(color: Colors.white, height: 1.1),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: 40);
      tp.paint(canvas, Offset(cx - tp.width / 2, cy - tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant _FingeringPainter oldDelegate) {
    return oldDelegate.notes != notes ||
        oldDelegate.highlightIndex != highlightIndex;
  }

  double _noteCenterX(int midiNote, double keyWidth) {
    const baseMidi = 60; // C4
    const maxWhiteKeys = 14;
    final semitone = (midiNote - baseMidi).clamp(0, 23);
    final octave = semitone ~/ 12;
    final semitoneInOctave = semitone % 12;

    double offset;
    switch (semitoneInOctave) {
      case 0:
        offset = 0;
        break;
      case 1:
        offset = 0.5;
        break;
      case 2:
        offset = 1;
        break;
      case 3:
        offset = 1.5;
        break;
      case 4:
        offset = 2;
        break;
      case 5:
        offset = 3;
        break;
      case 6:
        offset = 3.5;
        break;
      case 7:
        offset = 4;
        break;
      case 8:
        offset = 4.5;
        break;
      case 9:
        offset = 5;
        break;
      case 10:
        offset = 5.5;
        break;
      case 11:
        offset = 6;
        break;
      default:
        offset = 0;
    }

    final whiteIndex = (octave * 7) + offset;
    final clampedIndex = whiteIndex.clamp(0, maxWhiteKeys - 1) as double;
    return (clampedIndex + 0.5) * keyWidth;
  }
}
