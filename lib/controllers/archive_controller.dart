import 'package:flutter/material.dart';
import '../models/archive_model.dart';
import '../models/destination_model.dart';
import '../integration/services/archive_service.dart';

/// Archivados BACKEND-ONLY: la fuente de verdad es PostgreSQL.
/// No se almacenan archivados en SharedPreferences.
/// Un destino archivado deja de aparecer en Explorar y en "Para Ti".
class ArchiveController extends ChangeNotifier {
  final ArchiveService _archiveService;

  bool isLoading = false;
  List<ArchiveModel> archives = [];
  Set<String> archivedDestinationIds = {};
  String? error;
  bool hasLoaded = false;
  int _sessionGeneration = 0;
  int _mutationRevision = 0;
  final _pendingIds = <String>{};
  Future<void>? _pendingLoad;

  ArchiveController(this._archiveService);

  Future<void> loadArchives() =>
      _pendingLoad ??= _loadArchives(_sessionGeneration);

  Future<void> _loadArchives(int generation) async {
    final revision = _mutationRevision;
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final arcModels = await _archiveService.getArchives();
      if (generation != _sessionGeneration) return;
      if (revision != _mutationRevision || _pendingIds.isNotEmpty) return;
      archives = arcModels;
      archivedDestinationIds = archives.map((a) => a.destinationId).toSet();
      hasLoaded = true;
    } catch (e) {
      if (generation != _sessionGeneration) return;
      error = 'No pudimos cargar tus destinos archivados. Intenta nuevamente.';
    } finally {
      if (generation == _sessionGeneration) {
        _pendingLoad = null;
        isLoading = false;
        notifyListeners();
      }
    }
  }

  /// Archiva/desarchiva. Optimista en UI, persiste en backend.
  Future<bool?> toggleArchive(
    String id, [
    DestinationModel? model,
    ArchiveModel? archivedDestination,
  ]) async {
    if (!_pendingIds.add(id)) return null;
    _mutationRevision++;
    final generation = _sessionGeneration;
    error = null;
    final isArc = isArchived(id);
    final previousArchive = isArc
        ? archives.where((a) => a.destinationId == id).firstOrNull
        : null;
    if (isArc) {
      archivedDestinationIds.remove(id);
      archives.removeWhere((a) => a.destinationId == id);
    } else {
      archivedDestinationIds.add(id);
      if (archivedDestination != null) {
        archives.add(archivedDestination);
      } else if (model != null && !archives.any((a) => a.destinationId == id)) {
        archives.add(
          ArchiveModel(
            destinationId: model.id,
            name: model.name,
            city: model.city,
            region: model.region,
            category: model.category,
            coverImageUrl: model.imageUrl,
            createdAt: DateTime.now(),
          ),
        );
      }
    }
    notifyListeners();

    try {
      if (isArc) {
        if (!await _archiveService.removeArchive(id)) {
          throw StateError('Archive removal rejected');
        }
      } else {
        if (!await _archiveService.addArchive(id)) {
          throw StateError('Archive rejected');
        }
      }
      return generation == _sessionGeneration ? true : null;
    } catch (_) {
      if (generation != _sessionGeneration) return null;
      // Revertir cambio optimista
      if (isArc) {
        archivedDestinationIds.add(id);
        if (previousArchive != null) archives.add(previousArchive);
      } else {
        archivedDestinationIds.remove(id);
        archives.removeWhere((a) => a.destinationId == id);
      }
      error = 'No pudimos actualizar tus archivados. Intenta nuevamente.';
      return false;
    } finally {
      if (generation == _sessionGeneration) {
        _pendingIds.remove(id);
        notifyListeners();
      }
    }
  }

  bool isArchived(String id) => archivedDestinationIds.contains(id);

  /// Limpia todo el estado en memoria. Llamar al logout/cambio de usuario.
  void clearState() {
    _sessionGeneration++;
    _pendingLoad = null;
    _pendingIds.clear();
    hasLoaded = false;
    archives = [];
    archivedDestinationIds = {};
    error = null;
    isLoading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _sessionGeneration++;
    super.dispose();
  }
}
