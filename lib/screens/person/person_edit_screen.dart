import 'package:flutter/material.dart';
import '../../models/person.dart';
import '../../models/tag.dart';
import '../../repository/tag.dart';
import '../../utils/birthday.dart';
import '../../widgets/birthday_picker.dart';

class PersonEditScreen extends StatefulWidget {
  final Person original;
  const PersonEditScreen({required this.original, super.key});

  @override
  State<PersonEditScreen> createState() => _PersonEditScreenState();
}

class _PersonEditScreenState extends State<PersonEditScreen> {
  // Controllers - created in initState, disposed in dispose()
  late final TextEditingController _firstnameController;
  late final TextEditingController _lastnameController;
  late final TextEditingController _othernameController;
  late final TextEditingController _occupationController;
  late final TextEditingController _phonenoController;
  late final TextEditingController _emailController;
  late final TextEditingController _addressController;
  late final TextEditingController _metAtController;
  late final TextEditingController _partnerController;
  late final TextEditingController _introController;
  late final TextEditingController _metOnController;
  late final TextEditingController _followUpController;
  Birthday? _birthday;
  Sex? _sex;

  bool _formDirty = false;
  String? _workingPhoto;

  final _tagsRepo = TagsRepository();
  List<Tag> _allTags = [];
  Set<String> _initialTagIds = {};
  final Set<String> _selectedTagIds = {};
  // New tag names typed in this session; created only when the user saves.
  final List<String> _pendingTagNames = [];

  @override
  void initState() {
    super.initState();
    _workingPhoto = widget.original.photoPath;

    _firstnameController =
        TextEditingController(text: widget.original.firstname);
    _lastnameController = TextEditingController(text: widget.original.lastname ?? '');
    _othernameController =
        TextEditingController(text: widget.original.othername ?? '');
    _occupationController =
        TextEditingController(text: widget.original.occupation ?? '');
    _phonenoController = TextEditingController(text: widget.original.phoneno ?? '');
    _emailController = TextEditingController(text: widget.original.email ?? '');
    _addressController =
        TextEditingController(text: widget.original.address ?? '');
    _metAtController = TextEditingController(text: widget.original.metAt ?? '');
    _partnerController = TextEditingController(text: widget.original.partner ?? '');
    _introController = TextEditingController(text: widget.original.intro ?? '');
    _metOnController = widget.original.metOn != null
        ? TextEditingController(text: _formatDate(widget.original.metOn!))
        : TextEditingController();
    _followUpController = widget.original.followUpDate != null
        ? TextEditingController(
            text: _formatDate(widget.original.followUpDate!))
        : TextEditingController();

    _birthday = widget.original.birthday;
    _sex = widget.original.sex;

    _setupListeners();
    _loadTags();
  }

  Future<void> _loadTags() async {
    final all = await _tagsRepo.getAllTags();
    final mine = await _tagsRepo.getForPerson(widget.original.id);
    if (!mounted) return;
    setState(() {
      _allTags = all;
      _initialTagIds = mine.map((t) => t.id).toSet();
      _selectedTagIds.addAll(_initialTagIds);
    });
  }

  Future<void> _saveTags() async {
    final ids = {..._selectedTagIds};
    for (final name in _pendingTagNames) {
      ids.add((await _tagsRepo.getOrCreate(name)).id);
    }
    final unchanged = ids.length == _initialTagIds.length &&
        ids.containsAll(_initialTagIds);
    if (unchanged) return;
    await _tagsRepo.setPersonTags(widget.original.id, ids);
  }

  void _setupListeners() {
    final controllers = [
      _firstnameController,
      _lastnameController,
      _othernameController,
      _occupationController,
      _phonenoController,
      _emailController,
      _addressController,
      _metAtController,
      _partnerController,
      _introController,
      _metOnController,
      _followUpController,
    ];
    for (final c in controllers) {
      c.addListener(_onControllerChanged);
    }
  }

  void _onControllerChanged() {
    if (!mounted) return;
    setState(() => _formDirty = true);
  }

  @override
  void dispose() {
    _firstnameController.dispose();
    _lastnameController.dispose();
    _othernameController.dispose();
    _occupationController.dispose();
    _phonenoController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _metAtController.dispose();
    _partnerController.dispose();
    _introController.dispose();
    _metOnController.dispose();
    _followUpController.dispose();
    super.dispose();
  }

  // --- Save ---
  bool _canSave() {
    final firstname = _firstnameController.text.trim();
    return firstname.isNotEmpty;
  }

