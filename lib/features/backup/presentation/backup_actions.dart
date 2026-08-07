import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openlifts/features/backup/application/backup_providers.dart';
import 'package:openlifts/features/backup/domain/backup_repository.dart';
import 'package:openlifts/l10n/app_localizations.dart';
import 'package:openlifts/shared/widgets/confirm_dialog.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Serializes user data and hands it to the OS share sheet.
Future<void> exportBackup(BuildContext context, WidgetRef ref) async {
  final messenger = ScaffoldMessenger.of(context);
  final loc = AppLocalizations.of(context)!;
  try {
    final json = await ref.read(backupControllerProvider.notifier).exportJson();
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/openlifts-backup.json');
    await file.writeAsString(json);
    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path)], subject: 'OpenLifts backup'),
    );
  } on Object catch (e) {
    messenger.showSnackBar(SnackBar(content: Text(loc.exportFailed('$e'))));
  }
}

/// Picks a backup file, validates it, confirms the destructive replace, writes
/// a safety export of the current state, then restores.
Future<void> importBackup(BuildContext context, WidgetRef ref) async {
  final messenger = ScaffoldMessenger.of(context);
  final loc = AppLocalizations.of(context)!;
  final controller = ref.read(backupControllerProvider.notifier);

  final String json;
  try {
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      withData: true,
    );
    if (picked == null) return; // cancelled
    final file = picked.files.single;
    json = file.bytes != null
        ? utf8.decode(file.bytes!)
        : await File(file.path!).readAsString();
  } on Object catch (e) {
    messenger.showSnackBar(SnackBar(content: Text(loc.couldNotReadFile('$e'))));
    return;
  }

  // Validate before anything destructive; fail fast on newer/corrupt files.
  try {
    controller.validate(json);
  } on IncompatibleBackupException catch (e) {
    messenger.showSnackBar(SnackBar(content: Text(e.message)));
    return;
  } on CorruptBackupException catch (e) {
    messenger.showSnackBar(SnackBar(content: Text(e.message)));
    return;
  }

  if (!context.mounted) return;
  final confirmed = await showConfirmDialog(
    context,
    title: loc.restoreConfirmTitle,
    message: loc.restoreConfirmMessage,
    confirmLabel: loc.replace,
    cancelLabel: loc.cancel,
  );
  if (confirmed != true) return;

  try {
    // Safety export of the current state, then the transactional restore.
    final current = await controller.exportJson();
    final docs = await getApplicationDocumentsDirectory();
    await File('${docs.path}/openlifts-safety-backup.json')
        .writeAsString(current);
    await controller.restore(json);
    messenger.showSnackBar(SnackBar(content: Text(loc.backupRestoredMessage)));
  } on IncompatibleBackupException catch (e) {
    messenger.showSnackBar(SnackBar(content: Text(e.message)));
  } on CorruptBackupException catch (e) {
    messenger.showSnackBar(SnackBar(content: Text(e.message)));
  } on Object catch (e) {
    messenger.showSnackBar(SnackBar(content: Text(loc.restoreFailed('$e'))));
  }
}
