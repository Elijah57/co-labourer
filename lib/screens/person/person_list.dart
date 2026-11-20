import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/person.dart';
import '../../models/tag.dart';
import '../../repository/interaction.dart';
import '../../repository/person.dart';
import '../../repository/tag.dart';
import '../../services/notification_service.dart';
import '../../services/photo_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/activity.dart';
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
  final _tagsRepo = TagsRepository();
  final _interactionsRepo = InteractionsRepository();
  final _photos = PhotoService();
  List<Person> _people = [];
  bool _dueOnly = false;

  List<Tag> _tags = [];
  Map<String, Set<String>> _tagIdsByPerson = {};
  Map<String, DateTime> _lastByPerson = {};
  bool _activeOnly = false;
  String? _tagFilter;

  late final _searchController = TextEditingController();
  bool _searching = false;
  String _query = '';

  List<Person> get _visible {
    var list = _dueOnly ? _people.where(_isDue).toList() : _people;
    if (_activeOnly) list = list.where(_isActive).toList();
    final tagFilter = _tagFilter;
    if (tagFilter != null) {
      list = list
          .where((p) => _tagIdsByPerson[p.id]?.contains(tagFilter) ?? false)
          .toList();
    }
    final q = _query.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list
          .where(
            (p) =>
                _fullName(p).toLowerCase().contains(q) ||
                (p.metAt ?? '').toLowerCase().contains(q) ||
                (p.occupation ?? '').toLowerCase().contains(q),
          )
          .toList();
    }
    return list;
  }

  bool _isActive(Person person) => isActive(_lastByPerson[person.id]);

  List<String> _tagNamesFor(Person person) {
    final ids = _tagIdsByPerson[person.id];
    if (ids == null || ids.isEmpty) return const [];
    return [
      for (final tag in _tags)
        if (ids.contains(tag.id)) tag.name,
    ];
  }

  /// Only tags that at least one person has, so unused ones don't clutter.
  List<Tag> get _usedTags {
    final used = <String>{for (final ids in _tagIdsByPerson.values) ...ids};
    return _tags.where((t) => used.contains(t.id)).toList();
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
    final tags = await _tagsRepo.getAllTags();
    final tagIdsByPerson = await _tagsRepo.getTagIdsByPerson();
    final lastByPerson = await _interactionsRepo.getLastByPerson();
    people.sort((a, b) {
      final aDue = _isDue(a);
      final bDue = _isDue(b);
      if (aDue != bDue) return aDue ? -1 : 1;
      return b.createdAt.compareTo(a.createdAt);
    });
    if (!mounted) return;
    setState(() {
      _people = people;
      _tags = tags;
      _tagIdsByPerson = tagIdsByPerson;
      _lastByPerson = lastByPerson;
      if (_tagFilter != null && !_usedTags.any((t) => t.id == _tagFilter)) {
        _tagFilter = null;
      }
    });
  }

  Widget _buildFilters() {
    final tags = _usedTags;
    return SizedBox(
      height: 52,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
        children: [
          FilterChip(
            avatar: const Icon(Icons.bolt, size: 18),
            label: const Text('Active'),
            tooltip: 'Talked in the last 30 days',
            selected: _activeOnly,
            onSelected: (v) => setState(() => _activeOnly = v),
          ),
          for (final tag in tags) ...[
            const SizedBox(width: 8),
            FilterChip(
              label: Text(tag.name),
              selected: _tagFilter == tag.id,
              onSelected: (v) =>
                  setState(() => _tagFilter = v ? tag.id : null),
            ),
          ],
        ],
      ),
    );
  }

  String? _trimmedOrNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  Future<void> _showAddDialog() async {
    final firstname = TextEditingController();
    final lastname = TextEditingController();
    final othername = TextEditingController();
    final occupation = TextEditingController();
    final phoneno = TextEditingController();
    final email = TextEditingController();
    final address = TextEditingController();
    final metAt = TextEditingController();
    DateTime? followUpDate;
    Birthday? birthday;
    Sex? sex;
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
                    controller: occupation,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(labelText: 'Occupation'),
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Wrap(
                      spacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        const Text('Sex'),
                        for (final option in Sex.values)
                          ChoiceChip(
                            label: Text(option.label),
                            selected: sex == option,
                            onSelected: (v) =>
                                setDialogState(() => sex = v ? option : null),
                          ),
                      ],
                    ),
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
        occupation: _trimmedOrNull(occupation.text),
        sex: sex,
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
    occupation.dispose();
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
                  hintText: 'Search name, place or occupation',
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
      body: Column(
        children: [
          if (_people.isNotEmpty) _buildFilters(),
          Expanded(
            child: visible.isEmpty
          ? EmptyState(
              icon: _query.trim().isNotEmpty
                  ? Icons.search_off
                  : _activeOnly || _tagFilter != null
                  ? Icons.filter_alt_off_outlined
                  : _dueOnly
                  ? Icons.check_circle_outline
                  : Icons.people_outline,
              title: _query.trim().isNotEmpty
                  ? 'No matches'
                  : _activeOnly || _tagFilter != null
                  ? 'No one matches'
                  : _dueOnly
                  ? 'No follow-ups due'
                  : 'No one here yet',
              message: _query.trim().isNotEmpty
                  ? 'Try a different name, place or occupation.'
                  : _activeOnly || _tagFilter != null
                  ? 'Try turning off a filter.'
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
                    isActive: _isActive(person),
                    tags: _tagNamesFor(person),
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
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddDialog,
        icon: const Icon(Icons.add),
        label: const Text('Add person'),
      ),
    );
  }
}