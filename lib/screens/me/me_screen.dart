import 'dart:async';

import 'package:flutter/material.dart';
import '../../models/journal_entry.dart';
import '../../models/profile.dart';
import '../../repositories/journal_repository.dart';
import '../../repositories/profile_repository.dart';
import '../../services/audio_service.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/note_dialog.dart';
import '../../widgets/profile_dialog.dart';
import '../../widgets/recording_dialog.dart';
import '../../widgets/voice_visualizer.dart';

class MeScreen extends StatefulWidget {
  const MeScreen({super.key});

  @override
  State<MeScreen> createState() => _MeScreenState();
}

class _MeScreenState extends State<MeScreen> {
  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  final _profileRepo = ProfileRepository();
  final _journal = JournalRepository();
  final _audio = AudioService();

  Profile? _profile;
  List<JournalEntry> _entries = [];
  bool _loaded = false;
  String? _playingId;
  late final StreamSubscription<void> _completeSub;

  @override
  void initState() {
    super.initState();
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
    final profile = await _profileRepo.get();
    final entries = await _journal.getAll();
    if (!mounted) return;
    setState(() {
      _profile = profile;
      _entries = entries;
      _loaded = true;
    });
    if (profile == null) _editProfile();
  }

  Future<void> _reloadEntries() async {
    final entries = await _journal.getAll();
    if (!mounted) return;
    setState(() => _entries = entries);
  }

  Future<void> _editProfile() async {
    final result = await showDialog<Profile>(
      context: context,
      builder: (_) => ProfileDialog(initial: _profile),
    );
    if (result == null) return;
    await _profileRepo.save(result);
    if (!mounted) return;
    setState(() => _profile = result);
  }

  Future<void> _writeEntry({JournalEntry? existing}) async {
    final note = await showDialog<String>(
      context: context,
      builder: (_) => NoteDialog(
        title: existing == null ? 'New entry' : 'Edit entry',
        initial: existing?.note,
      ),
    );
    if (note == null || note.isEmpty) return;

    if (existing == null) {
      await _journal.add(note: note);
    } else {
      await _journal.updateNote(existing.id, note);
    }
    await _reloadEntries();
  }

  Future<void> _record() async {
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
      await _journal.add(audioPath: fileName);
      await _reloadEntries();
    } else {
      await _audio.cancelRecording();
    }
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

  String _when(DateTime d) {
    final hh = d.hour.toString().padLeft(2, '0');
    final mm = d.minute.toString().padLeft(2, '0');
    return '${d.day} ${_months[d.month - 1]} ${d.year}, $hh:$mm';
  }

  Widget _header() {
    final scheme = Theme.of(context).colorScheme;
    final profile = _profile;
    return Material(
      color: scheme.surfaceContainerLowest,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      child: InkWell(
        onTap: _editProfile,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: scheme.primaryContainer,
                child: Icon(Icons.person, size: 32, color: scheme.primary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile?.name ?? 'Add your name',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    if (profile?.about != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        profile!.about!,
                        style: TextStyle(color: scheme.onSurfaceVariant),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(Icons.edit_outlined, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _playEntry(JournalEntry entry) async {
    final path = entry.audioPath;
    if (path == null) return;
    if (_playingId == entry.id) {
      await _audio.stop();
      if (mounted) setState(() => _playingId = null);
      return;
    }
    await _audio.play(path);
    if (!mounted) return;
    setState(() => _playingId = entry.id);
  }

  Widget _entryCard(JournalEntry e) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final hasAudio = e.audioPath != null;
    final isPlaying = _playingId == e.id;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Dismissible(
        key: ValueKey(e.id),
        direction: DismissDirection.endToStart,
        background: Container(
          decoration: BoxDecoration(
            color: Colors.red,
            borderRadius: BorderRadius.circular(16),
          ),
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          child: const Icon(Icons.delete, color: Colors.white),
        ),
        confirmDismiss: (_) => _confirmDelete(),
        onDismissed: (_) {
          setState(() {
            _entries.removeWhere((x) => x.id == e.id);
            if (_playingId == e.id) _playingId = null;
          });
          _journal.delete(e.id);
        },
        child: Material(
          color: scheme.surfaceContainerLowest,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: scheme.outlineVariant),
          ),
          child: InkWell(
            onTap: () => _writeEntry(existing: e),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (hasAudio) ...[
                    IconButton.filledTonal(
                      icon: Icon(
                        isPlaying ? Icons.stop_rounded : Icons.play_arrow,
                      ),
                      tooltip: isPlaying ? 'Stop recording' : 'Play recording',
                      onPressed: () => _playEntry(e),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _when(e.createdAt),
                          style: text.labelMedium
                              ?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          e.note ?? 'Voice note',
                          style: e.note == null
                              ? text.bodyLarge?.copyWith(
                                  fontStyle: FontStyle.italic,
                                  color: scheme.onSurfaceVariant,
                                )
                              : text.bodyLarge,
                        ),
                        if (isPlaying)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: VoiceVisualizer(
                              active: true,
                              width: 80,
                              height: 22,
                              barCount: 16,
                              color: scheme.primary,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Me')),
      body: !_loaded
          ? const SizedBox.shrink()
          : CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                    child: _header(),
                  ),
                ),
                if (_entries.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: EmptyState(
                      icon: Icons.edit_note,
                      title: 'Your journal is empty',
                      message:
                          'Tap New entry to write, or the mic to record a voice note.',
                    ),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _entryCard(_entries[index]),
                      childCount: _entries.length,
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
            heroTag: 'me_mic',
            onPressed: _record,
            child: const Icon(Icons.mic),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: 'me_add',
            onPressed: () => _writeEntry(),
            icon: const Icon(Icons.add),
            label: const Text('New entry'),
          ),
        ],
      ),
    );
  }
}