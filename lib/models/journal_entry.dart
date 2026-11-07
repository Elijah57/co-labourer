class JournalEntry {
  final String id;
  final String? note;
  final String? audioPath;
  final DateTime createdAt;

  JournalEntry({
    required this.id,
    this.note,
    this.audioPath,
    required this.createdAt,
  });

  Map<String, Object?> toMap() => {
        'id': id,
        'note': note,
        'audio_path': audioPath,
        'created_at': createdAt.toIso8601String(),
      };

  factory JournalEntry.fromMap(Map<String, Object?> m) => JournalEntry(
        id: m['id'] as String,
        note: m['note'] as String?,
        audioPath: m['audio_path'] as String?,
        createdAt: DateTime.parse(m['created_at'] as String),
      );
}