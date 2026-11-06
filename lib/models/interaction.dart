class Interaction {
  final String id;
  final String personId;
  final String? note;
  final String? audioPath;
  final DateTime createdAt;

  Interaction({
    required this.id,
    required this.personId,
    this.note,
    this.audioPath,
    required this.createdAt,
  });

  Map<String, Object?> toMap() => {
    'id': id,
    'person_id': personId,
    'note': note,
    'audio_path': audioPath,
    'created_at': createdAt.toIso8601String(),
  };

  factory Interaction.fromMap(Map<String, Object?> m) => Interaction(
    id: m['id'] as String,
    personId: m['person_id'] as String,
    note: m['note'] as String?,
    audioPath: m['audio_path'] as String?,
    createdAt: DateTime.parse(m['created_at'] as String),
  );
}