import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/person.dart';
import '../../repository/person.dart';
import '../../services/auto_backup.dart';
import '../../services/backup_service.dart';
import '../../services/drive_auth_service.dart';
import '../../services/notification_service.dart';
import '../../services/photo_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/date_format.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/person_avatar.dart';
import '../../widgets/person_card.dart';
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
  final _searchController = TextEditingController();
  bool _searching = false;
  String _query = '';

  List<Person> get _visible {
    var list = _dueOnly ? _people.where(_isDue).toList() : _people;
    final q = _query.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list
          .where(
            (p) =>
                _fullName(p).toLowerCase().contains(q) ||
                (p.metAt ?? '').toLowerCase().contains(q),
          )
          .toList();
    }
    return list;
  }

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

  @override
  void initState() {
    super.initState();
    _loadPeople();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
                spacing: 12,
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
                    decoration: const InputDecoration(labelText: 'First name'),
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
                    decoration: const InputDecoration(
                      labelText: 'Phone number',
                    ),
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
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.field),
                      side: BorderSide(
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                    ),
                    title: Text(
                      followUpDate == null
                          ? 'Follow-up date'
                          : 'Follow-up ${formatDayMonth(followUpDate!)}',
                    ),
                    trailing: const Icon(Icons.calendar_today_outlined),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: followUpDate ?? DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(
                          const Duration(days: 3650),
                        ),
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
              FilledButton(
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
      final ran = await AutoBackup.instance.run(client);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            ran ? 'Backup complete' : 'A backup is already running',
          ),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Backup failed: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _toggleAutoBackup() async {
    final messenger = ScaffoldMessenger.of(context);
    final auto = AutoBackup.instance;

    if (auto.enabled) {
      await auto.setEnabled(false);
      setState(() {});
      return;
    }

    try {
      await DriveAuthService().signIn();
      await auto.setEnabled(true);
      auto.markDirty();
      setState(() {});
      messenger.showSnackBar(const SnackBar(content: Text('Auto backup on')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Could not enable: $e')));
    }
  }

  String _lastBackupLabel() {
    final t = AutoBackup.instance.lastBackup;
    if (t == null) return 'No backup yet';
    final hh = t.hour.toString().padLeft(2, '0');
    final mm = t.minute.toString().padLeft(2, '0');
    return 'Last backup: ${t.day}/${t.month} $hh:$mm';
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
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: _searching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                cursorColor: AppColors.wheat,
                decoration: const InputDecoration(
                  filled: false,
                  isDense: true,
                  hintText: 'Search people',
                  hintStyle: TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
                onChanged: (value) => setState(() => _query = value),
              )
            : const Text('Co-laborer'),
        bottom: _busy
            ? const PreferredSize(
                preferredSize: Size.fromHeight(4),
                child: LinearProgressIndicator(),
              )
            : null,
        actions: [
          IconButton(
            icon: Icon(_searching ? Icons.close : Icons.search),
            tooltip: 'Search',
            onPressed: () => setState(() {
              if (_searching) {
                _searchController.clear();
                _query = '';
              }
              _searching = !_searching;
            }),
          ),
          IconButton(
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              transitionBuilder: (child, animation) =>
                  ScaleTransition(scale: animation, child: child),
              child: Icon(
                _dueOnly ? Icons.filter_alt : Icons.filter_alt_outlined,
                key: ValueKey(_dueOnly),
              ),
            ),
            tooltip: 'Show only due',
            onPressed: () => setState(() => _dueOnly = !_dueOnly),
          ),
          PopupMenuButton<String>(
            enabled: !_busy,
            onSelected: (value) {
              if (value == 'backup') _backup();
              if (value == 'restore') _restore();
              if (value == 'auto') _toggleAutoBackup();
            },
            itemBuilder: (context) => [
              PopupMenuItem(enabled: false, child: Text(_lastBackupLabel())),
              PopupMenuItem(
                value: 'auto',
                child: ListTile(
                  leading: Icon(
                    AutoBackup.instance.enabled
                        ? Icons.check_box
                        : Icons.check_box_outline_blank,
                  ),
                  title: const Text('Auto backup'),
                ),
              ),
              const PopupMenuItem(
                value: 'backup',
                child: ListTile(
                  leading: Icon(Icons.cloud_upload),
                  title: Text('Back up now'),
                ),
              ),
              const PopupMenuItem(
                value: 'restore',
                child: ListTile(
                  leading: Icon(Icons.cloud_download),
                  title: Text('Restore from Drive'),
                ),
              ),
            ],
          ),
        ],
      ),
      body: visible.isEmpty
          ? EmptyState(
              icon: _query.trim().isNotEmpty
                  ? Icons.search_off
                  : _dueOnly
                  ? Icons.check_circle_outline
                  : Icons.people_outline,
              title: _query.trim().isNotEmpty
                  ? 'No matches'
                  : _dueOnly
                  ? 'No follow-ups due'
                  : 'No one here yet',
              message: _query.trim().isNotEmpty
                  ? 'Try a different name or place.'
                  : _dueOnly
                  ? 'Everyone is up to date.'
                  : 'Tap + to add someone you meet, then log what you talk about.',
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
              itemCount: visible.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final person = visible[index];
                return Dismissible(
                  key: ValueKey(person.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    decoration: BoxDecoration(
                      color: scheme.error,
                      borderRadius: BorderRadius.circular(AppRadius.card),
                    ),
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Icon(Icons.delete_outline, color: scheme.onError),
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
                  child: PersonCard(
                    person: person,
                    fullName: _fullName(person),
                    isDue: _isDue(person),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddDialog,
        icon: const Icon(Icons.add),
        label: const Text('Add person'),
      ),
    );
  }
}
