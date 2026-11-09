import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/person.dart';
import '../../repository/person.dart';
import '../../services/notification_service.dart';
import '../../services/photo_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/birthday.dart';
import '../../widgets/birthday_picker.dart';
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

  late final _searchController = TextEditingController();
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
    NotificationService.instance.refreshList = () { _loadPeople(); };
    _loadPeople();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => NotificationService.instance.handlePending(),
    );
  }

  @override
  void dispose() {
    NotificationService.instance.refreshList = null;
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
    Birthday? birthday;
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
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.cake_outlined),
                    title: const Text('Birthday'),
                    subtitle: Text(birthday?.displayFull ?? 'Not set'),
                    trailing: birthday == null
                        ? const Icon(Icons.chevron_right)
                        : IconButton(
                            icon: const Icon(Icons.clear, size: 20),
                            onPressed: () {
                              setDialogState(() => birthday = null);
                            },
                          ),
                    onTap: () async {
                      final picked =
                          await showBirthdayPicker(context, initial: birthday);
                      if (picked != null && context.mounted) {
                        setDialogState(() => birthday = picked);
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
        birthday: birthday,
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