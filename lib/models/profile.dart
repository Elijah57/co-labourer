class Profile {
  final String name;
  final String? about;

  Profile({required this.name, this.about});

  Map<String, Object?> toMap() => {
        'id': 'me',
        'name': name,
        'about': about,
      };

  factory Profile.fromMap(Map<String, Object?> m) => Profile(
        name: m['name'] as String,
        about: m['about'] as String?,
      );
}