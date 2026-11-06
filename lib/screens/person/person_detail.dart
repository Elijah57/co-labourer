import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../models/interaction.dart';
import '../../../models/person.dart';
import '../../repository/interaction.dart';
import '../../repository/person.dart';
import '../../services/audio_service.dart';
import '../../services/notification_service.dart';
import '../../services/photo_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/date_format.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/interaction_card.dart';
import '../../widgets/person_avatar.dart';
import '../../widgets/photo_source_sheet.dart';

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
  final _photos = PhotoService();
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
          FilledButton(
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
        content: CircleAvatar(
          radius: 28,
          backgroundColor: Theme.of(context).colorScheme.errorContainer,
          child: Icon(
            Icons.mic,
            size: 28,
            color: Theme.of(context).colorScheme.error,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
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

  Future<void> _showPhotoOptions({
    required BuildContext dialogContext,
    required bool hasPhoto,
    required Future<void> Function(String?) onPicked,
  }) async {
    final action = await showPhotoSourceSheet(
      dialogContext,
      hasPhoto: hasPhoto,
    );
    if (action == null) return;

    if (action == PhotoAction.remove) {
      await onPicked(null);
      return;
    }

    final source = action == PhotoAction.camera
        ? ImageSource.camera
        : ImageSource.gallery;
    final fileName = await _photos.pickAndSave(source);
    if (fileName != null) await onPicked(fileName);
  }

  Future<void> _showEditDialog() async {
    final firstnameController = TextEditingController(text: _person.firstname);
    final metAtController = TextEditingController(text: _person.metAt ?? '');

    final originalPhoto = _person.photoPath;
    String? workingPhoto = originalPhoto;
    bool photoChanged = false;
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
            await _showPhotoOptions(
              dialogContext: context,
              hasPhoto: workingPhoto != null,
              onPicked: (picked) async {
                if (!context.mounted) {
                  await _photos.delete(picked);
                  return;
                }
                final previous = workingPhoto;
                if (previous != null && tempFiles.remove(previous)) {
                  await _photos.delete(previous);
                }
                if (picked != null) tempFiles.add(picked);
                setDialogState(() {
                  workingPhoto = picked;
                  photoChanged = true;
                });
              },
            );
          }

          return AlertDialog(
            title: const Text('Edit person'),
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
                    child: const Text('Change photo'),
                  ),
                  TextField(
                    controller: firstnameController,
                    decoration: const InputDecoration(labelText: 'First name'),
                  ),
                  TextField(
                    controller: metAtController,
                    decoration: const InputDecoration(
                      labelText: 'Where you met',
                    ),
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

    final firstname = firstnameController.text.trim();
    if (saved != true || firstname.isEmpty) {
      await cleanupTemp();
      firstnameController.dispose();
      metAtController.dispose();
      return;
    }

    final newPhoto = photoChanged ? workingPhoto : originalPhoto;
    await cleanupTemp(keep: newPhoto);

    final metAt = metAtController.text.trim();
    final updated = Person(
      id: _person.id,
      firstname: firstname,
      lastname: _person.lastname,
      othername: _person.othername,
      phoneno: _person.phoneno,
      email: _person.email,
      address: _person.address,
      photoPath: newPhoto,
      metAt: metAt.isEmpty ? null : metAt,
      followUpDate: _person.followUpDate,
      createdAt: _person.createdAt,
    );
    await _peopleRepo.updatePerson(updated);
    await NotificationService.instance.schedule(updated);
    if (photoChanged && originalPhoto != null && originalPhoto != newPhoto) {
      await _photos.delete(originalPhoto);
    }
    if (!mounted) return;
    setState(() => _person = updated);

    firstnameController.dispose();
    metAtController.dispose();
  }

  Widget _buildInteraction(Interaction item) {
    final scheme = Theme.of(context).colorScheme;
    return Dismissible(
      key: ValueKey(item.id),
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
      confirmDismiss: (_) => _confirmDelete(),
      onDismissed: (_) {
        setState(() => _interactions.removeWhere((x) => x.id == item.id));
        _repo.deleteInteraction(item.id);
      },
      child: InteractionCard(
        interaction: item,
        onTap: () => _showNoteDialog(existing: item),
        onPlay: () => _audio.play(item.audioPath!),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Person'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit person',
            onPressed: _showEditDialog,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
        children: [
          _PersonHeader(person: _person),
          const SizedBox(height: 16),
          if (_interactions.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 24),
              child: EmptyState(
                icon: Icons.chat_bubble_outline,
                title: 'No conversations yet',
                message: 'Tap the mic to record a note or + to write one.',
              ),
            )
          else
            for (var i = 0; i < _interactions.length; i++) ...[
              _buildInteraction(_interactions[i]),
              if (i != _interactions.length - 1) const SizedBox(height: 12),
            ],
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.small(
            heroTag: 'mic',
            onPressed: _recordAudio,
            tooltip: 'Record audio',
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            foregroundColor: theme.colorScheme.primary,
            child: const Icon(Icons.mic),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: 'add',
            onPressed: () => _showNoteDialog(),
            icon: const Icon(Icons.add_comment_outlined),
            label: const Text('Log conversation'),
          ),
        ],
      ),
    );
  }
}

String _fullName(Person person) => [
  person.firstname,
  person.lastname,
  person.othername,
].whereType<String>().where((part) => part.isNotEmpty).join(' ');

class _PersonHeader extends StatelessWidget {
  final Person person;

  const _PersonHeader({required this.person});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final metAt = person.metAt?.trim();
    final followUp = person.followUpDate;
    final isDue = followUp != null && !followUp.isAfter(DateTime.now());

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            PersonAvatar(photoPath: person.photoPath, radius: 40),
            const SizedBox(height: 14),
            Text(
              _fullName(person),
              style: theme.textTheme.headlineSmall,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (metAt != null && metAt.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                metAt,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
            if (followUp != null) ...[
              const SizedBox(height: 12),
              _FollowUpChip(date: followUp, isDue: isDue),
            ],
          ],
        ),
      ),
    );
  }
}

class _FollowUpChip extends StatelessWidget {
  final DateTime date;
  final bool isDue;

  const _FollowUpChip({required this.date, required this.isDue});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final background = isDue ? AppColors.wheat : scheme.surfaceContainerHighest;
    final foreground = isDue ? AppColors.indigoDeep : scheme.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: isDue ? null : Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isDue ? Icons.notifications_active : Icons.event_outlined,
            size: 16,
            color: foreground,
          ),
          const SizedBox(width: 6),
          Text(
            'Follow-up ${formatDayMonth(date)}',
            style: theme.textTheme.labelMedium?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
