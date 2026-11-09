# AGENTS.md

Project-specific guidance for agents working in this repository. When this file conflicts with a generic Flutter tutorial or a stale external draft, the code in this repository wins.

## What This App Is

Co-laborer is an Android-first Flutter app for remembering people and conversations. It tracks people, interaction notes, follow-up dates, birthdays, voice notes, a personal journal, optional Google Drive app-data backup, and CSV export.

Core properties:

- Local-first: SQLite is the source of truth.
- No custom backend, analytics, telemetry, or crash reporting.
- Google Drive is used only for backup/restore through `drive.appdata`.
- Personal data is currently stored unencrypted on-device. Do not claim otherwise.
- The app is still using development defaults in places; see "Known Gaps".

## Toolchain

- Dart SDK constraint: `^3.12.2`.
- Current local Flutter: stable 3.44.5 / Dart 3.12.2.
- Android Gradle Plugin: 9.0.1.
- Kotlin: 2.3.20.
- SDK levels come from Flutter defaults: compile 36, min 24, target 36.
- Java/Kotlin target: 17.
- Release builds currently use debug signing and application ID `com.example.co_labourer`. Do not ship without replacing both.

Useful commands:

```bash
flutter pub get
flutter analyze
flutter test
flutter run
flutter build apk --debug
```

There is no custom lint script, code-generation step, or Makefile. `flutter analyze` is the lint/typecheck command. At the last check it reported six pre-existing warnings/info (unused imports/fields, an unused `_PersonHeader`, deprecated `onPopInvoked`, and `sort_child_properties_last`). Do not assume a warning was introduced by your change without checking `git diff`.

## Repository Layout

```text
lib/
  main.dart                 app startup and MaterialApp
  database.dart             SQLite singleton and migrations
  data/audio_storage.dart   app-documents audio/ and photos/ directories
  models/                   Person, Interaction, JournalEntry, Profile
  repository/               PeopleRepository and InteractionsRepository
  repositories/             JournalRepository, ProfileRepository,
                            and the separate orphan-audio helper
  screens/
    home_screen.dart        God / Me / Assignment tiles + Settings
    me/me_screen.dart       profile + journal
    person/                 people list, detail, edit
    settings_screen.dart    backup, restore, app lock, CSV export
  services/                 audio, photo, notifications, backup, auth,
                            auto-backup, app lock, export
  theme/app_theme.dart      colors, typography, Material 3 theme
  utils/                    birthday parsing, date display
  widgets/                  reusable UI
test/widget_test.dart       default counter test only; currently stale
```

Important naming caveat:

- People live in `lib/repository/person.dart`.
- Person interactions live in `lib/repository/interaction.dart`.
- `lib/repositories/interactions_repository.dart` contains a different `InteractionsRepository` class with only `removeOrphanAudio()`; it is not the main interaction repository and is currently not called.
- Do not merge or rename these layers without an explicit request.

## Startup and Navigation

`lib/main.dart`:

1. Initializes `AppDatabase.instance.database`.
2. Initializes `AutoBackup`.
3. Initializes `AppLock`.
4. Initializes `NotificationService`.
5. Runs `MaterialApp`, wrapped in `LockGate`.

Home has three tiles:

- `God`: intentionally non-tappable placeholder.
- `Me`: opens the profile/journal screen.
- `Assignment`: opens the people list.

Settings is the gear icon in the Home app bar.

## Database

`lib/database.dart` is the only SQLite owner. It currently uses database version **7** and the file `colaborer.db`.

`PRAGMA foreign_keys = ON` is enabled. Interactions use `ON DELETE CASCADE` from `people`.

Schema:

- `people`: `id`, `firstname`, `lastname`, `othername`, `phoneno`, `email`, `address`, `photo_path`, `birthday`, `partner`, `intro`, `met_on`, `met_at`, `follow_up_date`, `created_at`.
- `interactions`: `id`, `person_id`, `note`, `audio_path`, `created_at`.
- `journal_entries`: `id`, `note`, `audio_path`, `created_at`.
- `profile`: single-row key/value-ish shape: `id`, `name`, `about`.

