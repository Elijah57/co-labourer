import 'dart:convert';
import 'dart:io';
import 'package:share_plus/share_plus.dart';
import '../repository/person.dart';

class ExportService {
  Future<void> share() async {
    final people = await PeopleRepository().getAllPeople();
    final lines = <String>['ID,Firstname,Lastname,Phoneno,Met on,Follow-up'];
    for (final p in people) {
      final String id = p.id;
      final String first = p.firstname;
      final String last = p.lastname ?? '';
      final String phone = p.phoneno ?? '';
      final String met = p.metOn != null ? p.metOn!.toIso8601String() : '';
      final String follow = p.followUpDate != null ? p.followUpDate!.toString() : '';
      final String id2 = id.replaceAll(',', ';').replaceAll('"', '""');
      final String first2 = first.replaceAll(',', ';').replaceAll('"', '""');
      final String last2 = last.replaceAll(',', ';').replaceAll('"', '""');
      final String phone2 = phone.replaceAll(',', ';').replaceAll('"', '""');
      final String met2 = met.replaceAll(',', ';').replaceAll('"', '""');
      final String follow2 = follow.replaceAll(',', ';').replaceAll('"', '""');
      lines.add('$id2,$first2,$last2,$phone2,$met2,$follow2');
    }
    final csv = lines.join('\n');
    final bytes = utf8.encode(csv);
    final tempFile = File('/tmp/co_labourer_export.csv');
    await tempFile.writeAsBytes(bytes);
    await SharePlus.instance.share(
      ShareParams(
        text: csv,
        files: [XFile(tempFile.path)],
      ),
    );
  }
}