import 'package:flutter/material.dart';
import '../../../controllers/favorites_controller.dart';
import '../../../models/destination_model.dart';
import '../../localization/l10n.dart';
import '../../../l10n/app_localizations.dart';

Future<void> toggleFavoriteWithFeedback(
  BuildContext context,
  FavoritesController controller,
  String id, [
  DestinationModel? destination,
]) => _toggle(
  ScaffoldMessenger.of(context),
  context.l10n,
  controller,
  id,
  destination,
);

Future<void> _toggle(
  ScaffoldMessengerState messenger,
  AppLocalizations l10n,
  FavoritesController controller,
  String id,
  DestinationModel? destination,
) async {
  final wasSaved = controller.isFavorite(id);
  final model =
      destination ??
      controller.favorites.where((item) => item.id == id).firstOrNull;
  final saved = await controller.toggleFavorite(id, model);
  if (saved == null || !messenger.mounted) return;
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(
          saved
              ? (wasSaved ? l10n.favoriteRemoved : l10n.favoriteSaved)
              : l10n.favoriteSaveFailed,
        ),
        action: !saved || wasSaved
            ? SnackBarAction(
                label: saved ? l10n.undo : l10n.retry,
                onPressed: () {
                  if (messenger.mounted &&
                      controller.isFavorite(id) ==
                          (saved ? !wasSaved : wasSaved)) {
                    _toggle(messenger, l10n, controller, id, model);
                  }
                },
              )
            : null,
      ),
    );
}
