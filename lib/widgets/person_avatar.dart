import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import '../data/audio_storage.dart';

class PersonAvatar extends StatelessWidget {
  final String? photoPath;
  final double radius;

  const PersonAvatar({super.key, this.photoPath, this.radius = 20});

  @override
  Widget build(BuildContext context) {
    final fallback = CircleAvatar(
      radius: radius,
      child: Icon(Icons.person, size: radius),
    );

    final name = photoPath;
    if (name == null) return fallback;

    return FutureBuilder<Directory>(
      future: photoDirectory(),
      builder: (context, dirSnapshot) {
        final dir = dirSnapshot.data;
        if (dir == null) return fallback;

        final file = File(p.join(dir.path, name));
        return FutureBuilder<bool>(
          future: file.exists(),
          builder: (context, existsSnapshot) {
            if (existsSnapshot.data == true) {
              return CircleAvatar(
                radius: radius,
                backgroundImage: FileImage(file),
              );
            }
            return fallback;
          },
        );
      },
    );
  }
}
