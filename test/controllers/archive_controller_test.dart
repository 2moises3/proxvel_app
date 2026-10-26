import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:proxvell_app/controllers/archive_controller.dart';
import 'package:proxvell_app/integration/services/archive_service.dart';
import 'package:proxvell_app/models/archive_model.dart';

class _Archives extends ArchiveService {
  bool accept = false;
  @override
  Future<bool> addArchive(String id) async => accept;
  @override
  Future<bool> removeArchive(String id) async => accept;
  @override
  Future<List<ArchiveModel>> getArchives() async => throw StateError('offline');
}

class _DelayedArchives extends ArchiveService {
  final requests = <Completer<List<ArchiveModel>>>[];
  final mutation = Completer<bool>();
  @override
  Future<List<ArchiveModel>> getArchives() {
    final request = Completer<List<ArchiveModel>>();
    requests.add(request);
    return request.future;
  }

  @override
  Future<bool> addArchive(String id) => mutation.future;
}

void main() {
  test(
    'first load is unknown until success; concurrent callers share the request',
    () async {
      final service = _DelayedArchives();
      final controller = ArchiveController(service);
      final first = controller.loadArchives();
      final second = controller.loadArchives();
      expect(service.requests.length, 1);
      expect(controller.hasLoaded, false);
      expect(controller.isLoading, true);
      service.requests.single.complete([
        ArchiveModel(destinationId: 'hidden', name: 'Hidden'),
      ]);
      await Future.wait([first, second]);
      expect(controller.hasLoaded, true);
      expect(controller.isArchived('hidden'), true);
    },
  );

  test(
    'initial failure remains unknown and retry can confirm an empty list',
    () async {
      final service = _DelayedArchives();
      final controller = ArchiveController(service);
      final first = controller.loadArchives();
      service.requests.first.completeError(StateError('offline'));
      await first;
      expect(controller.hasLoaded, false);
      expect(controller.error, isNotNull);
      final retry = controller.loadArchives();
      service.requests.last.complete([]);
      await retry;
      expect(controller.hasLoaded, true);
      expect(controller.error, isNull);
    },
  );

  test(
    'old session response cannot replace current exclusions or end its loading',
    () async {
      final service = _DelayedArchives();
      final controller = ArchiveController(service);
      final old = controller.loadArchives();
      controller.clearState();
      final current = controller.loadArchives();
      service.requests.first.complete([
        ArchiveModel(destinationId: 'old', name: 'Old'),
      ]);
      await old;
      expect(controller.hasLoaded, false);
      expect(controller.isLoading, true);
      expect(controller.isArchived('old'), false);
      service.requests.last.complete([
        ArchiveModel(destinationId: 'new', name: 'New'),
      ]);
      await current;
      expect(controller.isArchived('new'), true);
      expect(controller.isArchived('old'), false);
    },
  );

  test(
    'failed mutation from previous session cannot rollback new session state',
    () async {
      final service = _DelayedArchives();
      final controller = ArchiveController(service);
      final old = controller.toggleArchive('shared');
      controller.clearState();
      final current = controller.loadArchives();
      service.requests.last.complete([
        ArchiveModel(destinationId: 'shared', name: 'Shared'),
      ]);
      await current;
      service.mutation.complete(false);
      await old;
      expect(controller.isArchived('shared'), true);
      expect(controller.error, isNull);
    },
  );

  test('refresh failure preserves a previously confirmed list', () async {
    final service = _DelayedArchives();
    final controller = ArchiveController(service);
    final first = controller.loadArchives();
    service.requests.first.complete([
      ArchiveModel(destinationId: 'hidden', name: 'Hidden'),
    ]);
    await first;
    final refresh = controller.loadArchives();
    service.requests.last.completeError(StateError('offline'));
    await refresh;
    expect(controller.hasLoaded, true);
    expect(controller.isArchived('hidden'), true);
  });
  test(
    'failed persistence rolls back, retry clears error, failed refresh preserves exclusions',
    () async {
      final service = _Archives();
      final controller = ArchiveController(service);
      await controller.toggleArchive('d1');
      expect(controller.isArchived('d1'), false);
      expect(controller.error, isNotNull);
      service.accept = true;
      await controller.toggleArchive('d1');
      expect(controller.isArchived('d1'), true);
      expect(controller.error, isNull);
      await controller.loadArchives();
      expect(controller.isArchived('d1'), true);
      service.accept = false;
      await controller.toggleArchive('d1');
      expect(controller.isArchived('d1'), true);
      service.accept = true;
      await controller.toggleArchive('d1');
      expect(controller.isArchived('d1'), false);
      expect(controller.error, isNull);
    },
  );
}
