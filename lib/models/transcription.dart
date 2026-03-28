class TranscriptionSegment {
  final double start;
  final double end;
  final String text;

  TranscriptionSegment({
    required this.start,
    required this.end,
    required this.text,
  });

  factory TranscriptionSegment.fromJson(Map<String, dynamic> json) {
    return TranscriptionSegment(
      start: (json['start'] as num).toDouble(),
      end: (json['end'] as num).toDouble(),
      text: json['text'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'start': start,
        'end': end,
        'text': text,
      };
}
