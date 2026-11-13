import 'dart:async';
import 'package:flutter/material.dart';
import '../integration/services/visit_service.dart';
import '../integration/api/api_client.dart';
import '../models/visit_model.dart';

class VisitController extends ChangeNotifier {
  final VisitService _visitService;

  VisitModel? activeVisit;
  AtlasSummaryModel? atlasSummary;
  PendingSealDestination? pendingDestination;

  bool isLoading = false;
  bool isActionLoading = false;
  String? error;
  String? actionMessage;
  String? latestStampedDestinationId;

  Timer? _tickerTimer;
  int _sessionRevision = 0;
  int _activeRevision = 0;

  VisitController([VisitService? visitService])
    : _visitService = visitService ?? VisitService();

  @override
  void dispose() {
    _sessionRevision++;
    _tickerTimer?.cancel();
    super.dispose();
  }

  void setPendingDestination(PendingSealDestination dest) {
    pendingDestination = dest;
    notifyListeners();
  }

  void dismissStampedStatus() {
    latestStampedDestinationId = null;
    notifyListeners();
  }

  void clearPendingDestination() {
    pendingDestination = null;
    notifyListeners();
  }

  void clearSession() {
    _sessionRevision++;
    _tickerTimer?.cancel();
    activeVisit = null;
    atlasSummary = null;
    pendingDestination = null;
    latestStampedDestinationId = null;
    error = null;
    actionMessage = null;
    isLoading = false;
    isActionLoading = false;
    notifyListeners();
  }

  /// Carga el Atlas y consulta si hay visita activa
  Future<void> initVisitState() async {
    await Future.wait([loadAtlas(), checkActiveVisit()]);
  }

  Future<void> loadAtlas() async {
    final session = _sessionRevision;
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final atlas = await _visitService.getAtlas();
      if (session == _sessionRevision) atlasSummary = atlas;
    } catch (_) {
      if (session == _sessionRevision) {
        error = 'No pudimos sincronizar tu Atlas de visitas.';
      }
    } finally {
      if (session == _sessionRevision) {
        isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> checkActiveVisit() async {
    if (isActionLoading) return;
    final session = _sessionRevision;
    final revision = ++_activeRevision;
    try {
      final active = await _visitService.getActiveVisit();
      if (session != _sessionRevision || revision != _activeRevision) return;
      activeVisit = active;
      _setupTickerIfNeeded();
      notifyListeners();
    } catch (_) {
      // Keep the last known visit and retry on the next poll.
    }
  }

  Future<bool> startCheckIn({
    required String destinationId,
    required double latitude,
    required double longitude,
  }) async {
    if (isActionLoading) return false;
    final session = _sessionRevision;
    _activeRevision++;
    isActionLoading = true;
    error = null;
    actionMessage = null;
    notifyListeners();

    try {
      final visit = await _visitService.checkIn(
        destinationId: destinationId,
        latitude: latitude,
        longitude: longitude,
      );
      if (session != _sessionRevision) return false;
      latestStampedDestinationId = null;
      activeVisit = visit;
      if (pendingDestination?.destinationId == destinationId) {
        pendingDestination = null;
      }
      actionMessage = '¡Check-in iniciado! Disfruta tu recorrido turístico.';
      _setupTickerIfNeeded();
      return session == _sessionRevision;
    } catch (e) {
      if (session != _sessionRevision) return false;
      error = e is ApiException
          ? e.message
          : 'No pudimos iniciar la visita. Inténtalo nuevamente.';
      return false;
    } finally {
      if (session == _sessionRevision) {
        isActionLoading = false;
        notifyListeners();
      }
    }
  }

  Future<bool> verifyActiveVisit({
    required double latitude,
    required double longitude,
  }) async {
    final visit = activeVisit;
    if (visit == null || isActionLoading) return false;

    final session = _sessionRevision;
    _activeRevision++;
    isActionLoading = true;
    error = null;
    actionMessage = null;
    notifyListeners();

    try {
      await _visitService.verifyVisit(
        visitId: visit.visitId,
        latitude: latitude,
        longitude: longitude,
      );
      if (session != _sessionRevision) return false;
      activeVisit = null;
      latestStampedDestinationId = visit.destinationId;
      _tickerTimer?.cancel();
      actionMessage =
          '🎉 ¡Felicitaciones! Visita sellada en tu Atlas de viajes.';
      // Recargar el atlas con el nuevo sello
      await loadAtlas();
      return session == _sessionRevision;
    } catch (e) {
      if (session != _sessionRevision) return false;
      error = e is ApiException
          ? e.message
          : 'No pudimos sellar la visita. Inténtalo nuevamente.';
      return false;
    } finally {
      if (session == _sessionRevision) {
        isActionLoading = false;
        notifyListeners();
      }
    }
  }

  void _setupTickerIfNeeded() {
    _tickerTimer?.cancel();
    if (activeVisit != null && activeVisit!.isInProgress) {
      // Timer cada 30 segundos para sincronizar y actualizar el progreso visual suavemente
      _tickerTimer = Timer.periodic(const Duration(seconds: 30), (_) {
        unawaited(checkActiveVisit());
      });
    }
  }
}
