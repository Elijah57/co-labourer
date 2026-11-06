import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/person.dart';
import '../../repository/person.dart';
import '../../services/backup_service.dart';
import '../../services/drive_auth_service.dart';
import '../../services/notification_service.dart';
import '../../services/photo_service.dart';
import '../../widgets/person_avatar.dart';
import '../../widgets/photo_source_sheet.dart';
import 'person_detail.dart';

class PeopleListScreen extends StatefulWidget {
  const PeopleListScreen({super.key});

  @override
  State<PeopleListScreen> createState() => _PeopleListScreenState();
}

class _PeopleListScreenState extends State<PeopleListScreen> {
  final _repo = PeopleRepository();
  final _photos = PhotoService();
  List<Person> _people = [];
  bool _dueOnly = false;
  bool _busy = false;

  List<Person> get _visible =>
      _dueOnly ? _people.where(_isDue).toList() : _people;

  bool _isDue(Person person) {
    final due = person.followUpDate;
    if (due == null) return false;
    return !due.isAfter(DateTime.now());
  }

  String _fullName(Person person) => [
    person.firstname,
    person.lastname,
    person.othername,
  ].whereType<String>().where((part) => part.isNotEmpty).join(' ');

  String _formatDate(DateTime d) => '${d.day}/${d.month}/${d.year}';

  Widget? _subtitle(Person person) {
    final parts = [
      person.phoneno,
      person.email,
      person.address,
      person.metAt,
      if (person.followUpDate != null)
        'Follow-up ${_formatDate(person.followUpDate!)}',
    ].whereType<String>().where((part) => part.isNotEmpty).toList();
    if (parts.isEmpty) return null;
    return Text(parts.join(' • '));
  }

  @override
  void initState() {
    super.initState();
    _loadPeople();
  }

  Future<bool> _confirmDelete(String name) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete?'),
        content: Text('This will delete $name and all their entries.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _loadPeople() async {
    final people = await _repo.getAllPeople();
    people.sort((a, b) {
      final aDue = _isDue(a);
      final bDue = _isDue(b);
      if (aDue != bDue) return aDue ? -1 : 1;
      return b.createdAt.compareTo(a.createdAt);
    });
    if (!mounted) return;
    setState(() => _people = people);
  }

