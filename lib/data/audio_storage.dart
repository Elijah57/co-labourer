import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

Future<Directory> audioDirectory() async {
  final base = await getApplicationDocumentsDirectory();
  final dir = Directory(p.join(base.path, 'audio'));
  if (!await dir.exists()) await dir.create(recursive: true);
  return dir;
}