  Person _buildPerson() {
    final lastname = _lastnameController.text.trim();
    final othername = _othernameController.text.trim();
    final occupation = _occupationController.text.trim();
    final phoneno = _phonenoController.text.trim();
    final email = _emailController.text.trim();
    final address = _addressController.text.trim();
    final partner = _partnerController.text.trim();
    final intro = _introController.text.trim();
    final metAt = _metAtController.text.trim();
    final metOn = _metOnController.text.trim().isNotEmpty
        ? _parseMetOnDate(_metOnController.text.trim())
        : null;
    final followUpDate = _followUpController.text.isNotEmpty
        ? _parseFollowUpDate(_followUpController.text.trim())
        : null;

    return widget.original.copyWith(
      firstname: _firstnameController.text.trim(),
      lastname: lastname.isEmpty ? null : lastname,
      clearLastname: lastname.isEmpty,
      othername: othername.isEmpty ? null : othername,
      clearOthername: othername.isEmpty,
      occupation: occupation.isEmpty ? null : occupation,
      clearOccupation: occupation.isEmpty,
      sex: _sex,
      clearSex: _sex == null,
      phoneno: phoneno.isEmpty ? null : phoneno,
      clearPhoneno: phoneno.isEmpty,
      email: email.isEmpty ? null : email,
      clearEmail: email.isEmpty,
      address: address.isEmpty ? null : address,
      clearAddress: address.isEmpty,
      photoPath: _workingPhoto ?? widget.original.photoPath,
      birthday: _birthday,
      clearBirthday: _birthday == null,
      partner: partner.isEmpty ? null : partner,
      clearPartner: partner.isEmpty,
      intro: intro.isEmpty ? null : intro,
      clearIntro: intro.isEmpty,
      metAt: metAt.isEmpty ? null : metAt,
      clearMetAt: metAt.isEmpty,
      metOn: metOn,
      clearMetOn: metOn == null,
      followUpDate: followUpDate,
      clearFollowUpDate: followUpDate == null,
    );
  }

  // --- Date parsing ---
  String _formatDate(DateTime date) =>
      '${date.day}/${date.month}/${date.year}';

