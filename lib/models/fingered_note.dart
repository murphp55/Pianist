class FingeredNote {
  const FingeredNote({
    required this.midiNote,
    required this.finger,
    this.beat,
  });

  final int midiNote;
  final int finger;
  final double? beat;

  Map<String, dynamic> toJson() => {
        'midiNote': midiNote,
        'finger': finger,
        'beat': beat,
      };

  factory FingeredNote.fromJson(Map<String, dynamic> json) {
    return FingeredNote(
      midiNote: json['midiNote'] as int,
      finger: json['finger'] as int,
      beat: (json['beat'] as num?)?.toDouble(),
    );
  }
}