Conventions:

- IDs are UUID v4 strings.
- Timestamps are ISO-8601 strings in local time. Use `DateTime.toIso8601String()`.
- Store photo/audio filenames in SQLite, not absolute paths.
- Audio files live in `<app documents>/audio/`; photos live in `<app documents>/photos/`.
- Repositories call `AutoBackup.instance.markDirty()` after mutations. Keep this behavior when adding writes.
- Migrations are additive and versioned. Never change the schema or version without a migration that preserves existing user data.
- `Person.fromMap` tolerates corrupt/legacy birthday text by loading it as `null`. Do not turn that into a crash.

## Birthday Format

`Birthday` in `lib/utils/birthday.dart` supports both known-year and year-less birthdays:

- Database format: `YYYY-MM-DD` when the year is known.
- Database format: `--MM-DD` when the year is intentionally omitted.
- Parsing also accepts `12 March 1990`, `March 12`, and similar day/month text.

Do not replace this format without a migration and legacy-data handling. `Person.copyWith` needs explicit clear flags (`clearBirthday`, `clearFollowUpDate`, `clearMetOn`) because a nullable argument cannot distinguish "leave unchanged" from "set to null".

## UX Conventions

- Material 3, light/dark via system setting.
- `buildTheme` is the design source of truth. Primary palette: deep indigo and wheat/gold. Cards are borderless-looking with outlines; radii are 16/20/12; app bars are indigo.
- Keep screens consistent with existing `Scaffold`/`AppBar`/card patterns.
- People list: searchable by name and `metAt`; due-only filter; swipe-to-delete with confirmation; FAB to add.
- Person detail: info card, interaction list, swipe-to-delete, mic FAB, "Log conversation" FAB.
- Person edit: birthday is chosen with `showBirthdayPicker`; follow-up is read-only and date-picked.
- Me: profile dialog opens automatically when no profile exists; journal entries can be written or recorded; swipe-to-delete.
- The birthday picker lets the user omit the year.
- `PersonInfoCard` currently displays only `firstname` at the top and not all stored fields. Do not assume every database field has a visible control.

## Audio and Visualizer

Existing dependencies: `record` and `audioplayers`. Do not add another audio dependency without asking.

- `AudioService` records `.m4a` files, exposes a normalized 100 ms amplitude stream, and exposes playback completion.
- Recording uses real microphone levels through `VoiceVisualizer.levelStream`.
- Playback indicators use the same widget with synthetic animation because `audioplayers` does not expose levels here.
- Callers own `AudioService` and must cancel stream subscriptions and dispose the service.
- Person detail and Me both track a single `_playingId`; tapping play/stop toggles it, and `onComplete` clears it.
- Deleting an interaction or journal row does not delete its audio file today. `removeOrphanAudio()` exists but is not wired in.

## Notifications

`NotificationService` uses `flutter_local_notifications` and `timezone`.

- Channel: `followups`, high importance.
- Follow-up target: 09:00 local date, scheduled inexactly with `inexactAllowWhileIdle`.
- A notification ID is derived from the first seven hex characters of the person UUID.
- Editing a person reschedules that person's reminder; deleting a person cancels it.
- Restore calls `rescheduleAll`.
- Notification payloads contain the person ID.
- `onOpenPerson` exists but is not assigned anywhere currently, so tapping a notification does not navigate to the person. Do not claim deep-link navigation works.
- Startup does not call `rescheduleAll` or `removeOrphanAudio`.

## Backup, Restore, Export

Backup:

- Backs up the SQLite database plus audio and photo files to Drive `appDataFolder`.
- Checkpoints WAL before uploading the DB.
- Uploads audio/photo files only when a file of that name is not already remote.
- Auto backup runs about 30 seconds after a change when enabled and silently authenticated.