  String? _trimmedOrNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  Future<void> _showAddDialog() async {
    final firstname = TextEditingController();
    final lastname = TextEditingController();
    final othername = TextEditingController();
    final phoneno = TextEditingController();
    final email = TextEditingController();
    final address = TextEditingController();
    final metAt = TextEditingController();
    DateTime? followUpDate;
    String? workingPhoto;
    final tempFiles = <String>{};

    Future<void> cleanupTemp({String? keep}) async {
      for (final name in tempFiles.toList()) {
        if (name == keep) continue;
        tempFiles.remove(name);
        await _photos.delete(name);
      }
    }

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          Future<void> changePhoto() async {
            final action = await showPhotoSourceSheet(
              context,
              hasPhoto: workingPhoto != null,
            );
            if (action == null) return;

            String? picked;
            if (action == PhotoAction.remove) {
              picked = null;
            } else {
              final source = action == PhotoAction.camera
                  ? ImageSource.camera
                  : ImageSource.gallery;
              picked = await _photos.pickAndSave(source);
              if (picked == null) return;
            }

            if (!context.mounted) {
              await _photos.delete(picked);
              return;
            }

            final previous = workingPhoto;
            if (previous != null && tempFiles.remove(previous)) {
              await _photos.delete(previous);
            }
            if (picked != null) tempFiles.add(picked);
            setDialogState(() => workingPhoto = picked);
          }

          return AlertDialog(
            title: const Text('Add person'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: changePhoto,
                    child: PersonAvatar(photoPath: workingPhoto, radius: 40),
                  ),
                  TextButton(
                    onPressed: changePhoto,
                    child: const Text('Add photo'),
                  ),
                  TextField(
                    controller: firstname,
                    autofocus: true,
                    decoration: const InputDecoration(
                      labelText: 'First name',
                    ),
                  ),
                TextField(
                  controller: lastname,
                  decoration: const InputDecoration(labelText: 'Last name'),
                ),
                TextField(
                  controller: othername,
                  decoration: const InputDecoration(labelText: 'Other name'),
                ),
                TextField(
                  controller: phoneno,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Phone number'),
                ),
                TextField(
                  controller: email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
                TextField(
                  controller: address,
                  decoration: const InputDecoration(labelText: 'Address'),
                ),
                TextField(
                  controller: metAt,
                  decoration: const InputDecoration(labelText: 'Met at'),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    followUpDate == null
                        ? 'Follow-up date'
                        : 'Follow-up: ${followUpDate!.toLocal().toString().split(' ').first}',
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: followUpDate ?? DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 3650)),
                    );
                    if (picked != null) {
                      setDialogState(() => followUpDate = picked);
                    }
                  },
                ),
              ],
            ),
          ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );

    if (saved == true && firstname.text.trim().isNotEmpty) {
      await cleanupTemp(keep: workingPhoto);
      await _repo.addPerson(
        firstname: firstname.text.trim(),
        lastname: _trimmedOrNull(lastname.text),
        othername: _trimmedOrNull(othername.text),
        phoneno: _trimmedOrNull(phoneno.text),
        email: _trimmedOrNull(email.text),
        address: _trimmedOrNull(address.text),
        photoPath: workingPhoto,
        metAt: _trimmedOrNull(metAt.text),
        followUpDate: followUpDate,
      );
      await _loadPeople();
    } else {
      await cleanupTemp();
    }

    firstname.dispose();
    lastname.dispose();
    othername.dispose();
    phoneno.dispose();
    email.dispose();
    address.dispose();
    metAt.dispose();
  }

  Future<void> _backup() async {
    if (_busy) return;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      final client = await DriveAuthService().signIn();
      await BackupService().backup(client);
      messenger.showSnackBar(
        const SnackBar(content: Text('Backup complete')),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Backup failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _restore() async {
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restore from Drive?'),
        content: const Text(
          'This replaces everything on this phone with your last backup.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Restore'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _busy = true);
    try {
      final client = await DriveAuthService().signIn();
      final found = await BackupService().restore(client);
      if (found) await _loadPeople();
      if (found) await NotificationService.instance.rescheduleAll(_people);
      messenger.showSnackBar(
        SnackBar(content: Text(found ? 'Restore complete' : 'No backup found')),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Restore failed: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final visible = _visible;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Co-laborer'),
        bottom: _busy
            ? const PreferredSize(
                preferredSize: Size.fromHeight(4),
                child: LinearProgressIndicator(),
              )
            : null,
        actions: [
          IconButton(
            icon: Icon(
              _dueOnly ? Icons.filter_alt : Icons.filter_alt_outlined,
            ),
            tooltip: 'Show only due',
            onPressed: () => setState(() => _dueOnly = !_dueOnly),
          ),
          IconButton(
            icon: const Icon(Icons.cloud_upload),
            tooltip: 'Back up to Drive',
            onPressed: _busy ? null : _backup,
          ),
          IconButton(
            icon: const Icon(Icons.cloud_download),
            tooltip: 'Restore from Drive',
            onPressed: _busy ? null : _restore,
          ),
        ],
      ),
      body: visible.isEmpty
          ? Center(
              child: Text(_dueOnly ? 'No one is due' : 'No people yet'),
            )
          : ListView.builder(
              itemCount: visible.length,
              itemBuilder: (context, index) {
                final person = visible[index];
                return Dismissible(
                  key: ValueKey(person.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 16),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  confirmDismiss: (_) => _confirmDelete(_fullName(person)),
                  onDismissed: (_) {
                    setState(
                      () => _people.removeWhere((p) => p.id == person.id),
                    );
                    _repo.deletePerson(person.id);
                    NotificationService.instance.cancel(person.id);
                    _photos.delete(person.photoPath);
                  },
                  child: ListTile(
                    leading: PersonAvatar(
                      photoPath: person.photoPath,
                      radius: 22,
                    ),
                    title: Text(_fullName(person)),
                    subtitle: _subtitle(person),
                    trailing: _isDue(person)
                        ? const Icon(
                            Icons.notifications_active,
                            color: Colors.orange,
                          )
                        : null,
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PersonDetailScreen(person: person),
                        ),
                      );
                      _loadPeople();
                    },
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}