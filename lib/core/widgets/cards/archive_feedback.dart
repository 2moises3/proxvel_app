import 'package:flutter/material.dart';
import '../../../controllers/archive_controller.dart';
import '../../../models/archive_model.dart';
import '../../../models/destination_model.dart';
import '../../localization/l10n.dart';

Future<void> toggleArchiveWithFeedback(
  BuildContext context,
  ArchiveController controller,
  String id, {
  DestinationModel? destination,
  ArchiveModel? archivedDestination,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  final l10n = context.l10n;
  final wasArchived = controller.isArchived(id);

  Future<void> toggle(bool expectedState) async {
    if (!messenger.mounted || controller.isArchived(id) != expectedState) {
      return;
    }
    final saved = await controller.toggleArchive(
      id,
      destination,
      archivedDestination,
    );
    if (saved == null || !messenger.mounted) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            saved
                ? (expectedState ? l10n.archiveRestored : l10n.archiveHidden)
                : l10n.archiveSaveFailed,
          ),
          action: SnackBarAction(
            label: saved ? l10n.undo : l10n.retry,
            onPressed: () => toggle(saved ? !expectedState : expectedState),
          ),
        ),
      );
  }

  await toggle(wasArchived);
}
