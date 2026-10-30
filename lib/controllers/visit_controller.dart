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

  Timer? _tickerTimer;

  VisitController([VisitService? visitService])
    : _visitService = visitService ?? VisitService();

  @override
  void dispose() {
    _tickerTimer?.cancel();
    super.dispose();
  }

  void setPendingDestination(PendingSealDestination dest) {
    pendingDestination = dest;
    notifyListeners();
  }

  void clearPendingDestination() {
    pendingDestination = null;
    notifyListeners();
  }

  void clearSession() {
    _tickerTimer?.cancel();
    activeVisit = null;
    atlasSummary = null;
    pendingDestination = null;
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
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      atlasSummary = await _visitService.getAtlas();
    } catch (e) {
      error = 'No pudimos sincronizar tu Atlas de visitas.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> checkActiveVisit() async {
    try {
      final active = await _visitService.getActiveVisit();
      activeVisit = active;
      _setupTickerIfNeeded();
      notifyListeners();
    } catch (_) {
      // Silencioso para no bloquear la experiencia si no hay visita
    }
  }

  Future<bool> startCheckIn({
    required String destinationId,
    required double latitude,
    required double longitude,
  }) async {
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
      activeVisit = visit;
      if (pendingDestination?.destinationId == destinationId) {
        pendingDestination = null;
      }
      actionMessage = '¡Check-in iniciado! Disfruta tu recorrido turístico.';
      _setupTickerIfNeeded();
      return true;
    } catch (e) {
      error = e is ApiException
          ? e.message
          : 'No pudimos iniciar la visita. Inténtalo nuevamente.';
      return false;
    } finally {
      isActionLoading = false;
      notifyListeners();
    }
  }

  Future<bool> verifyActiveVisit({
    required double latitude,
    required double longitude,
  }) async {
    if (activeVisit == null) return false;

    isActionLoading = true;
    error = null;
    actionMessage = null;
    notifyListeners();

    try {
      await _visitService.verifyVisit(
        visitId: activeVisit!.visitId,
        latitude: latitude,
        longitude: longitude,
      );
      activeVisit = null;
      _tickerTimer?.cancel();
      actionMessage =
          '🎉 ¡Felicitaciones! Visita sellada en tu Atlas de viajes.';
      // Recargar el atlas con el nuevo sello
      await loadAtlas();
      return true;
    } catch (e) {
      error = e is ApiException
          ? e.message
          : 'No pudimos sellar la visita. Inténtalo nuevamente.';
      return false;
    } finally {
      isActionLoading = false;
      notifyListeners();
    }
  }

  void _setupTickerIfNeeded() {
    _tickerTimer?.cancel();
    if (activeVisit != null && activeVisit!.isInProgress) {
      // Timer cada 30 segundos para sincronizar y actualizar el progreso visual suavemente
      _tickerTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
        final refreshed = await _visitService.getActiveVisit();
        if (refreshed != null) {
          activeVisit = refreshed;
          notifyListeners();
        } else {
          _tickerTimer?.cancel();
        }
      });
    }
  }
}
