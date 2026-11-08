import 'package:flutter/material.dart';
import '../../models/person.dart';
import '../../utils/birthday.dart';

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
  late final TextEditingController _phonenoController;
  late final TextEditingController _emailController;
  late final TextEditingController _addressController;
  late final TextEditingController _metAtController;
  late final TextEditingController _partnerController;
  late final TextEditingController _introController;
  late final TextEditingController _metOnController;
  late final TextEditingController _followUpController;
  late final Birthday _birthday;

  bool _formDirty = false;
  String? _workingPhoto;

  @override
  void initState() {
    super.initState();
    _workingPhoto = widget.original.photoPath;

    _firstnameController =
        TextEditingController(text: widget.original.firstname);
    _lastnameController = TextEditingController(text: widget.original.lastname ?? '');
    _othernameController =
        TextEditingController(text: widget.original.othername ?? '');
    _phonenoController = TextEditingController(text: widget.original.phoneno ?? '');
    _emailController = TextEditingController(text: widget.original.email ?? '');
    _addressController =
        TextEditingController(text: widget.original.address ?? '');
    _metAtController = TextEditingController(text: widget.original.metAt ?? '');
    _partnerController = TextEditingController(text: widget.original.partner ?? '');
    _introController = TextEditingController(text: widget.original.intro ?? '');
    _metOnController = widget.original.metOn != null
        ? TextEditingController(
            text: widget.original.metOn!.toIso8601String())
        : TextEditingController();
    _followUpController = widget.original.followUpDate != null
        ? TextEditingController(
            text:
                '${widget.original.followUpDate!.day}/${widget.original.followUpDate!.month}/${widget.original.followUpDate!.year}')
        : TextEditingController();

    _birthday = widget.original.birthday ??
        Birthday(day: 1, month: 'January', year: null);

    _setupListeners();
  }

  void _setupListeners() {
    final controllers = [
      _firstnameController,
      _lastnameController,
      _othernameController,
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
    final metAt =
        _metAtController.text.trim().isEmpty ? null : _metAtController.text.trim();
    final metOn = _metOnController.text.trim().isNotEmpty
        ? DateTime.tryParse(_metOnController.text.trim())
        : null;
    final followUpDate = _followUpController.text.isNotEmpty
        ? _parseFollowUpDate(_followUpController.text.trim())
        : null;

    return widget.original.copyWith(
      firstname: _firstnameController.text.trim(),
      lastname: _lastnameController.text.isNotEmpty
          ? _lastnameController.text
          : null,
      othername: _othernameController.text.isNotEmpty
          ? _othernameController.text
          : null,
      phoneno: _phonenoController.text.trim().isNotEmpty
          ? _phonenoController.text.trim()
          : null,
      email: _emailController.text.trim().isNotEmpty
          ? _emailController.text.trim()
          : null,
      address: _addressController.text.trim().isNotEmpty
          ? _addressController.text.trim()
          : null,
      photoPath: _workingPhoto ?? widget.original.photoPath,
      birthday: _birthday,
      partner: _partnerController.text.trim().isNotEmpty
          ? _partnerController.text.trim()
          : null,
      intro: _introController.text.trim().isNotEmpty
          ? _introController.text.trim()
          : null,
      metAt: metAt != null && metAt.isEmpty ? null : metAt,
      metOn: metOn,
      followUpDate: followUpDate,
    );
  }

  // --- Date parsing ---
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
    if (!mounted) return;
    Navigator.of(context).pop(updated);
  }

  // --- Build ---
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return PopScope(
      canPop: !_formDirty,
      onPopInvoked: (didPop) {
        if (!_formDirty) return;
        // Show discard confirmation - but since canPop already handles it,
        // we just allow the pop and the user can press back again if needed
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
              trailing: const Icon(Icons.calendar_today_outlined),
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
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _followUpController,
                    decoration: const InputDecoration(
                      labelText: 'Next follow-up date',
                    ),
                    onChanged: (_) => setState(() => _formDirty = true),
                  ),
                ),
                const SizedBox(width: 8),
                // Clear button for follow-up date
                IconButton(
                  icon: const Icon(Icons.clear, size: 20),
                  onPressed: () {
                    _followUpController.text = '';
                    setState(() => _formDirty = true);
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                // Birthday display
                const Icon(Icons.event, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: InkWell(
                    onTap: () {
                      // Show birthday picker - simple preset dates
                      _showBirthdayPicker();
                    },
                    child: Text(
                      _birthday.displayFull,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showBirthdayPicker() {
    // Show a simple dialog with preset options or just note that birthday can be set
    // For now, just note that tapping opens editing capability
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Birthday editing - select a date')),
    );
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
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Partner name'),
        content: TextField(
          onChanged: (v) =>
              setState(() => _partnerController.text = v.trim()),
          decoration: const InputDecoration(labelText: 'Enter partner name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}