Restore:

- Downloads the remote DB.
- Checkpoints and closes the local DB.
- Copies the current DB to `<db>.bak`.
- Replaces the DB, removes `-wal`/`-shm`, reopens it, and restores the `.bak` on failure.
- Downloads only missing audio/photo files; it does not delete extra local files.
- Reschedules notifications after a successful restore.

CSV export:

- `ExportService` currently exports people only: `ID,Firstname,Lastname,Phoneno,Met on,Follow-up`.
- It does not export conversations, notes, birthdays, email, address, or audio.
- The Settings subtitle says "people and conversations"; that description is inaccurate.
- The file is written to hard-coded `/tmp/co_labourer_export.csv`, which is not a reliable Android app-writable location. If you touch export, use an app temp directory.
- Export is unencrypted and the UI warns the user.

Do not represent export as a full backup. Drive backup is the full backup mechanism.

## Privacy and Security Rules

- Treat names, phone numbers, notes, birthdays, photos, and audio as sensitive personal data.
- Do not add analytics, tracking, remote logging, or third-party data sharing.
- Do not log personal content in production paths; `debugPrint` is acceptable for non-content errors.
- Keep the existing minimal Android permissions: `RECORD_AUDIO`, `POST_NOTIFICATIONS`, `RECEIVE_BOOT_COMPLETED`, `USE_BIOMETRIC`. Do not add contacts, broad storage, location, or internet-adjacent permissions without an explicit request.
- App lock uses `local_auth` and a persisted `app_lock_enabled` flag. It locks after 30 seconds in the background. `setEnabled(true)` refuses when the device has no supported authentication; `authenticate()` returns `true` when the device is unsupported. Preserve that behavior unless specifically asked to change it.
- There is no `FLAG_SECURE`, no Android recent-app-preview protection, and no native screen-privacy layer. Do not claim screenshots are blocked. Adding one is a product/security decision; ask first.
- The Google OAuth web client ID is a public client identifier, not a client secret. Do not add private keys to the repo.
- The database, audio, photos, and CSV are not encrypted at rest. Do not describe them as encrypted.

## Change Discipline

- Make the smallest change that solves the requested problem.
- Do not refactor adjacent code, rename layers, reformat whole files, or remove pre-existing dead code unless asked.
- Match the existing Material/theme patterns rather than introducing a new design system.
- Do not add packages for functionality that the current dependencies already provide.
- Do not change the Drive backup model, OAuth flow, database schema, or birthday serialization as drive-by work.
- When a nullable person field must be cleared, use the explicit `copyWith` clear flag.
- After code changes, run `flutter analyze` and at least `flutter build apk --debug` when the change affects runtime behavior. Report remaining warnings honestly.
- Do not commit unless the user explicitly requests it.

## Testing Reality

- `test/widget_test.dart` is still the default Flutter counter test and does not match this app. Treat it as stale, not as evidence that behavior is covered.
- There are no repository, migration, backup, export, notification, or birthday tests.
- If adding tests, prefer pure-unit coverage for `Birthday` parsing/serialization and database migrations first. Do not assume test infrastructure that is not in `pubspec.yaml`.
- Manual verification is still needed for microphone recording, playback indicators, notification taps, Drive sign-in, restore, share sheet, and app lock.

## Known Gaps / Do Not Assume

- Release signing and `applicationId` are still development defaults.
- Notification tap navigation is not wired.
- `removeOrphanAudio()` is not called; deleted records can leave audio files behind.
- Export is people-only, writes to `/tmp`, and its Settings subtitle overstates what it contains.
- Person profile info such as `metOn`, `partner`, `intro`, email, and address is only partially surfaced in the UI.
- `PersonInfoCard` shows the first name as the heading, not necessarily the full name.
- Birthday is informational; follow-up reminders are the only scheduled reminders.
- The only test is the stale default counter test.
- The app is local-first and unencrypted at rest; app lock and export warnings are not encryption.
