import 'package:flutter/material.dart';
import '../../../models/interaction.dart';
import '../../../models/person.dart';
import '../../repository/interaction.dart';
import '../../repository/person.dart';
import '../../services/audio_service.dart';

class PersonDetailScreen extends StatefulWidget {
  final Person person;
  const PersonDetailScreen({super.key, required this.person});

  @override
  State<PersonDetailScreen> createState() => _PersonDetailScreenState();
}

class _PersonDetailScreenState extends State<PersonDetailScreen> {
  final _repo = InteractionsRepository();
  final _peopleRepo = PeopleRepository();
  final _audio = AudioService();
  late Person _person;
  List<Interaction> _interactions = [];

  @override
  void initState() {
    super.initState();
    _person = widget.person;
    _load();
  }

  @override
  void dispose() {
    _audio.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final items = await _repo.getForPerson(_person.id);
    if (!mounted) return;
    setState(() => _interactions = items);
  }

  Future<bool> _confirmDelete() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete entry?'),
        content: const Text('This cannot be undone.'),
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


  Future<void> _showNoteDialog({Interaction? existing}) async {
    final controller = TextEditingController(text: existing?.note ?? '');
    final note = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(existing == null ? 'New entry' : 'Edit entry'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 4,
          decoration: const InputDecoration(labelText: 'What did you discuss?'),
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

    if (note == null || note.isEmpty) return;

    if (existing == null) {
      await _repo.addInteraction(personId: _person.id, note: note);
    } else {
      await _repo.updateNote(existing.id, note);
    }
    await _load();
  }

  Future<void> _recordAudio() async {
    final messenger = ScaffoldMessenger.of(context);
    final fileName = await _audio.startRecording();
    if (fileName == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Microphone permission needed')),
      );
      return;
    }
    if (!mounted) return;

    final save = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Recording...'),
        content: const Icon(Icons.mic, size: 48, color: Colors.red),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Stop & save'),
          ),
        ],
      ),
    );

    if (save == true) {
      await _audio.stopRecording();
      await _repo.addInteraction(personId: _person.id, audioPath: fileName);
      await _load();
    } else {
      await _audio.cancelRecording();
    }
  }

  Future<void> _showEditDialog() async {
    final firstnameController = TextEditingController(
      text: _person.firstname,
    );
    final metAtController = TextEditingController(text: _person.metAt ?? '');

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit person'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: firstnameController,
              decoration: const InputDecoration(labelText: 'First name'),
            ),
            TextField(
              controller: metAtController,
              decoration: const InputDecoration(labelText: 'Where you met'),
            ),
          ],
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
      ),
    );

    final firstname = firstnameController.text.trim();
    if (saved != true || firstname.isEmpty) return;

    final metAt = metAtController.text.trim();
    final updated = Person(
      id: _person.id,
      firstname: firstname,
      lastname: _person.lastname,
      othername: _person.othername,
      phoneno: _person.phoneno,
      email: _person.email,
      address: _person.address,
      metAt: metAt.isEmpty ? null : metAt,
      followUpDate: _person.followUpDate,
      createdAt: _person.createdAt,
    );
    await _peopleRepo.updatePerson(updated);
    if (!mounted) return;
    setState(() => _person = updated);

    firstnameController.dispose();
    metAtController.dispose();
  }

  String _formatDate(DateTime d) => '${d.day}/${d.month}/${d.year}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_person.firstname),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _showEditDialog,
          ),
        ],
      ),
      body: _interactions.isEmpty
          ? const Center(child: Text('No conversations logged yet'))
          : ListView.builder(
        itemCount: _interactions.length,
          itemBuilder: (context, index) {
            final item = _interactions[index];
            return Dismissible(
              key: ValueKey(item.id),
              direction: DismissDirection.endToStart,
              background: Container(
                color: Colors.red,
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 16),
                child: const Icon(Icons.delete, color: Colors.white),
              ),
              confirmDismiss: (_) => _confirmDelete(),
              onDismissed: (_) {
                setState(() => _interactions.removeAt(index));
                _repo.deleteInteraction(item.id);
              },
              child: ListTile(
                leading: item.audioPath != null
                    ? IconButton(
                        icon: const Icon(Icons.play_circle),
                        onPressed: () => _audio.play(item.audioPath!),
                      )
                    : null,
                title: Text(item.note ?? 'Audio note'),
                subtitle: Text(_formatDate(item.createdAt)),
                onTap: () => _showNoteDialog(existing: item),
              ),
            );
          },
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.small(
            heroTag: 'mic',
            onPressed: _recordAudio,
            child: const Icon(Icons.mic),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: 'add',
            onPressed: () => _showNoteDialog(),
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}