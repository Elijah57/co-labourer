import 'dart:async';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'person_edit_screen.dart';
import '../../../models/interaction.dart';
import '../../../models/person.dart';
import '../../repository/interaction.dart';
import '../../repository/person.dart';
import '../../services/audio_service.dart';
import '../../services/notification_service.dart';
import '../../services/auto_backup.dart';
import '../../services/photo_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/date_format.dart';
import '../../widgets/contact_buttons.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/interaction_card.dart';
import '../../widgets/person_avatar.dart';
import '../../widgets/person_info_card.dart';
import '../../widgets/photo_source_sheet.dart';
import '../../widgets/recording_dialog.dart';

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
  String? _playingId;
  late final StreamSubscription<void> _completeSub;

  @override
  void initState() {
    super.initState();
    _person = widget.person;
    _completeSub = _audio.onComplete.listen((_) {
      if (mounted) setState(() => _playingId = null);
    });
    _load();
  }

  @override
  void dispose() {
    _completeSub.cancel();
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
    if (!mounted) {
      await _audio.cancelRecording();
      return;
    }

    final save = await showRecordingDialog(
      context,
      levels: _audio.recordingLevels,
    );

    if (save == true) {
      await _audio.stopRecording();
      await _repo.addInteraction(personId: _person.id, audioPath: fileName);
      await _load();
    } else {
      await _audio.cancelRecording();
    }
  }

  Future<void> _editPerson() async {
    final result = await Navigator.push<Person?>(
      context,
      MaterialPageRoute(
        builder: (_) => PersonEditScreen(original: _person),
      ),
    );
    if (result != null && mounted) {
      final updated = result;
      await _peopleRepo.updatePerson(updated);
      await NotificationService.instance.schedule(updated);
      AutoBackup.instance.markDirty();
      if (mounted) setState(() => _person = updated);
    }
  }

  Future<void> _playInteraction(Interaction item) async {
    final path = item.audioPath;
    if (path == null) return;
    if (_playingId == item.id) {
      await _audio.stop();
      if (mounted) setState(() => _playingId = null);
      return;
    }
    await _audio.play(path);
    if (!mounted) return;
    setState(() => _playingId = item.id);
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
        setState(() {
          _interactions.removeWhere((x) => x.id == item.id);
          if (_playingId == item.id) _playingId = null;
        });
        _repo.deleteInteraction(item.id);
      },
      child: InteractionCard(
        interaction: item,
        isPlaying: _playingId == item.id,
        onTap: () => _showNoteDialog(existing: item),
        onPlay: () => _playInteraction(item),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final phone = _person.phoneno?.trim();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Person'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit person',
            onPressed: _editPerson,
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            sliver: SliverToBoxAdapter(
              child: Column(
                children: [
                  PersonInfoCard(
                    person: _person,
                    avatar: PersonAvatar(photoPath: _person.photoPath, radius: 40),
                    conversationCount: _interactions.length,
                  ),
                  if (phone != null && phone.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    ContactButtons(phoneNo: phone),
                  ],
                ],
              ),
            ),
          ),
          if (_interactions.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyState(
                icon: Icons.chat_bubble_outline,
                title: 'No conversations yet',
                message: 'Tap the mic to record a note or + to write one.',
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final item = _interactions[index];
                  return _buildInteraction(item);
                },
                childCount: _interactions.length,
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
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