  DateTime? _parseFollowUpDate(String text) {
    final parts = text.split('/');
    if (parts.length == 3) {
      try {
        final d = int.parse(parts[0]);
        final m = int.parse(parts[1]);
        final y = int.parse(parts[2]);
        return DateTime(y, m, d);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  // --- Save and pop ---
  Future<void> _saveAndPop() async {
    if (!_canSave()) return;
    final updated = _buildPerson();
    await _saveTags();
    if (!mounted) return;
    Navigator.of(context).pop(updated);
  }

  Future<bool> _confirmDiscard() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard changes?'),
        content: const Text('Your edits to this person will be lost.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep editing'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _handleBlockedPop() async {
    final discard = await _confirmDiscard();
    if (discard && mounted) Navigator.of(context).pop();
  }

  // --- Build ---
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return PopScope(
      canPop: !_formDirty,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _handleBlockedPop();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Edit person'),
          actions: [
            // Save pill - enabled when name is not empty
            ElevatedButton(
              onPressed: _canSave() ? _saveAndPop : null,
              child: const Text('Save'),
              style: ElevatedButton.styleFrom(
                backgroundColor: scheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: MediaQuery.of(context).size.width,
              maxWidth: MediaQuery.of(context).size.width * 2,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildBasics(),
                const SizedBox(height: 16),
                _buildHowWeMet(),
                const SizedBox(height: 16),
                _buildContact(),
                const SizedBox(height: 16),
                _buildFollowUpBirthday(),
                const SizedBox(height: 16),
                _buildTags(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- Form sections ---

  Widget _buildBasics() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Basics', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _firstnameController,
                    decoration: const InputDecoration(
                      labelText: 'First name',
                      hintText: 'Required',
                    ),
                    onChanged: (_) => setState(() => _formDirty = true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _lastnameController,
                    decoration: const InputDecoration(labelText: 'Last name'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _othernameController,
              decoration: const InputDecoration(labelText: 'Other name'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _occupationController,
              decoration: const InputDecoration(labelText: 'Occupation'),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 12),
            Text('Sex', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              children: [
                for (final option in Sex.values)
                  ChoiceChip(
                    label: Text(option.label),
                    selected: _sex == option,
                    // Tapping the selected chip again clears it.
                    onSelected: (v) => setState(() {
                      _sex = v ? option : null;
                      _formDirty = true;
                    }),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHowWeMet() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('How we met', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            TextField(
              controller: _metAtController,
              decoration: const InputDecoration(
                labelText: 'Where you met',
              ),
              onChanged: (_) => setState(() => _formDirty = true),
            ),
            const SizedBox(height: 8),
            ListTile(
              title: const Text('Date met'),
              subtitle: Text(
                _metOnController.text.isNotEmpty
                    ? _metOnController.text
                    : 'Not set',
              ),
              trailing: _metOnController.text.isEmpty
                  ? const Icon(Icons.calendar_today_outlined)
                  : IconButton(
                      icon: const Icon(Icons.clear, size: 20),
                      tooltip: 'Clear date met',
                      onPressed: () =>
                          setState(() => _metOnController.text = ''),
                    ),
              onTap: _pickMetOnDate,
            ),
            ListTile(
              title: const Text('Partner'),
              trailing: const Icon(Icons.person_outlined),
              onTap: _showPartnerSelector,
              subtitle: Text(_partnerController.text.isNotEmpty
                  ? _partnerController.text
                  : ''),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _introController,
              decoration: const InputDecoration(
                labelText: 'How you met (optional)',
                hintText: 'A short overview',
              ),
              maxLines: 3,
              onChanged: (_) => setState(() => _formDirty = true),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContact() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Contact', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            TextField(
              controller: _phonenoController,
              decoration: const InputDecoration(
                labelText: 'Phone (start with + and country code)',
              ),
              keyboardType: TextInputType.phone,
              onChanged: (_) => setState(() => _formDirty = true),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _addressController,
              decoration: const InputDecoration(labelText: 'Address'),
              keyboardType: TextInputType.streetAddress,
              textCapitalization: TextCapitalization.words,
              maxLines: 2,
              minLines: 1,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFollowUpBirthday() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Follow-up and birthday',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _followUpController,
              readOnly: true,
              onTap: _pickFollowUpDate,
              decoration: InputDecoration(
                labelText: 'Next follow-up date',
                hintText: 'Select a date',
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_followUpController.text.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.clear, size: 20),
                        onPressed: _clearFollowUpDate,
                      ),
                    IconButton(
                      icon: const Icon(Icons.calendar_today_outlined, size: 20),
                      onPressed: _pickFollowUpDate,
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 24),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.cake_outlined),
              title: const Text('Birthday'),
              subtitle: Text(_birthday?.displayFull ?? 'Not set'),
              trailing: _birthday == null
                  ? const Icon(Icons.chevron_right)
                  : IconButton(
                      icon: const Icon(Icons.clear, size: 20),
                      onPressed: () => setState(() {
                        _birthday = null;
                        _formDirty = true;
                      }),
                    ),
              onTap: _pickBirthday,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTags() {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tags', style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              'Long-press a tag to delete it for everyone.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final tag in _allTags)
                  GestureDetector(
                    onLongPress: () => _deleteTag(tag),
                    child: FilterChip(
                      label: Text(tag.name),
                      selected: _selectedTagIds.contains(tag.id),
                      onSelected: (v) => setState(() {
                        v
                            ? _selectedTagIds.add(tag.id)
                            : _selectedTagIds.remove(tag.id);
                        _formDirty = true;
                      }),
                    ),
                  ),
                for (final name in _pendingTagNames)
                  FilterChip(
                    label: Text(name),
                    selected: true,
                    onSelected: (_) => setState(() {
                      _pendingTagNames.remove(name);
                      _formDirty = true;
                    }),
                  ),
                ActionChip(
                  avatar: const Icon(Icons.add, size: 18),
                  label: const Text('New tag'),
                  onPressed: _addTag,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addTag() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New tag'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'Tag name'),
          onSubmitted: (v) => Navigator.pop(context, v.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    if (name == null || name.isEmpty || !mounted) return;

    final lower = name.toLowerCase();
    setState(() {
      final existing =
          _allTags.where((t) => t.name.toLowerCase() == lower).firstOrNull;
      if (existing != null) {
        _selectedTagIds.add(existing.id);
      } else if (!_pendingTagNames.any((n) => n.toLowerCase() == lower)) {
        _pendingTagNames.add(name);
      }
      _formDirty = true;
    });
  }

  Future<void> _deleteTag(Tag tag) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete "${tag.name}"?'),
        content: const Text(
          'This removes the tag from everyone who has it. '
          'People and conversations are not affected.',
        ),
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
    if (ok != true) return;
    await _tagsRepo.deleteTag(tag.id);
    if (!mounted) return;
    setState(() {
      _allTags.removeWhere((t) => t.id == tag.id);
      _selectedTagIds.remove(tag.id);
      _initialTagIds = {..._initialTagIds}..remove(tag.id);
    });
  }

  Future<void> _pickBirthday() async {
    final picked = await showBirthdayPicker(context, initial: _birthday);
    if (picked != null && mounted) {
      setState(() {
        _birthday = picked;
        _formDirty = true;
      });
    }
  }

  void _clearFollowUpDate() {
    setState(() {
      _followUpController.text = '';
      _formDirty = true;
    });
  }

  Future<void> _pickFollowUpDate() async {
    final current = _parseFollowUpDate(_followUpController.text.trim());
    final picked = await showDatePicker(
      context: context,
      initialDate: current ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (picked != null && mounted) {
      setState(() {
        _followUpController.text = _formatDate(picked);
        _formDirty = true;
      });
    }
  }

  // --- Date picking ---
  Future<void> _pickMetOnDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _metOnController.text.isNotEmpty
          ? _parseMetOnDate(_metOnController.text) ??
              DateTime.now()
          : DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (picked != null) {
      setState(() {
        _metOnController.text =
            '${picked.day}/${picked.month}/${picked.year}';
      });
    }
  }

  DateTime? _parseMetOnDate(String text) {
    final parts = text.split('/');
    if (parts.length == 3) {
      try {
        final d = int.parse(parts[0]);
        final m = int.parse(parts[1]);
        final y = int.parse(parts[2]);
        return DateTime(y, m, d);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  Future<void> _showPartnerSelector() async {
    if (!mounted) return;
    final controller = TextEditingController(text: _partnerController.text);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Partner name'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'Enter partner name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (result == null || !mounted) return;
    if (result == _partnerController.text) return;
    setState(() => _partnerController.text = result);
  }
}