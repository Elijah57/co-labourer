class Tag {
  final String id;
  final String name;
  final DateTime createdAt;

  Tag({required this.id, required this.name, required this.createdAt});

  Map<String, Object?> toMap() => {
    'id': id,
    'name': name,
    'created_at': createdAt.toIso8601String(),
  };

  factory Tag.fromMap(Map<String, Object?> m) => Tag(
    id: m['id'] as String,
    name: m['name'] as String,
    createdAt: DateTime.parse(m['created_at'] as String),
  );
}
